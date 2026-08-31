# 🎮 Dota 2 Analytics Pipeline

An end-to-end analytics pipeline built on Dota 2 match data — ingesting from
a public API, modeling into a dimensional schema, and orchestrating the full
workflow.

## 🎯 Overview

Raw match, player, and hero data is pulled from the OpenDota API, landed in
Snowflake, and transformed with dbt into a dimensional model. The project
applies dbt features including snapshots, incremental models, ephemeral
models, testing, macros, and documentation.

## 📡 Data Source

**[OpenDota API](https://docs.opendota.com/)** — a free, community-built API
providing Dota 2 match, player, and hero data. No authentication required
for basic use.

Key endpoints used:
| Endpoint | Purpose |
|---|---|
| `/heroes` | Hero reference data → `dim_hero` |
| `/publicMatches` | Match data → `fact_match` |
| `/matches/{match_id}` | Full match/player detail → `fact_player_performance` |
| `/players/{account_id}` | Player profile → `dim_player` |

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

## 🚧 Status

Phase 1: ingestion, modeling, and orchestration — in progress.
Phase 2 (planned): CI/CD and dbt-in-production practices.

## ⚙️ Setup

_Coming soon._
