import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../utils/formatters.dart';
import '../../models/transaction.dart' as models;
import '../../widgets/receipts/customer_statement_widget.dart';

/// 거래처 상세 화면
class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  final GlobalKey _statementKey = GlobalKey();

  // 내역서 공유
  Future<void> _shareStatement() async {
    try {
      final customerAsync = ref.read(customerProvider(widget.customerId));
      final transactionsAsync =
          ref.read(transactionsProvider(widget.customerId));
      final businessAsync = ref.read(currentBusinessProvider);

      final customer = await customerAsync.value;
      final transactions = await transactionsAsync.value;
      final business = await businessAsync.value;

      if (customer == null || business == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('정보를 불러올 수 없습니다')),
          );
        }
        return;
      }

      // 50건 초과 시 경고
      const maxTransactions = 50;
      if (transactions != null && transactions.length > maxTransactions) {
        if (mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('거래 건수 초과'),
                ],
              ),
              content: Text(
                '거래 내역이 ${transactions.length}건입니다.\n\n'
                '이미지 공유는 최근 $maxTransactions건만 표시됩니다.\n'
                '전체 내역은 추후 PDF 기능을 이용해주세요.\n\n'
                '계속하시겠습니까?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('계속'),
                ),
              ],
            ),
          );

          if (confirmed != true) return;
        }
      }

      // 공유 대화상자 표시
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // 약간의 지연 (위젯 렌더링 대기)
      await Future.delayed(const Duration(milliseconds: 300));

      final shareService = ref.read(shareServiceProvider);
      final success = await shareService.shareWidget(
        widgetKey: _statementKey,
        fileName:
            'statement_${customer.name}_${DateTime.now().millisecondsSinceEpoch}',
        text: '${customer.name} 거래 내역서',
      );

      if (mounted) {
        Navigator.pop(context); // 로딩 대화상자 닫기

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('내역서를 공유했습니다'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('내역서 공유에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 대화상자 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerProvider(widget.customerId));
    final transactionsAsync = ref.watch(transactionsProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('거래처 상세'),
        actions: [
          customerAsync.whenOrNull(
                data: (customer) => IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: '내역서 공유',
                  onPressed: _shareStatement,
                ),
              ) ??
              const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '수정',
            onPressed: () {
              context.go('/customers/${widget.customerId}/edit');
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
        data: (customer) {
          final businessAsync = ref.watch(currentBusinessProvider);

          return Stack(
            children: [
              // 메인 콘텐츠 - CustomScrollView 사용
              CustomScrollView(
                slivers: [
                  // 축소 가능한 헤더
                  SliverAppBar(
                    expandedHeight: 280,
                    floating: false,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        // 현재 확장 비율 계산
                        final maxHeight = 280.0;
                        final minHeight = kToolbarHeight;
                        final currentHeight = constraints.maxHeight;
                        final percent = ((currentHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0);

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
                                            ? Colors.green.shade200
                                            : Colors.red.shade200,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                          color: Theme.of(context).primaryColor,
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
                                          const Icon(Icons.phone,
                                              size: 16, color: Colors.white70),
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
                                    if (percent > 0.4) const Divider(
                                      color: Colors.white30,
                                      height: 24,
                                    ),
                                    if (percent > 0.4) const Text(
                                      '현재 잔액',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
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
                                    if (percent > 0.4) Text(
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
                  ),

                  // 거래 내역 헤더
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '거래 내역',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),

                  // 거래 목록
                  transactionsAsync.when(
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
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
                                    context.go(
                                        '/customers/${widget.customerId}/transactions/new');
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('거래 추가하기'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
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
                                      transaction.type ==
                                              models.TransactionType.receivable
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
                                        transaction.type ==
                                                models.TransactionType.receivable
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
                                            borderRadius:
                                                BorderRadius.circular(4),
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
                                    context.push('/transactions/${transaction.id}');
                                  },
                                ),
                              );
                            },
                            childCount: transactions.length,
                          ),
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => SliverFillRemaining(
                      child: Center(
                        child: Text('에러: $err'),
                      ),
                    ),
                  ),
                ],
              ),

              // 숨겨진 내역서 위젯 (캡처용)
              Positioned(
                left: -10000,
                top: 0,
                child: transactionsAsync.when(
                  data: (transactions) {
                    return businessAsync.when(
                      data: (business) {
                        if (business == null) {
                          return const SizedBox.shrink();
                        }

                        // 전체 거래 내역 기간 계산
                        DateTime startDate = DateTime.now();
                        DateTime endDate = DateTime.now();

                        if (transactions.isNotEmpty) {
                          startDate = transactions.last.date;
                          endDate = transactions.first.date;
                        }

                        return RepaintBoundary(
                          key: _statementKey,
                          child: CustomerStatementWidget(
                            customer: customer,
                            transactions: transactions,
                            startDate: startDate,
                            endDate: endDate,
                            businessName: business.name,
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ],
          );
        },
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
          context.go('/customers/${widget.customerId}/transactions/new');
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
      await service.deleteCustomer(widget.customerId);

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
