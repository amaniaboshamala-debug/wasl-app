-- وَصْل 006: الفرص والتقديم وطلباتي
-- انسخيه لـ Supabase → SQL Editor → Run (بيتشغّل أكتر من مرة بدون مشاكل)

-- 1) خانات جديدة للفرصة
alter table public.opportunities add column if not exists type text not null default 'volunteer';
alter table public.opportunities drop constraint if exists opportunities_type_check;
alter table public.opportunities add constraint opportunities_type_check
  check (type in ('volunteer', 'paid', 'volunteer_allowance'));
alter table public.opportunities add column if not exists compensation text;   -- مثلاً "50 ₪ يومياً" (الدفع برّا التطبيق)
alter table public.opportunities add column if not exists is_remote boolean not null default false;
alter table public.opportunities add column if not exists region text;
alter table public.opportunities add column if not exists accepted_count int not null default 0;
alter table public.opportunities add column if not exists created_at timestamptz not null default now();

-- 2) خانات جديدة للطلب
alter table public.applications add column if not exists available_days text[] not null default '{}';
alter table public.applications add column if not exists skills text[] not null default '{}';
alter table public.applications add column if not exists updated_at timestamptz not null default now();

-- 3) المراقب من 002 صار كمان بيعدّ المقبولين (عشان "باقي 3 مقاعد")
create or replace function public.sync_opportunity_capacity()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  accepted int;
  needed int;
begin
  select count(*) into accepted
    from applications where opportunity_id = new.opportunity_id and status = 'accepted';
  select volunteers_needed into needed from opportunities where id = new.opportunity_id;

  update opportunities set accepted_count = accepted where id = new.opportunity_id;

  if accepted >= needed then
    update opportunities set status = 'full'
      where id = new.opportunity_id and status = 'open';
  else
    update opportunities set status = 'open'
      where id = new.opportunity_id and status = 'full'
        and (apply_deadline is null or apply_deadline >= (now() at time zone 'Asia/Hebron')::date);
  end if;
  return new;
end; $$;

update public.opportunities o
   set accepted_count = (select count(*) from applications a where a.opportunity_id = o.id and a.status = 'accepted');

-- 4) الحماية (RLS)
alter table public.opportunities enable row level security;
alter table public.applications  enable row level security;

-- الفرص: المفتوحة والمكتملة بتطلع للكل، والمؤسسة بتشوف وبتدير فرصها
drop policy if exists "opportunity: read visible" on public.opportunities;
create policy "opportunity: read visible" on public.opportunities
  for select to authenticated
  using (status in ('open', 'full') or public.is_org_owner(organization_id));

drop policy if exists "opportunity: owner manage" on public.opportunities;
create policy "opportunity: owner manage" on public.opportunities
  for all to authenticated
  using (public.is_org_owner(organization_id)) with check (public.is_org_owner(organization_id));

-- الطلبات: المتطوع بيشوف طلباته بس، والمؤسسة بتشوف طلبات فرصها وبتقبل أو بترفض
drop policy if exists "application: read own" on public.applications;
create policy "application: read own" on public.applications
  for select to authenticated using (volunteer_id = auth.uid());

drop policy if exists "application: org read" on public.applications;
create policy "application: org read" on public.applications
  for select to authenticated
  using (exists (select 1 from opportunities o where o.id = opportunity_id and public.is_org_owner(o.organization_id)));

drop policy if exists "application: org decide" on public.applications;
create policy "application: org decide" on public.applications
  for update to authenticated
  using (exists (select 1 from opportunities o where o.id = opportunity_id and public.is_org_owner(o.organization_id)))
  with check (status in ('accepted', 'rejected'));
-- ما في insert ولا update للمتطوع مباشرة: التقديم والانسحاب بيمرّوا من الدالتين تحت،
-- عشان القواعد (متطوع بس · الفرصة مفتوحة · ما في تكرار) تنفحص على السيرفر.

