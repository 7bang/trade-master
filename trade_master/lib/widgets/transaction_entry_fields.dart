import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/on_colors.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

/// 거래 한 건의 입력 상태 (단일 거래 입력·다건 거래 입력이 함께 사용)
class TransactionEntry {
  final quantityController = TextEditingController();
  final unitPriceController = TextEditingController();
  final amountController = TextEditingController();
  final memoController = TextEditingController();

  TransactionType type = TransactionType.receivable;
  DateTime date = DateTime.now();

  /// true: 품목 선택(수량 × 단가), false: 금액 직접 입력
  bool useProductMode = false;
  Product? product;

  TransactionEntry();

  /// 수정할 거래로 채운다
  TransactionEntry.fromTransaction(Transaction t) {
    type = t.type;
    date = t.date;
    memoController.text = t.memo ?? '';
    if (t.productId != null) {
      useProductMode = true;
      product = t.product;
      quantityController.text = _number(t.quantity);
      unitPriceController.text = _number(t.unitPrice);
    } else {
      amountController.text = _number(t.amount);
    }
  }

  static String _number(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  static double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', ''));

  double? get quantity => useProductMode ? _parse(quantityController) : null;
  double? get unitPrice => useProductMode ? _parse(unitPriceController) : null;
  String? get memo {
    final text = memoController.text.trim();
    return text.isEmpty ? null : text;
  }

  double get amount {
    if (!useProductMode) return _parse(amountController) ?? 0;
    return (quantity ?? 0) * (unitPrice ?? 0);
  }

  void selectProduct(Product? value) {
    product = value;
    if (value?.defaultUnitPrice != null) {
      unitPriceController.text = _number(value!.defaultUnitPrice);
    }
  }

  void setProductMode(bool value) {
    useProductMode = value;
    if (value) {
      amountController.clear();
    } else {
      product = null;
      quantityController.clear();
      unitPriceController.clear();
    }
  }

  /// 새 거래로 만들기 (등록용)
  Transaction toNewTransaction({
    required String businessId,
    required String customerId,
  }) {
    final now = DateTime.now();
    return Transaction(
      id: '', // DB에서 생성
      businessId: businessId,
      customerId: customerId,
      type: type,
      productId: useProductMode ? product?.id : null,
      quantity: quantity,
      unitPrice: unitPrice,
      amount: amount,
      date: date,
      memo: memo,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 기존 거래에 입력값 반영 (수정용)
  Transaction applyTo(Transaction original) {
    return original.copyWith(
      type: type,
      productId: useProductMode ? product?.id : null,
      quantity: quantity,
      unitPrice: unitPrice,
      amount: amount,
      date: date,
      memo: memo,
      updatedAt: DateTime.now(),
    );
  }

  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
    amountController.dispose();
    memoController.dispose();
  }
}

/// 거래 입력 칸: 거래 유형, 날짜, 입력 방식(직접/품목), 품목·수량·단가 또는 금액, 메모.
/// 바깥의 Form 안에 넣어 사용한다. 값이 바뀌면 [onChanged]로 다시 그린다.
class TransactionEntryFields extends StatelessWidget {
  final TransactionEntry entry;
  final List<Product> products;
  final VoidCallback onChanged;

  const TransactionEntryFields({
    super.key,
    required this.entry,
    required this.products,
    required this.onChanged,
  });

  static const _label = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  String? _positive(String? value, String what) {
    final v = double.tryParse((value ?? '').trim().replaceAll(',', ''));
    if (value == null || value.trim().isEmpty) return '$what을(를) 입력해주세요';
    if (v == null || v <= 0) return '0보다 큰 숫자를 입력해주세요';
    return null;
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: entry.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      entry.date = picked;
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReceivable = entry.type == TransactionType.receivable;
    // 목록에 없는 품목(삭제된 품목 등)이 선택돼 있으면 드롭다운이 깨지지 않게 비운다
    final selected =
        products.contains(entry.product) ? entry.product : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('거래 유형', style: _label),
        const SizedBox(height: 8),
        SegmentedButton<TransactionType>(
          segments: const [
            ButtonSegment(
              value: TransactionType.receivable,
              label: Text('받을 돈'),
              icon: Icon(Icons.arrow_downward, color: OnColors.receivable),
            ),
            ButtonSegment(
              value: TransactionType.payable,
              label: Text('줄 돈'),
              icon: Icon(Icons.arrow_upward, color: OnColors.payable),
            ),
          ],
          selected: {entry.type},
          onSelectionChanged: (s) {
            entry.type = s.first;
            onChanged();
          },
        ),
        const SizedBox(height: 20),

        InkWell(
          onTap: () => _pickDate(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '거래 날짜',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              DateFormat('yyyy년 MM월 dd일').format(entry.date),
              style: const TextStyle(fontSize: 17),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            const Text('입력 방식', style: _label),
            const Spacer(),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('직접 입력')),
                ButtonSegment(value: true, label: Text('품목 선택')),
              ],
              selected: {entry.useProductMode},
              onSelectionChanged: (s) {
                entry.setProductMode(s.first);
                onChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (entry.useProductMode) ...[
          DropdownButtonFormField<Product>(
            initialValue: selected,
            decoration: const InputDecoration(
              labelText: '품목',
              prefixIcon: Icon(Icons.inventory_2),
            ),
            items: [
              for (final p in products)
                DropdownMenuItem(
                  value: p,
                  child: Text(
                    '${p.name} (${Formatters.formatCurrency(p.defaultUnitPrice ?? 0)}/${p.unit})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (p) {
              entry.selectProduct(p);
              onChanged();
            },
            validator: (v) => v == null ? '품목을 선택해주세요' : null,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: entry.quantityController,
                  decoration: InputDecoration(
                    labelText: '수량',
                    hintText: '예: 10',
                    suffixText: entry.product?.unit ?? '',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => onChanged(),
                  validator: (v) => _positive(v, '수량'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: entry.unitPriceController,
                  decoration: const InputDecoration(
                    labelText: '단가',
                    hintText: '예: 8000',
                    suffixText: '원',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => onChanged(),
                  validator: (v) => _positive(v, '단가'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OnColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: OnColors.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('총 금액', style: _label),
                Text(
                  Formatters.formatCurrency(entry.amount),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isReceivable ? OnColors.receivable : OnColors.payable,
                  ),
                ),
              ],
            ),
          ),
        ] else
          TextFormField(
            controller: entry.amountController,
            decoration: const InputDecoration(
              labelText: '금액',
              hintText: '예: 80000',
              prefixIcon: Icon(Icons.payments_outlined),
              suffixText: '원',
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (v) => _positive(v, '금액'),
          ),
        const SizedBox(height: 16),

        TextFormField(
          controller: entry.memoController,
          decoration: const InputDecoration(
            labelText: '메모 (선택)',
            hintText: '거래 내용을 메모하세요',
            prefixIcon: Icon(Icons.note_outlined),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
