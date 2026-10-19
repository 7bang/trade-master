-- Extend the existing Telegram report (stats.trade_report, read by the Raspberry Pi as stats_reader)
-- with AI usage and server sections.
-- 1) ai_usage_logs: one row per AI Edge Function call (written by the `ai` function with the service role)
-- 2) stats.trade_report(): same report as 20261018041002 + 🤖 AI + 🖥 서버 sections appended

CREATE TABLE IF NOT EXISTS public.ai_usage_logs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  user_id UUID,
  task TEXT NOT NULL,
  model TEXT,
  status INTEGER NOT NULL,
  input_tokens INTEGER NOT NULL DEFAULT 0,
  output_tokens INTEGER NOT NULL DEFAULT 0,
  duration_ms INTEGER
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_logs_created_at ON public.ai_usage_logs (created_at);

-- RLS on with no policies: anon/authenticated cannot read or write; service role bypasses RLS.
ALTER TABLE public.ai_usage_logs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ai_usage_logs FROM anon, authenticated;

-- An earlier draft of this migration (separate ops-report endpoint) was applied by hand; remove it.
DROP FUNCTION IF EXISTS public.ops_report(INTEGER);

create or replace function stats.trade_report()
returns text
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  now_kst timestamp := now() at time zone 'Asia/Seoul';
  today_kst date := (now() at time zone 'Asia/Seoul')::date;
  w12 timestamptz := now() - interval '12 hours';
  w7  timestamptz := now() - interval '7 days';
  w30 timestamptz := now() - interval '30 days';
  r text; t text;
  tx12 int; rcv12 int; pay12 int; biz12 int; del12 int; edit12 int; cust12 int; prod12 int;
  tx_today int; tx7 int; biz7 int; biz_total int; new_biz7 int; users_total int;
  ai_calls int; ai_failed int; ai_5xx int; ai_users int; ai_in bigint; ai_out bigint; ai_cost numeric; ai_avg_ms numeric;
  ai_calls7 int; ai_cost7 numeric;
  db_bytes bigint; db_conns int;
