import 'package:flutter/material.dart';
import '../../config/on_colors.dart';

/// 말로 거래 입력 (AI) — [+ 거래 추가] 위에 두는 둥근 버튼.
/// 누르면 AI 입력 화면이 열리면서 바로 듣기 시작한다.
class AiVoiceFab extends StatelessWidget {
  final VoidCallback onPressed;

  const AiVoiceFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '말로 거래 입력',
      button: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
            heroTag: 'ai-voice-fab',
            onPressed: onPressed,
            tooltip: '말로 거래 입력 (AI)',
            backgroundColor: OnColors.ink,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.mic, size: 30),
          ),
          // AI 표시 (인주색 작은 원)
          Positioned(
            right: -2,
            top: -2,
            child: IgnorePointer(
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: OnColors.vermilion,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
