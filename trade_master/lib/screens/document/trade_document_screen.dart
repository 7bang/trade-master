import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../providers/providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/receipts/trade_document_widget.dart';
import '../../config/on_colors.dart';

/// 견적서 / 납품서 작성 화면 (품목 입력 → 미리보기 → 이미지 공유)
class TradeDocumentScreen extends ConsumerStatefulWidget {
  final Customer customer;
  final TradeDocumentType type;

  const TradeDocumentScreen({
    super.key,
    required this.customer,
    required this.type,
  });

  @override
  ConsumerState<TradeDocumentScreen> createState() =>
      _TradeDocumentScreenState();
}

class _TradeDocumentScreenState extends ConsumerState<TradeDocumentScreen> {
  final GlobalKey _documentKey = GlobalKey();
  final List<_ItemRow> _rows = [_ItemRow()];
  final _noteController = TextEditingController();
  List<TradeDocumentItem>? _previewItems;
  bool _isSharing = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showPreview() {
    FocusScope.of(context).unfocus();
    final items = _rows
        .where((r) => r.name.trim().isNotEmpty && r.quantity > 0)
        .map((r) => TradeDocumentItem(
              name: r.name.trim(),
              quantity: r.quantity,
              unit: r.unit.trim().isEmpty ? '개' : r.unit.trim(),
              unitPrice: r.unitPrice,
            ))
        .toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('품목명과 수량을 하나 이상 입력해주세요')),
      );
      return;
    }
    setState(() => _previewItems = items);
  }

  Future<void> _share() async {
    setState(() => _isSharing = true);
    final title = widget.type.title;
    final success = await ref.read(shareServiceProvider).shareWidget(
          widgetKey: _documentKey,
          fileName:
              '${title}_${widget.customer.name}_${DateTime.now().millisecondsSinceEpoch}',
          text: '${widget.customer.name} $title',
        );
    if (!mounted) return;
    setState(() => _isSharing = false);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title 공유에 실패했습니다'),
          backgroundColor: OnColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type.title;
    final preview = _previewItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(preview == null ? '$title 작성' : '$title 미리보기'),
      ),
      body: preview == null ? _buildForm() : _buildPreview(preview),
    );
  }

  // ── 입력 ──────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    final total = _rows.fold<double>(0, (s, r) => s + r.quantity * r.unitPrice);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('받는 거래처'),
                  trailing: Text(
                    widget.customer.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('품목',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _rows.add(_ItemRow())),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('추가'),
                          ),
                        ],
                      ),
                      const Divider(),
                      for (var i = 0; i < _rows.length; i++)
                        _ItemEditor(
                          key: ObjectKey(_rows[i]),
                          index: i,
                          row: _rows[i],
                          canRemove: _rows.length > 1,
                          onRemove: () => setState(() => _rows.removeAt(i)),
                          onChanged: () => setState(() {}),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '합계 ${Formatters.formatCurrency(total)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _noteController,
                    maxLines: 2,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: '비고 (선택)',
                      hintText: '예: 유효기간 7일, 배송비 별도',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _showPreview,
                icon: const Icon(Icons.visibility),
                label: const Text('미리보기'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 미리보기 ───────────────────────────────────────────────────────────────

  Widget _buildPreview(List<TradeDocumentItem> items) {
    final business = ref.watch(currentBusinessProvider).valueOrNull;

    return Column(
      children: [
        Expanded(
          child: Container(
            color: OnColors.line,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RepaintBoundary(
                    key: _documentKey,
                    child: TradeDocumentWidget(
                      type: widget.type,
                      businessName: business?.name ?? '사업장',
                      businessPhone: business?.phone,
                      customerName: widget.customer.name,
                      issuedAt: DateTime.now(),
                      items: items,
                      note: _noteController.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSharing
                        ? null
                        : () => setState(() => _previewItems = null),
                    icon: const Icon(Icons.edit),
                    label: const Text('수정'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _share,
                    icon: _isSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share),
                    label: const Text('이미지로 공유'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 품목 편집 ─────────────────────────────────────────────────────────────────

class _ItemRow {
  String name = '';
  double quantity = 1;
  double unitPrice = 0;
  String unit = '개';
}

class _ItemEditor extends StatelessWidget {
  final int index;
  final _ItemRow row;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ItemEditor({
    super.key,
    required this.index,
    required this.row,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text('${index + 1}.',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: row.name,
                  decoration: const InputDecoration(
                    labelText: '품목명',
                    isDense: true,
                  ),
                  onChanged: (v) => row.name = v,
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline,
                      color: OnColors.danger, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 20),
              Expanded(
                child: TextFormField(
                  initialValue: TradeDocumentWidget.formatQuantity(row.quantity),
                  decoration: const InputDecoration(
                    labelText: '수량',
                    isDense: true,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    row.quantity = double.tryParse(v) ?? 0;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: row.unit,
                  decoration: const InputDecoration(
                    labelText: '단위',
                    isDense: true,
                  ),
                  onChanged: (v) => row.unit = v,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue:
                      row.unitPrice == 0 ? '' : row.unitPrice.toInt().toString(),
                  decoration: const InputDecoration(
                    labelText: '단가',
                    isDense: true,
                    suffixText: '원',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    row.unitPrice =
                        double.tryParse(v.replaceAll(',', '')) ?? 0;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
