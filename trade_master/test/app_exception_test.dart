import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trade_clip/services/ai_service.dart';
import 'package:trade_clip/utils/app_exception.dart';

void main() {
  group('AppException.from', () {
    test('DB 오류는 기술 메시지 대신 작업 이름으로 안내', () {
      final e = AppException.from(
        const PostgrestException(
          message: "Could not find the 'balance' column of 'customers'",
          code: 'PGRST204',
        ),
        '거래처 수정',
      );
      expect(e.message, '거래처 수정에 실패했습니다. 잠시 후 다시 시도해주세요.');
      expect(e.message, isNot(contains('balance')));
    });

    test('로그인 오류 코드는 한국어 문구로', () {
      final e = AppException.from(
        const AuthException('Invalid login credentials', code: 'invalid_credentials'),
        '로그인',
      );
      expect(e.message, '이메일 또는 비밀번호가 맞지 않습니다.');
    });

    test('모르는 로그인 오류 코드는 작업 이름으로', () {
      final e = AppException.from(const AuthException('boom', code: 'unknown_code'), '로그인');
      expect(e.message, '로그인에 실패했습니다.');
    });

    test('그 외 오류는 인터넷 연결 안내', () {
      final e = AppException.from(StateError('socket closed'), '거래 목록 조회');
      expect(e.message, contains('인터넷 연결을 확인해주세요'));
    });

    test('이미 AppException이면 그대로', () {
      const original = AppException('거래처명을 입력해주세요');
      expect(identical(AppException.from(original, '거래처 등록'), original), isTrue);
    });
  });

  group('userMessage', () {
    test('AppException·AiException은 문구 그대로', () {
      expect(userMessage(const AppException('저장했습니다')), '저장했습니다');
      expect(userMessage(const AiException('AI 응답 지연')), 'AI 응답 지연');
    });

    test('예상하지 못한 오류는 "Exception:" 같은 기술 표기 없이 일반 문구', () {
      final message = userMessage(Exception('raw technical detail'));
      expect(message, isNot(contains('Exception')));
      expect(message, isNot(contains('raw technical detail')));
    });
  });
}
