/// 입력 값 검증 유틸리티
class Validators {
  /// 이메일 유효성 검증
  ///
  /// Returns: 에러 메시지 또는 null (유효한 경우)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력하세요';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다';
    }

    return null;
  }

  /// 비밀번호 유효성 검증
  ///
  /// Returns: 에러 메시지 또는 null (유효한 경우)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력하세요';
    }

    if (value.length < 6) {
      return '비밀번호는 6자 이상이어야 합니다';
    }

    return null;
  }

  /// 필수 입력 검증
  ///
  /// Returns: 에러 메시지 또는 null (유효한 경우)
  static String? validateRequired(String? value, {String fieldName = '필드'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName을(를) 입력하세요';
    }
    return null;
  }

  /// 전화번호 유효성 검증
  ///
  /// Returns: 에러 메시지 또는 null (유효한 경우)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 선택사항
    }

    final phoneRegex = RegExp(r'^010-?\d{4}-?\d{4}$');

    if (!phoneRegex.hasMatch(value.replaceAll('-', ''))) {
      return '올바른 전화번호 형식이 아닙니다 (예: 010-1234-5678)';
    }

    return null;
  }

  /// 금액 유효성 검증
  ///
  /// Returns: 에러 메시지 또는 null (유효한 경우)
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return '금액을 입력하세요';
    }

    final numValue = double.tryParse(value.replaceAll(',', ''));

    if (numValue == null) {
      return '올바른 금액을 입력하세요';
    }

    if (numValue <= 0) {
      return '금액은 0보다 커야 합니다';
    }

    return null;
  }

  /// 수량 유효성 검증
  ///
  /// Returns: 에러 메시지 또는 null (유효한 경우)
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return '수량을 입력하세요';
    }

    final numValue = double.tryParse(value);

    if (numValue == null) {
      return '올바른 수량을 입력하세요';
    }

    if (numValue <= 0) {
      return '수량은 0보다 커야 합니다';
    }

    return null;
  }

  /// 가격 유효성 검증
  ///
  /// Returns: 에러 메시지 또는 null (유효한 경우)
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 선택사항
    }

    final numValue = double.tryParse(value.replaceAll(',', ''));

    if (numValue == null) {
      return '올바른 가격을 입력하세요';
    }

    if (numValue < 0) {
      return '가격은 0 이상이어야 합니다';
    }

    return null;
  }

  /// 이름 길이 검증
  ///
  /// Returns: 에러 메시지 또는 null (유효한 경우)
  static String? validateName(String? value, {int maxLength = 100}) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력하세요';
    }

    if (value.length > maxLength) {
      return '이름은 $maxLength자 이하로 입력하세요';
    }

    return null;
  }

  /// 비밀번호 확인 검증
  ///
  /// Returns: 에러 메시지 또는 null (유효한 경우)
  static String? validatePasswordConfirm(
    String? value,
    String? password,
  ) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력하세요';
    }

    if (value != password) {
      return '비밀번호가 일치하지 않습니다';
    }

    return null;
  }
}
