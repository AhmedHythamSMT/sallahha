-- Sallahha FieldOps — Supabase schema (Postgres), idempotent + trigger-based.
-- Paste into Supabase → SQL editor and run. Safe to re-run.
-- Optionally disable "Email confirmations" in Auth settings for instant sign-in;
-- the app also works with confirmations enabled (it asks the new user to confirm).
--
-- Replaces the mock backend (lib/core/backend/mock_backend.dart) when
-- SUPABASE_URL + SUPABASE_ANON_KEY are present in `.env`.
--
-- NOTE: RLS policies never reference NEW/OLD (Supabase on this project rejects
-- them). Service-request mutation rules live in the service_requests_guard
-- BEFORE UPDATE trigger instead.

-- ── 1. Profiles (extends auth.users) ────────────────────────────────
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  name       text not null default '',
  phone      text not null default '',
  role       text not null default 'customer' check (role in ('customer','technician','supervisor','admin')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles_read_all" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_insert_self" on public.profiles;
-- Any signed-in user can read profiles (nav needs tech names).
create policy "profiles_read_all"
  on public.profiles for select using (auth.role() = 'authenticated');
-- Users edit only their own row.
create policy "profiles_update_own"
  on public.profiles for update using (auth.uid() = id);
-- Belt-and-braces: the trigger below normally inserts the row; this
-- policy allows the app to write it directly if the trigger is removed.
create policy "profiles_insert_self"
  on public.profiles for insert with check (auth.uid() = id);

-- Auto-create a profile row on sign-up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, phone, role)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', ''), coalesce(new.raw_user_meta_data ->> 'phone', ''), coalesce(new.raw_user_meta_data ->> 'role', 'customer'))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── 2. Static catalogs ──────────────────────────────────────────────
create table if not exists public.services (
  id          text primary key,
  code        text not null default '',
  name_ar     text not null,
  name_en     text not null,
  sla_hours   int not null default 24
);
alter table public.services enable row level security;
drop policy if exists "services_read" on public.services;
create policy "services_read" on public.services for select using (auth.role() = 'authenticated');

create table if not exists public.parts (
  id        text primary key,
  name_ar   text not null,
  name_en   text not null,
  price_egp int not null default 0
);
alter table public.parts enable row level security;
drop policy if exists "parts_read" on public.parts;
create policy "parts_read" on public.parts for select using (auth.role() = 'authenticated');

insert into public.services (id, code, name_ar, name_en, sla_hours) values
  ('svc-ac-repair',   'AC-REP',   'تصليح تكييف', 'AC Repair',     24),
  ('svc-ac-install',  'AC-INS',   'تركيب تكييف', 'AC Installation', 48),
  ('svc-ac-cleaning', 'AC-CLN',   'تنظيف تكييف', 'AC Cleaning',   24),
  ('svc-ac-gas',      'AC-GAS',   'شحن فريون',   'AC Gas Refill', 24)
on conflict (id) do nothing;

insert into public.parts (id, name_ar, name_en, price_egp) values
  ('part-capacitor', 'مكثف',        'Capacitor',   650),
  ('part-filter',    'فلتر',        'Air Filter',  350),
  ('part-freon',     'فريون',       'Freon (kg)',  400),
  ('part-thermostat','ثيرموستات',   'Thermostat',  900),
  ('part-fan-motor', 'موتور مروحة', 'Fan Motor',  1800),
  ('part-remote',    'ريموت',       'Remote',      250)
on conflict (id) do nothing;

