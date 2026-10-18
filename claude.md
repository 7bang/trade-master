# TradeClip - Claude Setup Documentation

## Project Overview
**AI거래장인** (구 거래클립) - 소상공인을 위한 거래장 관리 Flutter 앱
Backend: Supabase (PostgreSQL + Authentication + Edge Functions)
AI: Claude API — Edge Function `ai`를 통해서만 호출 (키는 앱에 포함하지 않음)

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

---

**Last Updated**: 2026-10-18
**Project Status**: Phase 1 완료 (v1.1.0+7 출시), Phase 2 준비 중
