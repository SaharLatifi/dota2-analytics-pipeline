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
| `/players/{account_id}/matches` | Player match history → `fct_match_player` |
| `/publicMatches` | Match summaries → `fct_match` |
| `/matches/{match_id}` | Full match/player detail → `fct_match`, `fct_match_player` |
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
- `dim_hero` — from `/heroes` (SCD Type 2 — keeps history of role/attribute changes across patches)
- `dim_item` — from `constants_items` (SCD Type 2 — keeps history of cost/stat changes across patches; not yet wired to a fact table)
- `dim_role` — hero role classifications (Carry, Support, Nuker, etc.)
- `dim_game_mode` — from `constants_game_mode`
- `dim_lobby_type` — from `constants_lobby_type`
- `dim_region` — from `constants_region`
- `dim_team` — Radiant / Dire, a small seeded dimension
- `dim_rank_bracket` — Herald through Immortal, a small seeded dimension
- `dim_dates` — generated date spine (not yet joined from any fact — see Known Issues)
- `dim_player` — one row per known account_id, built from match history (first/last seen, most-played hero); rank is intentionally left out here — use `fct_match_player` for rank at the time of a match

All dimensions are SCD Type 1 except `dim_hero` and `dim_item`, which are
SCD Type 2 (see Design Decisions below for why).

**Bridge**
- `bridge_hero_role` — resolves the many-to-many between heroes and roles

