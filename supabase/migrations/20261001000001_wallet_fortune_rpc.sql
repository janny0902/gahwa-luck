-- 재화 증감은 service_role RPC만. 클라이언트 update는 지갑 칸을 바꾸지 못한다.

create or replace function public.keep_wallet_on_client_update()
returns trigger
language plpgsql
as $$
begin
  if coalesce(auth.role(), '') = 'authenticated' then
    new.amulet_count := old.amulet_count;
    new.rice_count := old.rice_count;
    new.last_daily_charge_date := old.last_daily_charge_date;
    new.daily_ad_view_count := old.daily_ad_view_count;
    new.pass_active := old.pass_active;
    new.pass_expired_at := old.pass_expired_at;
  end if;
  return new;
end;
$$;

drop trigger if exists users_keep_wallet on public.users;
create trigger users_keep_wallet
  before update on public.users
  for each row execute function public.keep_wallet_on_client_update();

-- 운세·채팅 쓰기는 Edge(service role)만
drop policy if exists fortunes_all_own on public.fortunes;
drop policy if exists fortunes_select_own on public.fortunes;
create policy fortunes_select_own on public.fortunes
  for select using (auth.uid() = user_id);

drop policy if exists fortune_chats_all_own on public.fortune_chats;
drop policy if exists fortune_chats_select_own on public.fortune_chats;
create policy fortune_chats_select_own on public.fortune_chats
  for select using (
    exists (
      select 1 from public.fortunes f
      where f.id = fortune_id and f.user_id = auth.uid()
    )
  );

create or replace function public._pass_active(user_row public.users)
returns boolean
language sql
stable
as $$
  select coalesce(user_row.pass_active, false)
    and user_row.pass_expired_at is not null
    and user_row.pass_expired_at > now();
$$;

create or replace function public.apply_daily_grant(p_user uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  user_row public.users%rowtype;
  today text := to_char(now() at time zone 'Asia/Seoul', 'YYYY-MM-DD');
  amulet integer;
  rice integer;
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
    amulet := 5;
    rice := 15;
  else
    amulet := 1;
    rice := 3;
  end if;
  update public.users
    set amulet_count = amulet,
        rice_count = rice,
        daily_ad_view_count = 0,
        last_daily_charge_date = today
    where id = p_user;
  insert into public.wallet_ledger (user_id, delta_amulet, delta_rice, reason)
  values (p_user, amulet, rice, 'daily_grant');
  return jsonb_build_object(
    'ok', true,
    'already', false,
    'amulet_count', amulet,
    'rice_count', rice
  );
end;
$$;

create or replace function public.spend_amulet(p_user uuid, p_reason text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  user_row public.users%rowtype;
begin
  select * into user_row from public.users where id = p_user for update;
  if not found then
    return jsonb_build_object('ok', false, 'error', '프로필이 없습니다');
  end if;
  if user_row.amulet_count < 1 then
    return jsonb_build_object('ok', false, 'error', '부적이 없습니다. 광고를 보거나 내일 다시 받아 주세요.');
  end if;
  update public.users set amulet_count = amulet_count - 1 where id = p_user;
  insert into public.wallet_ledger (user_id, delta_amulet, delta_rice, reason)
  values (p_user, -1, 0, p_reason);
  return jsonb_build_object('ok', true, 'amulet_count', user_row.amulet_count - 1);
end;
$$;

create or replace function public.refund_amulet(p_user uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.users set amulet_count = amulet_count + 1 where id = p_user;
  insert into public.wallet_ledger (user_id, delta_amulet, delta_rice, reason)
  values (p_user, 1, 0, p_reason);
end;
$$;

create or replace function public.spend_rice(p_user uuid, p_fortune uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  owner uuid;
  turns integer;
  rice integer;
begin
  select user_id, remaining_rice_turns into owner, turns
  from public.fortunes where id = p_fortune for update;
  if owner is null or owner <> p_user then
    return jsonb_build_object('ok', false, 'error', '운세 기록을 찾지 못했습니다');
  end if;
  if turns < 1 then
    return jsonb_build_object('ok', false, 'error', '이 운세의 추가 질문 5회를 모두 썼습니다');
  end if;
  select rice_count into rice from public.users where id = p_user for update;
  if rice < 1 then
    return jsonb_build_object('ok', false, 'error', '쌀알이 없습니다');
  end if;
  update public.users set rice_count = rice_count - 1 where id = p_user;
  update public.fortunes set remaining_rice_turns = remaining_rice_turns - 1 where id = p_fortune;
  insert into public.wallet_ledger (user_id, delta_amulet, delta_rice, reason, ref_id)
  values (p_user, 0, -1, 'followup', p_fortune::text);
  return jsonb_build_object('ok', true, 'remaining_rice_turns', turns - 1);
end;
$$;

create or replace function public.refund_rice(p_user uuid, p_fortune uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.users set rice_count = rice_count + 1 where id = p_user;
  update public.fortunes set remaining_rice_turns = remaining_rice_turns + 1 where id = p_fortune;
  insert into public.wallet_ledger (user_id, delta_amulet, delta_rice, reason, ref_id)
  values (p_user, 0, 1, 'followup_refund', p_fortune::text);
end;
$$;

create or replace function public.claim_ad_reward(p_user uuid, p_kind text)
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
  select * into user_row from public.users where id = p_user for update;
  if not found then
    return jsonb_build_object('ok', false, 'error', '프로필이 없습니다');
  end if;
  if user_row.daily_ad_view_count >= 10 then
    return jsonb_build_object('ok', false, 'error', '오늘 광고 충전 10회를 모두 썼습니다');
  end if;
  if p_kind = 'amulet' then
    add_amulet := 1;
  else
    add_rice := 3;
  end if;
  update public.users
    set amulet_count = amulet_count + add_amulet,
        rice_count = rice_count + add_rice,
        daily_ad_view_count = daily_ad_view_count + 1
    where id = p_user;
  insert into public.wallet_ledger (user_id, delta_amulet, delta_rice, reason)
  values (p_user, add_amulet, add_rice, 'reward_ad');
  return jsonb_build_object(
    'ok', true,
    'amulet_count', user_row.amulet_count + add_amulet,
    'rice_count', user_row.rice_count + add_rice
  );
end;
$$;

revoke all on function public.apply_daily_grant(uuid) from public, anon, authenticated;
revoke all on function public.spend_amulet(uuid, text) from public, anon, authenticated;
revoke all on function public.refund_amulet(uuid, text) from public, anon, authenticated;
revoke all on function public.spend_rice(uuid, uuid) from public, anon, authenticated;
revoke all on function public.refund_rice(uuid, uuid) from public, anon, authenticated;
revoke all on function public.claim_ad_reward(uuid, text) from public, anon, authenticated;

grant execute on function public.apply_daily_grant(uuid) to service_role;
grant execute on function public.spend_amulet(uuid, text) to service_role;
grant execute on function public.refund_amulet(uuid, text) to service_role;
grant execute on function public.spend_rice(uuid, uuid) to service_role;
grant execute on function public.refund_rice(uuid, uuid) to service_role;
grant execute on function public.claim_ad_reward(uuid, text) to service_role;
