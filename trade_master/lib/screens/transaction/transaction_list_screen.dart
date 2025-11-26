import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../utils/formatters.dart';

/// 전체 거래내역 Provider
final allTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final business = await ref.watch(currentBusinessProvider.future);

  if (business == null) return [];

  return await service.getTransactions(businessId: business.id);
});

/// 전체 거래내역 화면
class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  // 거래처 선택 다이얼로그
  Future<void> _showCustomerSelectionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final customersAsync = ref.read(customersProvider);

    await customersAsync.when(
      data: (customers) async {
        if (customers.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('먼저 거래처를 등록해주세요')),
            );
          }
          return;
        }

        final selectedCustomer = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('거래처 선택'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: customer.balance >= 0
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      child: Icon(
                        Icons.person,
                        color: customer.balance >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    title: Text(customer.name),
                    subtitle: customer.phone != null ? Text(customer.phone!) : null,
                    onTap: () {
                      Navigator.of(context).pop(customer.id);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
            ],
          ),
        );

        if (selectedCustomer != null && context.mounted) {
          context.push('/customers/$selectedCustomer/transactions/new');
        }
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거래처 목록을 불러오는 중...')),
        );
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $error')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 내역'),
        automaticallyImplyLeading: false,
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '거래 내역이 없습니다',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '거래처 상세에서 거래를 추가해주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          // 날짜별로 그룹화
          final groupedTransactions = <String, List<Transaction>>{};
          for (final transaction in transactions) {
            final dateKey = Formatters.formatDate(transaction.date);
            groupedTransactions.putIfAbsent(dateKey, () => []);
            groupedTransactions[dateKey]!.add(transaction);
          }

          // 날짜 역순 정렬
          final sortedDates = groupedTransactions.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final dateKey = sortedDates[index];
              final dayTransactions = groupedTransactions[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 헤더
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.grey.shade100,
                    child: Text(
                      dateKey,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  // 거래 목록
                  ...dayTransactions.map((transaction) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: transaction.type == TransactionType.receivable
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          transaction.type == TransactionType.receivable
                              ? Icons.add
                              : Icons.remove,
                          color: transaction.type == TransactionType.receivable
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      title: Text(
                        transaction.customer?.name ?? '거래처 정보 없음',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (transaction.product != null)
                            Text(transaction.product!.name),
                          if (transaction.memo != null &&
                              transaction.memo!.isNotEmpty)
                            Text(
                              transaction.memo!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        '${transaction.type == TransactionType.receivable ? '+' : '-'}${Formatters.formatCurrency(transaction.amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: transaction.type == TransactionType.receivable
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      onTap: () {
                        context.push('/transactions/${transaction.id}');
                      },
                    );
                  }),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('오류가 발생했습니다: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerSelectionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('거래 추가'),
      ),
    );
  }
}
