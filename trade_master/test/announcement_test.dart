import 'package:flutter_test/flutter_test.dart';
import 'package:trade_clip/models/announcement.dart';

void main() {
  group('Announcement.fromJson', () {
    test('링크·중요 표시가 있는 공지', () {
      final a = Announcement.fromJson({
        'id': 'a1',
        'title': '1.2.0 업데이트 안내',
        'body': '음성 입력이 추가되었습니다.\n설정에서 확인하세요.',
        'link_url': 'https://example.com/notes',
        'link_label': '자세히 보기',
        'is_important': true,
        'published_at': '2026-10-20T03:00:00+00:00',
      });
      expect(a.title, '1.2.0 업데이트 안내');
      expect(a.body, contains('\n'));
      expect(a.isImportant, isTrue);
      expect(a.hasLink, isTrue);
      expect(a.publishedAt.toUtc(), DateTime.utc(2026, 10, 20, 3));
    });

    test('링크 없음 / https가 아닌 링크는 버튼을 보이지 않음', () {
      final base = {
        'id': 'a2',
        'title': '안내',
        'body': '본문',
        'is_important': false,
        'published_at': '2026-10-20T03:00:00Z',
      };
      expect(Announcement.fromJson({...base, 'link_url': null}).hasLink, isFalse);
      expect(Announcement.fromJson({...base, 'link_url': 'http://x.com'}).hasLink, isFalse);
      expect(Announcement.fromJson({...base, 'link_url': 'javascript:alert(1)'}).hasLink, isFalse);
    });
  });
}