-- 5) التقديم على فرصة
create or replace function public.apply_to_opportunity(
  p_opportunity_id uuid,
  p_bio text default null,
  p_available_days text[] default '{}',
  p_skills text[] default '{}'
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
      -- انسحب قبل، وبده يرجع يقدّم
      update applications
         set status = 'pending', bio = p_bio, available_days = p_available_days,
             skills = p_skills, created_at = now(), updated_at = now()
       where id = existing_id;
      return existing_id;
    end if;
    raise exception 'already_applied';
  end if;

  insert into applications (opportunity_id, volunteer_id, bio, available_days, skills)
  values (p_opportunity_id, me, p_bio, p_available_days, p_skills)
  returning id into new_id;
  return new_id;
end; $$;

-- 6) الانسحاب (بس لما يكون الطلب قيد المراجعة أو مقبول)
create or replace function public.withdraw_application(p_application_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  update applications set status = 'withdrawn', updated_at = now()
   where id = p_application_id
     and volunteer_id = auth.uid()
     and status in ('pending', 'accepted');
  if not found then raise exception 'cannot_withdraw'; end if;
end; $$;

revoke all on function public.apply_to_opportunity(uuid, text, text[], text[]) from public, anon;
revoke all on function public.withdraw_application(uuid) from public, anon;
grant execute on function public.apply_to_opportunity(uuid, text, text[], text[]) to authenticated;
grant execute on function public.withdraw_application(uuid) to authenticated;

-- 7) فرص تجريبية (للعرض بس، مربوطة بالمؤسسات التجريبية من 005)
insert into public.opportunities
  (id, organization_id, initiative_id, title, tasks, location, region, date, duration, apply_deadline,
   volunteers_needed, skills, type, compensation, is_remote, status)
values
  ('00000000-0000-4000-e000-000000000001', '00000000-0000-4000-a000-000000000002', '00000000-0000-4000-b000-000000000002',
   'مساعدة في دروس تقوية', 'مساعدة المعلمة بمتابعة الطلاب وتصحيح الواجبات.', 'مدرسة الرمال', 'مدينة غزة',
   now() + interval '3 days', '3 ساعات', current_date + 2, 4, '{"تدريس","صبر مع الأطفال"}', 'volunteer', null, false, 'open'),
  ('00000000-0000-4000-e000-000000000002', '00000000-0000-4000-a000-000000000002', null,
   'مدخل بيانات لمسح تعليمي', 'إدخال نتائج استبيان الطلاب على جدول إكسل.', 'مقر الجمعية', 'مدينة غزة',
   now() + interval '5 days', '10 أيام', current_date + 4, 6, '{"إكسل","دقة"}', 'paid', '50 ₪ يومياً', false, 'open'),
  ('00000000-0000-4000-e000-000000000003', '00000000-0000-4000-a000-000000000001', null,
   'تصميم منشورات توعوية', 'تصميم 5 منشورات عن النظافة الشخصية للأطفال.', 'عن بُعد', null,
   null, 'مرن', current_date + 7, 3, '{"تصميم","كانفا"}', 'volunteer_allowance', 'بدل مواصلات', true, 'open'),
  ('00000000-0000-4000-e000-000000000004', '00000000-0000-4000-a000-000000000001', '00000000-0000-4000-b000-000000000001',
   'تنظيم طابور الفحص', 'استقبال العائلات وتنظيم الدور يوم الفحص المجاني.', 'مدرسة خانيونس', 'خانيونس',
   now() + interval '4 days', '5 ساعات', current_date + 3, 6, '{"تنظيم فعاليات"}', 'volunteer', null, false, 'open')
on conflict (id) do nothing;

-- ===== المسح (لما تخلصي من التجربة) =====
-- delete from public.applications  where opportunity_id::text like '00000000-0000-4000-e000-%';
-- delete from public.opportunities where id::text like '00000000-0000-4000-e000-%';
