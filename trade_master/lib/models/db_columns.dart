import 'business.dart';
import 'customer.dart';
import 'product.dart';
import 'transaction.dart';

/// 테이블별로 앱이 저장(insert/update)할 수 있는 칸 — **허용 목록**.
///
/// 모델에는 조회용 칸(Customer.balance, Transaction.customer/product 등)이 섞여 있어
/// `toJson()`을 그대로 보내면 PostgREST가 "없는 칸"이라며 400으로 거부한다.
/// 빼야 할 칸을 지우는 대신 보낼 칸만 고르므로, 모델에 새 칸이 생겨도 안전하다.
/// `id`, `created_at`(DB 기본값), `deleted_at`(삭제 전용)은 여기서 보내지 않는다.
///
/// 테이블에 칸을 추가·삭제하면 여기와 test/db_columns_test.dart의 스키마 목록을 함께 고친다.
class DbColumns {
  static const businesses = {'user_id', 'name', 'phone'};
  static const customers = {'business_id', 'name', 'phone', 'memo', 'is_active'};
  static const products = {
    'business_id', 'name', 'code', 'category', 'default_unit_price', 'unit',
    'description', 'is_active',
  };
  static const transactions = {
    'business_id', 'customer_id', 'type', 'product_id', 'quantity',
    'unit_price', 'amount', 'date', 'memo',
  };

  /// 수정할 때는 수정 시각도 함께 보낸다
  static const updatedAt = 'updated_at';
}

Map<String, dynamic> _pick(Map<String, dynamic> json, Set<String> columns) => {
      for (final column in columns)
        if (json.containsKey(column)) column: json[column],
    };

extension BusinessDb on Business {
  Map<String, dynamic> toInsertJson() => _pick(toJson(), DbColumns.businesses);
  Map<String, dynamic> toUpdateJson() =>
      _pick(toJson(), {...DbColumns.businesses, DbColumns.updatedAt});
}

extension CustomerDb on Customer {
  Map<String, dynamic> toInsertJson() => _pick(toJson(), DbColumns.customers);
  Map<String, dynamic> toUpdateJson() =>
      _pick(toJson(), {...DbColumns.customers, DbColumns.updatedAt});
}

extension ProductDb on Product {
  Map<String, dynamic> toInsertJson() => _pick(toJson(), DbColumns.products);
  Map<String, dynamic> toUpdateJson() =>
      _pick(toJson(), {...DbColumns.products, DbColumns.updatedAt});
}

extension TransactionDb on Transaction {
  Map<String, dynamic> toInsertJson() =>
      _pick(toJson(), DbColumns.transactions);
  Map<String, dynamic> toUpdateJson() =>
      _pick(toJson(), {...DbColumns.transactions, DbColumns.updatedAt});
}