**Facts**
- `fct_match` — one row per match
- `fct_match_player` — one row per player per match
- `fct_match_team_performance` — one row per team per match (tower/barracks status decoded from the raw bitmasks, kill count)
- `fct_match_gold_advantage` — planned, not yet built; `stg_matches__match_gold_advantage` exists in staging (Radiant's gold lead by minute, per match) but no mart fact consumes it yet

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

Checks run at the source, staging, snapshot, and mart layers: not-null,
uniqueness, `accepted_range`/`accepted_values`, `relationships`, and a few
business-rule checks specific to this data (see Design Decision #5 on why
some of these deliberately overlap across layers). `fct_match.sql`,
`fct_match_player.sql`, and `fct_match_team_performance.sql` don't have
their own schema `.yml` files with tests yet — that's the next doc/test gap
to close.

### ⚠️ Known issues (found while syncing docs to the built models)

- **`fct_match_player` silently drops private-profile players.** The model
  coalesces a missing `account_id` to `-1` before joining to `dim_player`,
  but `dim_player`'s synthetic "Unknown" row stores `account_id` as `NULL`,
  not `-1`. Since `-1 = NULL` is never true, the `inner join` finds no match
  and the row is dropped entirely — a real, currently-happening loss of
  player-match rows, not just a stale doc. Fix: don't coalesce before the
  join; `left join dim_player` on the raw (possibly null) `account_id`, then
  `coalesce(player_id, '-1')` afterward, the same pattern already used for
  `hero_id` via `dim_hero`.
- **Team and rank-bracket FKs don't actually match their dimensions' key
  type.** `dim_team.team_id` and `dim_rank_bracket.rank_bracket_id` are
  hashed `TEXT` surrogate keys, but `fct_match.winner_team_id`,
  `fct_match_player.team_id`, `fct_match_team_performance.team_id`, and
  `fct_match_player.rank_bracket_id` are all still plain `1`/`2` or `1`-`8`
  numbers carried straight through from staging. A `relationships` test
  from any of these to their dimension can't pass as currently built.
  Needs a decision: hash the fact-side columns to match, or stop hashing
  `dim_team`/`dim_rank_bracket`'s small, fixed key sets in the first place.
- **`fct_match.match_date` isn't joined to `dim_dates`.** `dim_dates` exists
  as a generated spine but nothing references it yet, so date-dimension
  attributes (`business_season`, `is_weekend`, etc.) aren't usable from any
  fact today.
- **`fct_match_team_performance.radiant_tower_status_bitmask` /
  `radiant_barracks_status_bitmask`** keep that name on the Dire-team row
  too (the model unions two near-identical CTEs positionally) — holds the
  right value for each team, just a misleading column name worth renaming
  to something team-neutral.

See `docs/sttm_staging_to_mart.xlsx` (flagged orange) for the full detail
on each of these, row by row.

## 📈 Business Questions & Key Metrics

The dimensional model is designed to answer population-level questions about
Dota 2 matches and heroes, rather than tracking a single player:

## Business questions

### Players and engagement
1. How many new and active players are there each week?
2. How many players come back in the weeks after they're first seen?
3. How are players distributed across rank brackets?
4. How does match volume vary by day of week and hour (UTC)?

### Heroes and balance
5. Which heroes have the highest win rates, and does that vary by rank bracket?
6. Do win rates differ by hero role, primary attribute or attack type?
7. Does the Radiant side have a structural win-rate advantage?
8. Does the team with the higher average rank win more often?
9. What is the average match duration by game mode and rank bracket?
10. How do KDA, GPM and XPM differ by rank bracket and between winners and losers?
11. How do KDA, GPM and XPM trend by week and patch?
12. How far do heroes level up in a match, and how does that depend on match length and winning?

## Metrics

| Metric | Definition | Questions |
| --- | --- | --- |
| New players | Known accounts whose first-seen match falls in the period (first-seen date stands in for install date) | 1 |
| Active players | Distinct known accounts with at least one match in the week | 1 |
| Matches per player | Matches ÷ active players | 1 |
| Weekly cohort retention | Share of a first-seen cohort with a match N weeks later | 2 |
| Rank distribution | Active players by rank bracket | 3 |
| Match volume | Matches by day of week and start hour | 4 |
| Hero win rate | Wins ÷ matches played with the hero | 5, 6 |
| Hero pick rate | Matches with the hero ÷ total matches | 5 |
| Radiant win rate | Radiant wins ÷ total matches | 7 |
| Rank edge win rate | Share of matches won by the team with the higher average rank | 8 |
| Average match duration | Mean minutes per match | 9 |
| GPM, XPM, KDA | Averages per player; KDA = (kills + assists) ÷ max(deaths, 1), from summed values | 10, 11 |
| Level milestone reach | Share of player-matches reaching at least level 6, 10, 15, 20 and 25, by duration bucket (under 30, 30–45, over 45 min) and win/loss | 12 |

## Dashboard wireframe

### Page 1 · Players: who plays, and do they come back?

```text
+------------------------------------------------------------------+
| Filters: date range | region | rank bracket                      |
+----------------+----------------+----------------+----------------+
| Matches        | Active players | New players    | Matches per    |
|                |                |                | player         |
+----------------+----------------+-+--------------+----------------+
| Weekly active players             | New players by week           |
| (line chart)                      | (bar chart)                   |
+-----------------------------------+-------------------------------+
| Weekly cohort retention                                           |
| (heatmap: first-seen week x weeks since first seen, % active)     |
+---------------------------------+---------------------------------+
| Players by rank bracket         | Matches by day of week and hour |
| (bar chart)                     | (heatmap, UTC)                  |
+---------------------------------+---------------------------------+
```

### Page 2 · Heroes and balance: what wins, and where?

```text
+------------------------------------------------------------------+
| Filters: patch | rank bracket | region | game mode                |
+----------------+----------------+----------------+----------------+
| Matches        | Radiant win    | Avg match      | Rank edge      |
|                | rate           | duration       | win rate       |
+----------------+----------------+-+--------------+----------------+
| Hero win rate vs pick rate        | Top 10 heroes by win rate     |
| (scatter, one dot per hero)       | (table, min match threshold)  |
+---------------------------------+-+-------------------------------+
| Win rate by attribute & attack  | Win rate by hero role           |
| (grouped bars)                  | (bar chart)                     |
+---------------------------------+---------------------------------+
| Duration by game mode and rank  | GPM, XPM and KDA by rank        |
| (heatmap, avg minutes)          | (grouped bars, winners/losers)  |
+---------------------------------+---------------------------------+
| Level milestone funnel                                            |
| (% reaching level 6, 10, 15, 20, 25; split by duration bucket    |
|  and winners vs losers)                                           |
+------------------------------------------------------------------+
| Patch trend                                                       |
| (lines by week: KDA, GPM, XPM, patch dates marked)                |
+------------------------------------------------------------------+
```

## Caveats
- Matches are a random sample of public games, so player metrics demonstrate the technique rather than true values.
- Anonymous accounts are excluded from player counts but kept in match and hero stats.
- Hero win rates use a minimum match count to avoid noise from rarely played heroes.
- Level is the hero's level at the end of one match and resets every game. Lower reach at high levels mostly reflects shorter games, not players getting stuck.

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
| 1 | `dim_player` includes a placeholder "unknown member" row for players with private/missing profiles — `player_key = '-1'`, `account_id` null, `is_anonymous = true`. Added via `UNION ALL` directly in `dim_player.sql`, the same pattern used for the 'Unknown' row on every other dimension in this project (not a seed file, and not resolved in staging — the bronze layer stays raw). | OpenDota omits `account_id` for players with private profiles. Using a default/unknown dimension member (a standard Kimball pattern) keeps every fact row joinable without dropping data or leaving null foreign keys. Matching the `UNION ALL` pattern used everywhere else keeps the project's dimensions consistent with each other. |
| 2 | Heroes can have more than one role (e.g. Anti-Mage is Carry, Escape, and Nuker at once), which doesn't fit in a single flat dimension row. Resolved with a `dim_role` dimension plus a `bridge_hero_role` bridge table — one row per hero/role pair. | This is the standard Kimball pattern for a many-to-many relationship between a fact and a dimension, and avoids forcing a hero into just one role. |
| 3 | `dim_hero` and `dim_item` keep a history of changes (SCD Type 2) instead of overwriting old values the way every other dimension here does. | Heroes get reworked and items get rebalanced almost every Dota 2 patch — a hero's role or an item's cost today isn't necessarily what it was when an older match was played. Keeping history means a match's stats always reflect the hero or item as it actually was back then, not as it is now. |
| 4 | `dim_hero`'s history is built with a dbt snapshot sitting on top of a staging model materialized as `ephemeral`, using the snapshot's `check` strategy rather than `timestamp`. (`dim_item` follows the same pattern.) | Ephemeral means the staging step never needs its own table in Snowflake — its only job is feeding the snapshot. `check` was the right call because reference data here gets reloaded by replacing it wholesale each run, which stamps every row with a new load timestamp whether or not anything actually changed — a `timestamp` strategy would have recorded a "change" on every single run, for every hero. `check` instead compares the real tracked columns and only records a new version when something genuinely did. |
| 5 | Tests deliberately overlap across layers — e.g. `source_hero_id` is checked for uniqueness in staging, again in the snapshot (scoped to the currently active version), and again in `dim_hero`. In a production setting this redundancy has a real warehouse-compute cost, and the usual trade-off is to test a given invariant once, at the layer closest to where it could first break, rather than re-paying for it downstream. | This is a learning project, so the layered tests are left in on purpose — the point is to see directly how a dbt snapshot's SCD Type 2 merge can silently break (duplicate business key, missing `dbt_valid_to` close) and to catch it at every layer while learning, not to run the leanest possible test suite. |

## 🚧 Status

Phase 1: ingestion, modeling, and orchestration — in progress.
Phase 2 (planned): CI/CD and dbt-in-production practices.

## ⚙️ Setup

_Coming soon._
