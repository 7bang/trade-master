import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/business.dart';

/// 사업장 정보 수정 화면
class BusinessEditScreen extends ConsumerStatefulWidget {
  const BusinessEditScreen({super.key});

  @override
  ConsumerState<BusinessEditScreen> createState() => _BusinessEditScreenState();
}

class _BusinessEditScreenState extends ConsumerState<BusinessEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  Business? _business;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    try {
      final business = await ref.read(currentBusinessProvider.future);
      if (business != null && mounted) {
        setState(() {
          _business = business;
          _nameController.text = business.name;
          _phoneController.text = business.phone ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사업장 정보를 불러올 수 없습니다: $e')),
        );
      }
    }
  }

  Future<void> _saveBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(supabaseServiceProvider);
      final updatedBusiness = _business!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      await service.updateBusiness(updatedBusiness);

      // Provider 갱신
      ref.invalidate(currentBusinessProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사업장 정보가 수정되었습니다')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사업장 정보 수정'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: '저장',
              onPressed: _saveBusiness,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 안내 카드
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '영수증과 내역서에 표시되는 사업장 정보입니다.',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 사업장명
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '사업장명',
                        hintText: '예: 홍길동 청과',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '사업장명을 입력해주세요';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // 연락처
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: '연락처 (선택)',
                        hintText: '예: 010-1234-5678',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _saveBusiness(),
                    ),
                    const SizedBox(height: 32),

                    // 저장 버튼
                    ElevatedButton.icon(
                      onPressed: _saveBusiness,
                      icon: const Icon(Icons.save),
                      label: const Text('저장'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
