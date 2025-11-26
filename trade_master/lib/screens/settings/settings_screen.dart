import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';

/// 설정 화면
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final businessAsync = ref.watch(currentBusinessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          // 사용자 정보
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(user.email ?? '사용자'),
                subtitle: const Text('계정 정보'),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(),

          // 사업장 정보
          businessAsync.when(
            data: (business) {
              if (business == null) return const SizedBox.shrink();
              return ListTile(
                leading: const Icon(Icons.business),
                title: Text(business.name),
                subtitle: Text(business.phone ?? '연락처 없음'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 사업장 정보 수정 화면
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('사업장 정보 수정 기능 준비중')),
                  );
                },
              );
            },
            loading: () => const ListTile(
              leading: Icon(Icons.business),
              title: Text('로딩 중...'),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(),

          // 로그아웃
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await SupabaseService().signOut();
                if (context.mounted) {
                  context.go('/');
                }
              }
            },
          ),

          const Divider(),

          // 앱 정보
          const AboutListTile(
            icon: Icon(Icons.info),
            applicationName: '거래의장인',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2025 거래의장인',
            child: Text('앱 정보'),
          ),
        ],
      ),
    );
  }
}
