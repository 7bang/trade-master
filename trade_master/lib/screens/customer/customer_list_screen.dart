import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/common_widgets.dart';

/// 거래처 목록 화면
class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searchQuery.isEmpty
            ? const Text('거래클립')
            : Text('검색: $_searchQuery'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '검색',
            onPressed: () {
              _showSearchDialog();
            },
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: '검색 초기화',
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
      body: customersAsync.when(
        data: (allCustomers) {
          // 검색 필터링
          final customers = _searchQuery.isEmpty
              ? allCustomers
              : allCustomers.where((customer) {
                  final query = _searchQuery.toLowerCase();
                  final nameMatch = customer.name.toLowerCase().contains(query);
                  final phoneMatch = customer.phone?.toLowerCase().contains(query) ?? false;
                  return nameMatch || phoneMatch;
                }).toList();
          if (customers.isEmpty) {
            return EmptyStateView(
              icon: _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
              title: _searchQuery.isEmpty ? '등록된 거래처가 없습니다' : '검색 결과가 없습니다',
              actionLabel: _searchQuery.isEmpty ? '거래처 추가하기' : '검색 초기화',
              onAction: _searchQuery.isEmpty
                  ? () => context.push('/customers/new')
                  : () => setState(() => _searchQuery = ''),
            );
          }

          // 전체 잔액 계산
          final totalReceivable = customers
              .where((c) => c.balance > 0)
              .fold(0.0, (sum, c) => sum + c.balance);
          final totalPayable = customers
              .where((c) => c.balance < 0)
              .fold(0.0, (sum, c) => sum + c.balance.abs());
          final netBalance = totalReceivable - totalPayable;

          return Column(
            children: [
              // 전체 잔액 요약
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '전체 잔액',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BalanceSummaryItem(
                          label: '받을 돈',
                          amount: totalReceivable,
                          icon: Icons.arrow_downward,
                          isPositive: true,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white30,
                        ),
                        _BalanceSummaryItem(
                          label: '줄 돈',
                          amount: totalPayable,
                          icon: Icons.arrow_upward,
                          isPositive: false,
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white30, height: 24),
                    Text(
                      '순액: ${Formatters.formatCurrency(netBalance)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 거래처 목록
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '내 거래처',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${customers.length}곳',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: BalanceAvatar(balance: customer.balance),
                        title: Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (customer.phone != null) ...[
                              const SizedBox(height: 4),
                              Text(customer.phone!),
                            ],
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.formatCurrency(customer.balance.abs()),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: customer.balance >= 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                            Text(
                              Formatters.formatBalanceType(customer.balance),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          context.push('/customers/${customer.id}');
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (err, stack) => ErrorView(
          error: err,
          onRetry: () => ref.refresh(customersProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/customers/new');
        },
        icon: const Icon(Icons.add),
        label: const Text('거래처 추가'),
      ),
    );
  }

  // 검색 다이얼로그 표시
  void _showSearchDialog() {
    final controller = TextEditingController(text: _searchQuery);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search),
            SizedBox(width: 8),
            Text('거래처 검색'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '거래처명 또는 연락처 입력',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
                Navigator.pop(context);
              },
              child: const Text('초기화'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = controller.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('검색'),
          ),
        ],
      ),
    );
  }
}

/// 잔액 요약 항목 위젯
class _BalanceSummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final bool isPositive;

  const _BalanceSummaryItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.formatCurrency(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
