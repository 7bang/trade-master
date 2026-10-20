-- 관리자 대시보드를 텔레그램 리포트(stats 스키마)와 분리
-- 20261021000000 은 AI 비용·기능 이름에 stats.ai_prices / stats.ai_task_labels 를 썼다.
-- 리포트는 사용자가 직접 관리하므로, 관리자 화면은 자체 단가·이름 함수를 쓰고 stats.* 를 읽지 않는다.
-- (20261021000000 이 stats 테이블에 넣은 단가·이름 행은 리포트 소유로 보고 여기서 지우지 않는다)

-- 단가: USD / 100만 토큰. 앱이 쓰는 모델이 바뀌면 새 마이그레이션에서 추가 (없는 모델은 비용 0)
CREATE OR REPLACE FUNCTION public._ai_price(p_model TEXT, OUT input_per_m NUMERIC, OUT output_per_m NUMERIC)
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT v.i, v.o FROM (VALUES
    ('claude-haiku-5-5', 0.10::NUMERIC, 0.50::NUMERIC),
    ('claude-sonnet-5-5', 2.00, 10.00)
  ) AS v(m, i, o)
  WHERE p_model LIKE v.m || '%';
$$;

CREATE OR REPLACE FUNCTION public._ai_cost(p_model TEXT, p_in INTEGER, p_out INTEGER)
RETURNS NUMERIC
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT COALESCE((SELECT (p_in * p.input_per_m + p_out * p.output_per_m) / 1000000.0
                   FROM public._ai_price(p_model) p), 0);
$$;

CREATE OR REPLACE FUNCTION public._ai_task_label(p_task TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_task
    WHEN 'parse_text' THEN '말·글자'
    WHEN 'parse_image' THEN '사진'
    WHEN 'insights' THEN '인사이트'
    WHEN 'collection_message' THEN '독촉'
    ELSE p_task
  END;
$$;

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
      SELECT jsonb_agg(jsonb_build_object('task', x.task, 'label', public._ai_task_label(x.task), 'calls', x.calls,
                                          'failed', x.failed, 'cost', round(x.cost, 4)) ORDER BY x.calls DESC)
      FROM (
        SELECT task, count(*) AS calls, count(*) FILTER (WHERE status >= 400) AS failed,
               sum(public._ai_cost(model, input_tokens, output_tokens)) AS cost
        FROM ai_usage_logs WHERE user_id = v_user AND created_at >= now() - interval '30 days'
        GROUP BY task
      ) x
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
      SELECT jsonb_agg(jsonb_build_object('task', x.task, 'label', public._ai_task_label(x.task), 'calls', x.calls,
                       'failed', x.failed, 'avg_ms', x.avg_ms, 'cost', round(x.cost, 4)) ORDER BY x.calls DESC)
      FROM (SELECT task, count(*) calls, count(*) FILTER (WHERE status >= 400) failed,
                   round(avg(duration_ms) FILTER (WHERE status < 400)) avg_ms, sum(cost) cost
            FROM l GROUP BY task) x
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
      FROM l WHERE NOT EXISTS (SELECT 1 FROM public._ai_price(l.model))
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

REVOKE ALL ON FUNCTION public._ai_price(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public._ai_cost(TEXT, INTEGER, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public._ai_task_label(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_business_detail(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_ai_usage(INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_business_detail(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_ai_usage(INTEGER) TO authenticated;
