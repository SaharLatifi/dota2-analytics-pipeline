# Dashboard Wireframe

Low-fidelity layout for the dashboard that answers the business questions in
the [README](../README.md). Split into three pages instead of one, since the
questions naturally fall into three levels of granularity: match, hero, and
player performance — and no single page has room for all of it without
getting cluttered.

## Page 1 — Match Overview

Answers: Radiant advantage, match volume/duration trends, outcome by game
mode/region.

```
┌──────────────────────────────────────────────────────────────────────┐
│  DOTA 2 MATCH ANALYSIS                                                │
│  Filters: Date Range · Patch · Region · Game Mode · Lobby Type · Rank │
├───────────────┬───────────────┬───────────────┬───────────────────────┤
│ TOTAL MATCHES │ AVG DURATION  │ RADIANT WIN % │ AVG FIRST BLOOD TIME  │
├───────────────┴───────────────┼───────────────┴───────────────────────┤
│ Matches Over Time (line)      │ Win Rate by Game Mode (bar)           │
├────────────────────────────────┼───────────────────────────────────────┤
│ Avg Duration by Game Mode ×    │ Win Rate by Region (bar)              │
│ Rank Tier (heatmap)            │                                       │
├──────────────────────────────────────────────────────────────────────┤
│ Avg Radiant Gold Advantage Over Time (line, x = minute mark, y = gold) │
│ Shows the typical match trajectory and how often leads flip           │
├──────────────────────────────────────────────────────────────────────┤
│ Match Details table: match_id, date, winner, duration, patch, region, │
│ game_mode, rank_tier, radiant_score, dire_score                       │
└──────────────────────────────────────────────────────────────────────┘
```

The gold-advantage chart is new — enabled by `matches__radiant_gold_adv`
(one row per match per minute). It's a strong signature visual for this
project: instead of just knowing Radiant wins ~51% of matches, it shows
*how* — whether matches are typically decided early or come down to
comebacks. See the [STTM](./sttm_raw_to_staging.md#11-rawmatches__radiant_gold_adv--stg_opendota__match_gold_advantage)
for the underlying model.

## Page 2 — Hero Performance

Answers: hero win rates, and whether role/attack type/primary attribute
correlate with win rate.

```
┌──────────────────────────────────────────────────────────────────────┐
│  HERO PERFORMANCE                                                     │
│  Filters: Date Range · Patch · Rank Tier · Role · Attack Type         │
├───────────────┬───────────────┬───────────────────────────────────────┤
│ TOTAL HEROES  │ MOST PICKED   │ HIGHEST WIN RATE                     │
├───────────────┴───────────────┼───────────────────────────────────────┤
│ Win Rate by Primary Attribute │ Win Rate by Attack Type               │
│ (str / agi / int — bar)       │ (melee / ranged — bar)                │
├────────────────────────────────┼───────────────────────────────────────┤
│ Win Rate by Role (bar)         │ Win Rate by Hero × Rank Tier          │
│                                 │ (heatmap, top N heroes)               │
├──────────────────────────────────────────────────────────────────────┤
│ Hero table: hero, primary_attr, attack_type, roles, pick_count,       │
│ win_rate                                                               │
└──────────────────────────────────────────────────────────────────────┘
```

## Page 3 — Player Performance & Trends

Answers: KDA/GPM/XPM trends over time, by rank tier, and their relationship
to win rate.

```
┌──────────────────────────────────────────────────────────────────────┐
│  PLAYER PERFORMANCE                                                   │
│  Filters: Date Range · Patch · Rank Tier                              │
├───────────────┬───────────────┬───────────────┬───────────────────────┤
│ AVG KDA       │ AVG GPM       │ AVG XPM       │ AVG ACTIONS/MIN       │
├───────────────┴───────────────┼───────────────┴───────────────────────┤
│ Avg KDA / GPM / XPM Over Time │ Avg KDA / GPM / XPM by Rank Tier      │
│ (line, one series each)       │ (grouped bar)                         │
├────────────────────────────────┼───────────────────────────────────────┤
│ Win Rate vs Avg Rank Tier      │ Win Rate vs GPM / XPM                │
│ (scatter or binned line)       │ (scatter, binned)                     │
├────────────────────────────────┼───────────────────────────────────────┤
│ Avg Teamfight Participation    │ Win Rate by Lane Role                │
│ by Rank Tier (bar)             │ (Safe / Mid / Off / Jungle — bar)     │
└──────────────────────────────────────────────────────────────────────┘
```

The APM KPI and last row are new — enabled by `matches__players` fields
that weren't in scope before (`teamfight_participation`, `lane_role`,
`actions_per_min`). They're additive: not tied to one of the 10 business
questions below, but they deepen the player-performance story with data
that's now actually available. See the [STTM](./sttm_raw_to_staging.md#10-rawmatches__players--stg_opendota__match_players)
for the field list.

## Business question → page mapping

| # | Question | Page |
|---|---|---|
| 1 | Hero win rates, overall and by rank tier | Hero Performance |
| 2 | Win rate by role / attack type | Hero Performance |
| 3 | Radiant structural win-rate advantage | Match Overview |
| 4 | Avg duration by game mode and rank tier | Match Overview |
| 5 | Win rate by primary attribute / attack type | Hero Performance |
| 6 | Outcome vs. avg rank tier | Player Performance |
| 7 | Match volume/outcome by day/time | Match Overview |
| 8 | Avg KDA/GPM/XPM trend over time | Player Performance |
| 9 | Avg KDA/GPM/XPM by rank tier | Player Performance |
| 10 | GPM/XPM vs. win rate | Player Performance |

## Status

Wireframe only — not yet built. Pages 2 and 3 depend on `dim_hero` and
`fact_player_performance` being modeled in dbt first.
