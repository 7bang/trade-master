-- 1. get_all_balances: 거래처 잔액을 단일 JOIN 쿼리로 일괄 조회 (N+1 해결)
CREATE OR REPLACE FUNCTION get_all_balances(p_business_id UUID)
RETURNS TABLE(customer_id UUID, balance DECIMAL(15, 2))
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
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

-- 2. products.unit 기본값 정합화: 'ea' → '개'
ALTER TABLE products ALTER COLUMN unit SET DEFAULT '개';
