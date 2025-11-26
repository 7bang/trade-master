import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../models/product.dart';
import '../../utils/formatters.dart';

/// 거래 입력/수정 화면
class TransactionFormScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String? transactionId; // null이면 등록, 값이 있으면 수정

  const TransactionFormScreen({
    super.key,
    required this.customerId,
    this.transactionId,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  bool _isLoading = false;
  bool _isEdit = false;
  Transaction? _originalTransaction;

  TransactionType _selectedType = TransactionType.receivable;
  Product? _selectedProduct;
  DateTime _selectedDate = DateTime.now();
  bool _useProductMode = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.transactionId != null;
    if (_isEdit) {
      _loadTransaction();
    }
  }

  Future<void> _loadTransaction() async {
    try {
      final transaction =
          await ref.read(transactionProvider(widget.transactionId!).future);
      setState(() {
        _originalTransaction = transaction;
        _selectedType = transaction.type;
        _selectedDate = transaction.date;
        _memoController.text = transaction.memo ?? '';

        if (transaction.productId != null) {
          _useProductMode = true;
          _quantityController.text = transaction.quantity?.toString() ?? '';
          _unitPriceController.text = transaction.unitPrice?.toString() ?? '';
          // Load product
          if (transaction.product != null) {
            _selectedProduct = transaction.product;
          }
        } else {
          _useProductMode = false;
          _amountController.text = transaction.amount.toString();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('거래 정보 로드 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  double _calculateAmount() {
    if (!_useProductMode) {
      return double.tryParse(_amountController.text.trim()) ?? 0;
    }

    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text.trim()) ?? 0;
    return quantity * unitPrice;
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_useProductMode && _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('품목을 선택하세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(supabaseServiceProvider);
      final business = await ref.read(currentBusinessProvider.future);

      if (business == null) {
        throw Exception('사업장 정보를 찾을 수 없습니다');
      }

      final amount = _calculateAmount();
      if (amount <= 0) {
        throw Exception('금액은 0보다 커야 합니다');
      }

      if (_isEdit && _originalTransaction != null) {
        // 수정
        final updatedTransaction = _originalTransaction!.copyWith(
          type: _selectedType,
          productId: _useProductMode ? _selectedProduct?.id : null,
          quantity: _useProductMode
              ? double.tryParse(_quantityController.text.trim())
              : null,
          unitPrice: _useProductMode
              ? double.tryParse(_unitPriceController.text.trim())
              : null,
          amount: amount,
          date: _selectedDate,
          memo: _memoController.text.trim().isEmpty
              ? null
              : _memoController.text.trim(),
          updatedAt: DateTime.now(),
        );

        await service.updateTransaction(updatedTransaction);

        // Provider 갱신
        ref.invalidate(transactionsProvider);
        ref.invalidate(transactionProvider(widget.transactionId!));
        ref.invalidate(customerProvider(widget.customerId));
        ref.invalidate(customersProvider);

        if (mounted) {
          context.go('/customers/${widget.customerId}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('거래 정보가 수정되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 등록
        final newTransaction = Transaction(
          id: '', // Supabase에서 자동 생성
          businessId: business.id,
          customerId: widget.customerId,
          type: _selectedType,
          productId: _useProductMode ? _selectedProduct?.id : null,
          quantity: _useProductMode
              ? double.tryParse(_quantityController.text.trim())
              : null,
          unitPrice: _useProductMode
              ? double.tryParse(_unitPriceController.text.trim())
              : null,
          amount: amount,
          date: _selectedDate,
          memo: _memoController.text.trim().isEmpty
              ? null
              : _memoController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await service.createTransaction(newTransaction);

        // Provider 갱신
        ref.invalidate(transactionsProvider);
        ref.invalidate(customerProvider(widget.customerId));
        ref.invalidate(customersProvider);

        if (mounted) {
          context.go('/customers/${widget.customerId}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('거래가 등록되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerProvider(widget.customerId));
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '거래 수정' : '거래 입력'),
      ),
      body: customerAsync.when(
        data: (customer) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 거래처 정보
                    Card(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '현재 잔액: ${Formatters.formatCurrency(customer.balance)} (${Formatters.formatBalanceType(customer.balance)})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 거래 유형 선택
                    const Text(
                      '거래 유형',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.receivable,
                          label: Text('받을 돈'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                        ButtonSegment(
                          value: TransactionType.payable,
                          label: Text('줄 돈'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (Set<TransactionType> selected) {
                        setState(() {
                          _selectedType = selected.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // 입력 모드 선택
                    Row(
                      children: [
                        const Text(
                          '입력 모드',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _useProductMode,
                          onChanged: (value) {
                            setState(() {
                              _useProductMode = value;
                              if (!value) {
                                _selectedProduct = null;
                                _quantityController.clear();
                                _unitPriceController.clear();
                              } else {
                                _amountController.clear();
                              }
                            });
                          },
                        ),
                        Text(_useProductMode ? '품목 사용' : '직접 입력'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 품목 모드
                    if (_useProductMode) ...[
                      // 품목 선택
                      productsAsync.when(
                        data: (products) {
                          return DropdownButtonFormField<Product>(
                            value: _selectedProduct,
                            decoration: const InputDecoration(
                              labelText: '품목',
                              prefixIcon: Icon(Icons.inventory_2),
                              helperText: '품목 선택',
                            ),
                            items: products.map((product) {
                              return DropdownMenuItem(
                                value: product,
                                child: Text(
                                  '${product.name} (${Formatters.formatCurrency(product.defaultUnitPrice ?? 0)}/${product.unit})',
                                ),
                              );
                            }).toList(),
                            onChanged: (product) {
                              setState(() {
                                _selectedProduct = product;
                                if (product != null &&
                                    product.defaultUnitPrice != null) {
                                  _unitPriceController.text =
                                      product.defaultUnitPrice.toString();
                                }
                              });
                            },
                            validator: (value) {
                              if (_useProductMode && value == null) {
                                return '품목을 선택하세요';
                              }
                              return null;
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (err, stack) => Text(
                          '품목 로드 실패: ${err.toString()}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 수량 및 단가
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: InputDecoration(
                                labelText: '수량',
                                hintText: '예: 10',
                                suffixText: _selectedProduct?.unit ?? '',
                              ),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              onChanged: (value) => setState(() {}),
                              validator: (value) {
                                if (_useProductMode &&
                                    (value == null || value.trim().isEmpty)) {
                                  return '수량 입력';
                                }
                                final quantity = double.tryParse(value!.trim());
                                if (quantity == null || quantity <= 0) {
                                  return '유효한 수량';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _unitPriceController,
                              decoration: const InputDecoration(
                                labelText: '단가',
                                hintText: '예: 8000',
                                suffixText: '원',
                              ),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              onChanged: (value) => setState(() {}),
                              validator: (value) {
                                if (_useProductMode &&
                                    (value == null || value.trim().isEmpty)) {
                                  return '단가 입력';
                                }
                                final price = double.tryParse(value!.trim());
                                if (price == null || price <= 0) {
                                  return '유효한 단가';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 계산된 금액 표시
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '총 금액',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(_calculateAmount()),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 직접 입력 모드
                    if (!_useProductMode) ...[
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: '금액',
                          hintText: '예: 80000',
                          prefixIcon: Icon(Icons.attach_money),
                          helperText: '거래 금액을 입력하세요',
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (!_useProductMode &&
                              (value == null || value.trim().isEmpty)) {
                            return '금액을 입력하세요';
                          }
                          final amount = double.tryParse(value!.trim());
                          if (amount == null || amount <= 0) {
                            return '유효한 금액을 입력하세요';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),

                    // 날짜 선택
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '거래 날짜',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 메모
                    TextFormField(
                      controller: _memoController,
                      decoration: const InputDecoration(
                        labelText: '메모',
                        hintText: '거래에 대한 메모를 입력하세요',
                        prefixIcon: Icon(Icons.note),
                        helperText: '선택 입력',
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 32),

                    // 저장 버튼
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTransaction,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEdit ? '수정 완료' : '등록하기',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 취소 버튼
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          context.pop();
                        },
                        child: const Text(
                          '취소',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('에러: ${err.toString()}'),
        ),
      ),
    );
  }
}