begin
  select count(*), count(*) filter (where type = 'receivable'), count(*) filter (where type = 'payable'),
         count(distinct business_id)
    into tx12, rcv12, pay12, biz12
  from transactions where created_at >= w12 and deleted_at is null;

  select count(*) into del12 from transactions where deleted_at >= w12;
  select count(*) into edit12 from transactions
   where deleted_at is null and updated_at >= w12 and updated_at > created_at + interval '1 minute';
  select count(*) into cust12 from customers where created_at >= w12;
  select count(*) into prod12 from products where created_at >= w12;

  select count(*) into tx_today from transactions
   where deleted_at is null and (created_at at time zone 'Asia/Seoul')::date = today_kst;
  select count(*), count(distinct business_id) into tx7, biz7
   from transactions where created_at >= w7 and deleted_at is null;
  select count(*) into biz_total from businesses;
  select count(*) into new_biz7 from businesses where created_at >= w7;
  select count(*) into users_total from auth.users;

  r := '📒 폰거래장 온 리포트 ' || to_char(now_kst, 'MM/DD HH24:MI') || E'\n\n'
    || '[최근 12시간]' || E'\n'
    || '거래 등록 ' || tx12 || '건 (미수 ' || rcv12 || ' · 미지급 ' || pay12 || ') · 사업장 ' || biz12 || '곳' || E'\n'
    || '수정 ' || edit12 || ' · 삭제 ' || del12 || ' · 신규 거래처 ' || cust12 || ' · 신규 품목 ' || prod12 || E'\n\n'
    || '[오늘] 거래 ' || tx_today || '건' || E'\n'
    || '[7일] 거래 ' || tx7 || '건 · 활동 사업장 ' || biz7 || '/' || biz_total || '곳' || E'\n'
    || '가입: 계정 ' || users_total || ' · 사업장 ' || biz_total || ' (7일 신규 ' || new_biz7 || ')';

  select string_agg(name, ', ' order by created_at) into t from businesses where created_at >= w7;
  if t is not null then
    r := r || E'\n' || '🆕 신규 사업장: ' || t;
  end if;

  -- 활동 사업장 (7일)
  select string_agg('  ' || b.name || ': ' || x.c || '건 · 마지막 ' || to_char(x.last_at at time zone 'Asia/Seoul', 'MM/DD HH24:MI'),
                    E'\n' order by x.c desc) into t
  from (select business_id, count(*) c, max(created_at) last_at
          from transactions where created_at >= w7 and deleted_at is null group by business_id) x
  join businesses b on b.id = x.business_id;
  r := r || E'\n\n' || '🏪 활동 사업장(7일)' || E'\n' || coalesce(t, '  없음');

  -- 이탈 신호: 최근 30일 안에 쓰다가 3일 이상 거래가 없는 사업장
  select string_agg(b.name || '(' || to_char(x.last_at at time zone 'Asia/Seoul', 'MM/DD') || ')', ', ' order by x.last_at desc) into t
  from (select business_id, max(created_at) last_at from transactions where deleted_at is null group by business_id) x
  join businesses b on b.id = x.business_id
  where x.last_at >= w30 and x.last_at < now() - interval '3 days';
  if t is not null then
    r := r || E'\n\n' || '⚠️ 3일 이상 거래 없음: ' || t;
  end if;

  -- AI 사용량 (ai_usage_logs). 단가 USD / 1M tokens: haiku-5-5 0.10/0.50, sonnet-5-5 2/10
  with ai as (
    select l.*,
      case
        when l.model like 'claude-haiku-5-5%' then (l.input_tokens * 0.10 + l.output_tokens * 0.50) / 1e6
        when l.model like 'claude-sonnet-5-5%' then (l.input_tokens * 2.0 + l.output_tokens * 10.0) / 1e6
        else 0
      end as cost
    from ai_usage_logs l where l.created_at >= w7
  )
  select count(*) filter (where created_at >= w12),
         count(*) filter (where created_at >= w12 and status >= 400),
         count(*) filter (where created_at >= w12 and status >= 500),
         count(distinct user_id) filter (where created_at >= w12),
         coalesce(sum(input_tokens) filter (where created_at >= w12), 0),
         coalesce(sum(output_tokens) filter (where created_at >= w12), 0),
         coalesce(sum(cost) filter (where created_at >= w12), 0),
         avg(duration_ms) filter (where created_at >= w12 and status < 400),
         count(*),
         coalesce(sum(cost), 0)
    into ai_calls, ai_failed, ai_5xx, ai_users, ai_in, ai_out, ai_cost, ai_avg_ms, ai_calls7, ai_cost7
  from ai;

  r := r || E'\n\n' || '🤖 AI(12시간)';
  if ai_calls = 0 then
    r := r || ' 호출 없음';
  else
    select string_agg(
             case task
               when 'parse_text' then '자연어'
               when 'parse_image' then '사진'
               when 'insights' then '인사이트'
               when 'collection_message' then '독촉'
               else task
             end || ' ' || n, ' · ' order by n desc) into t
    from (select task, count(*) n from ai_usage_logs where created_at >= w12 group by task) x;

    r := r || ' 호출 ' || ai_calls || '건 · 실패 ' || ai_failed || ' · 사용자 ' || ai_users || '명'
      || ' · 평균 ' || to_char(coalesce(ai_avg_ms, 0) / 1000.0, 'FM990.0') || '초' || E'\n'
      || '  ' || t || E'\n'
      || '  토큰 입력 ' || to_char(ai_in, 'FM999,999,999,990') || ' · 출력 ' || to_char(ai_out, 'FM999,999,999,990')
      || ' · 예상 $' || to_char(ai_cost, 'FM990.0000');
  end if;
  r := r || E'\n' || '  7일 누적: 호출 ' || ai_calls7 || '건 · 예상 $' || to_char(ai_cost7, 'FM990.0000');

  -- 서버 상태 (DB에서 알 수 있는 것)
  select pg_database_size(current_database()) into db_bytes;
  select count(*) into db_conns from pg_stat_activity where datname = current_database();
  r := r || E'\n\n' || '🖥 서버 DB ' || to_char(db_bytes / 1024.0 / 1024.0, 'FM999,990.0') || 'MB · 접속 ' || db_conns;
  if ai_5xx > 0 then
    r := r || E'\n' || '⚠️ AI 서버 오류 ' || ai_5xx || '건 (12시간)';
  end if;

  return r;
end;
$$;

revoke all on function stats.trade_report() from public;
grant execute on function stats.trade_report() to stats_reader;
