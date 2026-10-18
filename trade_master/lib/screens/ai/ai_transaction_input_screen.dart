import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/ai_providers.dart';
import '../../services/ai_service.dart';
import '../../utils/formatters.dart';
import '../transaction/transaction_form_screen.dart';

/// AI를 이용한 거래 입력 화면 (자연어 + 사진)
class AiTransactionInputScreen extends ConsumerStatefulWidget {
  final String customerId;

  const AiTransactionInputScreen({super.key, required this.customerId});

  @override
  ConsumerState<AiTransactionInputScreen> createState() =>
      _AiTransactionInputScreenState();
}

class _AiTransactionInputScreenState
    extends ConsumerState<AiTransactionInputScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _textController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  ParsedTransaction? _parsed;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ── 자연어 파싱 ────────────────────────────────────────────────────────────

  Future<void> _parseText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _startLoading();
    try {
      final ai = ref.read(aiServiceProvider);
      final result = await ai.parseNaturalLanguage(text);
      _showResult(result);
    } catch (e) {
      _showError(e);
    }
  }

  // ── 사진 파싱 ──────────────────────────────────────────────────────────────

  Future<void> _pickAndParseImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    _startLoading();
    try {
      final bytes = await file.readAsBytes();
      final ai = ref.read(aiServiceProvider);
      final result = await ai.parseReceiptImage(bytes);
      _showResult(result);
    } catch (e) {
      _showError(e);
    }
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
      _error = null;
      _parsed = null;
    });
  }

  void _showResult(ParsedTransaction? result) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _parsed = result;
    });
  }

  void _showError(Object e) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
    });
  }

  void _goToForm() {
    if (_parsed == null) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          customerId: widget.customerId,
          initialData: _parsed,
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _parsed = null;
      _error = null;
      _textController.clear();
    });
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 거래 입력'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.text_fields), text: '자연어 입력'),
            Tab(icon: Icon(Icons.camera_alt), text: '사진 입력'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TextInputTab(
                  controller: _textController,
                  onParse: _parseText,
                  isLoading: _isLoading,
                ),
                _PhotoInputTab(
                  onPick: _pickAndParseImage,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
          if (_isLoading) const _LoadingBanner(),
          if (_error != null) _ErrorBanner(error: _error!, onRetry: _reset),
          if (_parsed != null)
            _ResultCard(
              parsed: _parsed!,
              onConfirm: _goToForm,
              onReset: _reset,
            ),
        ],
      ),
    );
  }
}

// ── 자연어 탭 ────────────────────────────────────────────────────────────────

class _TextInputTab extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onParse;
  final bool isLoading;

  const _TextInputTab({
    required this.controller,
    required this.onParse,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '거래 내용을 자유롭게 입력하세요',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            '예: "사과 30개 5만원 받을 돈" 또는 "어제 감자 100kg 구매 120,000원"',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onParse(),
            decoration: const InputDecoration(
              hintText: '여기에 입력하세요...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onParse,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('AI로 분석하기'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 사진 탭 ──────────────────────────────────────────────────────────────────

class _PhotoInputTab extends StatelessWidget {
  final Future<void> Function(ImageSource) onPick;
  final bool isLoading;

  const _PhotoInputTab({required this.onPick, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            '영수증이나 메모 사진을 찍어주세요',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'AI가 금액·품목·날짜를 자동으로 읽어냅니다',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : () => onPick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('카메라로 촬영'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : () => onPick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('갤러리에서 선택'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 공통 하단 배너 ────────────────────────────────────────────────────────────

class _LoadingBanner extends StatelessWidget {
  const _LoadingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.deepPurple.shade50,
      padding: const EdgeInsets.all(16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('AI가 분석하고 있습니다...'),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade50,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('닫기')),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ParsedTransaction parsed;
  final VoidCallback onConfirm;
  final VoidCallback onReset;

  const _ResultCard({
    required this.parsed,
    required this.onConfirm,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isReceivable = parsed.type == 'receivable';
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 6),
              const Text(
                'AI 분석 결과',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(onPressed: onReset, child: const Text('다시 입력')),
            ],
          ),
          const Divider(height: 12),
          _Row('거래 유형', isReceivable ? '💰 받을 돈' : '💸 줄 돈'),
          _Row('금액', Formatters.formatCurrency(parsed.amount)),
          _Row('날짜', DateFormat('yyyy년 MM월 dd일').format(parsed.date)),
          if (parsed.customerName != null)
            _Row('거래처', parsed.customerName!),
          if (parsed.memo != null) _Row('메모', parsed.memo!),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onConfirm,
              child: const Text('이 내용으로 거래 입력'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
