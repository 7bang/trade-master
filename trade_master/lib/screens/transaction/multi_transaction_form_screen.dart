import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/on_colors.dart';
import '../../models/product.dart';
import '../../models/transaction.dart';
import '../../providers/data_refresh.dart';
import '../../providers/providers.dart';
import '../../utils/app_exception.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbars.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/transaction_entry_fields.dart';

/// 여러 건 거래 입력 화면
class MultiTransactionFormScreen extends ConsumerStatefulWidget {
  final String customerId;

  const MultiTransactionFormScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<MultiTransactionFormScreen> createState() =>
      _MultiTransactionFormScreenState();
}

/// 카드 한 장 = 거래 한 건
class _Item {
  final formKey = GlobalKey<FormState>();
  final entry = TransactionEntry();
  bool isExpanded = true;
}

class _MultiTransactionFormScreenState
    extends ConsumerState<MultiTransactionFormScreen> {
  final List<_Item> _items = [_Item()];
  bool _isLoading = false;

  void _addItem() => setState(() => _items.add(_Item()));

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() => _items.removeAt(index).entry.dispose());
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.entry.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    if (_isLoading) return;

    // 검증하려면 모든 카드의 Form이 화면에 있어야 한다 → 펼친 뒤 한 프레임 기다림
    setState(() {
      for (final item in _items) {
        item.isExpanded = true;
      }
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    for (var i = 0; i < _items.length; i++) {
      final form = _items[i].formKey.currentState;
      if (form != null && !form.validate()) {
        context.showError('거래 ${i + 1}의 입력값을 확인해주세요');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final business = await ref.read(currentBusinessProvider.future);
      if (business == null) {
        throw const AppException('사업장 정보를 찾을 수 없습니다');
      }

      // 모든 거래를 단일 INSERT로 저장 (원자성 보장)
      await ref.read(supabaseServiceProvider).createTransactionsBatch([
        for (final item in _items)
          item.entry.toNewTransaction(
            businessId: business.id,
            customerId: widget.customerId,
          ),
      ]);
      ref.refreshTransactions();

      if (mounted) {
        context.showSuccess('${_items.length}건의 거래가 저장되었습니다');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final saveLabel = '전체 저장 (${_items.length}건)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('여러 건 거래 입력'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveAll,
            icon: const Icon(Icons.save),
            label: Text(saveLabel),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) => Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: OnColors.infoBg,
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: OnColors.info),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '여러 건의 거래를 한 번에 입력할 수 있습니다',
                      style: TextStyle(color: OnColors.info, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, index) =>
                    _buildCard(index, _items[index], products),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: OnColors.line)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('거래 추가'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveAll,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('$saveLabel하기'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(error: err),
      ),
    );
  }

  Widget _buildCard(int index, _Item item, List<Product> products) {
    final entry = item.entry;
    final summary = '${entry.type == TransactionType.receivable ? '받을 돈' : '줄 돈'} · '
        '${DateFormat('M/d').format(entry.date)}'
        '${entry.amount > 0 ? ' · ${Formatters.formatCurrency(entry.amount)}' : ''}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ObjectKey(item),
          initiallyExpanded: item.isExpanded,
          onExpansionChanged: (expanded) =>
              setState(() => item.isExpanded = expanded),
          leading: CircleAvatar(
            backgroundColor: OnColors.paper,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: OnColors.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            '거래 ${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: item.isExpanded
              ? null
              : Text(summary, style: const TextStyle(color: OnColors.gray)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_items.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: OnColors.danger),
                  onPressed: () => _removeItem(index),
                  tooltip: '삭제',
                ),
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: item.formKey,
                child: TransactionEntryFields(
                  entry: entry,
                  products: products,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
