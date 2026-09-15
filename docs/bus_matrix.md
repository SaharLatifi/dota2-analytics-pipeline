# Enterprise Bus Matrix

Which business process (fact) uses which dimension, and at what grain.
Companion to the [ERD](https://claude.ai/artifact/1owK8c2Mn2QB9QvjxR3B2A) and
[STTM](./sttm_raw_to_staging.md) — this is the planning artifact that comes
before writing the mart SQL, not after.

## Matrix

| Business process (fact) | Grain | Date | Game Mode | Lobby Type | Region | Team | Hero | Role | Rank Tier |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **fact_matches** | One row per match | ● | ● | ● | ● | ● | — | — | — |
| **fact_match_players** | One row per player per match (~10 rows per match) | ○ | ○ | ○ | ○ | ● | ● | ○ | ● |
| **fact_match_gold_advantage** | One row per match per minute | ○ | ○ | ○ | ○ | — | — | — | — |

**Legend:** ● direct foreign key on the fact &nbsp;·&nbsp; ○ reachable only by
joining through another fact via `match_id` (drill-across, not a direct FK)
&nbsp;·&nbsp; — not applicable at this grain

## Why some cells are ○ instead of ●

`fact_match_players` and `fact_match_gold_advantage` don't carry
`game_mode_id`/`lobby_type_id`/`region_id`/`match_date_key` themselves —
those live on `fact_matches`. To filter player performance or gold-advantage
curves by region or game mode, the query joins up to `fact_matches` first via
the shared `match_id` degenerate key, then across to the dimension. This is
a deliberate design choice (avoids repeating match-level attributes on every
player row and every minute-level gold-advantage row) but it does mean those
are two-hop joins, not one-hop — worth knowing before writing a BI query
that assumes a direct FK exists.

## Fan-out warning: Hero → Role

`dim_role` is reachable from `fact_match_players` through `hero_id` →
`bridge_hero_role` → `dim_role`, and that bridge is **one-to-many**: a
single hero can have multiple roles (e.g. Anti-Mage is Carry, Escape, and
Nuker simultaneously). Joining `fact_match_players` to `dim_role` through
the bridge will fan out one player-match row into one row per role. That's
correct and intentional for "performance of heroes classified as Carry"
style questions, but it means `fact_match_players` should **never** be
joined to `dim_role` when the query also needs an accurate row count or sum
at the player-match grain — aggregate by role in its own query, separately
from player-level metrics.

## Grain reference

| Table | Grain | One row represents |
|---|---|---|
| `fact_matches` | Match | One played match (after dedup — raw `matches` is append-only and can have duplicates per `match_id`; this fact resolves to the preferred version) |
| `fact_match_players` | Player × Match | One player's performance in one match (10 per standard match) |
| `fact_match_gold_advantage` | Match × Minute | Radiant's gold lead at one minute of one match |
| `dim_hero`, `dim_game_mode`, `dim_lobby_type`, `dim_region`, `dim_rank_tier` | One row per business entity | Standard conformed dimension |
| `dim_team`, `dim_date` | One row per business entity (seeded / generated) | `dim_team`: Radiant or Dire (2 rows, seed). `dim_date`: one calendar day (generated spine) |
| `bridge_hero_role` | Hero × Role | One hero-role classification (many-to-many resolved) |
