-- get_transaction_summary: 거래 합계를 DB에서 계산 (앱이 목록을 받아 더하지 않도록)
-- 목록은 페이지 단위로 나눠 받으므로, 합계·건수·기간은 이 함수로 따로 구한다.
--   - AI 경영 인사이트: 이번 달 매출·매입 (p_start = 이번 달 1일)
--   - 거래처 내역서: 거래처 전체 합계·건수·기간 (p_customer_id)
-- 호출자가 해당 사업장 소유자인지 확인한다 (20260604000000 과 같은 방식).

CREATE OR REPLACE FUNCTION public.get_transaction_summary(
  p_business_id UUID,
  p_customer_id UUID DEFAULT NULL,
  p_start DATE DEFAULT NULL,
  p_end DATE DEFAULT NULL
)
RETURNS TABLE(
  receivable_total DECIMAL(15, 2),
  payable_total DECIMAL(15, 2),
  tx_count BIGINT,
  first_date DATE,
  last_date DATE
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM businesses
    WHERE id = p_business_id
      AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION '권한이 없습니다';
  END IF;

  RETURN QUERY
  SELECT
    COALESCE(SUM(t.amount) FILTER (WHERE t.type = 'receivable'), 0)::DECIMAL(15, 2),
    COALESCE(SUM(t.amount) FILTER (WHERE t.type = 'payable'), 0)::DECIMAL(15, 2),
    COUNT(*),
    MIN(t.date),
    MAX(t.date)
  FROM transactions t
  WHERE t.business_id = p_business_id
    AND t.deleted_at IS NULL
    AND (p_customer_id IS NULL OR t.customer_id = p_customer_id)
    AND (p_start IS NULL OR t.date >= p_start)
    AND (p_end IS NULL OR t.date <= p_end);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_transaction_summary(UUID, UUID, DATE, DATE) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_transaction_summary(UUID, UUID, DATE, DATE) TO authenticated;
