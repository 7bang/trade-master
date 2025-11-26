import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../utils/formatters.dart';
// import '../../utils/share_utils.dart'; // Temporarily disabled
import '../../models/transaction.dart' as models;

/// 거래처 상세 화면
class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerProvider(customerId));
    final transactionsAsync = ref.watch(transactionsProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('거래처 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '수정',
            onPressed: () {
              context.go('/customers/$customerId/edit');
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('삭제', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) => Column(
          children: [
            // 거래처 정보 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (customer.phone != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(color: Colors.white30, height: 32),
                  // 현재 잔액
                  const Text(
                    '현재 잔액',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.formatCurrency(customer.balance.abs()),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    Formatters.formatBalanceType(customer.balance),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // 거래 내역 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '거래 내역',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  // Share button temporarily disabled due to build issue
                  // transactionsAsync.whenOrNull(
                  //   data: (transactions) => TextButton.icon(
                  //     onPressed: () {
                  //       ShareUtils.shareReceipt(
                  //         context: context,
                  //         customer: customer,
                  //         transactions: transactions,
                  //       );
                  //     },
                  //     icon: const Icon(Icons.share, size: 18),
                  //     label: const Text('공유'),
                  //   ),
                  // ) ?? const SizedBox.shrink(),
                ],
              ),
            ),

            // 거래 목록
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '거래 내역이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.go('/customers/$customerId/transactions/new');
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('거래 추가하기'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: transaction.type ==
                                    models.TransactionType.receivable
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              transaction.type == models.TransactionType.receivable
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: transaction.type ==
                                      models.TransactionType.receivable
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                transaction.type == models.TransactionType.receivable
                                    ? '💰 받을 돈'
                                    : '💸 줄 돈',
                              ),
                              if (transaction.product != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    transaction.product!.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                Formatters.formatDate(transaction.date),
                              ),
                              if (transaction.memo != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  transaction.memo!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          trailing: Text(
                            '${transaction.type == models.TransactionType.receivable ? '+' : '-'}'
                            '${Formatters.formatCurrency(transaction.amount)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: transaction.type ==
                                      models.TransactionType.receivable
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          onTap: () {
                            context.go('/transactions/${transaction.id}');
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text('에러: $err'),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('에러가 발생했습니다: $err'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/customers/$customerId/transactions/new');
        },
        icon: const Icon(Icons.add),
        label: const Text('거래 추가'),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('거래처 삭제'),
        content: const Text(
          '이 거래처를 삭제하시겠습니까?\n모든 거래 내역도 함께 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteCustomer(context, ref);
    }
  }

  Future<void> _deleteCustomer(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.deleteCustomer(customerId);

      // Provider 갱신
      ref.invalidate(customersProvider);

      if (context.mounted) {
        context.go('/customers');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('거래처가 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
