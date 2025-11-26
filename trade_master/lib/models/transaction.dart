import 'package:freezed_annotation/freezed_annotation.dart';
import 'customer.dart';
import 'product.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

/// 거래 유형
enum TransactionType {
  /// 받을 돈 (매출/입금)
  @JsonValue('receivable')
  receivable,

  /// 줄 돈 (매입/출금)
  @JsonValue('payable')
  payable,
}

/// 거래 모델
///
/// 실제 거래 내역을 나타냅니다.
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    @JsonKey(name: 'business_id') required String businessId,
    @JsonKey(name: 'customer_id') required String customerId,
    required TransactionType type,

    /// 품목 정보 (선택사항)
    @JsonKey(name: 'product_id') String? productId,
    double? quantity,
    @JsonKey(name: 'unit_price') double? unitPrice,

    required double amount,
    required DateTime date,
    String? memo,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,

    /// JOIN 데이터 (조회 시에만)
    Customer? customer,
    Product? product,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
