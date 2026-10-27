# Calculateurs de mobilité — 2R Aventure

Collection of standalone, self-contained HTML widgets (vanilla JS + inline CSS, no build step, no dependencies) for simulating and comparing mobility costs in France. Each file can be opened directly in a browser or embedded in a page — the widgets use a transparent background and a `max-width` of ~700px, so they are designed to be dropped into a site (e.g. via iframe/WordPress).

## Files

| File | Purpose |
|------|---------|
| `index.html` | **Main tool — "CalMob / Bilan Mobilité Employeur"**. 7-step wizard (Accueil → Structure → Déplacements → Flotte & Budget → RH → Contact → Bilan) producing an employer mobility assessment: estimated mobility costs, a savings action plan, and regulatory obligations (PDME). Embeds French reference datasets as JSON: postal codes, departments, AOM/intercommunalités (BANATIC) and public transport networks. Step 5 optionally sends the contact to **Brevo** via sibforms endpoints (see `BREVO` config in the file). Step 6 archives a full snapshot to **Supabase** (see `STORE` config and [Data store](#data-store-supabase)). |
| `supabase/schema.sql` | DDL for the `calmob_snapshots` cold-store table + RLS policies. Run once in the Supabase SQL Editor. |

### Archived (`archives/`)

Older single-purpose widgets kept for reference — no longer maintained.

| File | Purpose |
|------|---------|
| `archives/calculateur_mobilite_LS.html` | **Social leasing ("leasing social") wizard**. Eligibility check for the ~95 €/month EV leasing scheme, alternatives for short trips (bike), and guided dossier preparation. |
| `archives/calculateur_mobilite_salaries.html` | **Employee mobility budget calculator**. Simulates the real cost of a personal vehicle, compares alternatives (transit, bike, carpooling/car-sharing), checks social-leasing eligibility and available subsidies. |
| `archives/mobilite_etudiante_parents.html` | **Student mobility variant**, aimed at students and their parents: cost of a student car vs. alternatives, plus a pros/cons section for parents. |
| `archives/calculateur_mobilite_salarie_v2.html` | Minimal mode-comparison widget: annual cost across modes (solo car at 0.33 €/km, carpooling, transit, shared EV, classic/e-bike/cargo bike) driven by distance and work-days sliders. |
| `archives/calculateur_mobilite_v4.html` | Identical duplicate of `archives/calculateur_mobilite_salarie_v2.html`. |

## Tech notes

- Single-file HTML: markup, styles and logic are all inline.
- Brand palette: dark teal `#004A4F` / teal `#3ECDC5` on cream `#FBF7F3`, Asap font (Google Fonts).
- All content is in French; cost figures are in EUR with `fr-FR` formatting.
- **Brevo capture** (main tool): step-5 contact info is POSTed to a Brevo subscription-form endpoint (`BREVO.URL` in the file) when at least one consent box is checked; `CONSENT_AOM` / `CONSENT_NL` flag attributes record which. Unchecked boxes or invalid email = nothing sent.
- **Snapshot store** (main tool): on reaching the Bilan step, a full session snapshot (contact, all inputs, computed results, action-plan selections) is upserted to Supabase — see [Data store](#data-store-supabase). Same consent gate as Brevo; silent, never blocks navigation.
- Git history is maintained via GitHub web uploads ("Update/Add files via upload") — commits are coarse-grained per file.

## Data store (Supabase)

Each session that reaches the Bilan step with at least one consent box checked is stored in `calmob_snapshots` — a cold store for later analysis (SQL, exports, BI tools). Rows are **append-only**: one row per send, `session_id` groups snapshots from the same browser session (take the latest `created_at` per session for the current state). Identical repeat visits are deduplicated client-side.

Row shape: a few queryable columns (`email`, `code_postal`, `aom`, `secteur`, `nb_sal`, `grand_total`, `consent_*`, timestamps) plus a `payload` jsonb column holding the complete snapshot — `contact`, `geo`, `inputs`, `results`, `eco`, `meta`.

### Setup (one-time)

1. Create a free [Supabase](https://supabase.com) project.
2. SQL Editor → run [`supabase/schema.sql`](supabase/schema.sql).
3. Settings → API → copy the **Project URL** and the **`anon` `public`** key into `STORE.URL` / `STORE.KEY` in `index.html` (leave empty to disable).
4. Push to `main` — GitHub Pages redeploys automatically.

### Security notes

- The `publishable` key is public by design; grants + RLS give it **INSERT only — no SELECT/UPDATE**, so nobody can read or modify the table with the key embedded in the widget.
- Reads require the `service_role`/`secret` key or the SQL Editor (dashboard) — keep the secret key out of the repo and the widget.
- Endpoint is publicly writable (same exposure as the Brevo form URL): junk inserts are possible. Rows can't be read back or altered, and `session_id` is a random UUID per page load.

### Querying

```sql
-- latest snapshots with key figures
select created_at, email, code_postal, aom, secteur, nb_sal, grand_total
from public.calmob_snapshots
order by created_at desc;

-- latest snapshot per session
select distinct on (session_id) *
from public.calmob_snapshots
order by session_id, created_at desc;

-- anything else lives in payload, e.g. average fleet size
select avg((payload->'inputs'->>'nb_veh')::numeric)
from public.calmob_snapshots;
```

### Manual test

```bash
curl -X POST "https://<project-ref>.supabase.co/rest/v1/calmob_snapshots" \
  -H "apikey: <publishable-key>" \
  -H "Authorization: Bearer <publishable-key>" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=minimal" \
  -d '[{"session_id": "'"$(uuidgen)"'", "consent_aom": true, "payload": {"v":1}}]'
# → 201. A GET on the same URL returns 401 (write-only).
```

## Usage

Open any file in a browser:

```bash
open index.html
```

To embed a widget, iframe the file and size the frame to at least ~700px wide.
