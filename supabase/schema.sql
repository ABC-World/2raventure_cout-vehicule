-- CalMob — cold store des bilans mobilité employeur
-- À exécuter dans le SQL Editor Supabase. Idempotent : peut être rejoué pour
-- mettre à jour une table existante (retire la contrainte d'unicité héritée
-- de la version "upsert" et restreint le rôle anon à INSERT seul).
--
-- Le widget (hébergé en statique) POSTe directement vers PostgREST avec la clé
-- publishable. Grants + RLS n'autorisent que INSERT : la table est
-- strictement write-only côté navigateur. Une ligne = un snapshot ;
-- session_id permet de regrouper / prendre le plus récent par session.

create table if not exists public.calmob_snapshots (
  id          bigint generated always as identity primary key,
  session_id  uuid        not null,
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

-- La v1 posait un UNIQUE sur session_id pour l'upsert : on le retire si présent.
alter table public.calmob_snapshots
  drop constraint if exists calmob_snapshots_session_id_key;

create index if not exists calmob_snapshots_session_idx on public.calmob_snapshots (session_id);
create index if not exists calmob_snapshots_created_idx on public.calmob_snapshots (created_at);
create index if not exists calmob_snapshots_cp_idx      on public.calmob_snapshots (code_postal);
create index if not exists calmob_snapshots_email_idx   on public.calmob_snapshots (email);

alter table public.calmob_snapshots enable row level security;

-- Privilèges table pour le rôle anon : INSERT uniquement (append-only).
-- On retire aussi les droits hérités d'une éventuelle exécution de la v1.
revoke select, update on public.calmob_snapshots from anon;
grant insert on public.calmob_snapshots to anon;
grant usage on sequence public.calmob_snapshots_id_seq to anon;

-- Policies RLS : écriture seule — aucune policy SELECT/UPDATE, le rôle anon
-- ne peut ni lire ni modifier des lignes existantes.
drop policy if exists calmob_insert on public.calmob_snapshots;
create policy calmob_insert on public.calmob_snapshots
  for insert to anon
  with check (true);

drop policy if exists calmob_update on public.calmob_snapshots;

-- Nettoyage des objets de la v1 (trigger updated_at) s'ils existent.
drop trigger if exists calmob_snapshots_touch on public.calmob_snapshots;
drop function if exists public.calmob_touch_updated_at();
