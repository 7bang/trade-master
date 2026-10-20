/// 공지사항 (관리자 웹페이지에서 작성, 앱은 읽기만)
class Announcement {
  final String id;
  final String title;
  final String body;
  final String? linkUrl;
  final String? linkLabel;

  /// true: 앱을 열 때 아직 안 읽었으면 팝업
  final bool isImportant;
  final DateTime publishedAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.linkUrl,
    this.linkLabel,
    required this.isImportant,
    required this.publishedAt,
  });

  bool get hasLink => linkUrl != null && linkUrl!.startsWith('https://');

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        linkUrl: json['link_url'] as String?,
        linkLabel: json['link_label'] as String?,
        isImportant: json['is_important'] as bool? ?? false,
        publishedAt: DateTime.parse(json['published_at'] as String).toLocal(),
      );
}
