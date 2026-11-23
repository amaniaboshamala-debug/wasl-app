-- 010: الحضور بالـ QR · الساعات · الشهادات المصدّقة (المرحلة 7)
-- آمن تشغّليه أكتر من مرة.

-- 0) تصليح صغير: حساب الإدارة كان ممنوع يعدّل ملفه (لأنه role = admin) — هلّق ممنوع بس "يغيّر" الدور
create or replace function public.protect_profile_role() returns trigger
language plpgsql as $$
begin
  if auth.uid() is null then return new; end if;            -- لوحة Supabase والسيرفر
  if tg_op = 'UPDATE' and new.role is not distinct from old.role then return new; end if;
  if new.role is not null and new.role not in ('user', 'volunteer', 'organization') then
    raise exception 'role_change_not_allowed';
  end if;
  if tg_op = 'UPDATE' and old.role = 'admin' then raise exception 'role_change_not_allowed'; end if;
  return new;
end; $$;

-- 1) الحضور: كل جلسة إلها دخول وخروج، والساعات بتنحسب لحالها
alter table public.attendance add column if not exists check_in_at  timestamptz not null default now();
alter table public.attendance add column if not exists check_out_at timestamptz;
alter table public.attendance add column if not exists recorded_by  uuid references public.profiles;
alter table public.attendance add column if not exists method       text not null default 'qr';  -- qr · manual
alter table public.attendance drop constraint if exists attendance_application_id_fkey;
alter table public.attendance add constraint attendance_application_id_fkey
  foreign key (application_id) references public.applications on delete cascade;
create index if not exists attendance_app_idx on public.attendance (application_id);

alter table public.attendance enable row level security;
drop policy if exists "attendance: volunteer reads own" on public.attendance;
create policy "attendance: volunteer reads own" on public.attendance for select to authenticated
  using (exists (select 1 from applications a where a.id = application_id and a.volunteer_id = auth.uid()));
drop policy if exists "attendance: org reads" on public.attendance;
create policy "attendance: org reads" on public.attendance for select to authenticated
  using (exists (select 1 from applications a join opportunities o on o.id = a.opportunity_id
                  where a.id = application_id and public.is_org_owner(o.organization_id)));
-- الكتابة بالدوال تحت بس

-- بيرجّع بيانات الطلب إذا المستخدم صاحب الفرصة والطلب مقبول، وإلا خطأ
create or replace function public._org_accepted_application(p_application_id uuid)
returns table (volunteer_id uuid, volunteer_name text, opportunity_id uuid, opportunity_title text)
language plpgsql security definer set search_path = public as $$
declare org_id uuid; st text;
begin
  select a.volunteer_id, coalesce(nullif(p.full_name, ''), 'متطوع'), o.id, o.title, o.organization_id, a.status
    into volunteer_id, volunteer_name, opportunity_id, opportunity_title, org_id, st
    from applications a
    join opportunities o on o.id = a.opportunity_id
    left join profiles p on p.id = a.volunteer_id
   where a.id = p_application_id;
  if opportunity_id is null then raise exception 'application_not_found'; end if;
  if not public.is_org_owner(org_id) then raise exception 'not_your_opportunity'; end if;
  if st <> 'accepted' then raise exception 'not_accepted'; end if;
  return next;
end; $$;
revoke all on function public._org_accepted_application(uuid) from public, anon, authenticated;

-- مسح QR: أول مسحة = دخول، التانية = خروج (والساعات بتنحسب)
create or replace function public.scan_attendance(p_application_id uuid)
returns json language plpgsql security definer set search_path = public as $$
declare
  info record;
  open_id uuid;
  opened timestamptz;
  h numeric;
begin
  select * into info from public._org_accepted_application(p_application_id);

  -- جلسة مفتوحة قديمة كتير (نسيوا يسجّلوا خروج) بتنلغى
  delete from attendance
   where application_id = p_application_id and check_out_at is null and check_in_at < now() - interval '16 hours';

  select id, check_in_at into open_id, opened from attendance
   where application_id = p_application_id and check_out_at is null
   order by check_in_at desc limit 1;

  if open_id is null then
    insert into attendance (application_id, check_in_at, hours, approved, recorded_by, method)
    values (p_application_id, now(), 0, false, auth.uid(), 'qr');
    return json_build_object('action', 'in', 'name', info.volunteer_name, 'opportunity', info.opportunity_title, 'hours', 0);
  end if;

  if now() - opened < interval '2 minutes' then raise exception 'just_checked_in'; end if;
  h := round(least(extract(epoch from now() - opened) / 3600.0, 12)::numeric, 1);
  update attendance set check_out_at = now(), hours = h, approved = true, attended_at = opened where id = open_id;
  return json_build_object('action', 'out', 'name', info.volunteer_name, 'opportunity', info.opportunity_title, 'hours', h);
