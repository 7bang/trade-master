import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service.dart' show AiException;

/// 사용자에게 그대로 보여줄 수 있는 오류.
///
/// 서비스 계층은 모든 실패를 이 타입으로 바꿔 던지고, 화면은 [userMessage]로 문구를 얻는다.
/// 기술적인 원인(PostgrestException 등)은 [cause]에 남기고 화면에는 노출하지 않는다.
class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, [this.cause]);

  /// 서비스 호출 실패를 사용자용 문구로 변환. [action] 예: '거래처 수정'
  factory AppException.from(Object error, String action) {
    if (error is AppException) return error;
    debugPrint('[$action] $error');

    if (error is AuthException) {
      return AppException(_authMessage(error) ?? '$action에 실패했습니다.', error);
    }
    if (error is PostgrestException) {
      return AppException('$action에 실패했습니다. 잠시 후 다시 시도해주세요.', error);
    }
    // 그 외는 대부분 네트워크 오류 (연결 끊김, 시간 초과)
    return AppException('$action 중 연결에 문제가 생겼습니다. 인터넷 연결을 확인해주세요.', error);
  }

  static String? _authMessage(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return '이메일 또는 비밀번호가 맞지 않습니다.';
      case 'email_not_confirmed':
        return '이메일 인증이 아직 완료되지 않았습니다. 메일함을 확인해주세요.';
      case 'user_already_exists':
      case 'email_exists':
        return '이미 가입된 이메일입니다.';
      case 'weak_password':
        return '비밀번호가 너무 쉽습니다. 6자 이상으로 입력해주세요.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
    }
    return null;
  }

  @override
  String toString() => message;
}

/// 어떤 오류든 화면에 보여줄 한국어 문구로 변환
String userMessage(Object error) {
  if (error is AppException) return error.message;
  if (error is AiException) return error.message;
  debugPrint('unexpected error: $error');
  return '문제가 생겼습니다. 잠시 후 다시 시도해주세요.';
}
