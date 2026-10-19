# 폰거래장 온 - Claude Setup Documentation

## Project Overview
**폰거래장 온** (구 거래클립 → AI거래장인) - 종이 거래장을 폰에 담아 찍고, 저장하고, 공유하는 거래장 앱 (Flutter)
Backend: Supabase (PostgreSQL + Authentication + Edge Functions)
AI: Claude API — Edge Function `ai`를 통해서만 호출 (키는 앱에 포함하지 않음)
타깃: 40대 이상 시장 상인·도매업체 사장님

---

## Brand & Design (필독)

**디자인·UI·문구 작업 전에 반드시 [`BRAND_GUIDE.md`](BRAND_GUIDE.md)를 먼저 읽는다.** (이름, 로고 사용 규칙, 색상 토큰, 글자 크기, 상태 표시 원칙)

| 항목 | 위치 |
|---|---|
| 브랜드 가이드 | `BRAND_GUIDE.md` (루트) |
| 색상 토큰 | `trade_master/lib/config/on_colors.dart` (`OnColors`) — 새 색상 하드코딩 금지 |
| 테마 | `trade_master/lib/config/app_theme.dart` |
| 로고 위젯 | `trade_master/lib/widgets/brand_logo.dart` (`BrandLogo.horizontal / .vertical / .symbol`) |
| 로고·심볼 SVG (앱 번들) | `trade_master/assets/logo/`, `trade_master/assets/symbol/` |
| 앱 아이콘 원본 | `trade_master/assets/png/app-icon-1024.png`, 적응형 전경 `app-icon-adaptive-foreground.png` |
| 파비콘·소셜·마케팅 PNG | `trade_master/assets/favicon/`, `social/`, `png/` (pubspec 미등록 → 앱에 포함 안 됨) |

핵심 규칙 요약:
- 앱 이름 표기: `폰거래장 온` (띄어쓰기 필수)
- 색 비율 한지 60 : 먹남 30 : 인주 10 — 인주(`OnColors.vermilion`)는 저장·확정 버튼과 심볼에만
- 본문 최소 17px, 버튼 높이 56px, 카드·버튼 모서리 14px, 그림자 대신 테두리
- 거래 방향 색: 받을 돈 `OnColors.receivable`(황토), 줄 돈 `OnColors.payable`(남색) — 빨강·초록 사용 금지
- 알림: 완료 `OnColors.success`, 오류·삭제 `OnColors.danger` / 장식용 아이콘·헤더는 `OnColors.ink` (인주 아님)
- 상태는 색 + 기호 + 글자로 표시, 상태 원형은 배경 채움 대신 테두리 + 아이콘색
- 로고 비율 변형·그림자·그라데이션·서체 교체 금지

앱 아이콘 다시 만들기:
```bash
cd trade_master
dart run flutter_launcher_icons   # pubspec.yaml 의 flutter_launcher_icons 설정 사용
cp assets/favicon/favicon-32.png web/favicon.png   # 웹 파비콘은 마이크로 심볼 (생성 후 덮어쓰기)
```

---

## Environment Setup

### 1. Supabase CLI Installation
- **Version**: 2.62.5
- **Installation Status**: ✅ Installed and verified
- **Command**: `supabase --version`

### 2. Project Information
- **Project Name**: trade-master
- **Project Ref**: `eloztkamiaemnscndlqb`
- **Region**: Northeast Asia (Seoul)
- **Supabase URL**: `https://eloztkamiaemnscndlqb.supabase.co`
- **Organization ID**: `ghcsrnnutsahxlvyxzhi`

### 3. API Keys
```env
SUPABASE_URL=https://eloztkamiaemnscndlqb.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVsb3p0a2FtaWFlbW5zY25kbHFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNjkyMTEsImV4cCI6MjA3OTY0NTIxMX0.wX5yii0Cehp5v_6okoQFcQCVEU0Tz-ouOBevrMldBDE
```

---

## Database Setup

### 1. Schema Migration
**Location**: `supabase/migrations/20251125135713_initial_schema.sql`

**Created Tables**:
- `businesses` - 사업장 정보
- `customers` - 거래처 정보
- `products` - 품목 정보
- `transactions` - 거래 내역

