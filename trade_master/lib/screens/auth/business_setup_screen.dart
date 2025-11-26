import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/business.dart';

/// 사업장 정보 설정 화면
///
/// 회원가입 후 최초 1회 표시됩니다.
class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(supabaseServiceProvider);
      final user = service.currentUser;

      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 사업장 정보 생성
      final business = Business(
        id: '', // Supabase에서 자동 생성
        userId: user.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.createBusiness(business);

      // Provider 갱신
      ref.invalidate(currentBusinessProvider);

      if (mounted) {
        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사업장 정보가 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        // 거래처 목록 화면으로 이동
        context.go('/customers');
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
        title: const Text('사업장 정보 입력'),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 헤더
                  Icon(
                    Icons.store,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '사업장 정보를 입력해주세요',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '나중에 설정에서 변경할 수 있습니다',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 48),

                  // 사업장 이름 입력
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '사업장 이름',
                      hintText: '예: 제주 청과물 가게',
                      prefixIcon: Icon(Icons.business),
                      helperText: '거래 명세서에 표시됩니다',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '사업장 이름을 입력하세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 연락처 입력 (선택사항)
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: '연락처 (선택사항)',
                      hintText: '예: 010-1234-5678',
                      prefixIcon: Icon(Icons.phone),
                      helperText: '거래 명세서에 표시됩니다',
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _saveBusiness(),
                  ),
                  const SizedBox(height: 32),

                  // 저장 버튼
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveBusiness,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '시작하기',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 안내 메시지
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 20, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              '거의 다 왔습니다!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '정보 입력 후 바로 거래처와 거래 내역을\n관리할 수 있습니다.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
