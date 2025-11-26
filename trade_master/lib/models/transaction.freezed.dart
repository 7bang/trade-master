// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Transaction _$TransactionFromJson(Map<String, dynamic> json) {
  return _Transaction.fromJson(json);
}

/// @nodoc
mixin _$Transaction {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'business_id')
  String get businessId => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_id')
  String get customerId => throw _privateConstructorUsedError;
  TransactionType get type => throw _privateConstructorUsedError;

  /// 품목 정보 (선택사항)
  @JsonKey(name: 'product_id')
  String? get productId => throw _privateConstructorUsedError;
  double? get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'unit_price')
  double? get unitPrice => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// JOIN 데이터 (조회 시에만)
  Customer? get customer => throw _privateConstructorUsedError;
  Product? get product => throw _privateConstructorUsedError;

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionCopyWith<Transaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionCopyWith<$Res> {
  factory $TransactionCopyWith(
    Transaction value,
    $Res Function(Transaction) then,
  ) = _$TransactionCopyWithImpl<$Res, Transaction>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'business_id') String businessId,
    @JsonKey(name: 'customer_id') String customerId,
    TransactionType type,
    @JsonKey(name: 'product_id') String? productId,
    double? quantity,
    @JsonKey(name: 'unit_price') double? unitPrice,
    double amount,
    DateTime date,
    String? memo,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime updatedAt,
    Customer? customer,
    Product? product,
  });

  $CustomerCopyWith<$Res>? get customer;
  $ProductCopyWith<$Res>? get product;
}

