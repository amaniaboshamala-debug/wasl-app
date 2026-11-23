-- وَصْل 009: المؤسسة بتنشر مبادرات وخدمات واحتياجات · "بقدر أوفّر هاد" · لوحة الإدارة · البلاغات
-- انسخيه لـ Supabase → SQL Editor → Run (بيتشغّل أكتر من مرة بدون مشاكل)

-- ========== 1) الإدارة ==========
-- حساب الإدارة: بتغيّري role لحسابك لـ 'admin' من Table Editor → profiles (من التطبيق ممنوع)
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin');
$$;

-- الإدارة بتشوف المبادرات اللي لسا قيد المراجعة
drop policy if exists "initiative: read published" on public.initiatives;
create policy "initiative: read published" on public.initiatives
  for select to authenticated
  using (status in ('published','active','completed') or public.is_org_owner(organization_id) or public.is_admin());

-- مبادرة جديدة من مؤسسة موثّقة بتنزل فوراً، ومن غير موثّقة بتستنى موافقة الإدارة
create or replace function public.initiative_initial_status()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() then return new; end if;
  new.status := case
    when exists (select 1 from organizations where id = new.organization_id and is_verified) then 'published'
    else 'pending' end;
  return new;
end; $$;

drop trigger if exists initiative_initial_status on public.initiatives;
create trigger initiative_initial_status
  before insert on public.initiatives
  for each row execute function public.initiative_initial_status();

-- المؤسسة ما بتقدر تنشر مبادرة بنفسها إذا لسا قيد المراجعة (بتقدر تلغيها أو تخلّصها بس)
create or replace function public.protect_initiative_status()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() or auth.uid() is null then return new; end if;
  if old.status = 'pending' and new.status not in ('pending', 'cancelled') then
    raise exception 'initiative_needs_review';
  end if;
  return new;
end; $$;

drop trigger if exists protect_initiative_status on public.initiatives;
create trigger protect_initiative_status
  before update of status on public.initiatives
  for each row execute function public.protect_initiative_status();

-- الإدارة بتشوف أسماء الناس (عشان البلاغات)
drop policy if exists "profile: admin read" on public.profiles;
create policy "profile: admin read" on public.profiles
  for select to authenticated using (public.is_admin());

-- أوامر الإدارة
create or replace function public.admin_verify_org(p_org_id uuid, p_verified boolean)
returns void language plpgsql security definer set search_path = public as $$
declare owner uuid;
begin
  if not public.is_admin() then raise exception 'admins_only'; end if;
  update organizations set is_verified = p_verified where id = p_org_id returning owner_id into owner;
  if p_verified and owner is not null then
    insert into notifications (user_id, title, body, type, link)
    values (owner, 'مؤسستك صارت موثّقة ✓', 'مبروك! العلامة الخضرا صارت تطلع جنب اسم مؤسستك.', 'org_verified', '/org');
  end if;
end; $$;

create or replace function public.admin_set_initiative_status(p_initiative_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare owner uuid; ttl text;
begin
  if not public.is_admin() then raise exception 'admins_only'; end if;
  update initiatives i set status = p_status where i.id = p_initiative_id returning i.title into ttl;
  select g.owner_id into owner from initiatives i join organizations g on g.id = i.organization_id
   where i.id = p_initiative_id;
  if owner is not null then
    insert into notifications (user_id, title, body, type, link)
    values (owner,
            case when p_status = 'published' then 'انتشرت مبادرتك 🎉' else 'تحديث على مبادرتك' end,
            case when p_status = 'published' then '«' || ttl || '» صارت ظاهرة للناس.'
                 else '«' || ttl || '» ما انقبلت للنشر. تواصلي مع فريق وَصْل للتفاصيل.' end,
            'initiative_review', '/org/initiatives');
  end if;
end; $$;

revoke all on function public.admin_verify_org(uuid, boolean) from public, anon;
revoke all on function public.admin_set_initiative_status(uuid, text) from public, anon;
grant execute on function public.admin_verify_org(uuid, boolean) to authenticated;
grant execute on function public.admin_set_initiative_status(uuid, text) to authenticated;

-- ========== 2) البلاغات ==========
alter table public.reports add column if not exists status text not null default 'open';
alter table public.reports enable row level security;

drop policy if exists "report: insert own" on public.reports;
create policy "report: insert own" on public.reports
  for insert to authenticated with check (reporter_id = auth.uid());

drop policy if exists "report: admin read" on public.reports;
create policy "report: admin read" on public.reports
  for select to authenticated using (public.is_admin());

