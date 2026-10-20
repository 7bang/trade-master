import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/on_colors.dart';
import '../../models/product.dart';
import '../../models/transaction.dart';
import '../../utils/formatters.dart';
import '../../utils/transaction_draft.dart';

/// AI가 정리한 거래 초안 — 항목을 눌러 고친 뒤 "거래 입력하기" (plan-voice-input.md 4.2)
class DraftResultCard extends StatelessWidget {
  final TransactionDraft draft;
  final List<Product> products;
  final VoidCallback onChanged;
  final VoidCallback? onSave;
  final VoidCallback onOpenForm;
  final bool isSaving;

  const DraftResultCard({
    super.key,
    required this.draft,
    required this.products,
    required this.onChanged,
    required this.onSave,
    required this.onOpenForm,
    this.isSaving = false,
  });

  static String formatQuantity(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  Future<void> _editNumber(
    BuildContext context, {
    required String title,
    required double? value,
    required String suffix,
    required bool decimal,
    required void Function(double?) apply,
  }) async {
    final result = await showModalBottomSheet<_NumberResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NumberSheet(
        title: title,
        value: value,
        suffix: suffix,
        decimal: decimal,
      ),
    );
    if (result != null) {
      apply(result.value);
      onChanged();
    }
  }

  Future<void> _editProduct(BuildContext context) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductSheet(draft: draft, products: products),
    );
    if (changed == true) onChanged();
  }

  Future<void> _editMemo(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TextSheet(title: '메모', value: draft.memo ?? ''),
    );
    if (result != null) {
      draft.memo = result.trim().isEmpty ? null : result.trim();
      onChanged();
    }
  }

  Future<void> _editDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      draft.date = picked;
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = draft.unit;
    final isReceivable = draft.type == TransactionType.receivable;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: OnColors.ink, size: 20),
                SizedBox(width: 8),
                Text('AI가 정리한 내용',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Spacer(),
                Text('눌러서 고치기',
                    style: TextStyle(fontSize: 14, color: OnColors.gray)),
              ],
            ),
            const SizedBox(height: 8),

            // 유형: 바로 바꾸는 토글
            _Row(
              label: '유형',
              child: SegmentedButton<TransactionType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: TransactionType.receivable,
                    label: Text('받을 돈'),
                  ),
                  ButtonSegment(
                    value: TransactionType.payable,
                    label: Text('줄 돈'),
                  ),
                ],
                selected: {draft.type},
                onSelectionChanged: (s) {
                  draft.type = s.first;
                  onChanged();
                },
              ),
            ),

            _Row(
              label: '품목',
              value: draft.productName ?? '없음 (총액만)',
              badge: draft.isNewProduct
                  ? '새 품목'
                  : (draft.candidates.length > 1
                      ? '비슷한 품목 ${draft.candidates.length}개'
                      : null),
              warn: draft.isNewProduct,
              onTap: () => _editProduct(context),
            ),

            if (draft.usesProduct) ...[
              _Row(
                label: '단가',
                value: draft.unitPrice == null
                    ? null
                    : '${Formatters.formatCurrency(draft.unitPrice!)} / $unit',
                note: [
                  if (draft.priceMismatch) '말한 단가와 계산이 달라 총액 기준으로 맞췄어요',
                  if (draft.unitPriceDiffersFromDefault)
                    '기본 단가 ${Formatters.formatCurrency(draft.defaultUnitPrice!)}',
                ].join(' · '),
                warn: draft.unitPriceMissing || draft.priceMismatch,
                onTap: () => _editNumber(
                  context,
                  title: '단가 ($unit당)',
                  value: draft.unitPrice,
                  suffix: '원',
                  decimal: false,
                  apply: draft.setUnitPrice,
                ),
              ),
              _Row(
                label: '수량',
                value: draft.quantity == null
                    ? null
                    : '${formatQuantity(draft.quantity!)} $unit',
                warn: draft.quantityMissing,
                onTap: () => _editNumber(
                  context,
                  title: '수량 ($unit)',
                  value: draft.quantity,
                  suffix: unit,
                  decimal: true,
                  apply: draft.setQuantity,
                ),
              ),
            ],

            _Row(
              label: '총액',
              value: draft.amountMissing
                  ? null
                  : Formatters.formatCurrency(draft.amount!),
              valueStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isReceivable ? OnColors.receivable : OnColors.payable,
              ),
              warn: draft.amountMissing,
              onTap: () => _editNumber(
                context,
                title: '총액',
                value: draft.amount,
                suffix: '원',
                decimal: false,
                apply: draft.setAmount,
              ),
            ),

            _Row(
              label: '날짜',
              value: DateFormat('yyyy년 M월 d일').format(draft.date),
              onTap: () => _editDate(context),
            ),
            _Row(
              label: '메모',
              value: draft.memo ?? '—',
              onTap: () => _editMemo(context),
            ),

            const SizedBox(height: 16),
            if (!draft.canSave)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '! 황토색 항목을 눌러 채워주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: OnColors.warning, fontSize: 15),
                ),
              ),
            ElevatedButton(
              onPressed: draft.canSave && !isSaving ? onSave : null,
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('거래 입력하기'),
            ),
            TextButton(
              onPressed: isSaving ? null : onOpenForm,
              child: const Text('자세히 입력'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 결과 카드 한 줄: 이름 · 값 · ✎ (줄 전체가 눌림 영역)
class _Row extends StatelessWidget {
  final String label;
  final String? value;
  final TextStyle? valueStyle;
  final String? badge;
  final String? note;
  final bool warn;
  final VoidCallback? onTap;
  final Widget? child;

  const _Row({
    required this.label,
    this.value,
    this.valueStyle,
    this.badge,
    this.note,
    this.warn = false,
    this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final missing = child == null && value == null;
    final highlight = warn || missing;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlight ? OnColors.warning : OnColors.line,
              width: highlight ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(label,
                    style: const TextStyle(fontSize: 15, color: OnColors.gray)),
              ),
              Expanded(
                child: child ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              missing ? '확인 필요' : value!,
                              style: missing
                                  ? const TextStyle(
                                      fontSize: 17,
                                      color: OnColors.warning,
                                      fontWeight: FontWeight.w700)
                                  : (valueStyle ??
                                      const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700)),
                            ),
                            if (badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: warn
                                          ? OnColors.warning
                                          : OnColors.info),
                                ),
                                child: Text(
                                  badge!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: warn
                                        ? OnColors.warning
                                        : OnColors.info,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (note != null && note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(note!,
                                style: const TextStyle(
                                    fontSize: 14, color: OnColors.gray)),
                          ),
                      ],
                    ),
              ),
              if (onTap != null && child == null)
                const Icon(Icons.edit_outlined, size: 20, color: OnColors.gray),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 편집창 ───────────────────────────────────────────────────────────────────

