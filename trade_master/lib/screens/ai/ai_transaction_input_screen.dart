import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../config/on_colors.dart';
import '../../models/product.dart';
import '../../providers/ai_providers.dart';
import '../../providers/data_refresh.dart';
import '../../providers/providers.dart';
import '../../services/ai_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbars.dart';
import '../../utils/transaction_draft.dart';
import '../../widgets/ai/draft_result_card.dart';
import '../../widgets/ai/voice_input_button.dart';
import '../../widgets/transaction_entry_fields.dart';
import '../transaction/transaction_form_screen.dart';

/// AI를 이용한 거래 입력 화면 (말·글자 + 사진) — plan-voice-input.md
class AiTransactionInputScreen extends ConsumerStatefulWidget {
  final String customerId;

  /// AI 마이크 버튼으로 들어오면 바로 듣기 시작
  final bool autoStartVoice;

  const AiTransactionInputScreen({
    super.key,
    required this.customerId,
    this.autoStartVoice = false,
  });

  @override
  ConsumerState<AiTransactionInputScreen> createState() =>
      _AiTransactionInputScreenState();
}

class _AiTransactionInputScreenState
    extends ConsumerState<AiTransactionInputScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _textController = TextEditingController();

  // 말·글자 탭
  bool _analyzing = false;
  String? _textError;
  TransactionDraft? _draft;
  bool _saving = false;

  // 사진 탭 (기존 흐름: 결과 → 거래 입력 폼)
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

  List<Product> get _products =>
      (ref.read(productsProvider).valueOrNull ?? const <Product>[])
          .where((p) => p.isActive)
          .toList();

  // ── 말·글자 분석 ───────────────────────────────────────────────────────────

  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _analyzing = true;
      _textError = null;
      _draft = null;
    });
    try {
      List<Product> products;
      try {
        products = (await ref.read(productsProvider.future))
            .where((p) => p.isActive)
            .toList();
      } catch (_) {
        products = const []; // 품목을 못 불러와도 분석은 진행 (새 품목으로 정리됨)
      }
      final spoken = await ref.read(aiServiceProvider).parseNaturalLanguage(
            text,
            productNames: products.map((p) => p.name).toList(),
          );
      if (!mounted) return;
      setState(() {
        _draft = TransactionDraft.fromSpoken(spoken, products);
        _analyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _textError = userMessage(e);
        _analyzing = false;
      });
    }
  }

  void _setText(String text) {
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// 3.5 새 품목은 저장할 때 만든다 (같은 이름이 생겼으면 그 품목 사용)
  Future<String?> _ensureProductId(TransactionDraft draft, String businessId) async {
    if (!draft.isNewProduct) return draft.product?.id;
    final name = draft.newProductName!.trim();
    final existing = _products
        .where((p) => p.name.trim().toLowerCase() == name.toLowerCase());
    if (existing.isNotEmpty) return existing.first.id;

    final now = DateTime.now();
    final created = await ref.read(supabaseServiceProvider).createProduct(
          Product(
            id: '',
            businessId: businessId,
            name: name,
            unit: draft.unit,
            defaultUnitPrice: draft.unitPrice,
            createdAt: now,
            updatedAt: now,
          ),
        );
    ref.refreshProducts();
    return created.id;
  }

  Future<void> _saveDraft() async {
    final draft = _draft;
    if (draft == null || !draft.canSave || _saving) return;
    setState(() => _saving = true);
    try {
      final business = await ref.read(currentBusinessProvider.future);
      if (business == null) {
        throw const AppException('사업장 정보를 찾을 수 없습니다');
      }
      final productId = await _ensureProductId(draft, business.id);
      await ref.read(supabaseServiceProvider).createTransaction(
            draft.toTransaction(
              businessId: business.id,
              customerId: widget.customerId,
              productId: productId,
            ),
          );
      ref.refreshTransactions();
      if (!mounted) return;
      context.showSuccess(draft.isNewProduct
          ? '거래를 입력했어요 (새 품목 "${draft.newProductName}" 등록)'
          : '거래를 입력했어요');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// "자세히 입력" — 정리된 값을 기존 거래 입력 폼으로 넘긴다
  void _openForm() {
    final d = _draft;
    if (d == null) return;
    String fmt(double v) => DraftResultCard.formatQuantity(v);

    final entry = TransactionEntry()
      ..type = d.type
      ..date = d.date;
    var memo = d.memo ?? '';
    if (d.product != null && d.quantity != null) {
      entry.setProductMode(true);
      entry.product = d.product;
      entry.quantityController.text = fmt(d.quantity!);
      if (d.unitPrice != null) entry.unitPriceController.text = fmt(d.unitPrice!);
    } else {
      if (d.amount != null) entry.amountController.text = fmt(d.amount!);
      // 폼은 등록된 품목만 고를 수 있어 새 품목 이름은 메모로 남긴다
      if (d.isNewProduct) memo = [d.newProductName, memo].where((s) => s != null && s.isNotEmpty).join(' · ');
    }
    entry.memoController.text = memo;

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          customerId: widget.customerId,
          initialEntry: entry,
        ),
      ),
    );
  }

  // ── 사진 파싱 (기존) ────────────────────────────────────────────────────────

  Future<void> _pickAndParseImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _parsed = null;
    });
    try {
      final bytes = await file.readAsBytes();
      final ai = ref.read(aiServiceProvider);
      final result = await ai.parseReceiptImage(bytes);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _parsed = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = userMessage(e);
      });
    }
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

  void _resetPhoto() {
    setState(() {
      _parsed = null;
      _error = null;
    });
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // 품목 목록을 미리 불러 둔다 (음성 인식 힌트·분석에 사용)
    final products = (ref.watch(productsProvider).valueOrNull ?? const <Product>[])
        .where((p) => p.isActive)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 거래 입력'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.mic), text: '말·글자 입력'),
            Tab(icon: Icon(Icons.camera_alt), text: '사진 입력'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTextTab(products),
          Column(
            children: [
              Expanded(
                child: _PhotoInputTab(
                  onPick: _pickAndParseImage,
                  isLoading: _isLoading,
                ),
              ),
              if (_isLoading) const _LoadingBanner(),
              if (_error != null)
                _ErrorBanner(error: _error!, onRetry: _resetPhoto),
              if (_parsed != null)
                _ResultCard(
                  parsed: _parsed!,
                  onConfirm: _goToForm,
                  onReset: _resetPhoto,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab(List<Product> products) {
    final draft = _draft;
    final busy = _analyzing || _saving;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '거래 내용을 말하거나 적어주세요',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          const Text(
            '예: "광어 3키로 6만원 받을 돈", "어제 우럭 두 키로 샀어 키로에 만오천원"',
            style: TextStyle(color: OnColors.gray, fontSize: 15),
          ),
          const SizedBox(height: 16),
          VoiceInputButton(
            autoStart: widget.autoStartVoice,
            enabled: !busy,
            hints: products.map((p) => p.name).toList(),
            onFinal: (text) {
              _setText(text);
              _analyze(); // 말이 끝나면 자동 분석
            },
            onError: (msg) => setState(() => _textError = msg),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _analyze(),
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(
              hintText: '다 말하면 내용이 여기에 나타나요. 직접 적어도 돼요.',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : _analyze,
            icon: const Icon(Icons.auto_awesome),
            label: Text(draft == null ? 'AI로 분석하기' : '다시 분석'),
          ),
          if (_analyzing) ...[
            const SizedBox(height: 16),
            const _LoadingBanner(),
          ],
          if (_textError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: OnColors.warningBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: OnColors.warning),
              ),
              child: Text(
                '! $_textError',
                style: const TextStyle(color: OnColors.warning, fontSize: 15),
              ),
            ),
          ],
          if (draft != null) ...[
            const SizedBox(height: 16),
            DraftResultCard(
              draft: draft,
              products: products,
              isSaving: _saving,
              onChanged: () => setState(() {}),
              onSave: _saveDraft,
              onOpenForm: _openForm,
            ),
          ],
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
          Icon(Icons.receipt_long, size: 80, color: OnColors.grayLight),
          const SizedBox(height: 16),
          const Text(
            '영수증이나 메모 사진을 찍어주세요',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'AI가 금액·품목·날짜를 자동으로 읽어냅니다',
            style: TextStyle(color: OnColors.gray),
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
      color: OnColors.infoBg,
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
      color: OnColors.dangerBg,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: OnColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: OnColors.danger),
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
        border: const Border(top: BorderSide(color: OnColors.line)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: OnColors.success, size: 20),
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
              style: TextStyle(color: OnColors.gray, fontSize: 13),
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
