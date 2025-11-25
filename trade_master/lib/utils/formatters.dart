import 'package:intl/intl.dart';

/// 날짜 및 금액 포맷 유틸리티
class Formatters {
  /// 금액을 천 단위 쉼표 형식으로 포맷
  ///
  /// 예: 1234567 -> "1,234,567"
  static String formatAmount(num amount) {
    return NumberFormat('#,###').format(amount.round());
  }

  /// 금액을 원화 형식으로 포맷
  ///
  /// 예: 1234567 -> "1,234,567원"
  static String formatCurrency(num amount) {
    return '${formatAmount(amount)}원';
  }

  /// 날짜를 yyyy-MM-dd 형식으로 포맷
  ///
  /// 예: 2024-11-15
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 날짜를 yyyy년 MM월 dd일 형식으로 포맷
  ///
  /// 예: 2024년 11월 15일
  static String formatDateKorean(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일').format(date);
  }

  /// 날짜를 MM/dd 형식으로 포맷
  ///
  /// 예: 11/15
  static String formatDateShort(DateTime date) {
    return DateFormat('MM/dd').format(date);
  }

  /// 날짜를 yyyy년 MM월 형식으로 포맷
  ///
  /// 예: 2024년 11월
  static String formatYearMonth(DateTime date) {
    return DateFormat('yyyy년 MM월').format(date);
  }

  /// DateTime을 시간 포함 형식으로 포맷
  ///
  /// 예: 2024-11-15 14:30
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  /// 전화번호 포맷
  ///
  /// 예: 01012345678 -> 010-1234-5678
  static String formatPhoneNumber(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6)}';
    } else if (phone.length == 11) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
    }
    return phone;
  }

  /// 잔액 표시 (양수면 "받을 돈", 음수면 "줄 돈")
  ///
  /// 예: 100000 -> "받을 돈 100,000원"
  /// 예: -50000 -> "줄 돈 50,000원"
  static String formatBalance(double balance) {
    if (balance > 0) {
      return '받을 돈 ${formatCurrency(balance)}';
    } else if (balance < 0) {
      return '줄 돈 ${formatCurrency(balance.abs())}';
    } else {
      return '정산 완료';
    }
  }

  /// 잔액 타입 반환
  ///
  /// 예: 100000 -> "(받을 돈)"
  /// 예: -50000 -> "(줄 돈)"
  static String formatBalanceType(double balance) {
    if (balance > 0) {
      return '(받을 돈)';
    } else if (balance < 0) {
      return '(줄 돈)';
    } else {
      return '(정산 완료)';
    }
  }
}