class _NumberResult {
  final double? value;
  const _NumberResult(this.value);
}

class _NumberSheet extends StatefulWidget {
  final String title;
  final double? value;
  final String suffix;
  final bool decimal;

  const _NumberSheet({
    required this.title,
    required this.value,
    required this.suffix,
    required this.decimal,
  });

  @override
  State<_NumberSheet> createState() => _NumberSheetState();
}

class _NumberSheetState extends State<_NumberSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value == null
        ? ''
        : DraftResultCard.formatQuantity(widget.value!),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final v = double.tryParse(_controller.text.trim().replaceAll(',', ''));
    Navigator.pop(context, _NumberResult(v != null && v > 0 ? v : null));
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: widget.title,
      onDone: _submit,
      child: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        decoration: InputDecoration(suffixText: widget.suffix),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}

class _TextSheet extends StatefulWidget {
  final String title;
  final String value;

  const _TextSheet({required this.title, required this.value});

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: widget.title,
      onDone: () => Navigator.pop(context, _controller.text),
      child: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 2,
      ),
    );
  }
}

/// 품목 바꾸기: 비슷한 품목 → 전체 품목 검색 → 새 품목 → 품목 없이
class _ProductSheet extends StatefulWidget {
  final TransactionDraft draft;
  final List<Product> products;

  const _ProductSheet({required this.draft, required this.products});

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  static const _commonUnits = ['개', 'kg', '박스', '마리'];

  late final TextEditingController _name =
      TextEditingController(text: widget.draft.productName ?? '');
  late String _unit = widget.draft.unit;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pick(Product p) {
    widget.draft.selectProduct(p);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final query = _name.text.trim();
    final active = widget.products.where((p) => p.isActive).toList();
    final matches = query.isEmpty ? active : matchProducts(query, active);
    final exact = active.any((p) => p.name.trim() == query);

    return _SheetFrame(
      title: '품목',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: false,
            decoration: const InputDecoration(
              labelText: '품목 이름 검색 또는 새 이름',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in matches)
                  ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      '${Formatters.formatCurrency(p.defaultUnitPrice ?? 0)} / ${p.unit}',
                    ),
                    trailing: p == widget.draft.product
                        ? const Icon(Icons.check, color: OnColors.success)
                        : null,
                    onTap: () => _pick(p),
                  ),
                if (matches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('등록된 품목 중 맞는 것이 없어요',
                        style: TextStyle(color: OnColors.gray)),
                  ),
              ],
            ),
          ),
          if (query.isNotEmpty && !exact) ...[
            const Divider(),
            Text('새 품목 "$query" 만들기 (저장할 때 등록)',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final u in {..._commonUnits, _unit})
                  ChoiceChip(
                    label: Text(u),
                    selected: _unit == u,
                    onSelected: (_) => setState(() => _unit = u),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                widget.draft.useNewProduct(query, unit: _unit);
                Navigator.pop(context, true);
              },
              child: Text('새 품목으로 ($_unit)'),
            ),
          ],
          TextButton(
            onPressed: () {
              widget.draft.clearProduct();
              Navigator.pop(context, true);
            },
            child: const Text('품목 없이 총액만 입력'),
          ),
        ],
      ),
    );
  }
}

/// 아래에서 올라오는 편집창 공통 틀 (키보드에 가리지 않게)
class _SheetFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onDone;

  const _SheetFrame({required this.title, required this.child, this.onDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            child,
            if (onDone != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onDone, child: const Text('확인')),
            ],
          ],
        ),
      ),
    );
  }
}
