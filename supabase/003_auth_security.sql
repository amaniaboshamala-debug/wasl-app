-- وَصْل 003: حماية الحسابات

-- 1) اسم حساب Google بيوصل صح (Google بيبعته باسم name مش full_name)
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'))
  on conflict (id) do nothing;
  return new;
end; $$;

-- 2) المستخدم بيقدر يعمل الـ profile تبعه إذا مش موجود (حسابات قديمة)
drop policy if exists "profile: insert own" on public.profiles;
create policy "profile: insert own" on public.profiles
  for insert with check (auth.uid() = id);

-- 3) ممنوع أي مستخدم يعمل حاله admin من التطبيق
create or replace function public.protect_profile_role() returns trigger
language plpgsql as $$
begin
  -- لوحة Supabase والسيرفر (بدون مستخدم) مسموحلهم
  if auth.uid() is null then return new; end if;
  if new.role is not null and new.role not in ('user', 'volunteer', 'organization') then
    raise exception 'role_change_not_allowed';
  end if;
  if tg_op = 'UPDATE' and old.role = 'admin' and new.role is distinct from old.role then
    raise exception 'role_change_not_allowed';
  end if;
  return new;
end; $$;

drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role
  before insert or update on public.profiles
  for each row execute function public.protect_profile_role();