**Features**:
- ✅ Row Level Security (RLS) enabled on all tables
- ✅ User-specific data access policies
- ✅ Indexes for performance optimization
- ✅ `get_customer_balance()` RPC function for balance calculation

### 2. Migration Commands
```bash
# Create new migration
supabase migration new <migration_name>

# Push migrations to remote
supabase db push

# Pull remote schema
supabase db pull

# Check migration status
supabase migration list --linked

# View differences
supabase db diff
```

### 3. Applied Migrations
```
20251125135646 - Remote schema
20251125135713 - Initial schema (businesses, customers, products, transactions)
```

---

## Authentication Setup

### 1. Authentication Type
- **Method**: JWT (JSON Web Token) based authentication
- **Provider**: Supabase Auth (Email/Password)

### 2. JWT Configuration
```toml
[auth]
jwt_expiry = 3600                    # Access Token: 1 hour
enable_refresh_token_rotation = true  # Auto refresh enabled
refresh_token_reuse_interval = 10     # 10 seconds
minimum_password_length = 6
enable_signup = true
```

### 3. JWT Token Structure
```json
{
  "iss": "supabase",
  "ref": "eloztkamiaemnscndlqb",
  "role": "authenticated",
  "sub": "user-uuid",
  "email": "user@example.com",
  "exp": 1234567890
}
```

---

## Flutter App Configuration

### 1. Dependencies
**pubspec.yaml**:
```yaml
dependencies:
  supabase_flutter: ^2.5.0      # Supabase client
  flutter_riverpod: ^2.5.0      # State management
  go_router: ^14.0.0            # Routing
  flutter_dotenv: ^5.1.0        # Environment variables
  intl: ^0.19.0                 # Internationalization
  screenshot: ^3.0.0            # Screenshot feature
  share_plus: ^10.0.0           # Share functionality
```

### 2. Environment Variables
**File**: `trade_master/.env`
```env
SUPABASE_URL=https://eloztkamiaemnscndlqb.supabase.co
SUPABASE_ANON_KEY=<anon_key>
```

**Note**: `.env` file is added to `.gitignore` for security

### 3. Supabase Configuration
**File**: `lib/config/supabase_config.dart`
```dart
class SupabaseConfig {
  static const String url = 'https://eloztkamiaemnscndlqb.supabase.co';
  static const String anonKey = '<anon_key>';
}
```

### 4. Supabase Service
**File**: `lib/services/supabase_service.dart`

**Implemented Methods**:
- Authentication: `signUp()`, `signIn()`, `signOut()`, `currentUser`, `authStateChanges`
- Businesses: `getBusiness()`, `createBusiness()`, `updateBusiness()`
- Customers: `getCustomers()`, `getCustomer()`, `createCustomer()`, `updateCustomer()`, `deleteCustomer()`
- Products: `getProducts()`, `getProduct()`, `createProduct()`, `updateProduct()`, `deleteProduct()`
- Transactions: `getTransactions()`, `getTransaction()`, `createTransaction()`, `updateTransaction()`, `deleteTransaction()`
- Balance: `getCustomerBalance()`

---

## AI Features (Edge Function)

### 1. Architecture
- 앱의 `AiService`(`lib/services/ai_service.dart`)가 `Supabase.instance.client.functions.invoke('ai', body: {task, input})` 호출
- Edge Function `supabase/functions/ai/index.ts`가 로그인 사용자 확인 → 입력 검증 → 프롬프트 생성 → Claude 호출
- **Claude API 키는 Edge Function secret `CLAUDE_API_KEY`에만 존재**. 앱 `.env`에 넣지 말 것 (`.env`는 앱 asset으로 번들되어 APK/IPA에서 추출 가능)

### 2. Tasks & Models
| task | 기능 | 모델 |
|------|------|------|
| `parse_text` | 자연어 → 거래 정보 (JSON) | `claude-haiku-5-5` |
| `parse_image` | 영수증/메모 사진 → 거래 정보 (JSON) | `claude-sonnet-5-5` |
| `insights` | 경영 인사이트 (JSON) | `claude-haiku-5-5` |
| `collection_message` | 미수금 독촉 문구 | `claude-haiku-5-5` |

