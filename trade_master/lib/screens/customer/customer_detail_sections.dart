import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/on_colors.dart';
import '../../models/customer.dart';
import '../../models/transaction.dart' as models;
import '../../providers/transaction_pages.dart';
import '../../utils/app_exception.dart';
import '../../utils/formatters.dart';
import '../../widgets/common_widgets.dart';

/// 거래처 상세 상단: 이름·연락처·현재 잔액 (스크롤하면 한 줄로 접힘)
class CustomerBalanceHeader extends StatelessWidget {
  final Customer customer;

  const CustomerBalanceHeader({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: OnColors.ink,
      foregroundColor: Colors.white,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // 현재 확장 비율 계산
          final maxHeight = 280.0;
          final minHeight = kToolbarHeight;
          final currentHeight = constraints.maxHeight;
          final percent =
              ((currentHeight - minHeight) / (maxHeight - minHeight)).clamp(
                0.0,
                1.0,
              );

          return FlexibleSpaceBar(
            centerTitle: true,
            title: percent < 0.5
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.formatCurrency(customer.balance.abs()),
                        style: TextStyle(
                          fontSize: 14,
                          color: customer.balance >= 0
                              ? OnColors.receivableOnDark
                              : OnColors.payableOnDark,
                        ),
                      ),
                    ],
                  )
                : null,
            background: Container(
              color: OnColors.ink,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (percent > 0.5) ...[
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: OnColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        customer.name,
                        style: TextStyle(
                          fontSize: 22 * percent + 16 * (1 - percent),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (customer.phone != null && percent > 0.4) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.white70,
                            ),
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
                      if (percent > 0.4)
                        const Divider(color: Colors.white30, height: 24),
                      if (percent > 0.4)
                        const Text(
                          '현재 잔액',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      if (percent > 0.4) const SizedBox(height: 6),
                      Text(
                        Formatters.formatCurrency(customer.balance.abs()),
                        style: TextStyle(
                          fontSize: 28 * percent + 14 * (1 - percent),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (percent > 0.4)
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
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 거래처 상세 거래 목록 (50건씩 이어서 불러옴)
class CustomerTransactionsSliver extends ConsumerWidget {
  final String customerId;

  const CustomerTransactionsSliver({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(
      transactionPagesProvider(TransactionQuery(customerId: customerId)),
    );
    return transactionsAsync.when(
      data: (page) {
        final transactions = page.items;
        if (transactions.isEmpty) {
          return SliverFillRemaining(
            child: EmptyStateView(
              icon: Icons.receipt_long,
              title: '거래 내역이 없습니다',
              actionLabel: '거래 추가하기',
              onAction: () =>
                  context.go('/customers/$customerId/transactions/new'),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              // 끝에 "더 불러오기" 한 칸 (50건씩 이어서 불러옴)
              if (index == transactions.length) {
                return LoadMoreFooter(
                  error: page.loadMoreError,
                  onLoadMore: () => ref
                      .read(
                        transactionPagesProvider(
                          TransactionQuery(customerId: customerId),
                        ).notifier,
                      )
                      .loadMore(),
                );
              }
              final transaction = transactions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: TransactionTypeAvatar(
                    isReceivable:
                        transaction.type == models.TransactionType.receivable,
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
                            color: OnColors.paper,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            transaction.product!.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: OnColors.gray,
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
                      Text(Formatters.formatDate(transaction.date)),
                      if (transaction.memo != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          transaction.memo!,
                          style: TextStyle(fontSize: 12, color: OnColors.gray),
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
                      color:
                          transaction.type == models.TransactionType.receivable
                          ? OnColors.receivable
                          : OnColors.payable,
                    ),
                  ),
                  onTap: () {
                    context.push('/transactions/${transaction.id}');
                  },
                ),
              );
            }, childCount: transactions.length + (page.hasMore ? 1 : 0)),
          ),
        );
      },
      loading: () => const SliverFillRemaining(child: LoadingView()),
      error: (err, _) =>
          SliverFillRemaining(child: Center(child: Text(userMessage(err)))),
    );
  }
}
