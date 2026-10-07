-- 애견·차 등 사람 외 이름 카테고리

do $$
declare
  cname text;
begin
  select con.conname into cname
  from pg_constraint con
  where con.conrelid = 'public.fortunes'::regclass
    and con.contype = 'c'
    and pg_get_constraintdef(con.oid) like '%category%';
  if cname is not null then
    execute format('alter table public.fortunes drop constraint %I', cname);
  end if;
end $$;

alter table public.fortunes add constraint fortunes_category_check
  check (
    category in (
      'family', 'colleague', 'date_pick', 'naming', 'thing_name', 'dream', 'my_fortune'
    )
  );
