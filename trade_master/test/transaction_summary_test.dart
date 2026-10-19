import 'package:flutter_test/flutter_test.dart';
import 'package:trade_clip/models/transaction_summary.dart';
import 'package:trade_clip/providers/providers.dart';
import 'package:trade_clip/providers/transaction_pages.dart';

void main() {
  group('TransactionSummary.fromJson (get_transaction_summary 결과)', () {
    test('합계·건수·기간과 잔액', () {
      final s = TransactionSummary.fromJson({
        'receivable_total': 50560000,
        'payable_total': 45893000.0,
        'tx_count': 196,
        'first_date': '2026-03-18',
        'last_date': '2026-07-29',
      });
      expect(s.receivableTotal, 50560000);
      expect(s.payableTotal, 45893000);
      expect(s.count, 196);
      expect(s.balance, 4667000);
      expect(s.firstDate, DateTime(2026, 3, 18));
      expect(s.lastDate, DateTime(2026, 7, 29));
    });

    test('거래가 없으면 기간은 null', () {
      final s = TransactionSummary.fromJson({
        'receivable_total': 0,
        'payable_total': 0,
        'tx_count': 0,
        'first_date': null,
        'last_date': null,
      });
      expect(s.count, 0);
      expect(s.firstDate, isNull);
      expect(s.balance, 0);
    });
  });

  group('StatementData.isLimited', () {
    const summary = TransactionSummary(receivableTotal: 0, payableTotal: 0, count: 120);

    test('전체 건수가 담긴 건수보다 많으면 제한 안내', () {
      const data = StatementData(recent: [], summary: summary);
      expect(data.isLimited, isTrue);
    });

    test('전부 담겼으면 안내 없음', () {
      const data = StatementData(
        recent: [],
        summary: TransactionSummary(receivableTotal: 0, payableTotal: 0, count: 0),
      );
      expect(data.isLimited, isFalse);
    });
  });

  group('TransactionQuery', () {
    test('같은 조건이면 같은 목록(Provider)을 쓴다', () {
      final a = TransactionQuery(customerId: 'c1', startDate: DateTime(2026, 10, 1));
      final b = TransactionQuery(customerId: 'c1', startDate: DateTime(2026, 10, 1));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('조건이 다르면 다른 목록', () {
      expect(const TransactionQuery(customerId: 'c1'), isNot(const TransactionQuery(customerId: 'c2')));
      expect(const TransactionQuery(), isNot(const TransactionQuery(customerId: 'c1')));
    });
  });
}
