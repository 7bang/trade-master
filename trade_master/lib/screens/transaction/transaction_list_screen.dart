import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../utils/formatters.dart';

/// 전체 거래내역 Provider (날짜 필터 지원)
final allTransactionsProvider = FutureProvider.family<List<Transaction>, DateFilter>((ref, filter) async {
  final service = ref.watch(supabaseServiceProvider);
  final business = await ref.watch(currentBusinessProvider.future);

  if (business == null) return [];

  return await service.getTransactions(
    businessId: business.id,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});

/// 날짜 필터 클래스
class DateFilter {
  final DateTime? startDate;
  final DateTime? endDate;

  const DateFilter({this.startDate, this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateFilter &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

/// 전체 거래내역 화면
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  DateFilter _dateFilter = const DateFilter();

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
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider(_dateFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 내역'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '기간 필터',
            onPressed: () {
              _showDateFilterDialog();
            },
          ),
        ],
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

  // 날짜 필터 다이얼로그
  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.filter_list),
            SizedBox(width: 8),
            Text('기간 필터'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('이번 달'),
              onTap: () {
                final now = DateTime.now();
                final startOfMonth = DateTime(now.year, now.month, 1);
                final endOfMonth = DateTime(now.year, now.month + 1, 0);
                setState(() {
                  _dateFilter = DateFilter(
                    startDate: startOfMonth,
                    endDate: endOfMonth,
                  );
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('지난 달'),
              onTap: () {
                final now = DateTime.now();
                final lastMonth = DateTime(now.year, now.month - 1, 1);
                final endOfLastMonth = DateTime(now.year, now.month, 0);
                setState(() {
                  _dateFilter = DateFilter(
                    startDate: lastMonth,
                    endDate: endOfLastMonth,
                  );
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('사용자 정의'),
              onTap: () async {
                Navigator.pop(context);
                await _showCustomDateRangePicker();
              },
            ),
            if (_dateFilter.startDate != null || _dateFilter.endDate != null)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('필터 초기화'),
                onTap: () {
                  setState(() {
                    _dateFilter = const DateFilter();
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // 사용자 정의 날짜 범위 선택
  Future<void> _showCustomDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateFilter.startDate != null && _dateFilter.endDate != null
          ? DateTimeRange(
              start: _dateFilter.startDate!,
              end: _dateFilter.endDate!,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFilter = DateFilter(
          startDate: picked.start,
          endDate: picked.end,
        );
      });
    }
  }
}
