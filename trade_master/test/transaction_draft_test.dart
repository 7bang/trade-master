import 'package:flutter_test/flutter_test.dart';
import 'package:trade_clip/models/product.dart';
import 'package:trade_clip/models/transaction.dart';
import 'package:trade_clip/services/ai_service.dart';
import 'package:trade_clip/utils/transaction_draft.dart';

Product _p(String id, String name,
        {double? price, String unit = '개', DateTime? created, bool active = true}) =>
    Product(
      id: id,
      businessId: 'b1',
      name: name,
      defaultUnitPrice: price,
      unit: unit,
      isActive: active,
      createdAt: created ?? DateTime(2026, 1, 1),
      updatedAt: created ?? DateTime(2026, 1, 1),
    );

SpokenTransaction _s({
  String? product,
  double? quantity,
  String? unit,
  double? unitPrice,
  double? amount,
  String type = 'receivable',
  String? memo,
}) =>
    SpokenTransaction(
      type: type,
      date: DateTime(2026, 10, 20),
      productName: product,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      amount: amount,
      memo: memo,
    );

final _flatfish = _p('p1', '광어', price: 18000, unit: 'kg');
final _catalog = [_flatfish, _p('p2', '우럭', price: 15000, unit: 'kg')];

void main() {
  group('3.2 금액 맞추기', () {
    test('수량 + 단가 → 총액 = 수량 × 단가', () {
      final d = TransactionDraft.fromSpoken(
          _s(product: '광어', quantity: 3, unitPrice: 20000), _catalog);
      expect(d.amount, 60000);
      expect(d.unitPrice, 20000);
      expect(d.canSave, isTrue);
    });

    test('수량 + 총액 → 단가 = 총액 ÷ 수량 (요청 예시: 광어 3키로 6만원)', () {
      final d = TransactionDraft.fromSpoken(
          _s(product: '광어', quantity: 3, unit: '키로', amount: 60000), _catalog);
      expect(d.product, _flatfish);
      expect(d.unitPrice, 20000);
      expect(d.quantity, 3);
      expect(d.amount, 60000);
      expect(d.priceMismatch, isFalse);
    });

    test('수량 + 단가 + 총액이 안 맞으면 총액 우선, 단가 재계산, 불일치 표시', () {
      final d = TransactionDraft.fromSpoken(
          _s(product: '광어', quantity: 3, unitPrice: 25000, amount: 60000),
          _catalog);
      expect(d.amount, 60000);
      expect(d.unitPrice, 20000);
      expect(d.priceMismatch, isTrue);
    });

    test('총액만 → 품목 없는 직접 입력 거래', () {
      final d = TransactionDraft.fromSpoken(_s(amount: 50000), _catalog);
      expect(d.usesProduct, isFalse);
      expect(d.amount, 50000);
      expect(d.canSave, isTrue);
    });

    test('수량만 (품목 있음) → 품목 기본 단가로 총액 계산', () {
      final d = TransactionDraft.fromSpoken(
          _s(product: '광어', quantity: 2), _catalog);
      expect(d.unitPrice, 18000);
      expect(d.amount, 36000);
      expect(d.unitPriceDiffersFromDefault, isFalse);
    });

    test('품목 이름은 있지만 수량이 없으면 총액만 거래, 품목명은 메모로 보존', () {
      final d = TransactionDraft.fromSpoken(
          _s(product: '광어', amount: 60000, memo: '오전 배송'), _catalog);
      expect(d.usesProduct, isFalse);
      expect(d.amount, 60000);
      expect(d.memo, '광어 · 오전 배송');
    });
  });

  group('금액을 못 알아들음 → 오류 대신 확인 필요', () {
    test('아무 금액도 없으면 총액 확인 필요, 저장 불가', () {
      final d = TransactionDraft.fromSpoken(_s(), _catalog);
      expect(d.amountMissing, isTrue);
      expect(d.canSave, isFalse);
    });

    test('새 품목 + 수량만 (기본 단가 없음) → 단가·총액 확인 필요', () {
      final d = TransactionDraft.fromSpoken(
          _s(product: '도미', quantity: 2, unit: '키로'), _catalog);
      expect(d.isNewProduct, isTrue);
      expect(d.unitPriceMissing, isTrue);
      expect(d.amountMissing, isTrue);
      expect(d.canSave, isFalse);
      d.setUnitPrice(30000);
      expect(d.amount, 60000);
      expect(d.canSave, isTrue);
    });
  });

  group('3.3 품목 고르기 / 3.4 후보 정렬', () {
    test('같은 이름 (띄어쓰기·대소문자 무시)', () {
      final list = [_p('a', '광 어', price: 1000)];
      expect(matchProducts('광어', list).single.id, 'a');
    });

    test('같은 이름이 없으면 포함된 이름 ("광어" ↔ "광어(대)")', () {
      final list = [_p('a', '광어(대)', price: 25000), _p('b', '우럭')];
      expect(matchProducts('광어', list).single.id, 'a');
      expect(matchProducts('광어 큰거', [_flatfish]).single, _flatfish);
    });

    test('같은 이름이 있으면 포함 이름 후보는 섞지 않음', () {
      final list = [_p('a', '광어', price: 1000), _p('b', '광어(대)', price: 9000)];
      expect(matchProducts('광어', list).map((p) => p.id), ['a']);
    });

    test('후보가 여럿이면 기본 단가 높은 것 → 같으면 최근 등록', () {
      final list = [
        _p('old-cheap', '광어', price: 15000, created: DateTime(2026, 1, 1)),
        _p('old-high', '광어', price: 20000, created: DateTime(2026, 1, 1)),
        _p('new-high', '광어', price: 20000, created: DateTime(2026, 9, 1)),
        _p('no-price', '광어', created: DateTime(2026, 10, 1)),
      ];
      expect(matchProducts('광어', list).map((p) => p.id),
          ['new-high', 'old-high', 'old-cheap', 'no-price']);
      final d = TransactionDraft.fromSpoken(_s(product: '광어', quantity: 1), list);
      expect(d.product!.id, 'new-high');
      expect(d.candidates.length, 4);
    });

    test('비활성 품목은 고르지 않음', () {
      final list = [_p('x', '광어', active: false)];
      expect(matchProducts('광어', list), isEmpty);
    });

    test('없으면 새 품목, 말한 단위 사용', () {
      final d = TransactionDraft.fromSpoken(
          _s(product: '도미', quantity: 2, unit: '킬로', amount: 50000), _catalog);
      expect(d.isNewProduct, isTrue);
      expect(d.productName, '도미');
      expect(d.unit, 'kg');
      expect(d.unitPrice, 25000);
    });
  });

  group('3.4 말한 단가가 기본 단가와 다르면 표시만', () {
    test('말한 단가 사용 + 기본 단가와 다름 표시, 기본 단가는 그대로', () {
      final d = TransactionDraft.fromSpoken(
          _s(product: '광어', quantity: 3, amount: 60000), _catalog);
      expect(d.unitPrice, 20000);
      expect(d.defaultUnitPrice, 18000);
      expect(d.unitPriceDiffersFromDefault, isTrue);
      expect(_flatfish.defaultUnitPrice, 18000);
    });
  });

  group('결과 카드에서 고치기', () {
    TransactionDraft draft() => TransactionDraft.fromSpoken(
        _s(product: '광어', quantity: 3, amount: 60000), _catalog);

    test('수량을 고치면 총액 재계산', () {
      final d = draft()..setQuantity(4);
      expect(d.amount, 80000);
    });

    test('총액을 고치면 단가 재계산', () {
      final d = draft()..setAmount(75000);
      expect(d.unitPrice, 25000);
    });

    test('다른 후보 품목으로 바꾸기 / 새 품목 / 품목 빼기', () {
      final d = draft();
      final rockfish = _catalog[1];
      d.selectProduct(rockfish);
      expect(d.product, rockfish);
      expect(d.unitPrice, 20000, reason: '이미 정해진 단가는 유지');

      d.useNewProduct('도미', unit: '키로');
      expect(d.isNewProduct, isTrue);
      expect(d.unit, 'kg');

      d.clearProduct();
      expect(d.usesProduct, isFalse);
      expect(d.amount, 60000);
      expect(d.canSave, isTrue);
    });
  });

  group('저장할 거래', () {
    test('등록 품목 거래', () {
      final d = TransactionDraft.fromSpoken(
          _s(product: '광어', quantity: 3, amount: 60000, type: 'payable'), _catalog);
      final t = d.toTransaction(businessId: 'b1', customerId: 'c1');
      expect(t.type, TransactionType.payable);
      expect(t.productId, 'p1');
      expect(t.quantity, 3);
      expect(t.unitPrice, 20000);
      expect(t.amount, 60000);
      expect(t.date, DateTime(2026, 10, 20));
    });

    test('새 품목은 저장 직전에 만든 id를 받음', () {
      final d = TransactionDraft.fromSpoken(
          _s(product: '도미', quantity: 2, amount: 50000), _catalog);
      final t = d.toTransaction(businessId: 'b1', customerId: 'c1', productId: 'new-id');
      expect(t.productId, 'new-id');
    });

    test('직접 입력 거래는 품목·수량·단가 없음', () {
      final t = TransactionDraft.fromSpoken(_s(amount: 50000), _catalog)
          .toTransaction(businessId: 'b1', customerId: 'c1');
      expect(t.productId, isNull);
      expect(t.quantity, isNull);
      expect(t.unitPrice, isNull);
    });
  });

  group('단위 정리', () {
    test('키로·킬로·키로그램 → kg, 그 외는 그대로', () {
      for (final u in ['키로', '킬로', '키로그램', 'KG', ' kg ']) {
        expect(normalizeUnit(u), 'kg', reason: u);
      }
      expect(normalizeUnit('박스'), '박스');
      expect(normalizeUnit(''), isNull);
      expect(normalizeUnit(null), isNull);
    });
  });

  group('SpokenTransaction.fromAiJson', () {
    test('못 알아들은 항목(null, 0)은 null', () {
      final s = SpokenTransaction.fromAiJson({
        'type': 'payable',
        'date': '2026-10-19',
        'productName': '광어',
        'quantity': 3,
        'unit': '키로',
        'unitPrice': null,
        'amount': 0,
        'memo': '',
      });
      expect(s.type, 'payable');
      expect(s.quantity, 3);
      expect(s.unitPrice, isNull);
      expect(s.amount, isNull);
      expect(s.memo, isNull);
    });
  });
}
