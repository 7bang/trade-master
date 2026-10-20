-- AI 모델 단가표 (100만 토큰당 USD). 모델명은 ai_usage_logs.model 값과 같아야 함
create table if not exists stats.ai_prices (
  model text primary key,
  input_per_m numeric not null,
  output_per_m numeric not null,
  updated_at timestamptz not null default now()
);
revoke all on stats.ai_prices from public;

-- 작업 이름 → 한글 표시명 (없으면 원래 이름 그대로 표시)
create table if not exists stats.ai_task_labels (
  task text primary key,
  label text not null
);
revoke all on stats.ai_task_labels from public;

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
  ai12 int; aifail12 int; ai5xx12 int; aiusers12 int; aims12 numeric; ain12 bigint; aout12 bigint; acost12 numeric;
  ai7 int; acost7 numeric; unpriced text;
  db_size text; conns int;
begin
  -- ===== 거래 =====
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

  select string_agg('  ' || b.name || ': ' || x.c || '건 · 마지막 ' || to_char(x.last_at at time zone 'Asia/Seoul', 'MM/DD HH24:MI'),
                    E'\n' order by x.c desc) into t
  from (select business_id, count(*) c, max(created_at) last_at
          from transactions where created_at >= w7 and deleted_at is null group by business_id) x
  join businesses b on b.id = x.business_id;
  r := r || E'\n\n' || '🏪 활동 사업장(7일)' || E'\n' || coalesce(t, '  없음');

  select string_agg(b.name || '(' || to_char(x.last_at at time zone 'Asia/Seoul', 'MM/DD') || ')', ', ' order by x.last_at desc) into t
  from (select business_id, max(created_at) last_at from transactions where deleted_at is null group by business_id) x
  join businesses b on b.id = x.business_id
  where x.last_at >= w30 and x.last_at < now() - interval '3 days';
  if t is not null then
    r := r || E'\n\n' || '⚠️ 3일 이상 거래 없음: ' || t;
  end if;

  -- ===== AI 사용량 =====
  select count(*),
         count(*) filter (where status >= 400),
         count(*) filter (where status >= 500),
         count(distinct user_id),
         round(avg(duration_ms) / 1000.0, 1),
         coalesce(sum(input_tokens), 0), coalesce(sum(output_tokens), 0)
    into ai12, aifail12, ai5xx12, aiusers12, aims12, ain12, aout12
  from ai_usage_logs where created_at >= w12;

  select sum(l.input_tokens * p.input_per_m + l.output_tokens * p.output_per_m) / 1000000.0 into acost12
  from ai_usage_logs l join stats.ai_prices p on p.model = l.model where l.created_at >= w12;

  select count(*) into ai7 from ai_usage_logs where created_at >= w7;
  select sum(l.input_tokens * p.input_per_m + l.output_tokens * p.output_per_m) / 1000000.0 into acost7
  from ai_usage_logs l join stats.ai_prices p on p.model = l.model where l.created_at >= w7;

  select string_agg(distinct coalesce(l.model, '(모델 없음)'), ', ') into unpriced
  from ai_usage_logs l left join stats.ai_prices p on p.model = l.model
  where l.created_at >= w7 and p.model is null;

  r := r || E'\n\n' || '🤖 AI(12시간) 호출 ' || ai12 || '건 · 실패 ' || aifail12 || ' · 사용자 ' || aiusers12 || '명'
         || ' · 평균 ' || coalesce(aims12::text, '-') || '초';

  select string_agg(coalesce(lb.label, x.task) || ' ' || x.c, ' · ' order by x.c desc) into t
  from (select task, count(*) c from ai_usage_logs where created_at >= w12 group by task) x
  left join stats.ai_task_labels lb on lb.task = x.task;
  if t is not null then
    r := r || E'\n' || '  ' || t;
  end if;

  r := r || E'\n' || '  토큰 입력 ' || to_char(ain12, 'FM999,999,999,990') || ' · 출력 ' || to_char(aout12, 'FM999,999,999,990')
         || ' · 예상 $' || coalesce(to_char(acost12, 'FM9990.0000'), '0.0000')
         || E'\n' || '  7일 누적: 호출 ' || ai7 || '건 · 예상 $' || coalesce(to_char(acost7, 'FM9990.0000'), '0.0000');
  if unpriced is not null then
    r := r || E'\n' || '  (단가 미등록 모델: ' || unpriced || ')';
  end if;

  -- ===== 서버 =====
  select pg_size_pretty(pg_database_size(current_database())) into db_size;
  select count(*) into conns from pg_stat_activity where datname = current_database();
  r := r || E'\n\n' || '🖥 서버 DB ' || db_size || ' · 접속 ' || conns;

  if ai5xx12 > 0 then
    r := r || E'\n' || '⚠️ AI 서버 오류 ' || ai5xx12 || '건 (12시간)';
  end if;

  return r;
end;
$$;

revoke all on function stats.trade_report() from public;
grant execute on function stats.trade_report() to stats_reader;;
