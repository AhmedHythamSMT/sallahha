-- Sallahha FieldOps — Supabase schema (Postgres)
-- ---------------------------------------------------------------------
-- Paste this into your Supabase project → SQL editor and run.
-- Optionally disable "Email confirmations" in Auth settings for instant
-- sign-in; the app also works with confirmations enabled (it asks the
-- new user to confirm first).
--
-- Replaces the mock backend (lib/core/backend/mock_backend.dart) when
-- SUPABASE_URL + SUPABASE_ANON_KEY are present in `.env`.
-- ---------------------------------------------------------------------

-- ── 1. Profiles (extends auth.users) ────────────────────────────────
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  name       text not null default '',
  phone      text not null default '',
  role       text not null default 'customer' check (role in ('customer','technician','supervisor','admin')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

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
create policy "services_read" on public.services for select using (auth.role() = 'authenticated');

create table if not exists public.parts (
  id        text primary key,
  name_ar   text not null,
  name_en   text not null,
  price_egp int not null default 0
);
alter table public.parts enable row level security;
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

-- ── 3. Service requests ─────────────────────────────────────────────
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

-- Read: owner + staff (technicians/supervisors/admins).
create policy "sr_read_mine" on public.service_requests for select
  using (customer_id = auth.uid() or auth.uid() in (select id from profiles where role in ('technician','supervisor','admin')));
-- Create: customers only, own rows only.
create policy "sr_insert_customer" on public.service_requests for insert
  with check (customer_id = auth.uid());
-- Update: supervisors/admins may touch everything (customer id immutable).
create policy "sr_update_staff" on public.service_requests for update
  using (auth.uid() in (select id from profiles where role in ('supervisor','admin')))
  with check (new.customer_id = old.customer_id);
-- Update: technicians may only change status+bump version OR set the estimate.
create policy "sr_update_technician" on public.service_requests for update
  using (auth.uid() in (select id from profiles where role = 'technician'))
  with check (
    new.customer_id = old.customer_id and new.confirmed = old.confirmed and
    ( (
        new.status is distinct from old.status and
        new.priority = old.priority and
        new.estimate_egp is not distinct from old.estimate_egp and
        new.version = old.version + 1
      ) or (
        new.status = old.status and
        new.priority = old.priority and
        new.estimate_egp is distinct from old.estimate_egp and
        new.version = old.version
      )
    )
  );
-- Update: the owning customer may only confirm a completed request.
create policy "sr_update_customer" on public.service_requests for update
  using (customer_id = auth.uid())
  with check (
    new.customer_id = old.customer_id and
    new.confirmed = true and old.confirmed = false and
    new.status = old.status and new.priority = old.priority and
    new.version = old.version and
    new.estimate_egp is not distinct from old.estimate_egp
  );

-- ── 4. Assignments, timeline, notes, photos, parts, ratings ─────────
create table if not exists public.job_assignments (
  id            text primary key,
  request_id    text not null references public.service_requests (id) on delete cascade,
  technician_id uuid not null references auth.users (id),
  assigned_by   uuid not null references auth.users (id),
  created_at    timestamptz not null default now()
);
alter table public.job_assignments enable row level security;
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
create policy "notifications_read" on public.notifications for select using (auth.uid() = user_id);
create policy "notifications_insert" on public.notifications for insert with check (auth.uid() = user_id);

-- ── 6. Proof-photo storage (bucket + object policies) ───────────────
insert into storage.buckets (id, name, public) values ('photos', 'photos', true)
  on conflict (id) do nothing;

create policy "photos_read" on storage.objects for select using (bucket_id = 'photos' and auth.role() = 'authenticated');
create policy "photos_insert" on storage.objects for insert
  with check (bucket_id = 'photos' and auth.role() = 'authenticated');

-- ── 7. Helper: promote the first user to admin ──────────────────────
-- Run once after creating your account:
-- update public.profiles set role = 'admin' where id = auth.uid();

-- ── 8. Role-to-role notifications (push RPC + realtime) ─────────────
-- Any authenticated user can route a notification to specific users and/or
-- entire roles. SECURITY DEFINER (service role semantics) so a client can
-- deliver into OTHER users' inboxes; recipients still read only their own
-- rows via the notifications_read policy below.
create or replace function public.api_push_notifications(
  roles    text[] default '{}',
  user_ids uuid[] default '{}',
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

-- mark-read: a user may update only their OWN rows (client syncs `read`).
create policy "notifications_update" on public.notifications
  for update using (auth.uid() = user_id);

-- realtime: stream notification rows to the owning user's connected apps.
alter publication supabase_realtime add table public.notifications;