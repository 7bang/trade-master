import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/on_colors.dart';
import '../../models/announcement.dart';
import '../../providers/data_refresh.dart';
import '../../providers/providers.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbars.dart';
import '../../widgets/common_widgets.dart';

/// 읽음 표시 후 빨간 점·팝업 갱신 (실패해도 화면은 그대로 — 다음에 다시 표시될 뿐)
Future<void> markAnnouncementRead(WidgetRef ref, Announcement a) async {
  try {
    await ref.read(supabaseServiceProvider).markAnnouncementRead(a.id);
    ref.invalidate(readAnnouncementIdsProvider);
  } catch (_) {}
}

/// 공지 링크 열기 (https만 — DB에서도 막는다)
Future<void> openAnnouncementLink(BuildContext context, Announcement a) async {
  if (!a.hasLink) return;
  final ok = await launchUrl(Uri.parse(a.linkUrl!),
      mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) context.showError('링크를 열 수 없습니다');
}

/// 설정 > 공지사항
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final readIds = ref.watch(readAnnouncementIdsProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refreshAnnouncements();
          try {
            await ref.read(announcementsProvider.future);
          } catch (_) {}
        },
        child: announcementsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                EmptyStateView(icon: Icons.campaign_outlined, title: '공지사항이 없습니다'),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = list[i];
                final unread = !readIds.contains(a.id);
                return ListTile(
                  minVerticalPadding: 14,
                  leading: unread
                      ? const _Dot(semanticLabel: '안 읽음')
                      : const SizedBox(width: 10),
                  title: Text(
                    a.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    [
                      if (a.isImportant) '중요',
                      Formatters.formatDateKorean(a.publishedAt),
                    ].join(' · '),
                    style: const TextStyle(fontSize: 15, color: OnColors.gray),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => AnnouncementDetailScreen(announcement: a),
                  )),
                );
              },
            );
          },
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.refreshAnnouncements(),
          ),
        ),
      ),
    );
  }
}

/// 공지 상세 — 열면 읽음 표시
class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  ConsumerState<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState
    extends ConsumerState<AnnouncementDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => markAnnouncementRead(ref, widget.announcement));
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (a.isImportant)
              const Align(
                alignment: Alignment.centerLeft,
                child: _ImportantBadge(),
              ),
            Text(
              a.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              Formatters.formatDateKorean(a.publishedAt),
              style: const TextStyle(fontSize: 15, color: OnColors.gray),
            ),
            const Divider(height: 32),
            SelectableText(
              a.body,
              style: const TextStyle(fontSize: 17, height: 1.6),
            ),
            if (a.hasLink) ...[
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => openAnnouncementLink(context, a),
                icon: const Icon(Icons.open_in_new),
                label: Text(a.linkLabel ?? '자세히 보기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final String semanticLabel;

  const _Dot({required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: OnColors.vermilion,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ImportantBadge extends StatelessWidget {
  const _ImportantBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OnColors.info, width: 1.5),
      ),
      child: const Text(
        '! 중요',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: OnColors.info,
        ),
      ),
    );
  }
}

/// 앱을 열 때: 안 읽은 중요 공지 중 가장 최근 1개를 팝업 (한 실행에 한 번)
class ImportantAnnouncementPopup {
  static bool _shownThisSession = false;

  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    if (_shownThisSession) return;
    List<Announcement> all;
    Set<String> read;
    try {
      all = await ref.read(announcementsProvider.future);
      read = await ref.read(readAnnouncementIdsProvider.future);
    } catch (_) {
      return; // 공지를 못 불러와도 앱 사용에는 지장 없게 조용히 넘어감
    }
    final target = all.where((a) => a.isImportant && !read.contains(a.id));
    if (target.isEmpty || !context.mounted) return;
    _shownThisSession = true;
    final a = target.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: SingleChildScrollView(
            child: Text(a.body, style: const TextStyle(fontSize: 17, height: 1.6)),
          ),
        ),
        actions: [
          if (a.hasLink)
            TextButton(
              onPressed: () => openAnnouncementLink(dialogContext, a),
              child: Text(a.linkLabel ?? '자세히 보기'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    // 확인을 누르거나 바깥을 눌러 닫으면 읽음 → 다시 뜨지 않음 (설정 > 공지사항에서 언제든 다시 보기)
    await markAnnouncementRead(ref, a);
  }

  /// 로그아웃 후 다른 계정으로 로그인하면 다시 확인
  static void reset() => _shownThisSession = false;
}