-- ── 3. Service requests (trigger-enforced mutations) ────────────────
-- NOTE: no NEW/OLD inside RLS policies; all mutation rules live in the
-- security definer BEFORE UPDATE trigger service_requests_guard.
create table if not exists public.service_requests (
  id              text primary key,          -- client-generated UUID
  customer_id     uuid not null references auth.users (id),
  service_id      text not null references public.services (id),
  description     text not null,
  address         text not null,
  governorate     text not null,
  phone           text not null,
  photo_local_path text,
  priority        text not null default 'normal',
  status          text not null default 'new',
  sla_due_at      timestamptz,
  estimate_egp    int,
  confirmed       boolean not null default false,
  idempotency_key text not null unique,      -- dedupe offline creates
  version         int not null default 1,    -- optimistic concurrency
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

alter table public.service_requests enable row level security;

drop policy if exists "sr_read_mine" on public.service_requests;
drop policy if exists "sr_insert_customer" on public.service_requests;
drop policy if exists "sr_update_staff" on public.service_requests;
drop policy if exists "sr_update_technician" on public.service_requests;
drop policy if exists "sr_update_customer" on public.service_requests;
-- Read: owner + staff (technicians/supervisors/admins).
create policy "sr_read_mine" on public.service_requests for select
  using (customer_id = auth.uid() or auth.uid() in (select id from profiles where role in ('technician','supervisor','admin')));
-- Create: customers only, own rows only.
create policy "sr_insert_customer" on public.service_requests for insert
  with check (customer_id = auth.uid());
-- Update gates are simple USING-only; value rules enforced in the trigger.
create policy "sr_update_staff" on public.service_requests for update
  using (auth.uid() in (select id from profiles where role in ('supervisor','admin')));
create policy "sr_update_technician" on public.service_requests for update
  using (auth.uid() in (select id from profiles where role = 'technician'));
create policy "sr_update_customer" on public.service_requests for update
  using (customer_id = auth.uid());

create or replace function public.service_requests_guard()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_role text;
begin
  -- customer_id is immutable for everyone.
  if new.customer_id is distinct from old.customer_id then
    raise exception 'customer_id cannot be changed';
  end if;
  select role into v_role from public.profiles p where p.id = auth.uid();
  if v_role is null then
    raise exception 'no profile for current user';
  end if;
  -- Supervisors/admins: any legitimate change.
  if v_role in ('supervisor','admin') then
    new.updated_at := now();
    return new;
  end if;
  -- Technicians: status bump (requires version+1) OR estimate-only.
  if v_role = 'technician' then
    if new.confirmed is distinct from old.confirmed then
      raise exception 'technician cannot change confirmed';
    end if;
    if new.status is distinct from old.status then
      if new.priority is distinct from old.priority
         or new.estimate_egp is distinct from old.estimate_egp then
        raise exception 'technician must keep priority and estimate when changing status';
      end if;
      if new.version <> old.version + 1 then
        raise exception 'technician status change must bump version by 1';
      end if;
      new.updated_at := now();
      return new;
    end if;
    if new.estimate_egp is distinct from old.estimate_egp then
      if new.priority is distinct from old.priority then
        raise exception 'technician may only change the estimate';
      end if;
      if new.version <> old.version then
        raise exception 'estimate-only change must keep version';
      end if;
      new.updated_at := now();
      return new;
    end if;
    raise exception 'technician unauthorized change';
  end if;
  -- Customers: confirm a completed request only.
  if v_role = 'customer' then
    if new.confirmed and not old.confirmed
       and new.status is not distinct from old.status
       and new.priority is not distinct from old.priority
       and new.estimate_egp is not distinct from old.estimate_egp
       and new.version = old.version then
      new.updated_at := now();
      return new;
    end if;
    raise exception 'customer may only confirm a completed request';
  end if;
  raise exception 'unauthorized update';
end;
$$;
drop trigger if exists service_requests_guard on public.service_requests;
create trigger service_requests_guard
  before update on public.service_requests
  for each row execute function public.service_requests_guard();

-- ── 4. Assignments, timeline, notes, photos, parts, ratings ─────────
create table if not exists public.job_assignments (
  id            text primary key,
  request_id    text not null references public.service_requests (id) on delete cascade,
  technician_id uuid not null references auth.users (id),
  assigned_by   uuid not null references auth.users (id),
  created_at    timestamptz not null default now()
);
alter table public.job_assignments enable row level security;
drop policy if exists "ja_read" on public.job_assignments;
drop policy if exists "ja_insert" on public.job_assignments;
create policy "ja_read"  on public.job_assignments for select using (auth.role() = 'authenticated');
create policy "ja_insert" on public.job_assignments for insert
  with check (auth.uid() in (select id from profiles where role in ('supervisor','admin')));

create table if not exists public.status_history (
  id          bigint generated always as identity primary key,
  request_id  text not null references public.service_requests (id) on delete cascade,
  from_status text,
  to_status   text not null,
  by_user_id  uuid not null,
  reason      text,
  created_at  timestamptz not null default now()
);
alter table public.status_history enable row level security;
drop policy if exists "sh_read" on public.status_history;
drop policy if exists "sh_insert" on public.status_history;
create policy "sh_read" on public.status_history for select using (auth.role() = 'authenticated');
create policy "sh_insert" on public.status_history for insert
  with check (exists (select 1 from public.service_requests s where s.id = request_id));

create table if not exists public.job_notes (
  id          bigint generated always as identity primary key,
  request_id  text not null references public.service_requests (id) on delete cascade,
  author_id   uuid not null references auth.users (id),
  kind        text not null default 'diagnosis',
  body        text not null,
  created_at  timestamptz not null default now()
);
alter table public.job_notes enable row level security;
drop policy if exists "jn_read" on public.job_notes;
drop policy if exists "jn_insert" on public.job_notes;
create policy "jn_read" on public.job_notes for select using (auth.role() = 'authenticated');
create policy "jn_insert" on public.job_notes for insert
  with check (exists (select 1 from public.service_requests s where s.id = request_id));

create table if not exists public.job_photos (
  id          bigint generated always as identity primary key,
  request_id  text not null references public.service_requests (id) on delete cascade,
  kind        text not null default 'other',
  url_path    text not null,
  created_at  timestamptz not null default now()
);
alter table public.job_photos enable row level security;
drop policy if exists "jp_read" on public.job_photos;
drop policy if exists "jp_insert" on public.job_photos;
create policy "jp_read" on public.job_photos for select using (auth.role() = 'authenticated');
create policy "jp_insert" on public.job_photos for insert
  with check (exists (select 1 from public.service_requests s where s.id = request_id));

create table if not exists public.job_part_usage (
  id         bigint generated always as identity primary key,
  request_id text not null references public.service_requests (id) on delete cascade,
  part_id    text not null,
  part_name  text not null default '',
  price_egp  int not null default 0,
  qty        int not null default 1,
  created_at timestamptz not null default now()
);
alter table public.job_part_usage enable row level security;
drop policy if exists "pu_read" on public.job_part_usage;
drop policy if exists "pu_insert" on public.job_part_usage;
create policy "pu_read" on public.job_part_usage for select using (auth.role() = 'authenticated');
create policy "pu_insert" on public.job_part_usage for insert
  with check (exists (select 1 from public.service_requests s where s.id = request_id));

create table if not exists public.service_ratings (
  request_id text primary key references public.service_requests (id) on delete cascade,
  stars      int not null check (stars between 1 and 5),
  comment    text,
  created_at timestamptz not null default now()
);
alter table public.service_ratings enable row level security;
drop policy if exists "ratings_read" on public.service_ratings;
drop policy if exists "ratings_insert" on public.service_ratings;
create policy "ratings_read" on public.service_ratings for select using (auth.role() = 'authenticated');
create policy "ratings_insert" on public.service_ratings for insert
  with check (exists (
    select 1 from public.service_requests s
    where s.id = request_id and (
      s.customer_id = auth.uid() or
      auth.uid() in (select id from profiles where role in ('supervisor','admin'))
    )
  ));

-- ── 5. Inbox notifications (edge functions/webhook push later) ──────
create table if not exists public.notifications (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references auth.users (id),
  kind        text not null,
  title       text not null,
  body        text not null,
  read        boolean not null default false,
  created_at  timestamptz not null default now()
);
alter table public.notifications enable row level security;
drop policy if exists "notifications_read" on public.notifications;
drop policy if exists "notifications_insert" on public.notifications;
drop policy if exists "notifications_update" on public.notifications;
create policy "notifications_read" on public.notifications for select using (auth.uid() = user_id);
create policy "notifications_insert" on public.notifications for insert with check (auth.uid() = user_id);
-- mark-read: a user may update only their OWN rows (client syncs `read`).
create policy "notifications_update" on public.notifications
  for update using (auth.uid() = user_id);

-- ── 6. Proof-photo storage (bucket + object policies) ───────────────
insert into storage.buckets (id, name, public) values ('photos', 'photos', true)
  on conflict (id) do nothing;

drop policy if exists "photos_read" on storage.objects;
drop policy if exists "photos_insert" on storage.objects;
create policy "photos_read" on storage.objects for select using (bucket_id = 'photos' and auth.role() = 'authenticated');
create policy "photos_insert" on storage.objects for insert
  with check (bucket_id = 'photos' and auth.role() = 'authenticated');

-- ── 7. Helper: promote a user to admin/supervisor/technician ────────
-- Run once after creating your account (SQL editor runs as postgres, so
-- auth.uid() is null there — target by email instead):
--   update public.profiles p set role = 'admin'
--   from auth.users u where u.id = p.id and u.email = 'you@example.com';
-- (legal roles: 'customer' | 'technician' | 'supervisor' | 'admin')

-- ── 8. Role-to-role notifications (push RPC + realtime) ─────────────
-- Any authenticated user can route a notification to specific users and/or
-- entire roles. SECURITY DEFINER (service role semantics) so a client can
-- deliver into OTHER users' inboxes; recipients still read only their own
-- rows via the notifications_read policy above.
-- NOTE: no DEFAULT parameters — Postgres rejects defaults followed by
-- non-default params (42P13); the app always passes all five arguments.
create or replace function public.api_push_notifications(
  roles    text[],
  user_ids uuid[],
  kind     text,
  title    text,
  body     text
) returns int
language plpgsql security definer set search_path = public as $$
declare
  caller uuid := auth.uid();
  inserted int := 0;
  v_id uuid;
begin
  if caller is null then
    raise exception 'not authenticated';
  end if;
  for v_id in
    select distinct id from (
      select unnest(user_ids) as id
      where cardinality(user_ids) > 0
      union
      select p.id from profiles p
      where p.role = any(roles)
    ) t
  loop
    insert into public.notifications (user_id, kind, title, body)
    values (v_id, kind, title, body);
    inserted := inserted + 1;
  end loop;
  return inserted;
end;
$$;

revoke execute on function public.api_push_notifications(text[], uuid[], text, text, text) from public;
grant execute on function public.api_push_notifications(text[], uuid[], text, text, text) to authenticated;
grant execute on function public.api_push_notifications(text[], uuid[], text, text, text) to service_role;

-- realtime: stream notification rows to the owning user's connected apps
-- and request-domain changes to staff apps (live badge + live lists).
do $$
declare
  t text;
begin
  foreach t in array array[
    'notifications',
    'service_requests',
    'job_assignments',
    'status_history',
    'job_notes',
    'job_photos',
    'job_part_usage',
    'service_ratings'
  ] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public'
        and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$$;