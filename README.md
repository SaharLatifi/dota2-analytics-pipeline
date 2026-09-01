# 🎮 Dota 2 Analytics Pipeline

An end-to-end analytics pipeline built on Dota 2 match data — ingesting from
a public API, modeling into a dimensional schema, and orchestrating the full
workflow.

## 🎯 Overview

Raw match, player, and hero data is pulled from the OpenDota API, landed in
Snowflake, and transformed with dbt into a dimensional model. The project
applies dbt features including snapshots, incremental models, ephemeral
models, testing, macros, and documentation.

## ❓ Business Questions

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

## 📊 Dashboard

_Coming soon — a dashboard answering the business questions above will be linked here._

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
| Transformation | dbt Fusion | Builds silver (cleaned) and gold (dimensional) layers |
| Orchestration | Airflow | Runs ingestion → dbt build, in sequence |

## 🗂️ Dimensional Model

- `dim_hero` — from `/heroes`
- `dim_player` — from `/players/{account_id}`
- `dim_date` — generated date spine
- `fact_match` — from `/publicMatches`, `/matches/{match_id}`
- `fact_player_performance` — one row per player per match (kills, deaths, assists, gold, XP)

## 📚 dbt Features Used

Staging, sources & refs, ephemeral models, incremental models, snapshots,
tests, unit tests, macros, documentation.

## 🧭 Design Decisions

Key modeling and architecture decisions made throughout the project, along
with the reasoning behind them.

| # | Decision | Rationale |
|---|---|---|
| 1 | `dim_player` includes a placeholder "unknown member" row (`account_id = -1`, name = "Unknown/Private") for players with private profiles. Applied in the dbt staging layer via `coalesce(account_id, -1)`, not in Python ingestion — the bronze layer stays raw. The `-1` row is seeded via a dbt seed file. | OpenDota omits `account_id` for players with private profiles. Using a default/unknown dimension member (a standard Kimball pattern) keeps every fact row joinable without dropping data or leaving null foreign keys. |
| 2 | *(Pending)* How to handle the `roles` field from `/heroes` (an array of multiple role strings per hero) in `dim_hero`. Options: (a) keep as a single semi-structured/array column, (b) split into a bridge table `dim_hero_role` (one row per hero-per-role), (c) flatten to just the primary role. | A hero can have multiple roles, which doesn't fit cleanly into a flat dimension row — to be decided once `dim_hero` is built. |

## 🚧 Status

Phase 1: ingestion, modeling, and orchestration — in progress.
Phase 2 (planned): CI/CD and dbt-in-production practices.

## ⚙️ Setup

_Coming soon._
