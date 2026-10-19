import 'package:flutter_test/flutter_test.dart';
import 'package:trade_clip/models/business.dart';
import 'package:trade_clip/models/customer.dart';
import 'package:trade_clip/models/db_columns.dart';
import 'package:trade_clip/models/product.dart';
import 'package:trade_clip/models/transaction.dart';

/// 원격 DB 스키마 스냅샷 (2026-10-19, information_schema.columns 기준).
/// 테이블 칸이 바뀌면 이 목록과 lib/models/db_columns.dart 를 함께 고친다.
const _schema = {
  'businesses': {'id', 'user_id', 'name', 'phone', 'created_at', 'updated_at'},
  'customers': {
    'id', 'business_id', 'name', 'phone', 'memo', 'is_active', 'created_at', 'updated_at',
  },
  'products': {
    'id', 'business_id', 'name', 'code', 'category', 'default_unit_price', 'unit',
    'description', 'is_active', 'created_at', 'updated_at',
  },
  'transactions': {
    'id', 'business_id', 'customer_id', 'type', 'product_id', 'quantity', 'unit_price',
    'amount', 'date', 'memo', 'created_at', 'updated_at', 'deleted_at',
  },
};

final _now = DateTime(2026, 10, 19, 12);

final _customer = Customer(
  id: 'c1',
  businessId: 'b1',
  name: '라네즈',
  phone: '010-1234-5678',
  memo: '메모',
  createdAt: _now,
  updatedAt: _now,
  balance: 4667000,
);

final _product = Product(
  id: 'p1',
  businessId: 'b1',
  name: '광어',
  createdAt: _now,
  updatedAt: _now,
);

final _transaction = Transaction(
  id: 't1',
  businessId: 'b1',
  customerId: 'c1',
  type: TransactionType.receivable,
  productId: 'p1',
  quantity: 2,
  unitPrice: 15000,
  amount: 30000,
  date: DateTime(2026, 10, 19),
  createdAt: _now,
  updatedAt: _now,
  customer: _customer,
  product: _product,
);

final _business = Business(
  id: 'b1',
  userId: 'u1',
  name: '테스트상회',
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  group('저장 칸 허용 목록은 실제 테이블 칸만 담는다', () {
    test('businesses', () => expect(_schema['businesses']!.containsAll(DbColumns.businesses), isTrue));
    test('customers', () => expect(_schema['customers']!.containsAll(DbColumns.customers), isTrue));
    test('products', () => expect(_schema['products']!.containsAll(DbColumns.products), isTrue));
    test('transactions', () => expect(_schema['transactions']!.containsAll(DbColumns.transactions), isTrue));
  });

  group('보내는 JSON에 테이블에 없는 칸이 없다 (2026-10-19 수정 오류 재발 방지)', () {
    void expectOnlyTableColumns(Map<String, dynamic> json, String table) {
      final extra = json.keys.toSet().difference(_schema[table]!);
      expect(extra, isEmpty, reason: '$table 에 없는 칸: $extra');
    }

    test('거래처: 조회용 잔액(balance)을 보내지 않는다', () {
      expect(_customer.toUpdateJson().containsKey('balance'), isFalse);
      expectOnlyTableColumns(_customer.toInsertJson(), 'customers');
      expectOnlyTableColumns(_customer.toUpdateJson(), 'customers');
    });

    test('거래: 연관 정보(customer, product)를 보내지 않는다', () {
      final update = _transaction.toUpdateJson();
      expect(update.containsKey('customer'), isFalse);
      expect(update.containsKey('product'), isFalse);
      expectOnlyTableColumns(_transaction.toInsertJson(), 'transactions');
      expectOnlyTableColumns(update, 'transactions');
    });

    test('품목·사업장', () {
      expectOnlyTableColumns(_product.toInsertJson(), 'products');
      expectOnlyTableColumns(_product.toUpdateJson(), 'products');
      expectOnlyTableColumns(_business.toInsertJson(), 'businesses');
      expectOnlyTableColumns(_business.toUpdateJson(), 'businesses');
    });
  });

  group('바꾸면 안 되는 칸은 보내지 않는다', () {
    test('id·created_at 은 등록·수정 모두 제외, updated_at 은 수정에만', () {
      for (final json in [_customer.toInsertJson(), _transaction.toInsertJson()]) {
        expect(json.keys, isNot(contains('id')));
        expect(json.keys, isNot(contains('created_at')));
        expect(json.keys, isNot(contains('updated_at')));
      }
      for (final json in [_customer.toUpdateJson(), _transaction.toUpdateJson()]) {
        expect(json.keys, isNot(contains('id')));
        expect(json.keys, isNot(contains('created_at')));
        expect(json.keys, contains('updated_at'));
      }
    });

    test('필요한 칸은 빠짐없이 보낸다', () {
      expect(_customer.toUpdateJson(), containsPair('phone', '010-1234-5678'));
      expect(_customer.toUpdateJson(), containsPair('memo', '메모'));
      expect(_transaction.toInsertJson(), containsPair('type', 'receivable'));
      expect(_transaction.toInsertJson(), containsPair('amount', 30000.0));
    });
  });
}
