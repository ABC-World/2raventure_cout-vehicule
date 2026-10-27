-- CalMob — cold store des bilans mobilité employeur
-- À exécuter dans le SQL Editor Supabase (une seule fois).
--
-- Le widget (hébergé en statique) POSTe directement vers PostgREST avec la clé
-- "anon" publique. Le RLS ci-dessous autorise uniquement INSERT + UPDATE à ce
-- rôle : impossible de lire la table avec la clé embarquée dans le navigateur.

create table if not exists public.calmob_snapshots (
  id          bigint generated always as identity primary key,
  session_id  uuid        not null unique,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  email       text,
  code_postal varchar(10),
  aom         text,
  secteur     varchar(20),
  nb_sal      integer,
  grand_total numeric(14, 2),
  consent_aom boolean,
  consent_nl  boolean,
  -- Snapshot complet : contact, inputs étapes 1–4, résultats calculés (C),
  -- leviers du plan d'action (eco), meta navigateur.
  payload     jsonb       not null
);

create index if not exists calmob_snapshots_created_idx on public.calmob_snapshots (created_at);
create index if not exists calmob_snapshots_cp_idx      on public.calmob_snapshots (code_postal);
create index if not exists calmob_snapshots_email_idx   on public.calmob_snapshots (email);

alter table public.calmob_snapshots enable row level security;

-- Privilèges table pour le rôle anon (les tables créées via SQL Editor ne
-- reçoivent pas les grants par défaut de l'API). SELECT est requis par
-- l'upsert PostgREST — sans policy SELECT, RLS renvoie toujours 0 ligne.
grant select, insert, update on public.calmob_snapshots to anon;
grant usage on sequence public.calmob_snapshots_id_seq to anon;

-- Le rôle anon peut écrire (upsert via resolution=merge-duplicates)…
drop policy if exists calmob_insert on public.calmob_snapshots;
create policy calmob_insert on public.calmob_snapshots
  for insert to anon
  with check (true);

drop policy if exists calmob_update on public.calmob_snapshots;
create policy calmob_update on public.calmob_snapshots
  for update to anon
  using (true)
  with check (true);

-- …mais aucune policy SELECT : lecture réservée au service_role / SQL Editor.

-- updated_at reflète le dernier envoi de la session.
create or replace function public.calmob_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists calmob_snapshots_touch on public.calmob_snapshots;
create trigger calmob_snapshots_touch
  before update on public.calmob_snapshots
  for each row execute function public.calmob_touch_updated_at();