### 3. Deploy
```bash
# secret 등록 (supabase/functions/.env 는 gitignore)
supabase secrets set --env-file supabase/functions/.env

# 함수 배포 (운영 프로젝트에 즉시 반영됨)
supabase functions deploy ai

# 등록된 secret 확인 (값 대신 digest 표시)
supabase secrets list

# 로그 확인 (CLI에는 logs 명령 없음) → 대시보드
# https://supabase.com/dashboard/project/eloztkamiaemnscndlqb/functions/ai/logs
```

---

## Code Conventions (앱)

새 코드도 아래 공용 방식을 쓴다 (2026-10-19 리팩토링, 상세: `todo-refactor.md`).

| 상황 | 쓰는 것 | 위치 |
|---|---|---|
| 서비스에서 실패 | `throw AppException.from(e, '거래처 수정')` | `lib/utils/app_exception.dart` |
| 화면에 오류 문구 | `userMessage(e)` — `e.toString()` 금지 | 〃 |
| 하단 알림 | `context.showSuccess / showError / showInfo` | `lib/utils/snackbars.dart` |
| 데이터 변경 후 새로고침 | `ref.refreshTransactions / refreshCustomers / refreshProducts / refreshBusiness / refreshAll` — `ref.invalidate` 직접 나열 금지 | `lib/providers/data_refresh.dart` |
| DB 저장 | `model.toInsertJson()` / `toUpdateJson()` — `toJson()` 그대로 보내기 금지 | `lib/models/db_columns.dart` |
| 거래 목록 | `transactionPagesProvider(TransactionQuery(...))` 50건씩 + `LoadMoreFooter` | `lib/providers/transaction_pages.dart` |
| 거래 합계·건수 | `getTransactionSummary()` (DB 함수) — 목록을 더하지 말 것 | `lib/services/supabase_service.dart` |
| 거래 입력 칸 | `TransactionEntry` + `TransactionEntryFields` | `lib/widgets/transaction_entry_fields.dart` |

- 테이블 칸을 바꾸면 `db_columns.dart`와 `test/db_columns_test.dart`의 스키마 목록을 함께 수정
- 커밋 전: `flutter analyze` 0건, `flutter test` 통과

---

## Ops Report (라즈베리파이 → 텔레그램)

라즈베리파이가 12시간마다 DB 함수 `stats.trade_report()`의 결과(완성된 리포트 문장)를 텔레그램으로 보낸다.

| 구성 | 위치 |
|---|---|
| 리포트 함수 | `stats.trade_report()` — migration `20261018041002`(최초), `20261019000000`(🤖 AI·🖥 서버 항목 추가) |
| 접속 계정 | DB 로그인 롤 `stats_reader` — `stats` 스키마 사용 + 이 함수 실행 권한만 있음 (비밀번호는 git에 없음) |
| AI 사용 기록 | `public.ai_usage_logs` — `ai` Edge Function이 호출마다 기록 (RLS 정책 없음 = 앱에서 접근 불가) |

- 리포트 항목을 바꿀 때는 새 migration에서 `create or replace function stats.trade_report()` 전체를 다시 정의하고, 끝에 `grant execute ... to stats_reader` 유지
- AI 모델·가격이 바뀌면 함수 안 비용 계산(CASE) 단가도 함께 수정
- 원격 DB에 SQL Editor로 직접 적용하면 migration 기록이 어긋나 `db push`가 막힌다 → 항상 migration 파일 + `supabase db push`

---

## Supabase Dashboard Configuration

### Required Settings

#### 1. Enable Email Authentication
**URL**: `https://supabase.com/dashboard/project/eloztkamiaemnscndlqb/auth/providers`

Steps:
1. Go to Authentication > Providers
2. Enable **Email** provider
3. Set **Confirm email**: OFF (for development) or ON (for production)

#### 2. Configure URL Settings
**URL**: `https://supabase.com/dashboard/project/eloztkamiaemnscndlqb/auth/url-configuration`

Settings:
```
Site URL: http://localhost:3000
Redirect URLs:
  - http://localhost:3000
  - trademaster://login-callback
```

#### 3. View Database Tables
**URL**: `https://supabase.com/dashboard/project/eloztkamiaemnscndlqb/editor`

#### 4. Manage Users
**URL**: `https://supabase.com/dashboard/project/eloztkamiaemnscndlqb/auth/users`

