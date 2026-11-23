-- وَصْل: جداول قاعدة البيانات (انسخيها لـ Supabase → SQL Editor → Run)

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text,
  role text check (role in ('user','volunteer','organization','admin')),
  region text,
  skills text[] default '{}',
  interests text[] default '{}',
  created_at timestamptz default now()
);

-- لما ينعمل حساب جديد، بينعمل إله profile تلقائياً
create function handle_new_user() returns trigger language plpgsql security definer as $$
begin
  insert into profiles (id, full_name) values (new.id, new.raw_user_meta_data->>'full_name');
  return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

create table organizations (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references profiles not null,
  name text not null,
  bio text,
  logo_url text,
  region text,
  contact text,
  is_verified boolean default false,
  created_at timestamptz default now()
);

create table initiatives (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations not null,
  title text not null,
  description text,
  category text,
  region text,
  start_date date,
  end_date date,
  volunteers_needed int default 0,
  skills text[] default '{}',
  image_url text,
  status text default 'pending' check (status in ('pending','published','active','completed','cancelled')),
  created_at timestamptz default now()
);

create table services (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations not null,
  name text not null,
  description text,
  beneficiaries text,
  region text,
  schedule text,
  how_to_benefit text,
  status text default 'available' check (status in ('available','limited','paused','ended')),
  last_confirmed_at timestamptz default now()
);

create table needs (
  id uuid primary key default gen_random_uuid(),
  initiative_id uuid references initiatives not null,
  type text,
  description text,
  quantity_needed int default 0,
  quantity_provided int default 0,
  status text default 'open' check (status in ('open','partially_covered','fully_covered','closed'))
);

create table opportunities (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations not null,
  initiative_id uuid references initiatives,
  title text not null,
  tasks text,
  location text,
  date timestamptz,
  duration text,
  apply_deadline date,
  volunteers_needed int default 1,
  skills text[] default '{}'
);

create table applications (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid references opportunities not null,
  volunteer_id uuid references profiles not null,
  bio text,
  status text default 'pending' check (status in ('pending','accepted','rejected','withdrawn')),
  created_at timestamptz default now(),
  unique (opportunity_id, volunteer_id)
);

create table attendance (
  id uuid primary key default gen_random_uuid(),
  application_id uuid references applications not null,
  attended_at timestamptz default now(),
  hours numeric default 0,
  approved boolean default false
);

create table certificates (
  id uuid primary key default gen_random_uuid(),
  volunteer_id uuid references profiles not null,
  initiative_id uuid references initiatives not null,
  hours numeric,
  issued_at timestamptz default now()
);

create table favorites (
  user_id uuid references profiles,
  item_type text,  -- initiative / service / need / opportunity
  item_id uuid,
  primary key (user_id, item_type, item_id)
);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles not null,
  title text,
  body text,
  is_read boolean default false,
  created_at timestamptz default now()
);

create table reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references profiles,
  item_type text,
  item_id uuid,
  reason text,
  created_at timestamptz default now()
);

-- الحماية (RLS): كل واحد بيشوف ويعدّل اللي إله بس
alter table profiles enable row level security;
create policy "profile: read own" on profiles for select using (auth.uid() = id);
create policy "profile: update own" on profiles for update using (auth.uid() = id);
-- باقي الـ policies بنضيفها مع كل feature
