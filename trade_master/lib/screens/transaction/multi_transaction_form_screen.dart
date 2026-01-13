import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../models/product.dart';
import '../../utils/formatters.dart';

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

class _MultiTransactionFormScreenState
    extends ConsumerState<MultiTransactionFormScreen> {
  final List<TransactionItem> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 첫 번째 거래 항목 추가
    _addTransaction();
  }

  void _addTransaction() {
    setState(() {
      _transactions.add(TransactionItem());
    });
  }

  void _removeTransaction(int index) {
    if (_transactions.length > 1) {
      setState(() {
        _transactions[index].dispose();
        _transactions.removeAt(index);
      });
    }
  }

  Future<void> _saveAll() async {
    // 이미 로딩 중이면 중복 실행 방지
    if (_isLoading) return;

    // 검증을 위해 모든 항목 펼치기 (Form이 빌드되어야 validate 가능)
    setState(() {
      for (var item in _transactions) {
        item.isExpanded = true;
      }
    });

    // Form이 빌드될 때까지 약간 대기
    await Future.delayed(const Duration(milliseconds: 150));

    // 모든 항목 검증
    bool allValid = true;
    for (var i = 0; i < _transactions.length; i++) {
      final currentState = _transactions[i].formKey.currentState;

      // Form이 아직 빌드되지 않았으면 건너뛰기
      if (currentState == null) continue;

      if (!currentState.validate()) {
        allValid = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('거래 ${i + 1}의 입력값을 확인해주세요'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      }
    }

    if (!allValid) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(supabaseServiceProvider);
      final businessAsync = ref.read(currentBusinessProvider);

      // AsyncValue에서 business 가져오기
      final business = businessAsync.maybeWhen(
        data: (data) => data,
        orElse: () => null,
      );

      if (business == null) {
        throw Exception('사업장 정보를 찾을 수 없습니다');
      }

      // 모든 거래를 순차적으로 저장
      for (var i = 0; i < _transactions.length; i++) {
        final item = _transactions[i];
        final amount = item.calculateAmount();
        final now = DateTime.now();

        final transaction = Transaction(
          id: '',
          businessId: business.id,
          customerId: widget.customerId,
          type: item.selectedType,
          amount: amount,
          date: item.selectedDate,
          productId: item.useProductMode ? item.selectedProduct?.id : null,
          quantity: item.useProductMode
              ? double.tryParse(item.quantityController.text.trim())
              : null,
          unitPrice: item.useProductMode
              ? double.tryParse(item.unitPriceController.text.trim())
              : null,
          memo: item.memoController.text.trim().isEmpty
              ? null
              : item.memoController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );

        await service.createTransaction(transaction);
      }

      // Provider 갱신
      ref.invalidate(transactionsProvider(widget.customerId));
      ref.invalidate(customerProvider(widget.customerId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_transactions.length}건의 거래가 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    for (var item in _transactions) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('여러 건 거래 입력'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveAll,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: Text(
              '전체 저장 (${_transactions.length}건)',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) => Column(
          children: [
            // 안내 메시지
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '여러 건의 거래를 한 번에 입력할 수 있습니다',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 거래 목록
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  return _buildTransactionCard(
                    index,
                    _transactions[index],
                    products,
                  );
                },
              ),
            ),

            // 하단 버튼
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: _addTransaction,
                    icon: const Icon(Icons.add),
                    label: const Text('거래 추가'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAll,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('전체 저장하기 (${_transactions.length}건)'),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('에러: $err')),
      ),
    );
  }

  Widget _buildTransactionCard(
    int index,
    TransactionItem item,
    List<Product> products,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('transaction_$index'),
          initiallyExpanded: item.isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              item.isExpanded = expanded;
            });
          },
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
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
              : Text(
                  '${item.selectedType == TransactionType.receivable ? "받을 돈" : "줄 돈"} • '
                  '${DateFormat('M/d').format(item.selectedDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_transactions.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeTransaction(index),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 받을돈/줄돈 선택
                    const Text(
                      '거래 유형',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.receivable,
                          label: Text('받을 돈'),
                          icon: Icon(Icons.arrow_downward, color: Colors.green),
                        ),
                        ButtonSegment(
                          value: TransactionType.payable,
                          label: Text('줄 돈'),
                          icon: Icon(Icons.arrow_upward, color: Colors.red),
                        ),
                      ],
                      selected: {item.selectedType},
                      onSelectionChanged: (Set<TransactionType> selected) {
                        setState(() {
                          item.selectedType = selected.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // 날짜 선택
                    const Text(
                      '거래 날짜',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(Formatters.formatDate(item.selectedDate)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: item.selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() {
                            item.selectedDate = date;
                          });
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 품목/직접입력 모드 선택
                    Row(
                      children: [
                        const Text(
                          '입력 방식',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('직접 입력'),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('품목 선택'),
                            ),
                          ],
                          selected: {item.useProductMode},
                          onSelectionChanged: (Set<bool> selected) {
                            setState(() {
                              item.useProductMode = selected.first;
                              if (!item.useProductMode) {
                                item.selectedProduct = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 품목 선택 모드
                    if (item.useProductMode) ...[
                      // 품목 선택
                      DropdownButtonFormField<Product>(
                        value: item.selectedProduct,
                        decoration: const InputDecoration(
                          labelText: '품목',
                          hintText: '품목을 선택하세요',
                        ),
                        items: products.map((product) {
                          return DropdownMenuItem(
                            value: product,
                            child: Text(product.name),
                          );
                        }).toList(),
                        onChanged: (product) {
                          setState(() {
                            item.selectedProduct = product;
                            if (product != null && product.defaultUnitPrice != null) {
                              item.unitPriceController.text =
                                  product.defaultUnitPrice.toString();
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return '품목을 선택해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 수량
                      TextFormField(
                        controller: item.quantityController,
                        decoration: const InputDecoration(
                          labelText: '수량',
                          hintText: '예: 10',
                          suffix: Text('개'),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '수량을 입력해주세요';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return '올바른 숫자를 입력해주세요';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // 단가
                      TextFormField(
                        controller: item.unitPriceController,
                        decoration: const InputDecoration(
                          labelText: '단가',
                          hintText: '예: 5000',
                          suffix: Text('원'),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '단가를 입력해주세요';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return '올바른 숫자를 입력해주세요';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // 계산된 금액 표시
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '총 금액',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(item.calculateAmount()),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: item.selectedType ==
                                        TransactionType.receivable
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // 직접 입력 모드
                      TextFormField(
                        controller: item.amountController,
                        decoration: const InputDecoration(
                          labelText: '금액',
                          hintText: '예: 50000',
                          suffix: Text('원'),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '금액을 입력해주세요';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return '올바른 숫자를 입력해주세요';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 메모
                    TextFormField(
                      controller: item.memoController,
                      decoration: const InputDecoration(
                        labelText: '메모 (선택사항)',
                        hintText: '거래 내용을 메모하세요',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 거래 항목 데이터 클래스
class TransactionItem {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController memoController = TextEditingController();

  TransactionType selectedType = TransactionType.receivable;
  Product? selectedProduct;
  DateTime selectedDate = DateTime.now();
  bool useProductMode = false;
  bool isExpanded = true;

  double calculateAmount() {
    if (!useProductMode) {
      return double.tryParse(amountController.text.trim()) ?? 0;
    }

    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    final unitPrice = double.tryParse(unitPriceController.text.trim()) ?? 0;
    return quantity * unitPrice;
  }

  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
    amountController.dispose();
    memoController.dispose();
  }
}
