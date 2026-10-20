import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../utils/formatters.dart';
import '../../widgets/common_widgets.dart';
import '../ai/insight_screen.dart';
import '../../config/on_colors.dart';
import '../../providers/data_refresh.dart';
import '../../utils/app_exception.dart';
import '../../providers/transaction_pages.dart';
import '../../utils/snackbars.dart';
import '../../widgets/ai/ai_voice_fab.dart';
import '../ai/ai_transaction_input_screen.dart';

/// 전체 거래내역 화면
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  TransactionQuery _query = const TransactionQuery();

  // 거래처 선택 다이얼로그
  /// 거래처를 고른 뒤 [onSelected] (일반 거래 입력 또는 AI 음성 입력)
  Future<void> _showCustomerSelectionDialog(
    BuildContext context,
    WidgetRef ref, {
    required void Function(String customerId) onSelected,
  }) async {
    final customersAsync = ref.read(customersProvider);

    await customersAsync.when(
      data: (customers) async {
        if (customers.isEmpty) {
          if (context.mounted) {
            context.showInfo('먼저 거래처를 등록해주세요');
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
                    leading: BalanceAvatar(balance: customer.balance),
                    title: Text(customer.name),
                    subtitle: customer.phone != null
                        ? Text(customer.phone!)
                        : null,
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
          onSelected(selectedCustomer);
        }
      },
      loading: () {
        context.showInfo('거래처 목록을 불러오는 중...');
      },
      error: (error, _) {
        context.showInfo(userMessage(error));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionPagesProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 내역'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI 경영 인사이트',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const InsightScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '기간 필터',
            onPressed: () {
              _showDateFilterDialog();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.pullToRefresh(transactionPagesProvider(_query).future),
        child: transactionsAsync.when(
          data: (page) {
            final transactions = page.items;
            if (transactions.isEmpty) {
              return EmptyStateView(
                icon: Icons.receipt_long,
                title: '거래 내역이 없습니다',
                subtitle: '거래처 상세에서 거래를 추가해주세요',
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
              // 아래 여백: AI 마이크 + 거래 추가 버튼에 마지막 거래가 가리지 않게
              padding: const EdgeInsets.only(bottom: 160),
              // 끝에 "더 불러오기" 한 칸 (50건씩 이어서 불러옴)
              itemCount: sortedDates.length + (page.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == sortedDates.length) {
                  return LoadMoreFooter(
                    error: page.loadMoreError,
                    onLoadMore: () => ref
                        .read(transactionPagesProvider(_query).notifier)
                        .loadMore(),
                  );
                }
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
                      color: OnColors.paper,
                      child: Text(
                        dateKey,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: OnColors.gray,
                        ),
                      ),
                    ),
                    // 거래 목록
                    ...dayTransactions.map((transaction) {
                      return ListTile(
                        leading: TransactionTypeAvatar(
                          isReceivable:
                              transaction.type == TransactionType.receivable,
                        ),
                        title: Text(transaction.customer?.name ?? '거래처 정보 없음'),
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
                                  color: OnColors.gray,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          '${transaction.type == TransactionType.receivable ? '+' : '-'}${Formatters.formatCurrency(transaction.amount)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                transaction.type == TransactionType.receivable
                                ? OnColors.receivable
                                : OnColors.payable,
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
          loading: () => const LoadingView(),
          error: (error, stack) =>
              ErrorView(error: error, onRetry: () => ref.refreshAll()),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AiVoiceFab(
            onPressed: () => _showCustomerSelectionDialog(
              context,
              ref,
              onSelected: (customerId) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AiTransactionInputScreen(
                    customerId: customerId,
                    autoStartVoice: true,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'add-transaction-fab',
            onPressed: () => _showCustomerSelectionDialog(
              context,
              ref,
              onSelected: (customerId) =>
                  context.push('/customers/$customerId/transactions/new'),
            ),
            icon: const Icon(Icons.add),
            label: const Text('거래 추가'),
          ),
        ],
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
                  _query = TransactionQuery(
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
                  _query = TransactionQuery(
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
            if (_query.startDate != null || _query.endDate != null)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('필터 초기화'),
                onTap: () {
                  setState(() {
                    _query = const TransactionQuery();
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
      initialDateRange:
          _query.startDate != null && _query.endDate != null
          ? DateTimeRange(
              start: _query.startDate!,
              end: _query.endDate!,
            )
          : null,
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _query = TransactionQuery(startDate: picked.start, endDate: picked.end);
      });
    }
  }
}
