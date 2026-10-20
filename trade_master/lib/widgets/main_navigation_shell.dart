import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/on_colors.dart';
import '../providers/providers.dart';
import '../screens/settings/announcements_screen.dart';

/// 하단 네비게이션이 있는 메인 Shell
/// 로그인 후 처음 열릴 때 안 읽은 중요 공지를 팝업으로 한 번 보여준다.
class MainNavigationShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ImportantAnnouncementPopup.maybeShow(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final hasUnread = ref.watch(unreadAnnouncementsProvider).isNotEmpty;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '거래처',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '품목',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '거래내역',
          ),
          NavigationDestination(
            // 안 읽은 공지가 있으면 빨간 점
            icon: Badge(
              isLabelVisible: hasUnread,
              backgroundColor: OnColors.vermilion,
              smallSize: 9,
              child: const Icon(Icons.settings_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: hasUnread,
              backgroundColor: OnColors.vermilion,
              smallSize: 9,
              child: const Icon(Icons.settings),
            ),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
