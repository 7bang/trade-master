# 거래클립 (TradeClip)

소상공인을 위한 모바일 거래장 관리 앱

## 프로젝트 소개

거래클립은 소상공인과 유통업체가 거래처와의 거래 내역을 쉽게 기록하고 관리할 수 있는 Flutter 기반 모바일 앱입니다.

### 주요 기능

- ✅ 거래처 관리 (CRUD)
- ✅ 품목 관리 (CRUD)
- ✅ 거래 관리 (생성/조회/수정/삭제)
- ✅ 거래처별 잔액 자동 계산
- ✅ 거래 내역 카카오톡 공유

## 기술 스택

- **Frontend**: Flutter 3.24.0+
- **Language**: Dart 3.5.0+
- **State Management**: Riverpod 2.5.0+
- **Backend**: Supabase (BaaS)
- **Routing**: GoRouter 14.0.0+

## 설치 방법

### 1. Flutter 설치

Flutter 공식 문서를 참고하여 Flutter를 설치하세요:
- https://docs.flutter.dev/get-started/install

### 2. 프로젝트 클론

```bash
git clone <repository-url>
cd trade-master/trade_master
```

### 3. 패키지 설치

```bash
flutter pub get
```

### 4. Supabase 설정

#### 4.1 Supabase 프로젝트 생성

1. https://supabase.com 접속
2. "New Project" 클릭
3. 프로젝트 정보 입력:
   - Name: trade-master
   - Database Password: (안전한 비밀번호 생성)
   - Region: Northeast Asia (Seoul)
4. "Create new project" 클릭

#### 4.2 데이터베이스 스키마 설정

1. Supabase 대시보드에서 SQL Editor 열기
2. 프로젝트 루트의 `database-schema.sql` 파일 내용 복사
3. SQL Editor에 붙여넣기 후 실행

#### 4.3 인증 설정

1. Supabase 대시보드 > Authentication > Providers
2. Email 활성화
3. "Confirm email" 옵션 비활성화 (개발 중에는)

#### 4.4 테스트 사용자 생성

1. Supabase 대시보드 > Authentication > Users
2. "Add user" 클릭
3. 이메일과 비밀번호 입력
4. "Create user" 클릭

#### 4.5 사업장 정보 생성

SQL Editor에서 다음 쿼리 실행 (USER_ID를 생성한 사용자 ID로 대체):

```sql
INSERT INTO businesses (user_id, name, phone)
VALUES ('YOUR_USER_ID', '테스트 가게', '010-1234-5678');
```

### 5. 앱 실행

```bash
flutter run
```

## 프로젝트 구조

```
lib/
├── config/              # 설정 파일
│   ├── supabase_config.dart
│   └── app_theme.dart
├── models/              # 데이터 모델
│   ├── business.dart
│   ├── customer.dart
│   ├── product.dart
│   └── transaction.dart
├── providers/           # Riverpod Providers
│   └── providers.dart
├── screens/             # 화면
│   ├── auth/
│   ├── customer/
│   └── transaction/
├── services/            # 비즈니스 로직
│   ├── supabase_service.dart
│   └── share_service.dart
├── utils/               # 유틸리티
│   ├── formatters.dart
│   └── validators.dart
├── widgets/             # 재사용 위젯
└── main.dart            # 앱 진입점
```

## 개발 상태

### 완료된 기능

- ✅ 프로젝트 구조 설정
- ✅ Supabase 연동
- ✅ 데이터 모델 (Freezed)
- ✅ 서비스 레이어
- ✅ 상태 관리 (Riverpod)
- ✅ 로그인 화면
- ✅ 거래처 목록 화면

### 개발 중인 기능

- 🚧 거래처 등록/수정 화면
- 🚧 품목 관리 화면
- 🚧 거래 입력/수정 화면
- 🚧 거래 내역 카카오톡 공유

### 향후 계획

- 📋 회원가입 화면
- 📋 거래처 상세 화면
- 📋 통계 및 대시보드
- 📋 다크 모드 지원

## 문제 해결

### 빌드 에러가 발생하는 경우

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Supabase 연결 오류

1. `lib/config/supabase_config.dart` 파일의 URL과 anon key 확인
2. Supabase 프로젝트가 활성화되어 있는지 확인
3. 네트워크 연결 상태 확인

### RLS (Row Level Security) 오류

1. Supabase SQL Editor에서 `database-schema.sql` 스크립트를 다시 실행
2. 모든 테이블에 RLS가 활성화되어 있는지 확인
3. 정책(Policy)이 올바르게 생성되었는지 확인

## 라이선스

MIT License

## 문의

프로젝트 관련 문의사항이 있으시면 이슈를 등록해주세요.

---

**참고 문서**:
- [trade-master-PRD.md](../../trade-master-PRD.md) - 제품 요구사항 문서
- [trade-master-tech.md](../../trade-master-tech.md) - 기술 문서
- [database-schema.sql](../../database-schema.sql) - 데이터베이스 스키마
