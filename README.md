# Calculateurs de mobilité — 2R Aventure

Collection of standalone, self-contained HTML widgets (vanilla JS + inline CSS, no build step, no dependencies) for simulating and comparing mobility costs in France. Each file can be opened directly in a browser or embedded in a page — the widgets use a transparent background and a `max-width` of ~700px, so they are designed to be dropped into a site (e.g. via iframe/WordPress).

## Files

| File | Purpose |
|------|---------|
| `calculateur_mobilite_2raventure.html` | **Main tool — "CalMob / Bilan Mobilité Employeur"**. 7-step wizard (Accueil → Structure → Déplacements → Flotte & Budget → RH → Contact → Bilan) producing an employer mobility assessment: estimated mobility costs, a savings action plan, and regulatory obligations (PDME). Embeds French reference datasets as JSON: postal codes, departments, AOM/intercommunalités (BANATIC) and public transport networks. Step 5 optionally sends the contact to **Brevo** via sibforms endpoints (see `BREVO` config in the file). |

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
- Git history is maintained via GitHub web uploads ("Update/Add files via upload") — commits are coarse-grained per file.

## Usage

Open any file in a browser:

```bash
open calculateur_mobilite_2raventure.html
```

To embed a widget, iframe the file and size the frame to at least ~700px wide.
