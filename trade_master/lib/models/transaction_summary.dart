/// 거래 합계 (DB 함수 get_transaction_summary 결과)
///
/// 목록은 페이지 단위로 나눠 받으므로 합계·건수·기간은 목록을 더하지 말고 이 값을 쓴다.
class TransactionSummary {
  final double receivableTotal;
  final double payableTotal;
  final int count;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const TransactionSummary({
    required this.receivableTotal,
    required this.payableTotal,
    required this.count,
    this.firstDate,
    this.lastDate,
  });

  /// 받을 돈 − 줄 돈
  double get balance => receivableTotal - payableTotal;

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? v) => v == null ? null : DateTime.parse(v as String);
    return TransactionSummary(
      receivableTotal: (json['receivable_total'] as num).toDouble(),
      payableTotal: (json['payable_total'] as num).toDouble(),
      count: (json['tx_count'] as num).toInt(),
      firstDate: date(json['first_date']),
      lastDate: date(json['last_date']),
    );
  }
}
