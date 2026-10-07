-- 매일 00시(KST) 지급은 기준 수량까지 채우기만 한다. 산 것·광고로 받은 것은 줄이지 않는다.

create or replace function public.apply_daily_grant(p_user uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  user_row public.users%rowtype;
  today text := to_char(now() at time zone 'Asia/Seoul', 'YYYY-MM-DD');
  floor_amulet integer;
  floor_rice integer;
  next_amulet integer;
  next_rice integer;
begin
  select * into user_row from public.users where id = p_user for update;
  if not found then
    return jsonb_build_object('ok', false, 'error', '프로필이 없습니다');
  end if;
  if user_row.last_daily_charge_date = today then
    return jsonb_build_object(
      'ok', true,
      'already', true,
      'amulet_count', user_row.amulet_count,
      'rice_count', user_row.rice_count
    );
  end if;
  if public._pass_active(user_row) then
    floor_amulet := 5;
    floor_rice := 15;
  else
    floor_amulet := 1;
    floor_rice := 3;
  end if;
  next_amulet := greatest(user_row.amulet_count, floor_amulet);
  next_rice := greatest(user_row.rice_count, floor_rice);
  update public.users
    set amulet_count = next_amulet,
        rice_count = next_rice,
        daily_ad_view_count = 0,
        last_daily_charge_date = today
    where id = p_user;
  insert into public.wallet_ledger (user_id, delta_amulet, delta_rice, reason)
  values (
    p_user,
    next_amulet - user_row.amulet_count,
    next_rice - user_row.rice_count,
    'daily_grant'
  );
  return jsonb_build_object(
    'ok', true,
    'already', false,
    'amulet_count', next_amulet,
    'rice_count', next_rice
  );
end;
$$;

-- AdMob 서버 검증 콜백은 같은 transaction_id 로 여러 번 올 수 있다.
create table if not exists public.ad_rewards (
  transaction_id text primary key,
  user_id uuid not null references public.users (id) on delete cascade,
  kind text not null check (kind in ('amulet', 'rice')),
  created_at timestamptz not null default now()
);

alter table public.ad_rewards enable row level security;

create or replace function public.claim_ad_reward_ssv(p_user uuid, p_kind text, p_txn text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  user_row public.users%rowtype;
  add_amulet integer := 0;
  add_rice integer := 0;
begin
  if p_kind not in ('amulet', 'rice') then
    return jsonb_build_object('ok', false, 'error', '보상 종류가 잘못되었습니다');
  end if;
  if p_txn is null or length(btrim(p_txn)) = 0 then
    return jsonb_build_object('ok', false, 'error', '광고 거래 번호가 없습니다');
  end if;
  select * into user_row from public.users where id = p_user for update;
  if not found then
    return jsonb_build_object('ok', false, 'error', '프로필이 없습니다');
  end if;
  if exists (select 1 from public.ad_rewards where transaction_id = p_txn) then
    return jsonb_build_object('ok', true, 'duplicate', true);
  end if;
  if user_row.daily_ad_view_count >= 10 then
    return jsonb_build_object('ok', false, 'error', '오늘 광고 충전 10회를 모두 썼습니다');
  end if;
  if p_kind = 'amulet' then
    add_amulet := 1;
  else
    add_rice := 3;
  end if;
  insert into public.ad_rewards (transaction_id, user_id, kind) values (p_txn, p_user, p_kind);
  update public.users
    set amulet_count = amulet_count + add_amulet,
        rice_count = rice_count + add_rice,
        daily_ad_view_count = daily_ad_view_count + 1
    where id = p_user;
  insert into public.wallet_ledger (user_id, delta_amulet, delta_rice, reason, ref_id)
  values (p_user, add_amulet, add_rice, 'reward_ad', p_txn);
  return jsonb_build_object('ok', true, 'duplicate', false);
exception
  when unique_violation then
    return jsonb_build_object('ok', true, 'duplicate', true);
end;
$$;

revoke all on function public.claim_ad_reward_ssv(uuid, text, text) from public, anon, authenticated;
grant execute on function public.claim_ad_reward_ssv(uuid, text, text) to service_role;
