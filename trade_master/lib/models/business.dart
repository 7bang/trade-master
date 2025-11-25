import 'package:freezed_annotation/freezed_annotation.dart';

part 'business.freezed.dart';
part 'business.g.dart';

/// 사업장 모델
///
/// 사용자의 사업장 정보를 나타냅니다.
@freezed
class Business with _$Business {
  const factory Business({
    required String id,
    required String userId,
    required String name,
    String? phone,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Business;

  factory Business.fromJson(Map<String, dynamic> json) =>
      _$BusinessFromJson(json);
}
