-- T7: Play 결제 토큰은 한 번만 지급. service_role 만 실행.

create or replace function public.grant_iap(
  p_user uuid,
  p_product text,
  p_token text,
  p_order text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  user_row public.users%rowtype;
  add_amulet integer := 0;
  add_rice integer := 0;
  grant_pass boolean := false;
  new_expiry timestamptz;
begin
  if p_token is null or length(btrim(p_token)) = 0 then
    return jsonb_build_object('ok', false, 'error', '결제 토큰이 없습니다');
  end if;

  if exists (select 1 from public.purchases where purchase_token = p_token) then
    select * into user_row from public.users where id = p_user;
    return jsonb_build_object(
      'ok', true,
      'duplicate', true,
      'amulet_count', user_row.amulet_count,
      'rice_count', user_row.rice_count,
      'pass_active', coalesce(user_row.pass_active, false),
      'pass_expired_at', user_row.pass_expired_at
    );
  end if;

  if p_product = 'amulet_1' then
    add_amulet := 1;
  elsif p_product = 'amulet_10' then
    add_amulet := 10;
  elsif p_product = 'amulet_30' then
    add_amulet := 30;
  elsif p_product = 'rice_1' then
    add_rice := 1;
  elsif p_product = 'rice_10' then
    add_rice := 10;
  elsif p_product = 'rice_30' then
    add_rice := 30;
  elsif p_product = 'pass_30d' then
    grant_pass := true;
  else
    return jsonb_build_object('ok', false, 'error', '알 수 없는 상품입니다');
  end if;

  select * into user_row from public.users where id = p_user for update;
  if not found then
    return jsonb_build_object('ok', false, 'error', '프로필이 없습니다');
  end if;

  if grant_pass then
    new_expiry := greatest(coalesce(user_row.pass_expired_at, now()), now()) + interval '30 days';
    update public.users
      set pass_active = true,
          pass_expired_at = new_expiry
      where id = p_user;
  else
    update public.users
      set amulet_count = amulet_count + add_amulet,
          rice_count = rice_count + add_rice
      where id = p_user;
  end if;

  insert into public.purchases (user_id, product_id, purchase_token, order_id, status, raw_payload)
  values (
    p_user,
    p_product,
    p_token,
    nullif(btrim(coalesce(p_order, '')), ''),
    'purchased',
    jsonb_build_object('product_id', p_product)
  );

  insert into public.wallet_ledger (user_id, delta_amulet, delta_rice, reason, ref_id)
  values (p_user, add_amulet, add_rice, 'iap', p_product);

  return jsonb_build_object(
    'ok', true,
    'duplicate', false,
    'amulet_count', user_row.amulet_count + add_amulet,
    'rice_count', user_row.rice_count + add_rice,
    'pass_active', grant_pass or coalesce(user_row.pass_active, false),
    'pass_expired_at', case when grant_pass then new_expiry else user_row.pass_expired_at end
  );
exception
  when unique_violation then
    select * into user_row from public.users where id = p_user;
    return jsonb_build_object(
      'ok', true,
      'duplicate', true,
      'amulet_count', user_row.amulet_count,
      'rice_count', user_row.rice_count,
      'pass_active', coalesce(user_row.pass_active, false),
      'pass_expired_at', user_row.pass_expired_at
    );
end;
$$;

revoke all on function public.grant_iap(uuid, text, text, text) from public, anon, authenticated;
grant execute on function public.grant_iap(uuid, text, text, text) to service_role;
