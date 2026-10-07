-- T1: 가화만사성 초기 스키마 + RLS
-- 적용: Supabase SQL Editor 또는 `supabase db push`

create extension if not exists "pgcrypto";

-- users (auth.users 와 1:1, id = auth.uid())
create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  provider text,
  amulet_count integer not null default 1 check (amulet_count >= 0),
  rice_count integer not null default 3 check (rice_count >= 0),
  last_daily_charge_date text,
  daily_ad_view_count integer not null default 0,
  pass_active boolean not null default false,
  pass_expired_at timestamptz,
  my_profile jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  name text not null,
  hanja text,
  relation text,
  priority integer not null default 0,
  birth_date date,
  birth_time text,
  is_lunar boolean not null default false,
  gender text,
  mbti text,
  kind text not null default 'family' check (kind in ('family', 'colleague', 'other')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists members_user_id_idx on public.members (user_id);

create table if not exists public.fortunes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  category text not null check (
    category in ('family', 'colleague', 'date_pick', 'naming', 'dream', 'my_fortune')
  ),
  input_summary jsonb not null default '{}'::jsonb,
  four_pillars jsonb not null default '{}'::jsonb,
  result_json jsonb not null default '{}'::jsonb,
  result_text text,
  remaining_rice_turns integer not null default 5 check (remaining_rice_turns >= 0),
  created_at timestamptz not null default now()
);

create index if not exists fortunes_user_id_created_idx
  on public.fortunes (user_id, created_at desc);

create table if not exists public.fortune_chats (
  id uuid primary key default gen_random_uuid(),
  fortune_id uuid not null references public.fortunes (id) on delete cascade,
  turn_index integer not null check (turn_index between 1 and 5),
  user_question text not null,
  ai_answer text not null,
  created_at timestamptz not null default now(),
  unique (fortune_id, turn_index)
);

create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  product_id text not null,
  purchase_token text not null,
  order_id text,
  status text not null default 'purchased',
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (purchase_token)
);

create index if not exists purchases_user_id_idx on public.purchases (user_id);

create table if not exists public.wallet_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  delta_amulet integer not null default 0,
  delta_rice integer not null default 0,
  reason text not null,
  ref_id text,
  created_at timestamptz not null default now()
);

create index if not exists wallet_ledger_user_id_idx
  on public.wallet_ledger (user_id, created_at desc);

-- updated_at trigger
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists users_set_updated_at on public.users;
create trigger users_set_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

drop trigger if exists members_set_updated_at on public.members;
create trigger members_set_updated_at
  before update on public.members
  for each row execute function public.set_updated_at();

-- RLS
alter table public.users enable row level security;
alter table public.members enable row level security;
alter table public.fortunes enable row level security;
alter table public.fortune_chats enable row level security;
alter table public.purchases enable row level security;
alter table public.wallet_ledger enable row level security;

-- users policies
drop policy if exists users_select_own on public.users;
create policy users_select_own on public.users
  for select using (auth.uid() = id);

drop policy if exists users_update_own on public.users;
create policy users_update_own on public.users
  for update using (auth.uid() = id);

drop policy if exists users_insert_own on public.users;
create policy users_insert_own on public.users
  for insert with check (auth.uid() = id);

-- members
drop policy if exists members_all_own on public.members;
create policy members_all_own on public.members
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- fortunes
drop policy if exists fortunes_all_own on public.fortunes;
create policy fortunes_all_own on public.fortunes
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- fortune_chats via parent fortune ownership
drop policy if exists fortune_chats_all_own on public.fortune_chats;
create policy fortune_chats_all_own on public.fortune_chats
  for all using (
    exists (
      select 1 from public.fortunes f
      where f.id = fortune_id and f.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.fortunes f
      where f.id = fortune_id and f.user_id = auth.uid()
    )
  );

-- purchases / ledger: 읽기만 클라이언트, 쓰기는 Edge(service role)
drop policy if exists purchases_select_own on public.purchases;
create policy purchases_select_own on public.purchases
  for select using (auth.uid() = user_id);

drop policy if exists wallet_ledger_select_own on public.wallet_ledger;
create policy wallet_ledger_select_own on public.wallet_ledger
  for select using (auth.uid() = user_id);

-- 신규 가입 시 users 행 자동 생성
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, provider)
  values (
    new.id,
    new.email,
    coalesce(new.raw_app_meta_data->>'provider', new.raw_app_meta_data->>'provider_id', 'unknown')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