end; $$;
revoke all on function public.scan_attendance(uuid) from public, anon;
grant execute on function public.scan_attendance(uuid) to authenticated;

-- تسجيل ساعات بالإيد (لما ما في كاميرا أو نسيوا يمسحوا)
create or replace function public.record_hours(p_application_id uuid, p_hours numeric)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._org_accepted_application(p_application_id);
  if p_hours is null or p_hours <= 0 or p_hours > 24 then raise exception 'invalid_hours'; end if;
  insert into attendance (application_id, check_in_at, check_out_at, hours, approved, recorded_by, method)
  values (p_application_id, now(), now(), round(p_hours, 1), true, auth.uid(), 'manual');
end; $$;
revoke all on function public.record_hours(uuid, numeric) from public, anon;
grant execute on function public.record_hours(uuid, numeric) to authenticated;

-- 2) الشهادات: وحدة لكل متطوع على كل فرصة، وإلها كود تحقق
alter table public.certificates alter column initiative_id drop not null;
alter table public.certificates add column if not exists application_id uuid references public.applications on delete cascade;
alter table public.certificates add column if not exists opportunity_id uuid references public.opportunities on delete set null;
alter table public.certificates add column if not exists organization_id uuid references public.organizations on delete set null;
alter table public.certificates add column if not exists code text;
alter table public.certificates add column if not exists title text;
alter table public.certificates add column if not exists org_name text;
alter table public.certificates add column if not exists issuer text;
alter table public.certificates add column if not exists volunteer_name text;
create unique index if not exists certificates_application_uq on public.certificates (application_id);
create unique index if not exists certificates_code_uq on public.certificates (code);

alter table public.certificates enable row level security;
drop policy if exists "certificate: volunteer reads own" on public.certificates;
create policy "certificate: volunteer reads own" on public.certificates for select to authenticated
  using (volunteer_id = auth.uid());
drop policy if exists "certificate: org reads" on public.certificates;
create policy "certificate: org reads" on public.certificates for select to authenticated
  using (organization_id is not null and public.is_org_owner(organization_id));

create or replace function public.issue_certificate(p_application_id uuid)
returns text language plpgsql security definer set search_path = public as $$
declare
  info record;
  total numeric;
  opp record;
  existing text;
  new_code text;
begin
  select * into info from public._org_accepted_application(p_application_id);
  select o.offers_certificate, o.certificate_issuer, o.organization_id, g.name as org_name
    into opp from opportunities o join organizations g on g.id = o.organization_id where o.id = info.opportunity_id;
  if not coalesce(opp.offers_certificate, false) then raise exception 'no_certificate_offered'; end if;

  select coalesce(sum(hours), 0) into total from attendance where application_id = p_application_id and approved;
  if total <= 0 then raise exception 'no_hours_yet'; end if;

  select code into existing from certificates where application_id = p_application_id;
  if existing is not null then
    update certificates set hours = total, issued_at = now() where application_id = p_application_id;
    return existing;
  end if;

  loop
    new_code := 'WSL-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 4))
                || '-' || upper(substr(md5(random()::text), 1, 4));
    exit when not exists (select 1 from certificates where code = new_code);
  end loop;

  insert into certificates (volunteer_id, application_id, opportunity_id, organization_id, code, title,
                            org_name, issuer, volunteer_name, hours, issued_at)
  values (info.volunteer_id, p_application_id, info.opportunity_id, opp.organization_id, new_code,
          info.opportunity_title, opp.org_name, nullif(opp.certificate_issuer, ''), info.volunteer_name, total, now());

  insert into notifications (user_id, title, body, type, link)
  values (info.volunteer_id, 'وصلتك شهادة تطوع 📜',
          'شهادة على «' || info.opportunity_title || '» من ' || opp.org_name || ' (' || total || ' ساعة).',
          'certificate', '/my-record');
  return new_code;
end; $$;
revoke all on function public.issue_certificate(uuid) from public, anon;
grant execute on function public.issue_certificate(uuid) to authenticated;

-- أي حدا (حتى بدون حساب) بيقدر يتأكد إنه الشهادة حقيقية من كودها
create or replace function public.verify_certificate(p_code text)
returns json language sql stable security definer set search_path = public as $$
  select json_build_object('name', volunteer_name, 'title', title, 'org', org_name, 'issuer', issuer,
                           'hours', hours, 'issued_at', issued_at)
    from certificates where code = upper(trim(p_code));
$$;
grant execute on function public.verify_certificate(text) to anon, authenticated;
