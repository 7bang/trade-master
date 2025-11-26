import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/customer.dart';

/// 거래처 등록/수정 화면
class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId; // null이면 등록, 값이 있으면 수정

  const CustomerFormScreen({
    super.key,
    this.customerId,
  });

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _memoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isEdit = false;
  Customer? _originalCustomer;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.customerId != null;
    if (_isEdit) {
      _loadCustomer();
    }
  }

  Future<void> _loadCustomer() async {
    try {
      final customer = await ref.read(customerProvider(widget.customerId!).future);
      setState(() {
        _originalCustomer = customer;
        _nameController.text = customer.name;
        _phoneController.text = customer.phone ?? '';
        _memoController.text = customer.memo ?? '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('거래처 정보 로드 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(supabaseServiceProvider);
      final business = await ref.read(currentBusinessProvider.future);

      if (business == null) {
        throw Exception('사업장 정보를 찾을 수 없습니다');
      }

      if (_isEdit && _originalCustomer != null) {
        // 수정
        final updatedCustomer = _originalCustomer!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          memo: _memoController.text.trim().isEmpty
              ? null
              : _memoController.text.trim(),
          updatedAt: DateTime.now(),
        );

        await service.updateCustomer(updatedCustomer);

        // Provider 갱신
        ref.invalidate(customersProvider);
        ref.invalidate(customerProvider(widget.customerId!));

        if (mounted) {
          context.go('/customers/${widget.customerId}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('거래처 정보가 수정되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 등록
        final newCustomer = Customer(
          id: '', // Supabase에서 자동 생성
          businessId: business.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          memo: _memoController.text.trim().isEmpty
              ? null
              : _memoController.text.trim(),
          isActive: true,
          balance: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await service.createCustomer(newCustomer);

        // Provider 갱신
        ref.invalidate(customersProvider);

        if (mounted) {
          context.go('/customers');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('거래처가 등록되었습니다'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '거래처 수정' : '거래처 등록'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더 아이콘
                Icon(
                  _isEdit ? Icons.edit : Icons.person_add,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  _isEdit ? '거래처 정보를 수정하세요' : '새 거래처를 등록하세요',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 32),

                // 거래처 이름 (필수)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '거래처 이름',
                    hintText: '예: 서울 청과 도매',
                    prefixIcon: Icon(Icons.business),
                    helperText: '필수 입력',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '거래처 이름을 입력하세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 연락처 (선택)
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '연락처',
                    hintText: '예: 010-1234-5678',
                    prefixIcon: Icon(Icons.phone),
                    helperText: '선택 입력',
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // 메모 (선택)
                TextFormField(
                  controller: _memoController,
                  decoration: const InputDecoration(
                    labelText: '메모',
                    hintText: '거래처에 대한 메모를 입력하세요',
                    prefixIcon: Icon(Icons.note),
                    helperText: '선택 입력',
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _saveCustomer(),
                ),
                const SizedBox(height: 32),

                // 저장 버튼
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveCustomer,
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
      ),
    );
  }
}
