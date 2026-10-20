import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/on_colors.dart';
import '../../models/customer.dart';
import '../../models/transaction.dart';
import '../../providers/data_refresh.dart';
import '../../providers/providers.dart';
import '../../services/ai_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbars.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/transaction_entry_fields.dart';

/// 거래 입력/수정 화면
class TransactionFormScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String? transactionId; // null이면 등록, 값이 있으면 수정
  final ParsedTransaction? initialData; // AI 사진 분석 결과 프리필

  /// AI 자연어·음성 결과 카드에서 "자세히 입력"으로 넘어올 때 (이 화면이 dispose 책임)
  final TransactionEntry? initialEntry;

  const TransactionFormScreen({
    super.key,
    required this.customerId,
    this.transactionId,
    this.initialData,
    this.initialEntry,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  TransactionEntry _entry = TransactionEntry();
  Transaction? _original;
  bool _isLoading = false;

  bool get _isEdit => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadTransaction();
    } else if (widget.initialEntry != null) {
      _entry.dispose();
      _entry = widget.initialEntry!;
    } else if (widget.initialData != null) {
      _applyInitialData(widget.initialData!);
    }
  }

  void _applyInitialData(ParsedTransaction data) {
    _entry.type = data.type == 'payable'
        ? TransactionType.payable
        : TransactionType.receivable;
    _entry.date = data.date;
    _entry.amountController.text = data.amount.toInt().toString();
    if (data.memo != null) _entry.memoController.text = data.memo!;
  }

  Future<void> _loadTransaction() async {
    try {
      final transaction =
          await ref.read(transactionProvider(widget.transactionId!).future);
      if (!mounted) return;
      setState(() {
        _entry.dispose();
        _entry = TransactionEntry.fromTransaction(transaction);
        _original = transaction;
      });
    } catch (e) {
      if (mounted) context.showError(e);
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final service = ref.read(supabaseServiceProvider);
      final business = await ref.read(currentBusinessProvider.future);
      if (business == null) {
        throw const AppException('사업장 정보를 찾을 수 없습니다');
      }
      if (_entry.amount <= 0) {
        throw const AppException('금액은 0보다 커야 합니다');
      }

      final original = _original;
      if (_isEdit && original != null) {
        await service.updateTransaction(_entry.applyTo(original));
      } else {
        await service.createTransaction(_entry.toNewTransaction(
          businessId: business.id,
          customerId: widget.customerId,
        ));
      }
      ref.refreshTransactions();

      if (mounted) {
        context.go('/customers/${widget.customerId}');
        context.showSuccess(_isEdit ? '거래 정보가 수정되었습니다' : '거래가 등록되었습니다');
      }
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerProvider(widget.customerId));
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '거래 수정' : '거래 입력')),
      body: customerAsync.when(
        data: (customer) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CustomerHeader(customer: customer),
                  const SizedBox(height: 24),
                  productsAsync.when(
                    data: (products) => TransactionEntryFields(
                      entry: _entry,
                      products: products,
                      onChanged: () => setState(() {}),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text(
                      userMessage(err),
                      style: const TextStyle(color: OnColors.danger),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEdit ? '수정 완료' : '등록하기'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('취소'),
                  ),
                ],
              ),
            ),
          ),
        ),
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(error: err),
      ),
    );
  }
}

/// 거래처 이름과 현재 잔액
class _CustomerHeader extends StatelessWidget {
  final Customer customer;

  const _CustomerHeader({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.person, color: OnColors.ink),
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
                    '현재 잔액: ${Formatters.formatCurrency(customer.balance)} '
                    '(${Formatters.formatBalanceType(customer.balance)})',
                    style: const TextStyle(fontSize: 15, color: OnColors.gray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
