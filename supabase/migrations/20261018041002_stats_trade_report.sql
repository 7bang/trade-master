create schema if not exists stats;
revoke all on schema stats from public;

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

  return r;
end;
$$;

revoke all on function stats.trade_report() from public;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'stats_reader') then
    create role stats_reader login noinherit;
  end if;
end $$;

grant usage on schema stats to stats_reader;
grant execute on function stats.trade_report() to stats_reader;