#### 5. SQL Editor
**URL**: `https://supabase.com/dashboard/project/eloztkamiaemnscndlqb/sql/new`

---

## Development Workflow

### Starting Development
```bash
# Navigate to Flutter project
cd trade_master

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Database Changes
```bash
# 1. Create new migration
supabase migration new <name>

# 2. Edit SQL file in supabase/migrations/

# 3. Push to remote
supabase db push

# 4. Verify
supabase migration list --linked
```

### Testing Authentication
```dart
// Sign up
final response = await SupabaseService().signUp(
  'test@example.com',
  'password123'
);

// Sign in
final response = await SupabaseService().signIn(
  'test@example.com',
  'password123'
);

// Check current user
final user = SupabaseService().currentUser;

// Sign out
await SupabaseService().signOut();
```

---

## Security Features

### 1. Row Level Security (RLS)
All tables have RLS enabled with user-specific access policies:

**Example Policy** (businesses table):
```sql
CREATE POLICY "Users can view their own business"
  ON businesses FOR SELECT
  USING (auth.uid() = user_id);
```

### 2. Environment Variables
- API keys stored in `.env` file
- `.env` added to `.gitignore`
- Never commit sensitive credentials

### 3. JWT Token Management
- Automatic token refresh
- Secure token storage by `supabase_flutter`
- 1-hour access token expiry

---

## Project Structure

```
trade-master/
├── database-schema.sql          # Original schema file
├── supabase/
│   ├── config.toml              # Supabase configuration
│   ├── functions/
│   │   ├── .env                 # CLAUDE_API_KEY (gitignored)
│   │   └── ai/index.ts          # Claude AI proxy Edge Function
│   └── migrations/
│       └── 20251125135713_initial_schema.sql
├── trade_master/                # Flutter app
│   ├── .env                     # Environment variables (gitignored)
│   ├── .gitignore
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── config/
│       │   ├── supabase_config.dart
│       │   └── app_theme.dart
│       ├── models/
│       ├── providers/
│       ├── screens/
│       ├── services/
│       │   └── supabase_service.dart
│       ├── utils/
│       └── widgets/
└── claude.md                    # This file
```

---

## Next Steps

### 1. Auto-create Business on Signup
**Option A**: Database Trigger (Recommended)
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.businesses (user_id, name)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

**Option B**: Flutter App Logic
```dart
final authResponse = await SupabaseService().signUp(email, password);
if (authResponse.user != null) {
  await SupabaseService().createBusiness(Business(
    userId: authResponse.user!.id,
    name: businessName,
  ));
}
```

### 2. Enable Email Confirmation
- Update Auth settings in Supabase dashboard
- Configure email templates

### 3. Add Password Reset
```dart
Future<void> resetPassword(String email) async {
  await Supabase.instance.client.auth.resetPasswordForEmail(email);
}
```

### 4. Implement MFA (Multi-Factor Authentication)
- Available on Supabase Pro plan
- Configure TOTP in `supabase/config.toml`

---

## Troubleshooting

### Issue: Migration fails with UTF-8 encoding error
**Solution**: Remove Korean comments from SQL files, use English only

### Issue: Docker not running
**Solution**: `supabase db pull` requires Docker Desktop for local development
**Workaround**: Use `supabase db push` for remote operations (no Docker needed)

### Issue: Authentication not working
**Checklist**:
1. ✅ Email provider enabled in Supabase dashboard
2. ✅ Site URL configured correctly
3. ✅ `.env` file loaded in Flutter app
4. ✅ `Supabase.initialize()` called in `main()`

### Issue: RLS blocking queries
**Debug**:
```sql
-- Check if user is authenticated
SELECT auth.uid();

-- Temporarily disable RLS for testing (NOT for production)
ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;
```

---

## Useful Commands

### Supabase CLI
```bash
# Login
supabase login

# Link project
supabase link --project-ref eloztkamiaemnscndlqb

# Project info
supabase projects list

# Get API keys
supabase projects api-keys --project-ref eloztkamiaemnscndlqb

# Database operations
supabase db push
supabase db pull
supabase db diff
supabase db dump -f schema.sql
supabase migration list --linked

# Status
supabase status --linked
```

### Flutter
```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Build
flutter build apk
flutter build ios

