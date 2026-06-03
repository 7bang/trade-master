-- RPC 소유권 검증 강화: SECURITY DEFINER 함수에 auth.uid() 소유 확인 추가

-- 1. get_customer_balance: 호출자가 해당 거래처의 사업장 소유자인지 검증
CREATE OR REPLACE FUNCTION get_customer_balance(p_customer_id UUID)
RETURNS DECIMAL(15, 2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result DECIMAL(15, 2);
BEGIN
  -- 호출자가 이 거래처의 사업장 소유자인지 확인
  IF NOT EXISTS (
    SELECT 1
    FROM customers c
    JOIN businesses b ON b.id = c.business_id
    WHERE c.id = p_customer_id
      AND b.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION '권한이 없습니다';
  END IF;

  SELECT COALESCE(
    SUM(
      CASE
        WHEN type = 'receivable' THEN amount
        WHEN type = 'payable'    THEN -amount
      END
    ),
    0
  )::DECIMAL(15, 2) INTO v_result
  FROM transactions
  WHERE customer_id = p_customer_id
    AND deleted_at IS NULL;

  RETURN v_result;
END;
$$;

-- 2. get_all_balances: 호출자가 해당 사업장의 소유자인지 검증
CREATE OR REPLACE FUNCTION get_all_balances(p_business_id UUID)
RETURNS TABLE(customer_id UUID, balance DECIMAL(15, 2))
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 호출자가 이 사업장의 소유자인지 확인
  IF NOT EXISTS (
    SELECT 1 FROM businesses
    WHERE id = p_business_id
      AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION '권한이 없습니다';
  END IF;

  RETURN QUERY
  SELECT
    c.id AS customer_id,
    COALESCE(
      SUM(
        CASE
          WHEN t.type = 'receivable' THEN t.amount
          WHEN t.type = 'payable'    THEN -t.amount
        END
      ),
      0
    )::DECIMAL(15, 2) AS balance
  FROM customers c
  LEFT JOIN transactions t
    ON t.customer_id = c.id
   AND t.deleted_at IS NULL
  WHERE c.business_id = p_business_id
    AND c.is_active = true
  GROUP BY c.id;
END;
$$;
