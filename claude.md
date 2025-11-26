# Trade Master - Claude Setup Documentation

## Project Overview
**거래의장인** - 소상공인을 위한 거래장 관리 Flutter 앱
Backend: Supabase (PostgreSQL + Authentication)

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

---

**Last Updated**: 2025-11-26
**Project Status**: Initial setup complete, ready for development