drop policy if exists "report: admin update" on public.reports;
create policy "report: admin update" on public.reports
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- ========== 3) الاحتياجات: "بقدر أوفّر هاد" ==========
create table if not exists public.need_offers (
  id uuid primary key default gen_random_uuid(),
  need_id uuid not null references public.needs on delete cascade,
  user_id uuid not null references public.profiles,
  quantity int not null default 1 check (quantity > 0),
  note text,
  phone text,
  status text not null default 'pending' check (status in ('pending', 'received', 'declined')),
  created_at timestamptz not null default now()
);

alter table public.need_offers enable row level security;

create or replace function public.is_need_owner(p_need_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from needs n join initiatives i on i.id = n.initiative_id
    where n.id = p_need_id and public.is_org_owner(i.organization_id));
$$;

drop policy if exists "need offer: read own or owner" on public.need_offers;
create policy "need offer: read own or owner" on public.need_offers
  for select to authenticated using (user_id = auth.uid() or public.is_need_owner(need_id));

-- المؤسسة بتشوف اسم ومنطقة اللي عرضوا يوفّروا لاحتياجاتها
drop policy if exists "profile: org reads need offerers" on public.profiles;
create policy "profile: org reads need offerers" on public.profiles
  for select to authenticated
  using (exists (select 1 from need_offers o where o.user_id = profiles.id and public.is_need_owner(o.need_id)));

-- العرض بيمرّ من دالة (بتفحص إنه الاحتياج لسا مفتوح)
create or replace function public.offer_need(p_need_id uuid, p_quantity int, p_note text default null, p_phone text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare st text; new_id uuid;
begin
  if auth.uid() is null then raise exception 'not_signed_in'; end if;
  select status into st from needs where id = p_need_id;
  if st is null then raise exception 'need_not_found'; end if;
  if st in ('fully_covered', 'closed') then raise exception 'need_closed'; end if;
  insert into need_offers (need_id, user_id, quantity, note, phone)
  values (p_need_id, auth.uid(), greatest(p_quantity, 1), p_note, p_phone)
  returning id into new_id;
  return new_id;
end; $$;

-- المؤسسة: "استلمنا" (بيزيد المتوفّر لحاله) أو "ما بنحتاجها"
create or replace function public.decide_need_offer(p_offer_id uuid, p_received boolean)
returns void language plpgsql security definer set search_path = public as $$
declare o record;
begin
  select * into o from need_offers where id = p_offer_id;
  if o.id is null then raise exception 'offer_not_found'; end if;
  if not public.is_need_owner(o.need_id) then raise exception 'not_your_need'; end if;
  if o.status <> 'pending' then return; end if;

  update need_offers set status = case when p_received then 'received' else 'declined' end where id = p_offer_id;
  if p_received then
    update needs set
      quantity_provided = quantity_provided + o.quantity,
      status = case when quantity_provided + o.quantity >= quantity_needed then 'fully_covered' else 'partially_covered' end
    where id = o.need_id;
  end if;
end; $$;

revoke all on function public.offer_need(uuid, int, text, text) from public, anon;
revoke all on function public.decide_need_offer(uuid, boolean) from public, anon;
grant execute on function public.offer_need(uuid, int, text, text) to authenticated;
grant execute on function public.decide_need_offer(uuid, boolean) to authenticated;

-- إشعارات العروض
create or replace function public.notify_on_need_offer()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner uuid; need_type text; who text;
begin
  select g.owner_id, n.type into owner, need_type
    from needs n join initiatives i on i.id = n.initiative_id join organizations g on g.id = i.organization_id
   where n.id = new.need_id;
  if tg_op = 'INSERT' then
    select coalesce(nullif(full_name, ''), 'حدا') into who from profiles where id = new.user_id;
    insert into notifications (user_id, title, body, type, link)
    values (owner, 'عرض مساعدة جديد 🤝', who || ' بقدر يوفّر ' || new.quantity || ' من «' || need_type || '»', 'need_offer', '/org/initiatives');
  elsif new.status = 'received' and old.status = 'pending' then
    insert into notifications (user_id, title, body, type, link)
    values (new.user_id, 'شكراً إلك 🤍', 'المؤسسة استلمت مساهمتك بـ «' || need_type || '».', 'need_received', null);
  end if;
  return new;
end; $$;

drop trigger if exists notify_on_need_offer on public.need_offers;
create trigger notify_on_need_offer
  after insert or update of status on public.need_offers
  for each row execute function public.notify_on_need_offer();
