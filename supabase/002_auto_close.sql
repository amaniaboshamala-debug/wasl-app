-- وَصْل 002: إغلاق الفرص تلقائياً
-- open = مفتوحة · full = مكتملة · expired = منتهية · closed = سكّرتها المؤسسة

-- 1) خانة الحالة
alter table public.opportunities add column if not exists status text not null default 'open';
alter table public.opportunities drop constraint if exists opportunities_status_check;
alter table public.opportunities add constraint opportunities_status_check
  check (status in ('open','full','expired','closed'));

-- 2) المراقب: لما يكتمل عدد المقبولين بتصير مكتملة، ولو حدا انسحب بترجع مفتوحة
create or replace function public.sync_opportunity_capacity()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  accepted_count int;
  needed int;
begin
  select count(*) into accepted_count
    from applications where opportunity_id = new.opportunity_id and status = 'accepted';
  select volunteers_needed into needed from opportunities where id = new.opportunity_id;

  if accepted_count >= needed then
    update opportunities set status = 'full'
      where id = new.opportunity_id and status = 'open';
  else
    update opportunities set status = 'open'
      where id = new.opportunity_id and status = 'full'
        and (apply_deadline is null or apply_deadline >= (now() at time zone 'Asia/Hebron')::date);
  end if;
  return new;
end; $$;

drop trigger if exists on_application_status_change on public.applications;
create trigger on_application_status_change
  after insert or update of status on public.applications
  for each row execute function public.sync_opportunity_capacity();

-- 3) المنبّه: كل ساعة، الفرص اللي عدّى موعد التقديم تبعها بتصير منتهية
create extension if not exists pg_cron;

create or replace function public.expire_opportunities()
returns void language sql security definer set search_path = public as $$
  update opportunities set status = 'expired'
   where status in ('open','full')
     and apply_deadline < (now() at time zone 'Asia/Hebron')::date;
$$;

select cron.schedule('expire-opportunities', '0 * * * *', 'select public.expire_opportunities()');
select public.expire_opportunities();
