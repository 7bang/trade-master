import 'package:flutter_test/flutter_test.dart';
import 'package:trade_clip/utils/formatters.dart';

void main() {
  group('Formatters.formatAmount', () {
    test('천 단위 쉼표 포맷', () {
      expect(Formatters.formatAmount(1234567), '1,234,567');
      expect(Formatters.formatAmount(1000), '1,000');
      expect(Formatters.formatAmount(0), '0');
    });

    test('소수점은 반올림', () {
      expect(Formatters.formatAmount(1234.5), '1,235');
      expect(Formatters.formatAmount(1234.4), '1,234');
    });
  });

  group('Formatters.formatCurrency', () {
    test('원화 단위 포맷', () {
      expect(Formatters.formatCurrency(1234567), '1,234,567원');
      expect(Formatters.formatCurrency(0), '0원');
      expect(Formatters.formatCurrency(500), '500원');
    });
  });

  group('Formatters.formatDate', () {
    test('yyyy-MM-dd 형식', () {
      expect(Formatters.formatDate(DateTime(2024, 11, 15)), '2024-11-15');
      expect(Formatters.formatDate(DateTime(2024, 1, 5)), '2024-01-05');
      expect(Formatters.formatDate(DateTime(2024, 12, 31)), '2024-12-31');
    });
  });

  group('Formatters.formatDateKorean', () {
    test('yyyy년 MM월 dd일 형식', () {
      expect(Formatters.formatDateKorean(DateTime(2024, 11, 15)), '2024년 11월 15일');
      expect(Formatters.formatDateKorean(DateTime(2024, 1, 1)), '2024년 01월 01일');
    });
  });

  group('Formatters.formatDateShort', () {
    test('MM/dd 형식', () {
      expect(Formatters.formatDateShort(DateTime(2024, 11, 15)), '11/15');
      expect(Formatters.formatDateShort(DateTime(2024, 1, 5)), '01/05');
    });
  });

  group('Formatters.formatYearMonth', () {
    test('yyyy년 MM월 형식', () {
      expect(Formatters.formatYearMonth(DateTime(2024, 11, 15)), '2024년 11월');
      expect(Formatters.formatYearMonth(DateTime(2024, 1, 1)), '2024년 01월');
    });
  });

  group('Formatters.formatPhoneNumber', () {
    test('11자리 포맷 (010-xxxx-xxxx)', () {
      expect(Formatters.formatPhoneNumber('01012345678'), '010-1234-5678');
      expect(Formatters.formatPhoneNumber('01098765432'), '010-9876-5432');
    });

    test('10자리 포맷 (0xx-xxx-xxxx)', () {
      expect(Formatters.formatPhoneNumber('0212345678'), '021-234-5678');
    });

    test('기타 자릿수는 원본 반환', () {
      expect(Formatters.formatPhoneNumber('12345'), '12345');
      expect(Formatters.formatPhoneNumber(''), '');
    });
  });

  group('Formatters.formatBalance', () {
    test('양수 — 받을 돈 표기', () {
      expect(Formatters.formatBalance(100000), '받을 돈 100,000원');
      expect(Formatters.formatBalance(1), '받을 돈 1원');
    });

    test('음수 — 줄 돈 표기 (절댓값 사용)', () {
      expect(Formatters.formatBalance(-50000), '줄 돈 50,000원');
      expect(Formatters.formatBalance(-1), '줄 돈 1원');
    });

    test('0 — 정산 완료', () {
      expect(Formatters.formatBalance(0), '정산 완료');
    });
  });

  group('Formatters.formatBalanceType', () {
    test('양수 — (받을 돈)', () {
      expect(Formatters.formatBalanceType(100000), '(받을 돈)');
    });

    test('음수 — (줄 돈)', () {
      expect(Formatters.formatBalanceType(-50000), '(줄 돈)');
    });

    test('0 — (정산 완료)', () {
      expect(Formatters.formatBalanceType(0), '(정산 완료)');
    });
  });
}
