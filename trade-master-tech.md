# 거래클립 - 통합 기술 문서 📚

> 개발 초보자도 쉽게 따라할 수 있는 완전한 개발 가이드

**문서 버전**: 2.0  
**최종 수정**: 2024-11-15  
**개발 기간**: 6주 (Phase 1 MVP)

---

## 📑 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [기술 스택](#2-기술-스택)
3. [개발 환경 설정](#3-개발-환경-설정)
4. [데이터베이스 설계](#4-데이터베이스-설계)
5. [프로젝트 구조](#5-프로젝트-구조)
6. [핵심 기능 구현](#6-핵심-기능-구현)
7. [카카오톡 공유 기능](#7-카카오톡-공유-기능)
8. [상태 관리](#8-상태-관리)
9. [화면별 구현 가이드](#9-화면별-구현-가이드)
10. [테스트 및 배포](#10-테스트-및-배포)
11. [Phase별 개발 로드맵](#11-phase별-개발-로드맵)
12. [FAQ](#12-자주-묻는-질문)

---

## 1. 프로젝트 개요

### 1.1 프로젝트 소개

**거래클립**은 소상공인과 유통업체가 거래처와의 거래 내역을 쉽게 기록하고 관리할 수 있는 모바일 거래장 앱입니다.

**핵심 가치:**
- 📱 **간편한 거래 입력**: 10초 안에 거래 기록
- 🔍 **실시간 잔액 확인**: 거래처별 자동 계산
- 💬 **카톡 공유**: 예쁜 거래 명세서를 카카오톡으로 즉시 전송

### 1.2 MVP 범위 (Phase 1)

**✅ 포함되는 기능**
- 거래처 관리 (CRUD)
- **품목 관리 (CRUD)** ⭐
- 거래 관리 (CRUD - 생성/조회/수정/삭제)
- 거래처별 잔액 자동 계산
- 거래 내역 카카오톡 공유

**❌ 제외되는 기능 (Phase 2 이후)**
- 다중 사용자 (직원 관리)
- 통계/차트
- PDF 생성
- 알림 기능
- 재고 관리

### 1.3 개발 목표

| 항목 | 목표 |
|------|------|
| 개발 기간 | 6주 |
| 데이터베이스 테이블 | 5개 |
| 주요 화면 | 6개 |
| 핵심 기능 | 카카오톡 공유 |
| 출시 플랫폼 | Android (Play Store) |

---

## 2. 기술 스택

### 2.1 프론트엔드

```yaml
Framework: Flutter 3.24.0+
Language: Dart 3.5.0+
```

**주요 패키지:**

```yaml
dependencies:
  # 백엔드
  supabase_flutter: ^2.5.0
  
  # 상태 관리
  flutter_riverpod: ^2.5.0
  
  # 라우팅
  go_router: ^14.0.0
  
  # 핵심 기능: 공유
  screenshot: ^3.0.0
  share_plus: ^10.0.0
  path_provider: ^2.1.3
  
  # 유틸리티
  intl: ^0.19.0                    # 날짜/금액 포맷
  freezed_annotation: ^2.4.0       # 불변 모델
  json_annotation: ^4.8.0          # JSON 직렬화
  
dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
```

### 2.2 백엔드

**Supabase (BaaS)**
- PostgreSQL 데이터베이스
- Authentication (이메일/비밀번호)
- Row Level Security (RLS)
- REST API & Realtime

### 2.3 기술 선택 이유

| 기술 | 선택 이유 |
|------|-----------|
| **Flutter** | • 하나의 코드로 Android/iOS 동시 개발<br>• 빠른 개발 속도 (Hot Reload)<br>• 아름다운 UI 쉽게 구현 |
| **Supabase** | • 백엔드 서버 구축 불필요<br>• 무료 플랜으로 시작 가능<br>• 자동 API 생성<br>• 실시간 데이터 동기화 |
| **Riverpod** | • Flutter 공식 추천 상태 관리<br>• 타입 안전성<br>• 테스트하기 쉬움 |

---

## 3. 개발 환경 설정

### 3.1 필수 도구 설치

#### Step 1: Flutter 설치

**Windows:**
```bash
# Flutter SDK 다운로드
# https://docs.flutter.dev/get-started/install/windows

# 환경 변수 설정
# Path에 flutter\bin 추가

# 설치 확인
flutter doctor
```

**macOS:**
```bash
# Homebrew로 설치
brew install flutter

# 설치 확인
flutter doctor
```

#### Step 2: 에디터 설정

**VS Code (추천):**
```bash
# VS Code 설치 후 Extensions 설치:
- Flutter
- Dart
- Riverpod Snippets
```

**Android Studio:**
```bash
# Android Studio 설치
# Flutter 플러그인 설치
# Dart 플러그인 설치
```

### 3.2 Supabase 프로젝트 설정

#### Step 1: 프로젝트 생성

```bash
1. https://supabase.com 접속
2. "New Project" 클릭
3. 프로젝트 정보 입력:
   - Name: trade-master
   - Database Password: (안전한 비밀번호 생성)
   - Region: Northeast Asia (Seoul)
4. "Create new project" 클릭
```

#### Step 2: 프로젝트 정보 저장

```bash
프로젝트 설정에서 다음 정보 복사:
- Project URL : https://eloztkamiaemnscndlqb.supabase.co
- anon public key : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVsb3p0a2FtaWFlbW5zY25kbHFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNjkyMTEsImV4cCI6MjA3OTY0NTIxMX0.wX5yii0Cehp5v_6okoQFcQCVEU0Tz-ouOBevrMldBDE
```

**저장할 위치: `lib/config/supabase_config.dart`**
```dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 3.3 Flutter 프로젝트 생성

```bash
# 프로젝트 생성
flutter create trade_master
cd trade_master

# 패키지 설치
flutter pub get

# 실행 확인
flutter run
```

---

## 4. 데이터베이스 설계

### 4.1 전체 ERD

```
users (Supabase Auth)
  |
  | 1:1
  |
businesses (사업장)
  |
  ├─ 1:N ─> customers (거래처)
  |           |
  ├─ 1:N ─> products (품목)
  |           |
  └─ 1:N ────>└─ 1:N ─> transactions (거래)
                         - product_id (선택)
                         - quantity (선택)
                         - unit_price (선택)
```

### 4.2 테이블 설계

#### 📋 businesses (사업장)

**용도**: 사용자의 사업장 정보

```sql
CREATE TABLE businesses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,              -- 가게 이름
  phone VARCHAR(20),                       -- 연락처
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_businesses_user_id ON businesses(user_id);

-- RLS
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only view their own business"
  ON businesses FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can only update their own business"
  ON businesses FOR UPDATE
  USING (auth.uid() = user_id);
```

**예시 데이터:**
```
id: 550e8400-e29b-41d4-a716-446655440000
user_id: auth사용자ID
name: "제주 청과물 가게"
phone: "010-1234-5678"
```

#### 📋 customers (거래처)

**용도**: 거래하는 상대방 정보

```sql
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  name VARCHAR(100) NOT NULL,              -- 거래처 이름
  phone VARCHAR(20),                       -- 거래처 연락처
  memo TEXT,                               -- 메모
  is_active BOOLEAN DEFAULT TRUE,          -- 활성 여부
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_customers_business_id ON customers(business_id);
CREATE INDEX idx_customers_name ON customers(name);
CREATE INDEX idx_customers_is_active ON customers(is_active);

-- RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their business customers"
  ON customers FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage their business customers"
  ON customers FOR ALL
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE user_id = auth.uid()
    )
  );
```

**예시 데이터:**
```
id: 660e8400-e29b-41d4-a716-446655440111
business_id: 550e8400-e29b-41d4-a716-446655440000
name: "서울 청과 도매"
phone: "010-9876-5432"
```

#### 📋 products (품목)

**용도**: 자주 거래하는 품목 등록 및 관리

```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  
  -- 품목 기본 정보
  name VARCHAR(100) NOT NULL,              -- 품목명
  code VARCHAR(50),                        -- 품목 코드 (선택)
  category VARCHAR(50),                    -- 카테고리 (예: 과일, 채소)
  
  -- 가격 정보
  default_unit_price DECIMAL(15, 2),       -- 기본 단가
  unit VARCHAR(20) DEFAULT '개',           -- 단위 (개, kg, box 등)
  
  -- 추가 정보
  description TEXT,                        -- 설명
  
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_products_business_id ON products(business_id);
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_is_active ON products(is_active);

-- 품목 코드는 사업장 내에서 고유
CREATE UNIQUE INDEX idx_products_business_code 
  ON products(business_id, code) 
  WHERE code IS NOT NULL;

-- RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their business products"
  ON products FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage their business products"
  ON products FOR ALL
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE user_id = auth.uid()
    )
  );
```

**예시 데이터:**
```
id: 880e8400-e29b-41d4-a716-446655440333
business_id: 550e8400-e29b-41d4-a716-446655440000
name: "한라봉"
code: "FRUIT-001"
category: "과일"
default_unit_price: 8000.00
unit: "kg"
description: "제주산 한라봉"
```

#### 📋 transactions (거래)

**용도**: 실제 거래 내역

```sql
-- 거래 유형 정의
CREATE TYPE simple_transaction_type AS ENUM (
  'receivable',  -- 받을 돈 (매출/입금)
  'payable'      -- 줄 돈 (매입/출금)
);

CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE NOT NULL,
  
  type simple_transaction_type NOT NULL,   -- 거래 유형
  
  -- 품목 정보 (선택사항)
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  quantity DECIMAL(15, 3),                 -- 수량 (소수점 3자리)
  unit_price DECIMAL(15, 2),               -- 단가
  
  amount DECIMAL(15, 2) NOT NULL,          -- 총 금액
  date DATE NOT NULL DEFAULT CURRENT_DATE, -- 거래 날짜
  memo TEXT,                               -- 메모
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 (조회 속도 향상)
CREATE INDEX idx_transactions_business_id ON transactions(business_id);
CREATE INDEX idx_transactions_customer_id ON transactions(customer_id);
CREATE INDEX idx_transactions_product_id ON transactions(product_id);
CREATE INDEX idx_transactions_date ON transactions(date DESC);
CREATE INDEX idx_transactions_type ON transactions(type);

-- RLS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their business transactions"
  ON transactions FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage their business transactions"
  ON transactions FOR ALL
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE user_id = auth.uid()
    )
  );
```

**거래 입력 방식:**

**방법 1: 품목 선택 (추천)**
```sql
-- "한라봉 10kg을 kg당 8,000원에 판매"
INSERT INTO transactions (
  business_id, customer_id, type,
  product_id, quantity, unit_price, amount
) VALUES (
  '사업장ID', '거래처ID', 'receivable',
  '한라봉ID', 10, 8000, 80000
);
```

**방법 2: 직접 입력**
```sql
-- "기타 거래 50,000원"
INSERT INTO transactions (
  business_id, customer_id, type, amount, memo
) VALUES (
  '사업장ID', '거래처ID', 'receivable', 50000, '기타 물품'
);
```

### 4.3 유용한 함수 (RPC)

#### 거래처별 잔액 계산

```sql
CREATE OR REPLACE FUNCTION get_customer_balance(
  p_customer_id UUID
)
RETURNS DECIMAL(15, 2)
LANGUAGE plpgsql
AS $$
DECLARE
  v_balance DECIMAL(15, 2);
BEGIN
  SELECT 
    SUM(
      CASE 
        WHEN type = 'receivable' THEN amount
        WHEN type = 'payable' THEN -amount
      END
    )
  INTO v_balance
  FROM transactions
  WHERE customer_id = p_customer_id;
  
  RETURN COALESCE(v_balance, 0);
END;
$$;
```

**사용 예시:**
```dart
// Flutter에서 호출
final balance = await supabase
  .rpc('get_customer_balance', params: {'p_customer_id': customerId});
```

---

## 5. 프로젝트 구조

### 5.1 폴더 구조

```
trade_master/
├── lib/
│   ├── main.dart                      # 앱 진입점
│   │
│   ├── config/                        # 설정 파일
│   │   ├── supabase_config.dart
│   │   └── app_theme.dart
│   │
│   ├── models/                        # 데이터 모델
│   │   ├── business.dart
│   │   ├── customer.dart
│   │   ├── product.dart              # 품목 모델
│   │   └── transaction.dart
│   │
│   ├── providers/                     # 상태 관리
│   │   ├── auth_provider.dart
│   │   ├── business_provider.dart
│   │   ├── customer_provider.dart
│   │   ├── product_provider.dart     # 품목 Provider
│   │   └── transaction_provider.dart
│   │
│   ├── screens/                       # 화면
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── customer/
│   │   │   ├── customer_list_screen.dart
│   │   │   ├── customer_detail_screen.dart
│   │   │   └── customer_form_screen.dart
│   │   ├── product/                   # 품목 화면
│   │   │   ├── product_list_screen.dart
│   │   │   └── product_form_screen.dart
│   │   └── transaction/
│   │       ├── transaction_form_screen.dart
│   │       ├── transaction_detail_screen.dart
│   │       └── transaction_edit_screen.dart
│   │
│   ├── widgets/                       # 재사용 위젯
│   │   ├── balance_card.dart
│   │   ├── transaction_list_item.dart
│   │   └── receipt_widget.dart
│   │
│   ├── services/                      # 비즈니스 로직
│   │   ├── supabase_service.dart
│   │   └── share_service.dart         # 공유 기능
│   │
│   └── utils/                         # 유틸리티
│       ├── formatters.dart
│       └── validators.dart
│
├── test/                              # 테스트
├── pubspec.yaml                       # 패키지 설정
└── README.md
```

### 5.2 main.dart 설정

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'config/supabase_config.dart';
import 'config/app_theme.dart';

void main() async {
  // Flutter 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  // 앱 실행
  runApp(
    const ProviderScope(  // Riverpod을 위한 래퍼
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '거래클립',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}

// 라우터 설정
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomerListScreen(),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductListScreen(),
    ),
    // ... 더 많은 라우트
  ],
);
```

---

## 6. 핵심 기능 구현

### 6.1 모델 정의 (Freezed 사용)

#### Customer 모델

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

@freezed
class Customer with _$Customer {
  const factory Customer({
    required String id,
    required String businessId,
    required String name,
    String? phone,
    String? memo,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    
    // 조회 시에만 사용 (DB에는 없음)
    @Default(0) double balance,
  }) = _Customer;
  
  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}
```

#### Product 모델

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String businessId,
    required String name,
    String? code,
    String? category,
    double? defaultUnitPrice,
    @Default('개') String unit,
    String? description,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Product;
  
  factory Product.fromJson(Map<String, dynamic> json) => 
      _$ProductFromJson(json);
}
```

#### Transaction 모델

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType {
  @JsonValue('receivable')
  receivable,  // 받을 돈
  
  @JsonValue('payable')
  payable,     // 줄 돈
}

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String businessId,
    required String customerId,
    required TransactionType type,
    
    // 품목 정보 (선택사항)
    String? productId,
    double? quantity,
    double? unitPrice,
    
    required double amount,
    required DateTime date,
    String? memo,
    required DateTime createdAt,
    required DateTime updatedAt,
    
    // JOIN 데이터 (조회 시에만)
    Customer? customer,
    Product? product,
  }) = _Transaction;
  
  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
```

### 6.2 Supabase 서비스

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // 싱글톤 패턴
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();
  
  // ========== 인증 ==========
  
  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // ========== 거래처 ==========
  
  Future<List<Customer>> getCustomers(String businessId) async {
    final response = await _client
        .from('customers')
        .select()
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('name');
    
    return (response as List)
        .map((json) => Customer.fromJson(json))
        .toList();
  }
  
  Future<Customer> createCustomer(Customer customer) async {
    final response = await _client
        .from('customers')
        .insert(customer.toJson())
        .select()
        .single();
    
    return Customer.fromJson(response);
  }
  
  Future<void> updateCustomer(Customer customer) async {
    await _client
        .from('customers')
        .update(customer.toJson())
        .eq('id', customer.id);
  }
  
  Future<void> deleteCustomer(String customerId) async {
    await _client
        .from('customers')
        .update({'is_active': false})
        .eq('id', customerId);
  }
  
  // ========== 품목 ==========
  
  Future<List<Product>> getProducts(String businessId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('name');
    
    return (response as List)
        .map((json) => Product.fromJson(json))
        .toList();
  }
  
  Future<Product> createProduct(Product product) async {
    final response = await _client
        .from('products')
        .insert(product.toJson())
        .select()
        .single();
    
    return Product.fromJson(response);
  }
  
  Future<void> updateProduct(Product product) async {
    await _client
        .from('products')
        .update(product.toJson())
        .eq('id', product.id);
  }
  
  Future<void> deleteProduct(String productId) async {
    await _client
        .from('products')
        .update({'is_active': false})
        .eq('id', productId);
  }
  
  // ========== 거래 ==========
  
  Future<List<Transaction>> getTransactions({
    required String customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('transactions')
        .select('*, customer:customers(*), product:products(*)')
        .eq('customer_id', customerId)
        .order('date', ascending: false);
    
    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String());
    }
    
    final response = await query;
    
    return (response as List)
        .map((json) => Transaction.fromJson(json))
        .toList();
  }
  
  Future<Transaction> getTransaction(String transactionId) async {
    final response = await _client
        .from('transactions')
        .select('*, customer:customers(*), product:products(*)')
        .eq('id', transactionId)
        .single();
    
    return Transaction.fromJson(response);
  }
  
  Future<Transaction> createTransaction(Transaction transaction) async {
    final response = await _client
        .from('transactions')
        .insert(transaction.toJson())
        .select()
        .single();
    
    return Transaction.fromJson(response);
  }
  
  Future<void> updateTransaction(Transaction transaction) async {
    await _client
        .from('transactions')
        .update(transaction.toJson())
        .eq('id', transaction.id);
  }
  
  Future<void> deleteTransaction(String transactionId) async {
    await _client
        .from('transactions')
        .delete()
        .eq('id', transactionId);
  }
  
  // ========== 잔액 ==========
  
  Future<double> getCustomerBalance(String customerId) async {
    final response = await _client.rpc(
      'get_customer_balance',
      params: {'p_customer_id': customerId},
    );
    
    return (response as num).toDouble();
  }
}
```

---

## 7. 카카오톡 공유 기능

### 7.1 공유 서비스 구현

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ShareService {
  final ScreenshotController _screenshotController = ScreenshotController();
  
  /// 거래 내역을 이미지로 공유
  Future<void> shareTransactionReceipt({
    required String businessName,
    required String businessPhone,
    required String customerName,
    required List<Transaction> transactions,
    required double balance,
  }) async {
    try {
      // 1. 영수증 위젯 생성
      final receiptWidget = _buildReceiptWidget(
        businessName: businessName,
        businessPhone: businessPhone,
        customerName: customerName,
        transactions: transactions,
        balance: balance,
      );
      
      // 2. 위젯을 이미지로 캡처
      final imageBytes = await _screenshotController.captureFromWidget(
        receiptWidget,
        pixelRatio: 3.0,  // 고해상도
        context: null,
      );
      
      // 3. 임시 파일로 저장
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/receipt_$timestamp.png');
      await file.writeAsBytes(imageBytes);
      
      // 4. 공유 시트 열기
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '[$businessName] 거래 명세서\n거래처: $customerName',
        subject: '거래 명세서',
      );
      
    } catch (e) {
      print('공유 실패: $e');
      rethrow;
    }
  }
  
  /// 영수증 위젯 생성
  Widget _buildReceiptWidget({
    required String businessName,
    required String businessPhone,
    required String customerName,
    required List<Transaction> transactions,
    required double balance,
  }) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          const Text(
            '💼 거래 명세서',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // 사업장 정보
          Text(
            businessName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            '📞 $businessPhone',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          
          // 거래처 정보
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '거래처:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // 날짜
          Text(
            '📅 ${DateFormat('yyyy년 MM월').format(DateTime.now())}',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          
          // 구분선
          const Divider(thickness: 2, color: Colors.black54),
          
          // 거래 내역
          ...transactions.map((tx) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MM/dd').format(tx.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          tx.type == TransactionType.receivable 
                              ? '💰 받을 돈' 
                              : '💸 준 돈',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (tx.product != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${tx.product!.name})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                Text(
                  '${tx.type == TransactionType.receivable ? '+' : '-'}'
                  '${_formatAmount(tx.amount)}원',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tx.type == TransactionType.receivable
                        ? const Color(0xFF388E3C)
                        : const Color(0xFFD32F2F),
                  ),
                ),
              ],
            ),
          )),
          
          // 구분선
          const Divider(thickness: 2, color: Colors.black54),
          const SizedBox(height: 8),
          
          // 잔액
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: balance >= 0 
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: balance >= 0
                    ? const Color(0xFFA5D6A7)
                    : const Color(0xFFEF9A9A),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '📊 현재 잔액',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatAmount(balance.abs())}원',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0
                        ? const Color(0xFF388E3C)
                        : const Color(0xFFD32F2F),
                  ),
                ),
                Text(
                  balance >= 0 ? '(받을 돈)' : '(줄 돈)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 푸터
          Text(
            '${DateFormat('yyyy-MM-dd').format(DateTime.now())} 발행',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 금액 포맷 (천 단위 쉼표)
  String _formatAmount(double amount) {
    return NumberFormat('#,###').format(amount.round());
  }
}
```

---

## 8. 상태 관리

### 8.1 Provider 정의

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Supabase 서비스 Provider
final supabaseServiceProvider = Provider((ref) => SupabaseService());

// 현재 사용자 Provider
final currentUserProvider = StreamProvider((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.authStateChanges;
});

// 현재 사업장 Provider
final currentBusinessProvider = FutureProvider<Business>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final user = ref.watch(currentUserProvider).value;
  
  if (user == null) throw Exception('로그인이 필요합니다');
  
  return await service.getBusiness(user.id);
});

// ========== 거래처 ==========

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final business = await ref.watch(currentBusinessProvider.future);
  
  return await service.getCustomers(business.id);
});

final customerProvider = FutureProvider.family<Customer, String>(
  (ref, customerId) async {
    final service = ref.watch(supabaseServiceProvider);
    final customer = await service.getCustomer(customerId);
    
    // 잔액 조회
    final balance = await service.getCustomerBalance(customerId);
    
    return customer.copyWith(balance: balance);
  },
);

// ========== 품목 ==========

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final business = await ref.watch(currentBusinessProvider.future);
  
  return await service.getProducts(business.id);
});

final productProvider = FutureProvider.family<Product, String>(
  (ref, productId) async {
    final service = ref.watch(supabaseServiceProvider);
    return await service.getProduct(productId);
  },
);

// ========== 거래 ==========

final transactionsProvider = FutureProvider.family<List<Transaction>, String>(
  (ref, customerId) async {
    final service = ref.watch(supabaseServiceProvider);
    return await service.getTransactions(customerId: customerId);
  },
);

final transactionProvider = FutureProvider.family<Transaction, String>(
  (ref, transactionId) async {
    final service = ref.watch(supabaseServiceProvider);
    return await service.getTransaction(transactionId);
  },
);
```

---

## 9. 화면별 구현 가이드

### 9.1 로그인 화면

```dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        context.go('/customers');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고
                const Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  '거래클립',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                
                // 이메일 입력
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력하세요';
                    }
                    if (!value.contains('@')) {
                      return '올바른 이메일을 입력하세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // 비밀번호 입력
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력하세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('로그인', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 회원가입 버튼
                TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text('계정이 없으신가요? 회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 9.2 거래처 목록 화면

```dart
class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 거래처'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2),
            onPressed: () => context.go('/products'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '등록된 거래처가 없습니다',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/customers/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('거래처 추가하기'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return CustomerListItem(
                customer: customer,
                onTap: () => context.go('/customers/${customer.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('에러가 발생했습니다: $err'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/customers/new'),
        icon: const Icon(Icons.add),
        label: const Text('거래처 추가'),
      ),
    );
  }
}
```

### 9.3 품목 목록 화면

```dart
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('품목 관리'),
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('등록된 품목이 없습니다'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/products/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('품목 추가하기'),
                  ),
                ],
              ),
            );
          }
          
          // 카테고리별로 그룹화
          final groupedProducts = <String, List<Product>>{};
          for (final product in products) {
            final category = product.category ?? '미분류';
            groupedProducts.putIfAbsent(category, () => []).add(product);
          }
          
          return ListView(
            children: groupedProducts.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  ...entry.value.map((product) => ListTile(
                    leading: const Icon(Icons.inventory_2),
                    title: Text(product.name),
                    subtitle: Text(
                      '${NumberFormat('#,###').format(product.defaultUnitPrice ?? 0)}원/${product.unit}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/products/${product.id}'),
                  )),
                  const Divider(),
                ],
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('에러: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('품목 추가'),
      ),
    );
  }
}
```

### 9.4 거래 입력 화면 (품목 선택 포함)

```dart
class TransactionFormScreen extends ConsumerStatefulWidget {
  final String customerId;
  