/// @nodoc
class _$TransactionCopyWithImpl<$Res, $Val extends Transaction>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = null,
    Object? customerId = null,
    Object? type = null,
    Object? productId = freezed,
    Object? quantity = freezed,
    Object? unitPrice = freezed,
    Object? amount = null,
    Object? date = null,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? customer = freezed,
    Object? product = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            businessId: null == businessId
                ? _value.businessId
                : businessId // ignore: cast_nullable_to_non_nullable
                      as String,
            customerId: null == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as TransactionType,
            productId: freezed == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as String?,
            quantity: freezed == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as double?,
            unitPrice: freezed == unitPrice
                ? _value.unitPrice
                : unitPrice // ignore: cast_nullable_to_non_nullable
                      as double?,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            memo: freezed == memo
                ? _value.memo
                : memo // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            customer: freezed == customer
                ? _value.customer
                : customer // ignore: cast_nullable_to_non_nullable
                      as Customer?,
            product: freezed == product
                ? _value.product
                : product // ignore: cast_nullable_to_non_nullable
                      as Product?,
          )
          as $Val,
    );
  }

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CustomerCopyWith<$Res>? get customer {
    if (_value.customer == null) {
      return null;
    }

    return $CustomerCopyWith<$Res>(_value.customer!, (value) {
      return _then(_value.copyWith(customer: value) as $Val);
    });
  }

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProductCopyWith<$Res>? get product {
    if (_value.product == null) {
      return null;
    }

    return $ProductCopyWith<$Res>(_value.product!, (value) {
      return _then(_value.copyWith(product: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TransactionImplCopyWith<$Res>
    implements $TransactionCopyWith<$Res> {
  factory _$$TransactionImplCopyWith(
    _$TransactionImpl value,
    $Res Function(_$TransactionImpl) then,
  ) = __$$TransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'business_id') String businessId,
    @JsonKey(name: 'customer_id') String customerId,
    TransactionType type,
    @JsonKey(name: 'product_id') String? productId,
    double? quantity,
    @JsonKey(name: 'unit_price') double? unitPrice,
    double amount,
    DateTime date,
    String? memo,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime updatedAt,
    Customer? customer,
    Product? product,
  });

  @override
  $CustomerCopyWith<$Res>? get customer;
  @override
  $ProductCopyWith<$Res>? get product;
}

/// @nodoc
class __$$TransactionImplCopyWithImpl<$Res>
    extends _$TransactionCopyWithImpl<$Res, _$TransactionImpl>
    implements _$$TransactionImplCopyWith<$Res> {
  __$$TransactionImplCopyWithImpl(
    _$TransactionImpl _value,
    $Res Function(_$TransactionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = null,
    Object? customerId = null,
    Object? type = null,
    Object? productId = freezed,
    Object? quantity = freezed,
    Object? unitPrice = freezed,
    Object? amount = null,
    Object? date = null,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? customer = freezed,
    Object? product = freezed,
  }) {
    return _then(
      _$TransactionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        businessId: null == businessId
            ? _value.businessId
            : businessId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerId: null == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as TransactionType,
        productId: freezed == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantity: freezed == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as double?,
        unitPrice: freezed == unitPrice
            ? _value.unitPrice
            : unitPrice // ignore: cast_nullable_to_non_nullable
                  as double?,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        memo: freezed == memo
            ? _value.memo
            : memo // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        customer: freezed == customer
            ? _value.customer
            : customer // ignore: cast_nullable_to_non_nullable
                  as Customer?,
        product: freezed == product
            ? _value.product
            : product // ignore: cast_nullable_to_non_nullable
                  as Product?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionImpl implements _Transaction {
  const _$TransactionImpl({
    required this.id,
    @JsonKey(name: 'business_id') required this.businessId,
    @JsonKey(name: 'customer_id') required this.customerId,
    required this.type,
    @JsonKey(name: 'product_id') this.productId,
    this.quantity,
    @JsonKey(name: 'unit_price') this.unitPrice,
    required this.amount,
    required this.date,
    this.memo,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') required this.updatedAt,
    this.customer,
    this.product,
  });

  factory _$TransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'business_id')
  final String businessId;
  @override
  @JsonKey(name: 'customer_id')
  final String customerId;
  @override
  final TransactionType type;

  /// 품목 정보 (선택사항)
  @override
  @JsonKey(name: 'product_id')
  final String? productId;
  @override
  final double? quantity;
  @override
  @JsonKey(name: 'unit_price')
  final double? unitPrice;
  @override
  final double amount;
  @override
  final DateTime date;
  @override
  final String? memo;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  /// JOIN 데이터 (조회 시에만)
  @override
  final Customer? customer;
  @override
  final Product? product;

  @override
  String toString() {
    return 'Transaction(id: $id, businessId: $businessId, customerId: $customerId, type: $type, productId: $productId, quantity: $quantity, unitPrice: $unitPrice, amount: $amount, date: $date, memo: $memo, createdAt: $createdAt, updatedAt: $updatedAt, customer: $customer, product: $product)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.memo, memo) || other.memo == memo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.customer, customer) ||
                other.customer == customer) &&
            (identical(other.product, product) || other.product == product));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    businessId,
    customerId,
    type,
    productId,
    quantity,
    unitPrice,
    amount,
    date,
    memo,
    createdAt,
    updatedAt,
    customer,
    product,
  );

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      __$$TransactionImplCopyWithImpl<_$TransactionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionImplToJson(this);
  }
}

abstract class _Transaction implements Transaction {
  const factory _Transaction({
    required final String id,
    @JsonKey(name: 'business_id') required final String businessId,
    @JsonKey(name: 'customer_id') required final String customerId,
    required final TransactionType type,
    @JsonKey(name: 'product_id') final String? productId,
    final double? quantity,
    @JsonKey(name: 'unit_price') final double? unitPrice,
    required final double amount,
    required final DateTime date,
    final String? memo,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'updated_at') required final DateTime updatedAt,
    final Customer? customer,
    final Product? product,
  }) = _$TransactionImpl;

  factory _Transaction.fromJson(Map<String, dynamic> json) =
      _$TransactionImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'business_id')
  String get businessId;
  @override
  @JsonKey(name: 'customer_id')
  String get customerId;
  @override
  TransactionType get type;

  /// 품목 정보 (선택사항)
  @override
  @JsonKey(name: 'product_id')
  String? get productId;
  @override
  double? get quantity;
  @override
  @JsonKey(name: 'unit_price')
  double? get unitPrice;
  @override
  double get amount;
  @override
  DateTime get date;
  @override
  String? get memo;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// JOIN 데이터 (조회 시에만)
  @override
  Customer? get customer;
  @override
  Product? get product;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
