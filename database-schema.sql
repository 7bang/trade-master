-- ====================================
-- 거래의장인 데이터베이스 스키마
-- ====================================
-- Supabase SQL Editor에서 이 스크립트를 실행하세요
-- https://supabase.com > SQL Editor

-- ====================================
-- 1. businesses (사업장) 테이블
-- ====================================

CREATE TABLE IF NOT EXISTS businesses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_businesses_user_id ON businesses(user_id);

-- RLS 활성화
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;

-- RLS 정책
DROP POLICY IF EXISTS "Users can view their own business" ON businesses;
CREATE POLICY "Users can view their own business"
  ON businesses FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own business" ON businesses;
CREATE POLICY "Users can insert their own business"
  ON businesses FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own business" ON businesses;
CREATE POLICY "Users can update their own business"
  ON businesses FOR UPDATE
  USING (auth.uid() = user_id);

-- ====================================
-- 2. customers (거래처) 테이블
-- ====================================

CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  memo TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_customers_business_id ON customers(business_id);
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);
CREATE INDEX IF NOT EXISTS idx_customers_is_active ON customers(is_active);

-- RLS 활성화
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- RLS 정책
DROP POLICY IF EXISTS "Users can view their business customers" ON customers;
CREATE POLICY "Users can view their business customers"
  ON customers FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can manage their business customers" ON customers;
CREATE POLICY "Users can manage their business customers"
  ON customers FOR ALL
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE user_id = auth.uid()
    )
  );

-- ====================================
-- 3. products (품목) 테이블
-- ====================================

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,

  -- 품목 기본 정보
  name VARCHAR(100) NOT NULL,
  code VARCHAR(50),
  category VARCHAR(50),

  -- 가격 정보
  default_unit_price DECIMAL(15, 2),
  unit VARCHAR(20) DEFAULT '개',

  -- 추가 정보
  description TEXT,

  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_products_business_id ON products(business_id);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON products(is_active);

-- 품목 코드는 사업장 내에서 고유
CREATE UNIQUE INDEX IF NOT EXISTS idx_products_business_code
  ON products(business_id, code)
  WHERE code IS NOT NULL;

-- RLS 활성화
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- RLS 정책
DROP POLICY IF EXISTS "Users can view their business products" ON products;
CREATE POLICY "Users can view their business products"
  ON products FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can manage their business products" ON products;
CREATE POLICY "Users can manage their business products"
  ON products FOR ALL
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE user_id = auth.uid()
    )
  );

-- ====================================
-- 4. transactions (거래) 테이블
-- ====================================

-- 거래 유형 ENUM 생성
DO $$ BEGIN
  CREATE TYPE simple_transaction_type AS ENUM ('receivable', 'payable');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE NOT NULL,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE NOT NULL,

  type simple_transaction_type NOT NULL,

  -- 품목 정보 (선택사항)
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  quantity DECIMAL(15, 3),
  unit_price DECIMAL(15, 2),

  amount DECIMAL(15, 2) NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  memo TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_transactions_business_id ON transactions(business_id);
CREATE INDEX IF NOT EXISTS idx_transactions_customer_id ON transactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_product_id ON transactions(product_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);

-- RLS 활성화
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- RLS 정책
DROP POLICY IF EXISTS "Users can view their business transactions" ON transactions;
CREATE POLICY "Users can view their business transactions"
  ON transactions FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can manage their business transactions" ON transactions;
CREATE POLICY "Users can manage their business transactions"
  ON transactions FOR ALL
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE user_id = auth.uid()
    )
  );

-- ====================================
-- 5. RPC 함수: 거래처별 잔액 계산
-- ====================================

CREATE OR REPLACE FUNCTION get_customer_balance(
  p_customer_id UUID
)
RETURNS DECIMAL(15, 2)
LANGUAGE plpgsql
SECURITY DEFINER
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

-- ====================================
-- 완료!
-- ====================================

-- 스키마 생성이 완료되었습니다.
--
-- 다음 단계:
-- 1. Supabase Authentication에서 이메일/비밀번호 인증 활성화
-- 2. 테스트 사용자 생성
-- 3. Flutter 앱 실행
