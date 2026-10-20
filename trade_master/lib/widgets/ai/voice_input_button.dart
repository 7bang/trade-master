import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../config/on_colors.dart';

/// 눌러서 말하기 — 기기 내장 음성 인식(Android Google, iOS Apple, Chrome)으로 말을 글자로 바꾼다.
/// AI 모델은 쓰지 않는다.
///
/// 기기 음성 인식은 말이 잠깐만 끊겨도 스스로 끝나는 경우가 많다(특히 Android).
/// 그래서 **이어서 듣기**: 한 번 끝났을 때 새로 들은 말이 있으면 바로 다시 듣기 시작해 뒤에 붙이고,
/// 아무 말 없이 한 번 더 끝나면(=말을 마침) [onFinal]로 넘긴다.
/// 버튼을 다시 누르면 기다리지 않고 바로 마친다. 전체 최대 [_maxTotal].
/// 말하는 동안에는 글자를 보여주지 않고, 마친 뒤 최종 문장만 한 번 넘긴다.
class VoiceInputButton extends StatefulWidget {
  /// 말을 마쳤을 때 최종 글자 (비어 있지 않음)
  final ValueChanged<String> onFinal;

  /// 권한 거부·인식 실패 등 안내 문구
  final ValueChanged<String> onError;

  /// 인식 힌트 (품목 이름 등) — 지원하는 기기에서 정확도를 높인다
  final List<String> hints;

  final bool enabled;

  /// 화면이 열리자마자 듣기 시작 (AI 마이크 버튼으로 들어온 경우)
  final bool autoStart;

