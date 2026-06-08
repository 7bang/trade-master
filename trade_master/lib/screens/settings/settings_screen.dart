import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';

// 카카오 오픈채팅 문의 링크 — 실제 링크로 교체 필요
const _kakaoOpenChatUrl = 'https://open.kakao.com/o/PLACEHOLDER';

Future<void> _launchKakaoChat(BuildContext context) async {
  final uri = Uri.parse(_kakaoOpenChatUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카카오톡을 열 수 없습니다')),
      );
    }
  }
}

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

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
                  context.push('/settings/business/edit');
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

          // 개발자 문의
          ListTile(
            leading: const Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFFFAE100),
            ),
            title: const Text('개발자에게 문의'),
            subtitle: const Text('카카오 오픈채팅으로 연결됩니다'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchKakaoChat(context),
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
          ref.watch(_packageInfoProvider).when(
            data: (info) => AboutListTile(
              icon: const Icon(Icons.info),
              applicationName: '거래클립',
              applicationVersion: info.version,
              applicationLegalese: '© 2025 거래클립',
              child: const Text('앱 정보'),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.info),
              title: Text('앱 정보'),
            ),
            error: (_, __) => const AboutListTile(
              icon: Icon(Icons.info),
              applicationName: '거래클립',
              child: Text('앱 정보'),
            ),
          ),
        ],
      ),
    );
  }
}
