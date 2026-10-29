# 🎮 Dota 2 Analytics Pipeline

An end-to-end analytics pipeline built on Dota 2 match data — ingesting from
a public API, modeling into a dimensional schema, and orchestrating the full
workflow.

## 🎯 Overview

Match and hero data is pulled from the OpenDota API, landed in Snowflake,
and transformed with dbt into a dimensional model built for match- and
hero-level analysis — not tracking individual players.

## 📡 Data Source

**[OpenDota API](https://docs.opendota.com/)** — a free, community-built API
providing Dota 2 match, player, and hero data. No authentication required
for basic use.

Key endpoints used:
| Endpoint | Purpose |
|---|---|
| `/heroes` | Hero reference data → `dim_hero` |
| `/players/{account_id}` | Player profile → `dim_player` |
| `/players/{account_id}/matches` | Player match history → `fact_player_performance` |
| `/publicMatches` | Match summaries → `fact_match` |
| `/matches/{match_id}` | Full match/player detail → `fact_match`, `fact_player_performance` |
| `/constants/{resource}` | Lookup data (game_mode, lobby_type, cluster, items) → reference dimensions |

## 🏗️ Architecture

| Layer | Tool | Role |
|---|---|---|
| Ingestion | Python + [dlt](https://dlthub.com/) | Pulls data from the OpenDota API into Snowflake |
| Storage / Bronze | ❄️ Snowflake | Raw landing zone |
| Transformation | dbt Fusion | Builds staging (cleaned) and mart (dimensional) layers |
| Orchestration | Airflow | Runs ingestion → dbt build, in sequence |

_Diagram coming soon._

## 🗂️ Data Model

**Dimensions**
- `dim_hero` — from `/heroes`
- `dim_role` — hero role classifications (Carry, Support, Nuker, etc.)
- `dim_game_mode` — from `constants_game_mode`
- `dim_lobby_type` — from `constants_lobby_type`
- `dim_region` — from `constants_region`
- `dim_team` — Radiant / Dire, a small seeded dimension
- `dim_rank_tier` — Herald through Immortal, a small seeded dimension
- `dim_date` — generated date spine

**Bridge**
- `bridge_hero_role` — resolves the many-to-many between heroes and roles

**Facts**
- `fact_matches` — one row per match
- `fact_match_players` — one row per player per match
- `fact_match_gold_advantage` — Radiant's gold lead by minute, per match

ERD reference (will be replaced with an embedded diagram image):
[Dota 2 Star Schema](https://claude.ai/artifact/1owK8c2Mn2QB9QvjxR3B2A)

## 🔄 ETL Flow

Three layers: **raw** (landed as-is from the API) → **staging** (cleaned,
renamed, typed) → **mart** (the dimensional model above, ready for
reporting).

The source-to-target mappings for each step are documented in `docs/`:
- `sttm_raw_to_staging.xlsx`
- `sttm_staging_to_mart.xlsx`

_dbt's auto-generated lineage graph will be added here once the mart layer
is complete._

## ✅ Data Quality

_Coming soon — a table listing the checks in place at the source, staging,
and mart layers (not-null, uniqueness, accepted ranges, relationships, and
a few business-rule checks specific to this data)._

## 📈 Business Questions & Key Metrics

The dimensional model is designed to answer population-level questions about
Dota 2 matches and heroes, rather than tracking a single player:

1. Which heroes have the highest win rates overall, and does that vary by rank tier?
2. Do certain heroes perform better in certain roles or attack types?
3. Does the Radiant side have a structural win-rate advantage?
4. What's the average match duration by game mode and rank tier?
5. Is there a relationship between a hero's primary attribute (str/agi/int) or attack type and win rate?
6. How does match outcome correlate with the average rank tier of participants?
7. How does match volume/outcome vary by day of week or time of day?
8. How do average KDA, GPM, and XP trend over time across all matches (e.g., by date, week, or patch)?
9. Do average KDA, GPM, or XP differ significantly by rank tier?
10. Is there a relationship between GPM/XP and win rate across matches?

## 📊 Public Dashboard

_Coming soon — a link to the live dashboard and a screenshot will go here
once it's built._

## 📚 dbt Features Used

Staging, sources & refs, ephemeral models, incremental models, snapshots,
tests, unit tests, macros, documentation.

## 🧭 Design Decisions

Key modeling and architecture decisions made throughout the project, along
with the reasoning behind them.

| # | Decision | Rationale |
|---|---|---|
| 1 | `dim_player` includes a placeholder "unknown member" row (`account_id = -1`, name = "Unknown/Private") for players with private profiles. Applied in the dbt staging layer via `coalesce(account_id, -1)`, not in Python ingestion — the bronze layer stays raw. The `-1` row is seeded via a dbt seed file. | OpenDota omits `account_id` for players with private profiles. Using a default/unknown dimension member (a standard Kimball pattern) keeps every fact row joinable without dropping data or leaving null foreign keys. |
| 2 | Heroes can have more than one role (e.g. Anti-Mage is Carry, Escape, and Nuker at once), which doesn't fit in a single flat dimension row. Resolved with a `dim_role` dimension plus a `bridge_hero_role` bridge table — one row per hero/role pair. | This is the standard Kimball pattern for a many-to-many relationship between a fact and a dimension, and avoids forcing a hero into just one role. |

## 🚧 Status

Phase 1: ingestion, modeling, and orchestration — in progress.
Phase 2 (planned): CI/CD and dbt-in-production practices.

## ⚙️ Setup

_Coming soon._
