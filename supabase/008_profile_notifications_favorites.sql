-- وَصْل 008: حسابي · الإشعارات · المفضلة
-- انسخيه لـ Supabase → SQL Editor → Run (بيتشغّل أكتر من مرة بدون مشاكل)

-- 1) معلومات إضافية بالملف الشخصي
alter table public.profiles add column if not exists phone text;
alter table public.profiles add column if not exists bio text;

-- 2) الإشعارات: نوع ورابط (عشان لما تنضغط تفتح الشاشة الصح)
alter table public.notifications add column if not exists type text;
alter table public.notifications add column if not exists link text;

alter table public.notifications enable row level security;

drop policy if exists "notification: read own" on public.notifications;
create policy "notification: read own" on public.notifications
  for select to authenticated using (user_id = auth.uid());

-- المستخدم بيقدر يعلّم إشعاراته "مقروءة" ويحذفها، بس ما بيقدر يعمل إشعارات (هاي بتعملها المراقبات تحت)
drop policy if exists "notification: update own" on public.notifications;
create policy "notification: update own" on public.notifications
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "notification: delete own" on public.notifications;
create policy "notification: delete own" on public.notifications
  for delete to authenticated using (user_id = auth.uid());

create index if not exists notifications_user_idx on public.notifications (user_id, created_at desc);

-- 3) إشعارات تلقائية على الطلبات
create or replace function public.notify_on_application()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  opp_title text;
  org_owner uuid;
  volunteer_name text;
begin
  select o.title, g.owner_id into opp_title, org_owner
    from opportunities o join organizations g on g.id = o.organization_id
   where o.id = new.opportunity_id;
  select coalesce(nullif(full_name, ''), 'متطوع') into volunteer_name from profiles where id = new.volunteer_id;

  -- طلب جديد (أو رجع قدّم بعد ما انسحب) ← للمؤسسة
  if (tg_op = 'INSERT' and new.status = 'pending')
     or (tg_op = 'UPDATE' and old.status = 'withdrawn' and new.status = 'pending') then
    insert into notifications (user_id, title, body, type, link)
    values (org_owner, 'طلب تطوع جديد', volunteer_name || ' قدّم على «' || opp_title || '»', 'new_application', '/org/requests');
  end if;

  if tg_op = 'UPDATE' and new.status is distinct from old.status then
    -- انقبل ← للمتطوع
    if new.status = 'accepted' then
      insert into notifications (user_id, title, body, type, link)
      values (new.volunteer_id, 'انقبل طلبك 🎉', 'المؤسسة قبلتك على «' || opp_title || '». رح يتواصلوا معك بالتفاصيل.',
              'accepted', '/opportunity/' || new.opportunity_id);
    -- انرفض ← للمتطوع
    elsif new.status = 'rejected' then
      insert into notifications (user_id, title, body, type, link)
      values (new.volunteer_id, 'تحديث على طلبك', 'للأسف ما انقبل طلبك على «' || opp_title || '». في فرص تانية بتستناك 🤍',
              'rejected', '/opportunities');
    -- انسحب ← للمؤسسة
    elsif new.status = 'withdrawn' and old.status in ('pending', 'accepted') then
      insert into notifications (user_id, title, body, type, link)
      values (org_owner, 'متطوع انسحب', volunteer_name || ' انسحب من «' || opp_title || '»', 'withdrawn', '/org/requests');
    end if;
  end if;
  return new;
end; $$;

drop trigger if exists notify_on_application on public.applications;
create trigger notify_on_application
  after insert or update of status on public.applications
  for each row execute function public.notify_on_application();

-- 4) المفضلة: كل واحد بيدير مفضلته بس
alter table public.favorites enable row level security;
alter table public.favorites drop constraint if exists favorites_item_type_check;
alter table public.favorites add constraint favorites_item_type_check
  check (item_type in ('initiative', 'service', 'need', 'opportunity'));

drop policy if exists "favorite: own" on public.favorites;
create policy "favorite: own" on public.favorites
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 5) شهادة تطوع مصدّقة: هل الفرصة أو المبادرة بتعطي شهادة، ومين بيصدّقها
alter table public.opportunities add column if not exists offers_certificate boolean not null default false;
alter table public.opportunities add column if not exists certificate_issuer text;
alter table public.initiatives  add column if not exists offers_certificate boolean not null default false;
alter table public.initiatives  add column if not exists certificate_issuer text;

-- البيانات التجريبية: بعضها فيه شهادة وبعضها لأ
update public.opportunities set offers_certificate = true, certificate_issuer = 'جمعية نور للتعليم'
 where id = '00000000-0000-4000-e000-000000000001';
update public.opportunities set offers_certificate = true
 where id = '00000000-0000-4000-e000-000000000004';
update public.initiatives set offers_certificate = true, certificate_issuer = 'وزارة التنمية الاجتماعية'
 where id = '00000000-0000-4000-b000-000000000002';
