-- وَصْل 007: لوحة المؤسسة (إعداد المؤسسة · نشر الفرص · قبول ورفض الطلبات)
-- انسخيه لـ Supabase → SQL Editor → Run (بيتشغّل أكتر من مرة بدون مشاكل)

-- 1) رقم جوال المتطوع على الطلب، عشان المؤسسة تتواصل معه لما تقبله
alter table public.applications add column if not exists phone text;

-- 2) حساب المؤسسة بس بيقدر يعمل مؤسسة (مش أي حساب)
create or replace function public.my_role() returns text
language sql stable security definer set search_path = public as $$
  select role from profiles where id = auth.uid();
$$;

drop policy if exists "org: owner manage" on public.organizations;
drop policy if exists "org: owner insert" on public.organizations;
drop policy if exists "org: owner update" on public.organizations;
create policy "org: owner insert" on public.organizations
  for insert to authenticated
  with check (owner_id = auth.uid() and public.my_role() = 'organization' and is_verified = false);
-- التوثيق (is_verified) بيصير من لوحة Supabase بس، مش من التطبيق
create policy "org: owner update" on public.organizations
  for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid() and is_verified = (select o.is_verified from organizations o where o.id = organizations.id));

-- 3) المؤسسة بتشوف اسم ومهارات ومنطقة المتطوعين اللي قدّموا على فرصها (بس هدول)
drop policy if exists "profile: org reads applicants" on public.profiles;
create policy "profile: org reads applicants" on public.profiles
  for select to authenticated
  using (exists (
    select 1 from applications a join opportunities o on o.id = a.opportunity_id
    where a.volunteer_id = profiles.id and public.is_org_owner(o.organization_id)
  ));

-- 4) القبول والرفض بيمرّوا من دالة على السيرفر (بتفحص إنك صاحبة الفرصة وإنه في مقاعد)
drop policy if exists "application: org decide" on public.applications;

create or replace function public.decide_application(p_application_id uuid, p_accept boolean)
returns void
language plpgsql security definer set search_path = public as $$
declare
  opp_id uuid;
  org_id uuid;
  cur_status text;
  needed int;
  accepted int;
begin
  select a.opportunity_id, o.organization_id, a.status, o.volunteers_needed
    into opp_id, org_id, cur_status, needed
    from applications a join opportunities o on o.id = a.opportunity_id
   where a.id = p_application_id;

  if opp_id is null then raise exception 'application_not_found'; end if;
  if not public.is_org_owner(org_id) then raise exception 'not_your_opportunity'; end if;
  if cur_status = 'withdrawn' then raise exception 'volunteer_withdrew'; end if;

  if p_accept then
    if cur_status = 'accepted' then return; end if;
    select count(*) into accepted from applications
     where opportunity_id = opp_id and status = 'accepted';
    if accepted >= needed then raise exception 'opportunity_full'; end if;
    update applications set status = 'accepted', updated_at = now() where id = p_application_id;
  else
    update applications set status = 'rejected', updated_at = now() where id = p_application_id;
  end if;
end; $$;

revoke all on function public.decide_application(uuid, boolean) from public, anon;
grant execute on function public.decide_application(uuid, boolean) to authenticated;

-- 5) التقديم صار ياخد رقم الجوال كمان (بنشيل النسخة القديمة من 006)
drop function if exists public.apply_to_opportunity(uuid, text, text[], text[]);

create or replace function public.apply_to_opportunity(
  p_opportunity_id uuid,
  p_bio text default null,
  p_available_days text[] default '{}',
  p_skills text[] default '{}',
  p_phone text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  me uuid := auth.uid();
  my_role text;
  opp_status text;
  existing_id uuid;
  existing_status text;
  new_id uuid;
begin
  if me is null then raise exception 'not_signed_in'; end if;

  select role into my_role from profiles where id = me;
  if my_role is distinct from 'volunteer' then raise exception 'only_volunteers'; end if;

  select status into opp_status from opportunities where id = p_opportunity_id;
  if opp_status is null then raise exception 'opportunity_not_found'; end if;
  if opp_status <> 'open' then raise exception 'opportunity_closed'; end if;

  select id, status into existing_id, existing_status from applications
   where opportunity_id = p_opportunity_id and volunteer_id = me;

  if found then
    if existing_status = 'withdrawn' then
      update applications
         set status = 'pending', bio = p_bio, available_days = p_available_days,
             skills = p_skills, phone = p_phone, created_at = now(), updated_at = now()
       where id = existing_id;
      return existing_id;
    end if;
    raise exception 'already_applied';
  end if;

  insert into applications (opportunity_id, volunteer_id, bio, available_days, skills, phone)
  values (p_opportunity_id, me, p_bio, p_available_days, p_skills, p_phone)
  returning id into new_id;
  return new_id;
end; $$;

revoke all on function public.apply_to_opportunity(uuid, text, text[], text[], text) from public, anon;
grant execute on function public.apply_to_opportunity(uuid, text, text[], text[], text) to authenticated;
