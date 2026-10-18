import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/providers.dart';
import '../../providers/ai_providers.dart';
import '../../models/customer.dart';

/// 견적서/납품서 자동 생성 화면
class DocumentGeneratorScreen extends ConsumerStatefulWidget {
  final Customer customer;

  const DocumentGeneratorScreen({super.key, required this.customer});

  @override
  ConsumerState<DocumentGeneratorScreen> createState() =>
      _DocumentGeneratorScreenState();
}

class _DocumentGeneratorScreenState
    extends ConsumerState<DocumentGeneratorScreen> {
  String _docType = 'quote'; // 'quote' | 'delivery'
  final List<_ItemRow> _items = [_ItemRow()];
  bool _isLoading = false;
  String? _result;
  String? _error;

  Future<void> _generate() async {
    // 빈 항목 제거 후 유효성 검사
    final validItems = _items.where((r) => r.name.isNotEmpty).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('품목을 하나 이상 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final business = await ref.read(currentBusinessProvider.future);
      final ai = ref.read(aiServiceProvider);

      final result = await ai.generateDocument(
        _docType,
        business?.name ?? '사업장',
        widget.customer.name,
        validItems
            .map((r) => {
                  'name': r.name,
                  'quantity': r.quantity,
                  'unitPrice': r.unitPrice,
                  'unit': r.unit,
                })
            .toList(),
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('견적서/납품서 생성'),
      ),
      body: _result != null ? _ResultView(result: _result!, onReset: () => setState(() => _result = null)) : _FormView(
        docType: _docType,
        items: _items,
        customer: widget.customer,
        isLoading: _isLoading,
        error: _error,
        onDocTypeChanged: (v) => setState(() => _docType = v),
        onAddItem: () => setState(() => _items.add(_ItemRow())),
        onRemoveItem: (i) => setState(() => _items.removeAt(i)),
        onGenerate: _generate,
      ),
    );
  }
}

// ── 입력 폼 뷰 ────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  final String docType;
  final List<_ItemRow> items;
  final Customer customer;
  final bool isLoading;
  final String? error;
  final ValueChanged<String> onDocTypeChanged;
  final VoidCallback onAddItem;
  final ValueChanged<int> onRemoveItem;
  final VoidCallback onGenerate;

  const _FormView({
    required this.docType,
    required this.items,
    required this.customer,
    required this.isLoading,
    required this.error,
    required this.onDocTypeChanged,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 문서 유형 선택
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('문서 유형',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeButton(
                              label: '견적서',
                              icon: Icons.request_quote,
                              selected: docType == 'quote',
                              onTap: () => onDocTypeChanged('quote'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TypeButton(
                              label: '납품서',
                              icon: Icons.local_shipping,
                              selected: docType == 'delivery',
                              onTap: () => onDocTypeChanged('delivery'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 수신자
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('수신 거래처'),
                  trailing: Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 품목 목록
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
                            onPressed: onAddItem,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('추가'),
                          ),
                        ],
                      ),
                      const Divider(),
                      ...items.asMap().entries.map((entry) => _ItemEditor(
                            index: entry.key,
                            row: entry.value,
                            canRemove: items.length > 1,
                            onRemove: () => onRemoveItem(entry.key),
                          )),
                    ],
                  ),
                ),
              ),

              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(error!,
                            style: TextStyle(color: Colors.red.shade700)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // 생성 버튼
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onGenerate,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(isLoading ? 'AI 생성 중...' : 'AI로 문서 생성'),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 결과 뷰 ───────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final String result;
  final VoidCallback onReset;

  const _ResultView({required this.result, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                result,
                style: const TextStyle(fontSize: 14, height: 1.7),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: result));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('클립보드에 복사했습니다')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('복사'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Share.share(result),
                      icon: const Icon(Icons.share),
                      label: const Text('공유'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onReset,
                  child: const Text('다시 입력'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 품목 편집 위젯 ─────────────────────────────────────────────────────────────

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

  const _ItemEditor({
    required this.index,
    required this.row,
    required this.canRemove,
    required this.onRemove,
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
                flex: 3,
                child: TextFormField(
                  initialValue: row.name,
                  decoration: const InputDecoration(
                    labelText: '품목명',
                    isDense: true,
                  ),
                  onChanged: (v) => row.name = v,
                ),
              ),
              const SizedBox(width: 8),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 20),
              Expanded(
                child: TextFormField(
                  initialValue: row.quantity.toInt().toString(),
                  decoration: const InputDecoration(
                    labelText: '수량',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => row.quantity = double.tryParse(v) ?? 1,
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
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => row.unitPrice = double.tryParse(v) ?? 0,
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

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? Colors.white : Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
