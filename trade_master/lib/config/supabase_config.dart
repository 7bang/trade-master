/// Supabase 프로젝트 설정
///
/// Supabase 대시보드에서 Project URL과 anon public key를 복사하여 사용하세요.
///
/// 설정 방법:
/// 1. https://supabase.com 접속
/// 2. 프로젝트 선택
/// 3. Settings > API 메뉴 이동
/// 4. Project URL과 anon public key 복사
class SupabaseConfig {
  /// Supabase 프로젝트 URL
  ///
  /// 예: 'https://xyzcompany.supabase.co'
  static const String url = 'https://eloztkamiaemnscndlqb.supabase.co';

  /// Supabase anon public key
  ///
  /// 이 키는 클라이언트에서 사용하기 안전합니다.
  /// Row Level Security(RLS)가 데이터를 보호합니다.
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVsb3p0a2FtaWFlbW5zY25kbHFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNjkyMTEsImV4cCI6MjA3OTY0NTIxMX0.wX5yii0Cehp5v_6okoQFcQCVEU0Tz-ouOBevrMldBDE';
}