  const TransactionFormScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() => 
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _memoController = TextEditingController();
  
  TransactionType _type = TransactionType.receivable;
  DateTime _date = DateTime.now();
  Product? _selectedProduct;
  bool _useProduct = false;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _memoController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('거래 입력')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 거래 유형 선택
            const Text(
              '거래 유형',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.receivable,
                  label: Text('💰 받을 돈'),
                ),
                ButtonSegment(
                  value: TransactionType.payable,
                  label: Text('💸 줄 돈'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() {
                  _type = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // 품목 사용 여부
            SwitchListTile(
              title: const Text('품목으로 입력하기'),
              subtitle: const Text('품목, 수량, 단가를 입력합니다'),
              value: _useProduct,
              onChanged: (value) {
                setState(() {
                  _useProduct = value;
                  if (!value) {
                    _selectedProduct = null;
                    _quantityController.clear();
                    _unitPriceController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            
            // 품목 선택 UI
            if (_useProduct) ...[
              productsAsync.when(
                data: (products) => DropdownButtonFormField<Product>(
                  decoration: const InputDecoration(
                    labelText: '품목',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  value: _selectedProduct,
                  items: products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text('${product.name} (${product.unit})'),
                    );
                  }).toList(),
                  onChanged: (product) {
                    setState(() {
                      _selectedProduct = product;
                      if (product?.defaultUnitPrice != null) {
                        _unitPriceController.text = 
                            product!.defaultUnitPrice.toString();
                        _calculateAmount();
                      }
                    });
                  },
                  validator: (value) {
                    if (_useProduct && value == null) {
                      return '품목을 선택하세요';
                    }
                    return null;
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (err, _) => Text('품목 로드 실패: $err'),
              ),
              const SizedBox(height: 16),
              
              // 수량, 단가 입력
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: '수량',
                        border: const OutlineInputBorder(),
                        suffixText: _selectedProduct?.unit ?? '',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateAmount(),
                      validator: (value) {
                        if (_useProduct && (value == null || value.isEmpty)) {
                          return '수량을 입력하세요';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitPriceController,
                      decoration: const InputDecoration(
                        labelText: '단가',
                        border: OutlineInputBorder(),
                        suffixText: '원',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateAmount(),
                      validator: (value) {
                        if (_useProduct && (value == null || value.isEmpty)) {
                          return '단가를 입력하세요';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 자동 계산된 금액
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '합계',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_amountController.text}원',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 금액 직접 입력
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: '금액',
                  border: OutlineInputBorder(),
                  suffixText: '원',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (!_useProduct && (value == null || value.isEmpty)) {
                    return '금액을 입력하세요';
                  }
                  return null;
                },
                onChanged: (value) {
                  // 천 단위 쉼표 자동 추가
                  final number = value.replaceAll(',', '');
                  if (number.isNotEmpty) {
                    final formatted = NumberFormat('#,###').format(
                      int.tryParse(number) ?? 0,
                    );
                    _amountController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
            
            // 날짜 선택
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('거래 날짜'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _date = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // 메모
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모 (선택사항)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            
            // 저장 버튼
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('저장', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _calculateAmount() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
    final amount = quantity * unitPrice;
    
    _amountController.text = NumberFormat('#,###').format(amount.round());
  }
  
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final service = ref.read(supabaseServiceProvider);
      final business = await ref.read(currentBusinessProvider.future);
      
      final transaction = Transaction(
        id: '',
        businessId: business.id,
        customerId: widget.customerId,
        type: _type,
        productId: _useProduct ? _selectedProduct?.id : null,
        quantity: _useProduct 
            ? double.tryParse(_quantityController.text) 
            : null,
        unitPrice: _useProduct 
            ? double.tryParse(_unitPriceController.text) 
            : null,
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        date: _date,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await service.createTransaction(transaction);
      
      // Provider 갱신
      ref.invalidate(transactionsProvider(widget.customerId));
      ref.invalidate(customerProvider(widget.customerId));
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거래가 등록되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

### 9.5 거래 상세/수정/삭제

**거래 상세 화면:**

```dart
class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;
  
  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionProvider(transactionId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.go('/transactions/$transactionId/edit');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: transactionAsync.when(
        data: (transaction) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 거래 정보 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 거래처
                    _buildInfoRow(
                      Icons.business,
                      '거래처',
                      transaction.customer?.name ?? '알 수 없음',
                    ),
                    const Divider(height: 24),
                    
                    // 거래 유형
                    _buildInfoRow(
                      transaction.type == TransactionType.receivable
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      '거래 유형',
                      transaction.type == TransactionType.receivable
                          ? '💰 받을 돈'
                          : '💸 줄 돈',
                      valueColor: transaction.type == TransactionType.receivable
                          ? Colors.green
                          : Colors.red,
                    ),
                    
                    // 품목 정보 (있을 경우)
                    if (transaction.product != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.inventory_2,
                        '품목',
                        transaction.product!.name,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Column(
                          children: [
                            _buildSubInfoRow(
                              '수량',
                              '${transaction.quantity} ${transaction.product!.unit}',
                            ),
                            const SizedBox(height: 8),
                            _buildSubInfoRow(
                              '단가',
                              '${NumberFormat('#,###').format(transaction.unitPrice)}원',
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const Divider(height: 24),
                    
                    // 금액
                    _buildInfoRow(
                      Icons.attach_money,
                      '금액',
                      '${NumberFormat('#,###').format(transaction.amount)}원',
                      valueFontSize: 20,
                      valueBold: true,
                    ),
                    const Divider(height: 24),
                    
                    // 날짜
                    _buildInfoRow(
                      Icons.calendar_today,
                      '거래 날짜',
                      DateFormat('yyyy-MM-dd').format(transaction.date),
                    ),
                    
                    // 메모 (있을 경우)
                    if (transaction.memo != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.note,
                        '메모',
                        transaction.memo!,
                        multiline: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 수정 버튼
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go('/transactions/$transactionId/edit');
                },
                icon: const Icon(Icons.edit),
                label: const Text('수정', style: TextStyle(fontSize: 18)),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 삭제 버튼
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteDialog(context, ref),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  '삭제',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('에러: $err')),
      ),
    );
  }
  
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    double? valueFontSize,
    bool? valueBold,
    bool multiline = false,
  }) {
    return Row(
      crossAxisAlignment: multiline 
          ? CrossAxisAlignment.start 
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
        if (!multiline) const Spacer(),
        if (!multiline) const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize ?? 16,
              fontWeight: valueBold == true 
                  ? FontWeight.bold 
                  : FontWeight.normal,
              color: valueColor,
            ),
            textAlign: multiline ? TextAlign.start : TextAlign.end,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSubInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
  
  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('거래 삭제'),
        content: const Text(
          '이 거래를 정말 삭제하시겠습니까?\n삭제된 거래는 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      await _deleteTransaction(context, ref);
    }
  }
  
  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(supabaseServiceProvider);
      final transaction = await ref.read(
        transactionProvider(transactionId).future,
      );
      
      await service.deleteTransaction(transactionId);
      
      // Provider 갱신
      ref.invalidate(transactionsProvider(transaction.customerId));
      ref.invalidate(customerProvider(transaction.customerId));
      
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거래가 삭제되었습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }
}
```

---

## 10. 테스트 및 배포

### 10.1 단위 테스트

```dart
// test/services/supabase_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_master/services/supabase_service.dart';

void main() {
  group('SupabaseService', () {
    late SupabaseService service;
    
    setUp(() {
      service = SupabaseService();
    });
    
    test('금액 포맷이 올바르게 동작하는지', () {
      expect(service.formatAmount(1000), '1,000');
      expect(service.formatAmount(1234567), '1,234,567');
    });
    
    // 더 많은 테스트...
  });
}
```

### 10.2 Play Store 출시 준비

#### Step 1: 앱 아이콘 생성

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.0

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

```bash
flutter pub run flutter_launcher_icons
```

#### Step 2: 앱 서명

```bash
# 키스토어 생성
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# android/key.properties 파일 생성
storePassword=<비밀번호>
keyPassword=<비밀번호>
keyAlias=upload
storeFile=<키스토어 경로>
```

#### Step 3: 릴리즈 빌드

```bash
# AAB 파일 생성 (Play Store 권장)
flutter build appbundle --release

# 생성된 파일 위치
# build/app/outputs/bundle/release/app-release.aab
```

#### Step 4: Play Console 업로드

```
1. Google Play Console 접속
2. 앱 만들기
3. 앱 정보 입력:
   - 앱 이름: 거래클립
   - 설명: 거래처 관리를 쉽고 간편하게
   - 카테고리: 비즈니스
4. 스크린샷 업로드 (최소 2개)
5. AAB 파일 업로드
6. 검토 제출
```

---

## 11. Phase별 개발 로드맵

### Phase 1: MVP (6주)

#### Week 1-2: 기본 CRUD
```
✅ 개발 환경 설정
✅ Supabase 프로젝트 생성
✅ 데이터베이스 스키마 구축
✅ 사용자 인증 (로그인/회원가입)
✅ 사업장 정보 입력
✅ 거래처 CRUD
```

#### Week 3: 품목 관리
```
✅ 품목 등록/수정/삭제
✅ 품목 목록 조회
✅ 품목 카테고리 관리
✅ 품목별 기본 단가 설정
```

#### Week 4: 거래 관리
```
✅ 거래 입력 화면 (품목 선택 옵션)
✅ 거래 목록 조회
✅ 거래 수정 기능
✅ 거래 삭제 기능 (확인 다이얼로그)
✅ 거래처별 잔액 계산
```

#### Week 5: 공유 기능 ⭐
```
✅ 영수증 위젯 디자인 (품목 정보 포함)
✅ 스크린샷 캡처 기능
✅ 시스템 공유 시트 연동
✅ 카카오톡 공유 테스트
```

#### Week 6: 테스트 & 출시
```
✅ 버그 수정
✅ UI/UX 개선
✅ 베타 테스트 (지인 5명)
✅ 피드백 반영
✅ Play Store 출시
```

### Phase 2: 기능 확장 (3개월)

```
□ 다중 사용자
  - 직원 초대 기능
  - 역할별 권한 관리
  - 활동 로그

□ 통계 & 분석
  - 월별 매출 차트
  - 거래처별 분석
  - 품목별 판매 통계
  - 엑셀 내보내기

□ 알림 기능
  - 푸시 알림
  - 외상 만기 알림

□ 재고 관리
  - 품목별 재고 추적
  - 재고 부족 알림

□ 공유 기능 강화
  - 50건 이상 시 PDF로 출력 및 공유
  - PDF 생성 기능: 50건 초과 시 PDF로 전체 내역 공유
    - 페이지 자동 분할
    - 인쇄 가능한 형식
    - 더 작은 파일 크기

```

### Phase 3: 프리미엄 기능 (6개월)

```
□ 양방향 거래 확인
  - 거래처 초대
  - 거래 승인/거절
  - 실시간 동기화

□ 고급 분석
  - AI 기반 예측
  - 수익성 분석
  - 트렌드 분석

□ 연동 기능
  - 카카오 알림톡
  - 전자세금계산서
  - 은행 계좌 연동
```

---

## 12. 자주 묻는 질문

### Q1: Flutter를 처음 배우는데 이 프로젝트를 따라할 수 있나요?

**A:** 네! 이 문서는 초보자도 따라할 수 있도록 작성되었습니다. 단계별로 따라하시고, 막히는 부분은 Flutter 공식 문서나 커뮤니티에 질문하세요.

### Q2: Supabase 무료 플랜으로도 충분한가요?

**A:** 네, MVP 단계에서는 무료 플랜으로 충분합니다. 무료 플랜 제한:
- 데이터베이스: 500MB
- 월간 사용자: 50,000명
- 월간 대역폭: 2GB

### Q3: iOS 앱은 언제 출시하나요?

**A:** Phase 1에서는 Android만 출시합니다. Android에서 안정화된 후 iOS로 확장할 예정입니다.

### Q4: 품목 관리는 왜 Phase 1에 포함되었나요?

**A:** 실제 사용자 피드백 결과, 품목별 거래 관리가 핵심 기능으로 판단되어 Phase 1에 포함했습니다. 품목 없이도 사용 가능하지만, 품목을 활용하면 훨씬 효율적입니다.

### Q5: 데이터는 안전한가요?

**A:** 네, Supabase는 AWS 인프라를 사용하며, 모든 데이터는 암호화됩니다. 또한 RLS(Row Level Security)로 내 데이터만 볼 수 있습니다.

---

## 13. 추가 리소스

### 📚 학습 자료

- [Flutter 공식 문서](https://docs.flutter.dev/)
- [Riverpod 공식 문서](https://riverpod.dev/)
- [Supabase 공식 문서](https://supabase.com/docs)
- [Dart 언어 투어](https://dart.dev/guides/language/language-tour)

### 🛠️ 유용한 도구

- [Flutter DevTools](https://docs.flutter.dev/tools/devtools) - 디버깅 도구
- [Postman](https://www.postman.com/) - API 테스트
- [DartPad](https://dartpad.dev/) - 온라인 Dart 연습
- [Figma](https://www.figma.com/) - UI/UX 디자인

### 👥 커뮤니티

- [Flutter 한국 사용자 그룹](https://www.facebook.com/groups/flutterkorea)
- [Flutter Discord](https://discord.gg/flutter)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

---

## 14. 마무리

### 핵심 원칙

1. **간단함이 최고**: MVP는 최소한의 기능으로
2. **사용자 중심**: 실제 사용자의 니즈에 집중
3. **빠른 반복**: 출시 후 피드백으로 개선

### 개발 순서

```
1. 환경 설정 → 2. 데이터베이스 → 3. 인증
→ 4. 거래처 CRUD → 5. 품목 CRUD → 6. 거래 CRUD
→ 7. 공유 기능 → 8. 테스트 → 9. 출시
```

### 성공을 위한 조언

- ✅ 매일 조금씩 꾸준히 개발하기
- ✅ 막히면 공식 문서 먼저 확인하기
- ✅ 커뮤니티에 적극적으로 질문하기
- ✅ 작은 성공을 축하하며 동기부여 유지하기

**화이팅! 🚀**

---

## 문서 정보

- **버전**: 2.0
- **최종 수정**: 2024-11-15
- **주요 변경사항**:
  - Phase 1에 품목 관리 포함
  - 거래 CRUD 완전 구현 (수정/삭제 추가)
  - DB 설계에 products 테이블 추가
  - transactions 테이블에 품목 관련 컬럼 추가
  - 개발 기간 6주로 조정
- **다음 업데이트**: Phase 1 완료 후
