// 폰거래장 온 관리자 페이지 설정
// anon 키는 앱에도 들어가는 공개용 값이다. 데이터는 DB의 admin_* 함수가
// 관리자(public.admins)인지 확인한 뒤에만 돌려준다. service role 키는 절대 넣지 말 것.
window.ADMIN_CONFIG = {
  supabaseUrl: 'https://eloztkamiaemnscndlqb.supabase.co',
  supabaseAnonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVsb3p0a2FtaWFlbW5zY25kbHFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNjkyMTEsImV4cCI6MjA3OTY0NTIxMX0.wX5yii0Cehp5v_6okoQFcQCVEU0Tz-ouOBevrMldBDE',
};
