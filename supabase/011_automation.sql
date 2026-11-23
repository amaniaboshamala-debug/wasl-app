-- 011: الأتمتة (المرحلة 8): إشعارات مطابقة + تذكيرات يومية
-- آمن تشغّليه أكتر من مرة.

-- هل المنطقة بتناسب؟ ('*' أو فاضية = كل المناطق)
create or replace function public._region_fits(item_region text, user_region text)
returns boolean language sql immutable as $$
  select coalesce(nullif(item_region, ''), '*') = '*' or item_region = user_region;
$$;

-- 1) فرصة جديدة ← للمتطوعين بنفس المنطقة (أو عن بُعد) واللي مهاراتهم بتناسب
create or replace function public.notify_matching_opportunity()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner uuid;
begin
  if new.status <> 'open' then return new; end if;
  select owner_id into owner from organizations where id = new.organization_id;
  insert into notifications (user_id, title, body, type, link)
  select p.id, 'فرصة بتناسبك ✨', '«' || new.title || '»' ||
           case when new.is_remote then ' (عن بُعد)' when coalesce(new.region, '') not in ('', '*') then ' في ' || new.region else '' end,
         'match', '/opportunity/' || new.id
    from profiles p
   where p.role = 'volunteer' and p.id <> owner
     and (new.is_remote or public._region_fits(new.region, p.region))
     and (cardinality(coalesce(new.skills, '{}')) = 0 or p.skills && new.skills)
   limit 300;
  return new;
end; $$;
drop trigger if exists notify_matching_opportunity on public.opportunities;
create trigger notify_matching_opportunity after insert on public.opportunities
  for each row execute function public.notify_matching_opportunity();

-- 2) مبادرة انتشرت (فوراً أو بعد موافقة الإدارة) ← للناس بنفس المنطقة
create or replace function public.notify_new_initiative()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner uuid;
begin
  if new.status <> 'published' then return new; end if;
  if tg_op = 'UPDATE' and old.status is not distinct from new.status then return new; end if;
  select owner_id into owner from organizations where id = new.organization_id;
  insert into notifications (user_id, title, body, type, link)
  select p.id, 'مبادرة جديدة قريبة منك 🌱', '«' || new.title || '»' ||
           case when coalesce(new.region, '') not in ('', '*') then ' في ' || new.region else '' end,
         'match', '/initiative/' || new.id
    from profiles p
   where p.role in ('volunteer', 'user') and p.id <> owner
     and p.region is not null and public._region_fits(new.region, p.region)
   limit 300;
  return new;
end; $$;
drop trigger if exists notify_new_initiative on public.initiatives;
create trigger notify_new_initiative after insert or update of status on public.initiatives
  for each row execute function public.notify_new_initiative();

-- 3) احتياج جديد ← للي حافظين المبادرة بالمفضلة
create or replace function public.notify_new_need()
returns trigger language plpgsql security definer set search_path = public as $$
declare t text;
begin
  select title into t from initiatives where id = new.initiative_id and status in ('published', 'active');
  if t is null then return new; end if;
  insert into notifications (user_id, title, body, type, link)
  select f.user_id, 'احتياج جديد بمبادرة بتتابعيها', '«' || t || '» محتاجة: ' || coalesce(new.type, 'مساعدة'),
         'need', '/initiative/' || new.initiative_id
    from favorites f
   where f.item_type = 'initiative' and f.item_id = new.initiative_id;
  return new;
end; $$;
drop trigger if exists notify_new_need on public.needs;
create trigger notify_new_need after insert on public.needs
  for each row execute function public.notify_new_need();

-- 4) خدمة تغيّرت حالتها ← للي حافظينها
create or replace function public.notify_service_status()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is not distinct from old.status then return new; end if;
  insert into notifications (user_id, title, body, type, link)
  select f.user_id, 'تحديث على خدمة بتتابعيها',
         '«' || new.name || '» ' || case new.status
           when 'available' then 'رجعت متاحة ✅' when 'limited' then 'صارت محدودة'
           when 'paused' then 'متوقفة مؤقتاً' else 'انتهت' end,
         'service', '/service/' || new.id
    from favorites f
   where f.item_type = 'service' and f.item_id = new.id;
  return new;
end; $$;
drop trigger if exists notify_service_status on public.services;
create trigger notify_service_status after update of status on public.services
  for each row execute function public.notify_service_status();

-- 5) التذكيرات اليومية (كل يوم 7 المسا بتوقيت غزة)
create or replace function public.daily_reminders()
returns void language plpgsql security definer set search_path = public as $$
declare today date := (now() at time zone 'Asia/Hebron')::date;
begin
  -- أ) للمتطوع: فرصتك بكرا
  insert into notifications (user_id, title, body, type, link)
  select a.volunteer_id, 'تذكير: فرصتك بكرا ⏰',
         '«' || o.title || '»' || coalesce(' · ' || nullif(o.location, ''), '') ||
         ' · الساعة ' || to_char(o.date at time zone 'Asia/Hebron', 'HH24:MI'),
         'reminder', '/opportunity/' || o.id
    from applications a join opportunities o on o.id = a.opportunity_id
   where a.status = 'accepted'
     and (o.date at time zone 'Asia/Hebron')::date = today + 1
     and not exists (select 1 from notifications n where n.user_id = a.volunteer_id
                       and n.type = 'reminder' and n.link = '/opportunity/' || o.id);

  -- ب) للمؤسسة: الفرصة خلصت ولسا ما سجّلتي ساعات المتطوعين
  insert into notifications (user_id, title, body, type, link)
  select g.owner_id, 'سجّلي ساعات المتطوعين 🕒',
         'فرصة «' || o.title || '» خلصت. سجّلي حضورهم عشان تنحسبلهم الساعات' ||
           case when o.offers_certificate then ' وتطلعلهم الشهادات.' else '.' end,
         'log_hours', '/org/requests'
    from opportunities o join organizations g on g.id = o.organization_id
   where (o.date at time zone 'Asia/Hebron')::date between today - 3 and today - 1
     and exists (select 1 from applications a where a.opportunity_id = o.id and a.status = 'accepted'
                   and not exists (select 1 from attendance t where t.application_id = a.id and t.approved))
     and not exists (select 1 from notifications n where n.user_id = g.owner_id and n.type = 'log_hours'
                       and n.body like '%«' || o.title || '»%' and n.created_at > now() - interval '7 days');

  -- ج) للمؤسسة: أكّدي إنه الخدمة لسا شغّالة (كل شهر)
  insert into notifications (user_id, title, body, type, link)
  select g.owner_id, 'خدمتك لسا متاحة؟',
         'صارلها شهر ما تأكدت: «' || s.name || '». أكّديها عشان الناس توثق فيها.',
         'confirm_service', '/org/initiatives'
    from services s join organizations g on g.id = s.organization_id
   where s.status in ('available', 'limited')
     and s.last_confirmed_at < now() - interval '30 days'
     and not exists (select 1 from notifications n where n.user_id = g.owner_id and n.type = 'confirm_service'
                       and n.body like '%«' || s.name || '»%' and n.created_at > now() - interval '30 days');

  -- د) تنظيف: إشعارات مقروءة أقدم من 3 شهور
  delete from notifications where is_read and created_at < now() - interval '90 days';
end; $$;
revoke all on function public.daily_reminders() from public, anon, authenticated;

select cron.schedule('wasl-daily-reminders', '0 17 * * *', 'select public.daily_reminders()');
