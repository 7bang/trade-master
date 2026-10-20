-- 최고관리자 웹 대시보드 (plan-admin-dashboard.md)
-- - admins: 관리자 목록 (RLS 정책 없음 = 앱에서 접근 불가). 등록은 git 밖에서 1회:
--     insert into public.admins(user_id) select id from auth.users where email = '<관리자 이메일>';
-- - admin_*(): 조회 전용. 첫 줄에서 관리자 확인, 아니면 거부
-- - admin_access_logs: 사업장 상세 열람 기록
-- - stats.ai_prices / ai_task_labels: 비어 있던 AI 단가·작업 이름 채움 (텔레그램 리포트와 공용)

-- ===== 관리자 =====
CREATE TABLE IF NOT EXISTS public.admins (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.admins FROM anon, authenticated;

CREATE TABLE IF NOT EXISTS public.admin_access_logs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  admin_id UUID NOT NULL,
  business_id UUID NOT NULL,
  viewed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_admin_access_logs_viewed_at ON public.admin_access_logs (viewed_at);
ALTER TABLE public.admin_access_logs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.admin_access_logs FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (SELECT 1 FROM public.admins WHERE user_id = auth.uid());
$$;

-- 관리자가 아니면 예외 (모든 admin_* 함수 첫 줄)
CREATE OR REPLACE FUNCTION public._require_admin()
RETURNS VOID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION '관리자 권한이 없습니다' USING ERRCODE = '42501';
  END IF;
END;
$$;

-- ===== AI 단가·작업 이름 (비어 있으면 채움, 이미 있으면 그대로) =====
INSERT INTO stats.ai_prices (model, input_per_m, output_per_m) VALUES
  ('claude-haiku-5-5', 0.10, 0.50),
  ('claude-sonnet-5-5', 2.00, 10.00)
ON CONFLICT (model) DO NOTHING;

INSERT INTO stats.ai_task_labels (task, label) VALUES
  ('parse_text', '말·글자'),
  ('parse_image', '사진'),
  ('insights', '인사이트'),
  ('collection_message', '독촉')
ON CONFLICT (task) DO NOTHING;

-- AI 호출 1건의 예상 비용 (USD) — 단가 미등록 모델은 0
CREATE OR REPLACE FUNCTION public._ai_cost(p_model TEXT, p_in INTEGER, p_out INTEGER)
RETURNS NUMERIC
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT COALESCE(
    (SELECT (p_in * p.input_per_m + p_out * p.output_per_m) / 1000000.0
       FROM stats.ai_prices p WHERE p.model = p_model),
    0);
$$;

-- ===== 개요 =====
CREATE OR REPLACE FUNCTION public.admin_overview()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  today_kst DATE := (now() AT TIME ZONE 'Asia/Seoul')::DATE;
  result JSONB;
BEGIN
  PERFORM public._require_admin();

  WITH last_tx AS (
    SELECT business_id, max(created_at) AS last_at, count(*) AS total
    FROM transactions WHERE deleted_at IS NULL GROUP BY business_id
  ),
  days AS (
    SELECT generate_series(today_kst - 29, today_kst, '1 day')::DATE AS d
  )
  SELECT jsonb_build_object(
    'totals', jsonb_build_object(
      'accounts', (SELECT count(*) FROM auth.users),
      'businesses', (SELECT count(*) FROM businesses),
      'active_today', (SELECT count(DISTINCT business_id) FROM transactions
                       WHERE deleted_at IS NULL AND (created_at AT TIME ZONE 'Asia/Seoul')::DATE = today_kst),
      'active_7d', (SELECT count(*) FROM last_tx WHERE last_at >= now() - interval '7 days'),
      'active_30d', (SELECT count(*) FROM last_tx WHERE last_at >= now() - interval '30 days'),
      'new_accounts_7d', (SELECT count(*) FROM auth.users WHERE created_at >= now() - interval '7 days'),
      'tx_7d', (SELECT count(*) FROM transactions WHERE deleted_at IS NULL AND created_at >= now() - interval '7 days'),
      'ai_calls_30d', (SELECT count(*) FROM ai_usage_logs WHERE created_at >= now() - interval '30 days'),
      'ai_cost_30d', (SELECT round(COALESCE(sum(public._ai_cost(model, input_tokens, output_tokens)), 0), 4)
                      FROM ai_usage_logs WHERE created_at >= now() - interval '30 days')
    ),
    'daily', (
      SELECT jsonb_agg(jsonb_build_object(
        'date', d.d,
        'tx', (SELECT count(*) FROM transactions t
               WHERE t.deleted_at IS NULL AND (t.created_at AT TIME ZONE 'Asia/Seoul')::DATE = d.d),
        'active', (SELECT count(DISTINCT t.business_id) FROM transactions t
                   WHERE t.deleted_at IS NULL AND (t.created_at AT TIME ZONE 'Asia/Seoul')::DATE = d.d),
        'signups', (SELECT count(*) FROM auth.users u
                    WHERE (u.created_at AT TIME ZONE 'Asia/Seoul')::DATE = d.d)
      ) ORDER BY d.d)
      FROM days d
    ),
    'at_risk', COALESCE((
      SELECT jsonb_agg(jsonb_build_object('business_id', b.id, 'name', b.name, 'last_at', l.last_at, 'total', l.total)
                       ORDER BY l.last_at DESC)
      FROM last_tx l JOIN businesses b ON b.id = l.business_id
      WHERE l.last_at >= now() - interval '30 days' AND l.last_at < now() - interval '3 days'
    ), '[]'::jsonb),
    'unused', COALESCE((
      SELECT jsonb_agg(jsonb_build_object('business_id', b.id, 'name', b.name, 'email', u.email, 'created_at', b.created_at)
                       ORDER BY b.created_at DESC)
      FROM businesses b JOIN auth.users u ON u.id = b.user_id
      WHERE NOT EXISTS (SELECT 1 FROM transactions t WHERE t.business_id = b.id AND t.deleted_at IS NULL)
    ), '[]'::jsonb)
  ) INTO result;

  RETURN result;
END;
$$;

-- ===== 사업장 목록 =====
CREATE OR REPLACE FUNCTION public.admin_businesses()
RETURNS TABLE (
  business_id UUID,
  business_name TEXT,
  phone TEXT,
  email TEXT,
  signed_up_at TIMESTAMPTZ,
  last_sign_in_at TIMESTAMPTZ,
  last_tx_at TIMESTAMPTZ,
  tx_7d BIGINT,
  tx_30d BIGINT,
  tx_total BIGINT,
  customers BIGINT,
  products BIGINT,
  ai_calls_30d BIGINT,
  ai_cost_30d NUMERIC,
  status TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public._require_admin();

  RETURN QUERY
  WITH tx AS (
    SELECT t.business_id,
           max(t.created_at) AS last_at,
           count(*) FILTER (WHERE t.created_at >= now() - interval '7 days') AS c7,
           count(*) FILTER (WHERE t.created_at >= now() - interval '30 days') AS c30,
           count(*) AS total
    FROM transactions t WHERE t.deleted_at IS NULL GROUP BY t.business_id
  ),
  ai AS (
    SELECT l.user_id, count(*) AS calls,
           sum(public._ai_cost(l.model, l.input_tokens, l.output_tokens)) AS cost
    FROM ai_usage_logs l WHERE l.created_at >= now() - interval '30 days' GROUP BY l.user_id
  )
  SELECT
    b.id,
    b.name::TEXT,
    b.phone::TEXT,
    u.email::TEXT,
    u.created_at,
    u.last_sign_in_at,
    tx.last_at,
    COALESCE(tx.c7, 0),
    COALESCE(tx.c30, 0),
    COALESCE(tx.total, 0),
    (SELECT count(*) FROM customers c WHERE c.business_id = b.id AND c.is_active),
    (SELECT count(*) FROM products p WHERE p.business_id = b.id AND p.is_active),
    COALESCE(ai.calls, 0),
    round(COALESCE(ai.cost, 0), 4),
    CASE
      WHEN tx.last_at IS NULL THEN 'unused'
      WHEN tx.last_at >= now() - interval '7 days' THEN 'active'
      WHEN tx.last_at >= now() - interval '30 days' THEN 'caution'
      ELSE 'churned'
    END
  FROM businesses b
  JOIN auth.users u ON u.id = b.user_id
  LEFT JOIN tx ON tx.business_id = b.id
  LEFT JOIN ai ON ai.user_id = b.user_id
  ORDER BY tx.last_at DESC NULLS LAST, b.created_at DESC;
END;
$$;

-- ===== 사업장 상세 (열람 기록 남김) =====
CREATE OR REPLACE FUNCTION public.admin_business_detail(p_business_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  today_kst DATE := (now() AT TIME ZONE 'Asia/Seoul')::DATE;
  v_user UUID;
  result JSONB;
BEGIN
  PERFORM public._require_admin();

  SELECT user_id INTO v_user FROM businesses WHERE id = p_business_id;
  IF v_user IS NULL THEN
    RAISE EXCEPTION '사업장을 찾을 수 없습니다';
  END IF;

  INSERT INTO admin_access_logs (admin_id, business_id) VALUES (auth.uid(), p_business_id);

  SELECT jsonb_build_object(
    'business', (
      SELECT jsonb_build_object('id', b.id, 'name', b.name, 'phone', b.phone, 'created_at', b.created_at,
                                'email', u.email, 'last_sign_in_at', u.last_sign_in_at)
      FROM businesses b JOIN auth.users u ON u.id = b.user_id WHERE b.id = p_business_id
    ),
    'summary', (
      SELECT jsonb_build_object(
        'receivable_total', COALESCE(sum(amount) FILTER (WHERE type = 'receivable'), 0),
        'payable_total', COALESCE(sum(amount) FILTER (WHERE type = 'payable'), 0),
        'tx_count', count(*),
        'first_date', min(date),
        'last_date', max(date),
        'last_created_at', max(created_at))
      FROM transactions WHERE business_id = p_business_id AND deleted_at IS NULL
    ),
    'customers', COALESCE((
      SELECT jsonb_agg(x ORDER BY abs(x.balance) DESC, x.name)
      FROM (
        SELECT c.name, c.phone, c.is_active,
               COALESCE(sum(CASE WHEN t.type = 'receivable' THEN t.amount ELSE -t.amount END), 0) AS balance,
               count(t.id) AS tx_count
        FROM customers c
        LEFT JOIN transactions t ON t.customer_id = c.id AND t.deleted_at IS NULL
        WHERE c.business_id = p_business_id
        GROUP BY c.id, c.name, c.phone, c.is_active
      ) x
    ), '[]'::jsonb),
    'products', COALESCE((
      SELECT jsonb_agg(jsonb_build_object('name', p.name, 'unit', p.unit, 'default_unit_price', p.default_unit_price,
                                          'is_active', p.is_active) ORDER BY p.name)
      FROM products p WHERE p.business_id = p_business_id
    ), '[]'::jsonb),
    'ai', COALESCE((
      SELECT jsonb_agg(jsonb_build_object('task', x.task, 'label', COALESCE(lb.label, x.task), 'calls', x.calls,
                                          'failed', x.failed, 'cost', round(x.cost, 4)) ORDER BY x.calls DESC)
      FROM (
        SELECT task, count(*) AS calls, count(*) FILTER (WHERE status >= 400) AS failed,
               sum(public._ai_cost(model, input_tokens, output_tokens)) AS cost
        FROM ai_usage_logs WHERE user_id = v_user AND created_at >= now() - interval '30 days'
        GROUP BY task
      ) x LEFT JOIN stats.ai_task_labels lb ON lb.task = x.task
    ), '[]'::jsonb),
    'daily', (
      SELECT jsonb_agg(jsonb_build_object(
        'date', d,
        'tx', (SELECT count(*) FROM transactions t
               WHERE t.business_id = p_business_id AND t.deleted_at IS NULL
                 AND (t.created_at AT TIME ZONE 'Asia/Seoul')::DATE = d)
      ) ORDER BY d)
      FROM generate_series(today_kst - 29, today_kst, '1 day') AS g(d)
    )
  ) INTO result;

  RETURN result;
END;
$$;

-- ===== 사업장 상세: 거래 목록 (페이지) =====
CREATE OR REPLACE FUNCTION public.admin_business_transactions(
  p_business_id UUID,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  date DATE,
  created_at TIMESTAMPTZ,
  type TEXT,
  customer_name TEXT,
  product_name TEXT,
  quantity NUMERIC,
  unit TEXT,
  unit_price NUMERIC,
  amount NUMERIC,
  memo TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public._require_admin();

  RETURN QUERY
  SELECT t.date, t.created_at, t.type::TEXT, c.name::TEXT, p.name::TEXT,
         t.quantity::NUMERIC, p.unit::TEXT, t.unit_price::NUMERIC, t.amount::NUMERIC, t.memo::TEXT
  FROM transactions t
  LEFT JOIN customers c ON c.id = t.customer_id
  LEFT JOIN products p ON p.id = t.product_id
  WHERE t.business_id = p_business_id AND t.deleted_at IS NULL
  ORDER BY t.date DESC, t.created_at DESC, t.id DESC
  LIMIT LEAST(GREATEST(p_limit, 1), 200) OFFSET GREATEST(p_offset, 0);
END;
$$;

-- ===== AI 사용량 =====
CREATE OR REPLACE FUNCTION public.admin_ai_usage(p_days INTEGER DEFAULT 30)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  since TIMESTAMPTZ := now() - make_interval(days => LEAST(GREATEST(p_days, 1), 365));
  today_kst DATE := (now() AT TIME ZONE 'Asia/Seoul')::DATE;
  result JSONB;
BEGIN
  PERFORM public._require_admin();

  WITH l AS (
    SELECT *, public._ai_cost(model, input_tokens, output_tokens) AS cost
    FROM ai_usage_logs WHERE created_at >= since
  )
  SELECT jsonb_build_object(
    'days', LEAST(GREATEST(p_days, 1), 365),
    'totals', (SELECT jsonb_build_object('calls', count(*), 'failed', count(*) FILTER (WHERE status >= 400),
                      'input_tokens', COALESCE(sum(input_tokens), 0), 'output_tokens', COALESCE(sum(output_tokens), 0),
                      'cost', round(COALESCE(sum(cost), 0), 4)) FROM l),
    'by_task', COALESCE((
      SELECT jsonb_agg(jsonb_build_object('task', x.task, 'label', COALESCE(lb.label, x.task), 'calls', x.calls,
                       'failed', x.failed, 'avg_ms', x.avg_ms, 'cost', round(x.cost, 4)) ORDER BY x.calls DESC)
      FROM (SELECT task, count(*) calls, count(*) FILTER (WHERE status >= 400) failed,
                   round(avg(duration_ms) FILTER (WHERE status < 400)) avg_ms, sum(cost) cost
            FROM l GROUP BY task) x
      LEFT JOIN stats.ai_task_labels lb ON lb.task = x.task
    ), '[]'::jsonb),
    'by_business', COALESCE((
      SELECT jsonb_agg(jsonb_build_object('business_id', b.id, 'name', COALESCE(b.name, '(사업장 없음)'),
                       'calls', x.calls, 'failed', x.failed, 'cost', round(x.cost, 4)) ORDER BY x.calls DESC)
      FROM (SELECT user_id, count(*) calls, count(*) FILTER (WHERE status >= 400) failed, sum(cost) cost
            FROM l GROUP BY user_id) x
      LEFT JOIN businesses b ON b.user_id = x.user_id
    ), '[]'::jsonb),
    'unpriced_models', COALESCE((
      SELECT jsonb_agg(DISTINCT COALESCE(l.model, '(모델 없음)'))
      FROM l LEFT JOIN stats.ai_prices p ON p.model = l.model WHERE p.model IS NULL
    ), '[]'::jsonb),
    'daily', (
      SELECT jsonb_agg(jsonb_build_object(
        'date', d,
        'calls', (SELECT count(*) FROM l WHERE (l.created_at AT TIME ZONE 'Asia/Seoul')::DATE = d),
        'cost', (SELECT round(COALESCE(sum(cost), 0), 4) FROM l WHERE (l.created_at AT TIME ZONE 'Asia/Seoul')::DATE = d)
      ) ORDER BY d)
      FROM generate_series(today_kst - (LEAST(GREATEST(p_days, 1), 365) - 1), today_kst, '1 day') AS g(d)
    )
  ) INTO result;

  RETURN result;
END;
$$;

-- ===== 권한: 로그인한 사용자만 호출 가능 (안에서 관리자 확인) =====
REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public._require_admin() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public._ai_cost(TEXT, INTEGER, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_overview() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_businesses() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_business_detail(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_business_transactions(UUID, INTEGER, INTEGER) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_ai_usage(INTEGER) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_overview() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_businesses() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_business_detail(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_business_transactions(UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_ai_usage(INTEGER) TO authenticated;
