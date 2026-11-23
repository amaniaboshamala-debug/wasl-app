-- وَصْل 004: شاشة الرئيسية واستكشف (مبادرات · خدمات · احتياجات)
-- انسخيه لـ Supabase → SQL Editor → Run

-- 1) تصنيف للخدمة (صحة، تعليم، دعم نفسي...) عشان أزرار التصفية
alter table public.services add column if not exists category text;

-- 2) الحماية (RLS): أي حدا مسجّل دخول بيقدر يقرأ، والتعديل بس لصاحب المؤسسة
alter table public.organizations enable row level security;
alter table public.initiatives  enable row level security;
alter table public.services     enable row level security;
alter table public.needs        enable row level security;

-- المؤسسات: الكل بيشوفها، وصاحبها بس بيعدّلها
drop policy if exists "org: read all" on public.organizations;
create policy "org: read all" on public.organizations
  for select to authenticated using (true);

drop policy if exists "org: owner manage" on public.organizations;
create policy "org: owner manage" on public.organizations
  for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- دالة صغيرة: هل المستخدم الحالي صاحب هاي المؤسسة؟
create or replace function public.is_org_owner(org uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from organizations where id = org and owner_id = auth.uid());
$$;

-- المبادرات: المنشورة بس بتطلع للناس، والمؤسسة بتشوف كل مبادراتها (حتى اللي لسا قيد المراجعة)
drop policy if exists "initiative: read published" on public.initiatives;
create policy "initiative: read published" on public.initiatives
  for select to authenticated
  using (status in ('published','active','completed') or public.is_org_owner(organization_id));

drop policy if exists "initiative: owner manage" on public.initiatives;
create policy "initiative: owner manage" on public.initiatives
  for all to authenticated
  using (public.is_org_owner(organization_id)) with check (public.is_org_owner(organization_id));

-- الخدمات: الكل بيشوفها، وصاحب المؤسسة بس بيعدّلها
drop policy if exists "service: read all" on public.services;
create policy "service: read all" on public.services
  for select to authenticated using (true);

drop policy if exists "service: owner manage" on public.services;
create policy "service: owner manage" on public.services
  for all to authenticated
  using (public.is_org_owner(organization_id)) with check (public.is_org_owner(organization_id));

-- الاحتياجات: بتطلع إذا المبادرة تبعها ظاهرة
drop policy if exists "need: read visible" on public.needs;
create policy "need: read visible" on public.needs
  for select to authenticated
  using (exists (select 1 from initiatives i where i.id = initiative_id));

drop policy if exists "need: owner manage" on public.needs;
create policy "need: owner manage" on public.needs
  for all to authenticated
  using (exists (select 1 from initiatives i where i.id = initiative_id and public.is_org_owner(i.organization_id)))
  with check (exists (select 1 from initiatives i where i.id = initiative_id and public.is_org_owner(i.organization_id)));
