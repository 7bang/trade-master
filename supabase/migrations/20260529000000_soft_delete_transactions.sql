-- transactions 테이블에 soft delete 지원을 위한 deleted_at 컬럼 추가

ALTER TABLE transactions ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

-- 활성 거래 조회 성능을 위한 부분 인덱스
CREATE INDEX IF NOT EXISTS idx_transactions_active
  ON transactions(customer_id, date DESC)
  WHERE deleted_at IS NULL;

-- get_customer_balance: 삭제된 거래는 잔액 계산에서 제외
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
  WHERE customer_id = p_customer_id
    AND deleted_at IS NULL;

  RETURN COALESCE(v_balance, 0);
END;
$$;
