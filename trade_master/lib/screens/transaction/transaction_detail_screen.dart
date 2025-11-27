import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../utils/formatters.dart';
import '../../widgets/receipts/transaction_receipt_widget.dart';

/// 거래 상세 화면
class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  final GlobalKey _receiptKey = GlobalKey();

  // 영수증 공유
  Future<void> _shareReceipt(Transaction transaction) async {
    try {
      final shareService = ref.read(shareServiceProvider);
      final businessAsync = ref.read(currentBusinessProvider);

      final business = await businessAsync.value;
      if (business == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사업장 정보를 불러올 수 없습니다')),
          );
        }
        return;
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

      final success = await shareService.shareWidget(
        widgetKey: _receiptKey,
        fileName: 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        text: '${transaction.customer?.name ?? '거래처'} 거래 영수증',
      );

      if (mounted) {
        Navigator.pop(context); // 로딩 대화상자 닫기

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('영수증을 공유했습니다'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('영수증 공유에 실패했습니다'),
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

  Future<void> _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('거래 삭제'),
        content: const Text('이 거래를 삭제하시겠습니까?\n거래처 잔액이 재계산됩니다.'),
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
      try {
        final service = ref.read(supabaseServiceProvider);
        await service.deleteTransaction(widget.transactionId);

        // Provider 갱신
        ref.invalidate(transactionsProvider);
        ref.invalidate(customerProvider(transaction.customerId));
        ref.invalidate(customersProvider);

        if (context.mounted) {
          context.go('/customers/${transaction.customerId}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('거래가 삭제되었습니다'),
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

  @override
  Widget build(BuildContext context) {
    final transactionAsync = ref.watch(transactionProvider(widget.transactionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 상세'),
        actions: [
          transactionAsync.whenOrNull(
                data: (transaction) {
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share),
                        tooltip: '영수증 공유',
                        onPressed: () => _shareReceipt(transaction),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: '수정',
                        onPressed: () {
                          context.go(
                            '/customers/${transaction.customerId}/transactions/${transaction.id}/edit',
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: '삭제',
                        onPressed: () =>
                            _deleteTransaction(context, ref, transaction),
                      ),
                    ],
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: transactionAsync.when(
        data: (transaction) {
          final isReceivable = transaction.type == TransactionType.receivable;
          final businessAsync = ref.watch(currentBusinessProvider);

          return Stack(
            children: [
              // 메인 콘텐츠
              SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 거래 유형 및 금액 헤더
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isReceivable
                          ? [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ]
                          : [
                              Colors.red.shade400,
                              Colors.red.shade600,
                            ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isReceivable
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isReceivable ? '받을 돈 (매출/입금)' : '줄 돈 (매입/출금)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.formatCurrency(transaction.amount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('yyyy년 MM월 dd일').format(transaction.date),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // 거래처 정보
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '거래처',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (transaction.customer != null)
                            InkWell(
                              onTap: () {
                                context.go(
                                  '/customers/${transaction.customerId}',
                                );
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      transaction.customer!.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            )
                          else
                            const Text(
                              '거래처 정보 없음',
                              style: TextStyle(fontSize: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 품목 정보 (있는 경우)
                if (transaction.productId != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '품목 정보',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (transaction.product != null) ...[
                              _DetailRow(
                                label: '품목명',
                                value: transaction.product!.name,
                              ),
                              const SizedBox(height: 8),
                              _DetailRow(
                                label: '수량',
                                value:
                                    '${transaction.quantity?.toStringAsFixed(2) ?? '-'} ${transaction.product!.unit}',
                              ),
                              const SizedBox(height: 8),
                              _DetailRow(
                                label: '단가',
                                value:
                                    '${Formatters.formatCurrency(transaction.unitPrice ?? 0)}원',
                              ),
                              const SizedBox(height: 8),
                              _DetailRow(
                                label: '금액',
                                value: Formatters.formatCurrency(
                                  transaction.amount,
                                ),
                                valueStyle: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ] else ...[
                              const Text('품목 정보를 불러올 수 없습니다'),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // 메모 (있는 경우)
                if (transaction.memo != null &&
                    transaction.memo!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.note,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '메모',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              transaction.memo!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // 생성/수정 정보
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailRow(
                            label: '생성일시',
                            value: DateFormat('yyyy-MM-dd HH:mm')
                                .format(transaction.createdAt),
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: '수정일시',
                            value: DateFormat('yyyy-MM-dd HH:mm')
                                .format(transaction.updatedAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
              ),

              // 숨겨진 영수증 위젯 (캡처용)
              Positioned(
                left: -10000,
                top: 0,
                child: businessAsync.when(
                  data: (business) {
                    if (business == null || transaction.customer == null) {
                      return const SizedBox.shrink();
                    }
                    return RepaintBoundary(
                      key: _receiptKey,
                      child: TransactionReceiptWidget(
                        transaction: transaction,
                        customer: transaction.customer!,
                        businessName: business.name,
                      ),
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
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                '에러가 발생했습니다',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상세 정보 행 위젯
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: valueStyle ?? const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