# Clean
flutter clean
```

---

## Resources

- **Supabase Dashboard**: https://supabase.com/dashboard/project/eloztkamiaemnscndlqb
- **Supabase Docs**: https://supabase.com/docs
- **Flutter Supabase Docs**: https://supabase.com/docs/reference/dart
- **Project GitHub**: https://github.com/7bang/trade-master

---

## Changelog

### 2025-11-25
- ✅ Supabase CLI installed and verified (v2.62.5)
- ✅ Project linked to remote Supabase (eloztkamiaemnscndlqb)
- ✅ Database schema migrated to remote
- ✅ Flutter app configured with Supabase
- ✅ Environment variables set up (.env)
- ✅ JWT-based authentication configured
- ✅ RLS policies applied to all tables
- ✅ Supabase service layer implemented

### 2026-06-04
- ✅ P0: 서비스 계층 전체 try-catch 추가 (PostgrestException/AuthException 분리)
- ✅ P0: 다건 거래 atomic batch INSERT (`createTransactionsBatch`)
- ✅ P0: 거래 soft delete 전환 (`deleted_at` 컬럼, 부분 인덱스)
- ✅ P1: `get_all_balances` RPC 신설 — N+1 쿼리 해결
- ✅ P1: 전체 FutureProvider에 `ref.keepAlive()` 캐싱
- ✅ P1: `supabase_config.dart` dotenv 전환, `main.dart` dotenv.load() 추가
- ✅ P1: products.unit 기본값 '개'로 통일 (DB·모델 정합)
- ✅ P2: `common_widgets.dart` 신설 및 6개 화면 일괄 적용
- ✅ P2: `.disabled` 파일 3개 삭제 (~847줄)
- ✅ P2: 다크테마 미사용 코드 제거, `Future.delayed` → `endOfFrame` 교체
- ✅ P3: `formatters_test.dart` 단위 테스트 작성 (8개 그룹 30케이스)
- ✅ P3: RPC 소유권 검증 강화 (migration 20260604000000)
- ✅ P3: 서비스 경계 입력 검증 추가 (amount>0, name 빈값 방지)
- ✅ P3: BalanceAvatar/TransactionTypeAvatar Semantics 라벨 추가

### 2026-10-18
- ✅ 앱 이름 변경: 거래클립 → AI거래장인 (Flutter, Android, iOS)
- ✅ AI 기능 4가지: 자연어 거래 입력, 사진 거래 입력, 경영 인사이트, 미수금 독촉 문구(사업장명·연락처 서명)
- ✅ Edge Function `ai` 신설 — Claude API 키를 서버에만 보관, 로그인 사용자 확인, 입력 제한
- ✅ iOS 카메라·사진 권한 문구 추가, 이미지 형식 자동 감지
- ✅ AI 응답 structured outputs + 앱측 검증, 오류 메시지 한국어화
- ✅ 견적서/납품서 이미지 생성 (AI 미사용, `TradeDocumentWidget`) — 거래처 상세 공유 메뉴에 내역서/견적서/납품서
- ✅ 웹(Chrome)에서 이미지 공유 실패 수정 (`ShareService` 웹은 `XFile.fromData`)
- ✅ Edge Function 배포, Chrome 테스트 완료 / ⏳ Android 실기기 테스트 대기 (`todo-AI.md` 참고)
- ✅ 리브랜딩: AI거래장인 → **폰거래장 온** (`BRAND_GUIDE.md`)
  - 앱 아이콘 교체 (Android 적응형 포함, iOS, 웹 PWA 아이콘·파비콘)
  - 브랜드 테마 (`OnColors`, 한지 배경·인주 버튼·17px 본문·56px 버튼·테두리 카드)
  - 로그인(세로형 로고+태그라인), 회원가입(심볼), 거래처 목록 상단(가로형 로고), 앱 정보(심볼)
  - 영수증·내역서·견적서 하단 표기 변경
  - 화면별 하드코딩 색상 전부 토큰으로 전환 (A안: 받을 돈 황토 / 줄 돈 남색, 그라데이션·그림자 제거, 큰 헤더 먹남)

---

**Last Updated**: 2026-10-18
**Project Status**: Phase 1 완료 (v1.1.0+7 출시), Phase 2 준비 중
