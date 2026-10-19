import 'package:flutter_test/flutter_test.dart';
import 'package:trade_clip/models/product.dart';
import 'package:trade_clip/models/transaction.dart';
import 'package:trade_clip/widgets/transaction_entry_fields.dart';

final _now = DateTime(2026, 10, 19);
final _product = Product(
  id: 'p1',
  businessId: 'b1',
  name: '광어',
  defaultUnitPrice: 15000,
  unit: 'kg',
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  group('TransactionEntry 금액', () {
    test('직접 입력: 금액 칸 (쉼표 허용)', () {
      final e = TransactionEntry()..amountController.text = '80,000';
      expect(e.amount, 80000);
      expect(e.quantity, isNull);
      expect(e.unitPrice, isNull);
    });

    test('품목 선택: 수량 × 단가, 단가는 품목 기본 단가로 채움', () {
      final e = TransactionEntry()
        ..setProductMode(true)
        ..selectProduct(_product)
        ..quantityController.text = '1.5';
      expect(e.unitPriceController.text, '15000');
      expect(e.amount, 22500);
    });

    test('입력 방식을 바꾸면 반대쪽 값은 비운다', () {
      final e = TransactionEntry()
        ..setProductMode(true)
        ..selectProduct(_product)
        ..quantityController.text = '2';
      e.setProductMode(false);
      expect(e.product, isNull);
      expect(e.quantityController.text, isEmpty);
      expect(e.amount, 0);
    });
  });

  group('TransactionEntry 거래 변환', () {
    test('새 거래: 품목 모드면 품목·수량·단가 포함, 빈 메모는 null', () {
      final e = TransactionEntry()
        ..type = TransactionType.payable
        ..setProductMode(true)
        ..selectProduct(_product)
        ..quantityController.text = '2'
        ..memoController.text = '  ';
      final t = e.toNewTransaction(businessId: 'b1', customerId: 'c1');
      expect(t.type, TransactionType.payable);
      expect(t.productId, 'p1');
      expect(t.quantity, 2);
      expect(t.unitPrice, 15000);
      expect(t.amount, 30000);
      expect(t.memo, isNull);
    });

    test('수정: 불러온 거래를 그대로 다시 저장하면 값이 같다', () {
      final original = Transaction(
        id: 't1',
        businessId: 'b1',
        customerId: 'c1',
        type: TransactionType.receivable,
        productId: 'p1',
        quantity: 3,
        unitPrice: 15000,
        amount: 45000,
        date: _now,
        memo: '오전 납품',
        createdAt: _now,
        updatedAt: _now,
        product: _product,
      );
      final e = TransactionEntry.fromTransaction(original);
      expect(e.useProductMode, isTrue);
      expect(e.quantityController.text, '3');

      final saved = e.applyTo(original);
      expect(saved.id, 't1');
      expect(saved.amount, 45000);
      expect(saved.productId, 'p1');
      expect(saved.memo, '오전 납품');
      expect(saved.createdAt, original.createdAt);
    });

    test('수정: 품목 거래를 직접 입력으로 바꾸면 품목 정보는 지운다', () {
      final original = Transaction(
        id: 't1',
        businessId: 'b1',
        customerId: 'c1',
        type: TransactionType.receivable,
        productId: 'p1',
        quantity: 3,
        unitPrice: 15000,
        amount: 45000,
        date: _now,
        createdAt: _now,
        updatedAt: _now,
      );
      final e = TransactionEntry.fromTransaction(original)
        ..setProductMode(false)
        ..amountController.text = '50000';
      final saved = e.applyTo(original);
      expect(saved.productId, isNull);
      expect(saved.quantity, isNull);
      expect(saved.unitPrice, isNull);
      expect(saved.amount, 50000);
    });
  });
}
