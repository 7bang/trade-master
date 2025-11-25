import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

/// 거래처 모델
///
/// 거래하는 상대방 정보를 나타냅니다.
@freezed
class Customer with _$Customer {
  const factory Customer({
    required String id,
    required String businessId,
    required String name,
    String? phone,
    String? memo,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// 조회 시에만 사용 (DB에는 없음)
    @Default(0) double balance,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}