  const VoiceInputButton({
    super.key,
    required this.onFinal,
    required this.onError,
    this.hints = const [],
    this.enabled = true,
    this.autoStart = false,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  /// 한 번 듣기 안에서 이만큼 조용하면 그 회차를 끝냄 (기기가 더 일찍 끝낼 수도 있음)
  static const _pauseFor = Duration(seconds: 4);

  /// 말하기 전체 최대 시간 (이어 듣기 포함)
  static const _maxTotal = Duration(seconds: 60);

  final _speech = SpeechToText();
  bool _ready = false;
  bool _unavailable = false;
  String _localeId = 'ko_KR';

  bool _listening = false; // 사용자에게 보이는 상태 (이어 듣기 사이에도 true)
  bool _userStopped = false;
  DateTime _startedAt = DateTime.now();

  /// 지난 회차까지 확정된 글자
  String _committed = '';

  /// 이번 회차에서 들은 글자
  String _sessionWords = '';

  /// 회차 번호 — 끝남 신호가 여러 번 와도 한 번만 처리
  int _session = 0;
  int _endedSession = -1;

  /// 소리 크기 0~1 (버튼 막대 표시용). 기기마다 값 범위가 달라 들어온 값의 범위로 맞춘다
  double _level = 0;
  double _minLevel = -2; // Android rmsdB 대략 -2 ~ 10
  double _maxLevel = 10;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_listening) _toggle();
      });
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  String get _fullText => [_committed, _sessionWords]
      .where((s) => s.trim().isNotEmpty)
      .join(' ')
      .trim();

  /// 처음 누를 때 초기화 (이때 마이크 권한을 묻는다)
  Future<bool> _ensureReady() async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
    } catch (_) {
      _ready = false;
    }
    if (!_ready) {
      setState(() => _unavailable = true);
      widget.onError('이 기기에서는 음성 입력을 쓸 수 없어요. '
          '마이크 권한을 확인하거나 글자로 입력해주세요.');
      return false;
    }
    try {
      final locales = await _speech.locales();
      final ko = locales.where((l) => l.localeId.toLowerCase().startsWith('ko'));
      if (ko.isNotEmpty) _localeId = ko.first.localeId;
    } catch (_) {}
    return true;
  }

  Future<void> _toggle() async {
    if (_listening) {
      // 다 말했으면 버튼으로 바로 마침 (최종 결과는 끝남 신호로 들어온다)
      _userStopped = true;
      final session = _session;
      await _speech.stop(); // 최종 결과·끝남 신호가 이어서 들어온다
      // 기기가 끝남 신호를 보내지 않는 경우 대비
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_session == session) _endSession();
      });
      return;
    }
    if (!await _ensureReady()) return;

    _committed = '';
    _sessionWords = '';
    _userStopped = false;
    _startedAt = DateTime.now();
    setState(() => _listening = true);
    await _startSession();
  }

  Future<void> _startSession() async {
    _session++;
    _sessionWords = '';
    final remaining = _maxTotal - DateTime.now().difference(_startedAt);
    try {
      await _speech.listen(
        onResult: _handleResult,
        onSoundLevelChange: _handleLevel,
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          pauseFor: _pauseFor,
          listenFor: remaining > const Duration(seconds: 5)
              ? remaining
              : const Duration(seconds: 5),
          contextualPhrases: widget.hints.take(100).toList(),
        ),
      );
    } catch (_) {
      _finish();
    }
  }

  void _handleLevel(double level) {
    if (!mounted || !_listening) return;
    if (level < _minLevel) _minLevel = level;
    if (level > _maxLevel) _maxLevel = level;
    final range = _maxLevel - _minLevel;
    final next = range <= 0 ? 0.0 : ((level - _minLevel) / range).clamp(0.0, 1.0);
    // 너무 잦은 다시 그리기를 줄이려 변화가 작으면 건너뜀
    if ((next - _level).abs() < 0.04) return;
    setState(() => _level = next);
  }

  void _handleResult(SpeechRecognitionResult result) {
    // 이미 끝난 회차에 늦게 온 결과는 무시 (같은 문장이 두 번 붙던 문제)
    if (!_listening || _endedSession == _session) return;
    _sessionWords = result.recognizedWords;
    if (result.finalResult) _endSession();
  }

  void _handleStatus(String status) {
    // 'notListening'은 최종 결과보다 먼저 올 수 있어(마지막 단어 누락) 'done'만 끝으로 본다
    if (status == SpeechToText.doneStatus) _endSession();
  }

  void _handleError(SpeechRecognitionError error) {
    final msg = error.errorMsg;
    // 조용해서 끝난 것 = 말을 마쳤다는 신호 → 들은 내용으로 마무리
    if (msg.contains('no_match') || msg.contains('speech_timeout')) {
      _endSession();
      return;
    }
    if (!mounted || !_listening) return;
    _listening = false;
    setState(() {});
    if (msg.contains('permission')) {
      widget.onError('마이크 권한이 필요해요. 설정에서 마이크 권한을 허용해주세요.');
    } else if (msg.contains('network')) {
      widget.onError('음성 인식에 인터넷 연결이 필요해요. 연결을 확인해주세요.');
    } else if (_fullText.isNotEmpty) {
      widget.onFinal(_fullText); // 들은 내용이 있으면 살려서 분석
    } else {
      widget.onError('음성 인식 중 문제가 생겼어요. 다시 눌러 말씀해주세요.');
    }
  }

  /// 한 회차가 끝남 → 새로 들은 말이 있으면 이어 듣기, 없으면 마침
  void _endSession() {
    if (!mounted || !_listening || _endedSession == _session) return;
    _endedSession = _session;

    final heardThisTime = _sessionWords.trim().isNotEmpty;
    if (heardThisTime) {
      _committed = _fullText;
      _sessionWords = '';
    }
    final timeLeft =
        DateTime.now().difference(_startedAt) < _maxTotal - const Duration(seconds: 3);

    if (heardThisTime && !_userStopped && timeLeft) {
      // 기기가 일찍 끝냈을 수 있음 → 이어서 듣기
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && _listening && !_userStopped) _startSession();
      });
      return;
    }
    _finish();
  }

  void _finish() {
    if (!mounted || !_listening) return;
    setState(() {
      _listening = false;
      _level = 0;
    });
    final text = _fullText;
    if (text.isEmpty) {
      widget.onError('잘 듣지 못했어요. 다시 말씀해주세요.');
    } else {
      widget.onFinal(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unavailable) return const SizedBox.shrink();

    return SizedBox(
      height: 64,
      child: _listening
          ? ElevatedButton.icon(
              onPressed: _toggle,
              icon: _LevelBars(level: _level),
              label: const Text('듣고 있어요 · 다 말했으면 누르기'),
            )
          : OutlinedButton.icon(
              onPressed: widget.enabled ? _toggle : null,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: OnColors.vermilion, width: 2),
                foregroundColor: OnColors.vermilion,
              ),
              icon: const Icon(Icons.mic, size: 28),
              label: const Text('눌러서 말하기'),
            ),
    );
  }
}

/// 소리 크기에 따라 움직이는 막대 5개 (가운데가 가장 크게)
class _LevelBars extends StatelessWidget {
  final double level;

  const _LevelBars({required this.level});

  static const _shape = [0.45, 0.75, 1.0, 0.75, 0.45];
  static const _maxHeight = 26.0;
  static const _minHeight = 4.0;

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color ??
        IconTheme.of(context).color ??
        Colors.white;
    return SizedBox(
      width: 34,
      height: _maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final s in _shape)
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: 4,
              height: _minHeight + (_maxHeight - _minHeight) * level * s,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
