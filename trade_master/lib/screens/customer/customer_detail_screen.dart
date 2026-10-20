import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/receipts/customer_statement_widget.dart';
import '../../widgets/receipts/trade_document_widget.dart';
import '../../widgets/ai/collection_message_sheet.dart';
import '../ai/ai_transaction_input_screen.dart';
import '../document/trade_document_screen.dart';
import '../../config/on_colors.dart';
import '../../providers/data_refresh.dart';
import '../../utils/app_exception.dart';
import '../../utils/snackbars.dart';
import 'customer_detail_sections.dart';
import '../../widgets/ai/ai_voice_fab.dart';

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
      // 아직 불러오는 중이어도 끝날 때까지 기다린다 (.value는 로딩 중 null)
      final customer =
          await ref.read(customerProvider(widget.customerId).future);
      final statement =
          await ref.read(statementDataProvider(widget.customerId).future);
      final business = await ref.read(currentBusinessProvider.future);

      if (business == null) {
        if (mounted) {
          context.showInfo('정보를 불러올 수 없습니다');
        }
        return;
      }

      // 최근 50건만 담기므로 그보다 많으면 안내 (합계는 전체 기준)
      if (statement.isLimited) {
        if (mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: OnColors.warning),
                  SizedBox(width: 8),
                  Text('거래 건수 초과'),
                ],
              ),
              content: Text(
                '거래 내역이 ${statement.summary.count}건입니다.\n\n'
                '이미지에는 최근 ${StatementData.statementMaxRows}건만 표시되고,\n'
                '합계와 잔액은 전체 거래 기준입니다.\n\n'
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
          context.showSuccess('내역서를 공유했습니다');
        } else {
          context.showError('내역서 공유에 실패했습니다');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 대화상자 닫기
        context.showError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerProvider(widget.customerId));
    final statementAsync = ref.watch(statementDataProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('거래처 상세'),
        actions: [
          customerAsync.whenOrNull(
                data: (customer) => PopupMenuButton<String>(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'AI 도구',
                  onSelected: (value) {
                    if (value == 'collection') {
                      showCollectionMessageSheet(context, ref, customer);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'collection',
                      child: Row(
                        children: [
                          Icon(Icons.message_outlined),
                          SizedBox(width: 8),
                          Text('미수금 독촉 문구'),
                        ],
                      ),
                    ),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
          customerAsync.whenOrNull(
                data: (customer) => PopupMenuButton<String>(
                  icon: const Icon(Icons.share),
                  tooltip: '공유',
                  onSelected: (value) {
                    if (value == 'statement') {
                      _shareStatement();
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TradeDocumentScreen(
                          customer: customer,
                          type: value == 'quote'
                              ? TradeDocumentType.quote
                              : TradeDocumentType.delivery,
                        ),
                      ),
                    );
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'statement',
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_outlined),
                          SizedBox(width: 8),
                          Text('내역서 공유'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'quote',
                      child: Row(
                        children: [
                          Icon(Icons.request_quote_outlined),
                          SizedBox(width: 8),
                          Text('견적서 생성'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delivery',
                      child: Row(
                        children: [
                          Icon(Icons.local_shipping_outlined),
                          SizedBox(width: 8),
                          Text('납품서 생성'),
                        ],
                      ),
                    ),
                  ],
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
                    Icon(Icons.delete, color: OnColors.danger),
                    SizedBox(width: 8),
                    Text('삭제', style: TextStyle(color: OnColors.danger)),
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
                  CustomerBalanceHeader(customer: customer),

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
                  CustomerTransactionsSliver(customerId: widget.customerId),
                ],
              ),

              // 숨겨진 내역서 위젯 (캡처용)
              Positioned(
                left: -10000,
                top: 0,
                child: statementAsync.when(
                  data: (statement) {
                    return businessAsync.when(
                      data: (business) {
                        if (business == null) {
                          return const SizedBox.shrink();
                        }

                        return RepaintBoundary(
                          key: _statementKey,
                          child: CustomerStatementWidget(
                            customer: customer,
                            statement: statement,
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
              const Icon(Icons.error_outline, size: 64, color: OnColors.danger),
              const SizedBox(height: 16),
              Text(userMessage(err)),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AiVoiceFab(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AiTransactionInputScreen(
                  customerId: widget.customerId,
                  autoStartVoice: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'add-transaction-fab',
            onPressed: () => _showAddTransactionMenu(context),
            icon: const Icon(Icons.add),
            label: const Text('거래 추가'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long, color: OnColors.ink),
              title: const Text('단건 입력'),
              subtitle: const Text('거래를 1건 입력합니다'),
              onTap: () {
                Navigator.pop(context);
                context.go('/customers/${widget.customerId}/transactions/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_add, color: OnColors.ink),
              title: const Text('여러 건 입력'),
              subtitle: const Text('거래를 여러 건 한번에 입력합니다'),
              onTap: () {
                Navigator.pop(context);
                context.go('/customers/${widget.customerId}/transactions/multi');
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: OnColors.ink),
              title: const Text('AI 자동 입력'),
              subtitle: const Text('자연어 또는 사진으로 자동 입력합니다'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AiTransactionInputScreen(
                      customerId: widget.customerId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
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
            style: TextButton.styleFrom(foregroundColor: OnColors.danger),
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
      ref.refreshCustomers();

      if (context.mounted) {
        context.go('/customers');
        context.showSuccess('거래처가 삭제되었습니다');
      }
    } catch (e) {
      if (context.mounted) {
        context.showError(e);
      }
    }
  }
}
