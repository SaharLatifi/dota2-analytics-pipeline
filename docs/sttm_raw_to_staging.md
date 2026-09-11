# Source-to-Target Mapping — Raw → Staging

Field-level mapping from the raw Snowflake tables (loaded as-is from the
OpenDota API) to the dbt staging models that clean, rename, and cast them.
Scope is intentionally limited to **raw → staging** for now — mart-level
design (dimensions, facts, bridges) will get its own STTM once the mart
model is finalized.

**Staging conventions used throughout:**
- Rename to clear, consistent `snake_case` business names.
- Cast to proper types (Unix timestamps → `TIMESTAMP_NTZ`, numeric codes →
  `INTEGER`, flags → `BOOLEAN`).
- Keep every raw row — no filtering, deduplication, or business logic.
- dlt technical columns (`_dlt_id`, `_dlt_load_id`) are kept in staging for
  lineage/joins but excluded from anything past staging.

---

## Contents

1. [`raw.heroes`](#1-rawheroes--stg_opendota__heroes)
2. [`raw.heroes__roles`](#2-rawheroes__roles--stg_opendota__hero_roles)
3. [`raw.constants_game_mode`](#3-rawconstants_game_mode--stg_opendota__game_modes)
4. [`raw.constants_lobby_type`](#4-rawconstants_lobby_type--stg_opendota__lobby_types)
5. [`raw.constants_region`](#5-rawconstants_region--stg_opendota__regions)
6. [`raw.constants_items`](#6-rawconstants_items--stg_opendota__items)
7. [`raw.public_matches`](#7-rawpublic_matches--no-staging-model)
8. [`raw.matches`](#8-rawmatches--stg_opendota__matches)
9. [Match detail child tables — scope decision](#9-match-detail-child-tables--scope-decision)
10. [`raw.matches__players`](#10-rawmatches__players--stg_opendota__match_players)
11. [`raw.matches__radiant_gold_adv`](#11-rawmatches__radiant_gold_adv--stg_opendota__match_gold_advantage)
12. [Not yet in scope](#12-not-yet-in-scope)

---

## 1. `raw.heroes` → `stg_opendota__heroes`

| Source column | Meaning | Staging transformation | Decision |
|---|---|---|---|
| `id` | Hero identifier, matches `hero_id` elsewhere | Rename to `hero_id` | Keep |
| `name` | Internal name, e.g. `npc_dota_hero_antimage` | Rename to `hero_internal_name` | Keep |
| `localized_name` | Display name, e.g. `Anti-Mage` | Rename to `hero_name` | Keep |
| `primary_attr` | `str` / `agi` / `int` / `all` | Rename to `primary_attribute` | Keep as raw code; decode to a readable label in the mart layer |
| `attack_type` | `Melee` / `Ranged` | Rename to `attack_type` | Keep |
| `legs` | Number of legs | Rename to `leg_count` | Keep in staging; unlikely to be used in marts |
| `_dlt_id` | dlt row id | Keep as `dlt_row_id` | Lineage only; needed to join `heroes__roles` |
| `_dlt_load_id` | dlt batch id | Keep as `dlt_load_id` | Lineage only |

## 2. `raw.heroes__roles` → `stg_opendota__hero_roles`

Child table — one row per hero per role (a hero has multiple roles).

| Source column | Meaning | Staging transformation | Decision |
|---|---|---|---|
| `value` | Role name, e.g. `Carry`, `Support` | Rename to `role_name` | Keep |
| `_dlt_parent_id` | Links back to `heroes._dlt_id` | Join to `stg_opendota__heroes.dlt_row_id` to resolve `hero_id` | Keep, resolved to `hero_id` in staging |
| `_dlt_list_idx` | Original position in the roles array | Drop | Not needed |
| `_dlt_id` | dlt row id | Keep as `dlt_row_id` | Lineage only |

## 3. `raw.constants_game_mode` → `stg_opendota__game_modes`

| Source column | Meaning | Staging transformation | Decision |
|---|---|---|---|
| `id` | Game mode code, matches `game_mode` on matches | Rename to `game_mode_id` | Keep |
| `name` | Technical name, e.g. `game_mode_all_pick` | Rename to `game_mode_name`, strip `game_mode_` prefix, title-case | Keep |
| `balanced` | OpenDota's "standard/comparable mode" flag; may be `NULL` | Rename to `is_balanced` | Keep `NULL` as-is in staging — don't collapse to `FALSE` yet |
| `_dlt_id` / `_dlt_load_id` | dlt technical columns | Keep as `dlt_row_id` / `dlt_load_id` | Lineage only |

## 4. `raw.constants_lobby_type` → `stg_opendota__lobby_types`

| Source column | Meaning | Staging transformation | Decision |
|---|---|---|---|
| `id` | Lobby type code, matches `lobby_type` on matches | Rename to `lobby_type_id` | Keep |
| `name` | Technical name, e.g. `lobby_type_ranked` | Rename to `lobby_type_name`, strip `lobby_type_` prefix, title-case | Keep |
| `balanced` | OpenDota's "standard/comparable" flag | Rename to `is_balanced` | Keep `NULL` as-is |
| `_dlt_id` / `_dlt_load_id` | dlt technical columns | Keep as `dlt_row_id` / `dlt_load_id` | Lineage only |

## 5. `raw.constants_region` → `stg_opendota__regions`

| Source column | Meaning | Staging transformation | Decision |
|---|---|---|---|
| `id` | Region code, matches `region` on matches | Rename to `region_id` | Keep |
| `name` | Server region name, e.g. `US WEST` | Rename to `region_name`, title-case | Keep |
| `_dlt_id` / `_dlt_load_id` | dlt technical columns | Keep as `dlt_row_id` / `dlt_load_id` | Lineage only |

Not mapped: `cluster` on match tables is a *different, more granular*
identifier than `region` — it needs its own mapping table before it could
ever join to this dimension, and there's no such mapping planned yet.

## 6. `raw.constants_items` → `stg_opendota__items`

Parent table only for this pass — dlt also creates child tables for nested
item fields (see [Section 12](#12-not-yet-in-scope)).

| Source column | Meaning | Staging transformation | Decision |
|---|---|---|---|
| `id` | Item id, matches `item_0`–`item_5` etc. on match players | Rename to `item_id` | Keep |
| `dname` | Display name, e.g. `Blink Dagger` | Rename to `item_name` | Keep |
| `qual` | Category, e.g. `component`, `consumable`, `artifact` | Rename to `item_quality` | Keep |
| `cost` | Gold cost | Rename to `item_cost` | Keep |
| `created` | Whether the item is assembled from components | Rename to `is_created_item`, cast boolean | Keep |
| `tier` | Neutral-item tier, `NULL` for shop items | Rename to `neutral_item_tier` | Keep |
| `behavior` | How the active ability is used | Rename to `item_behavior` | Keep |
| `mc` | Mana cost | Rename to `mana_cost` | Keep |
| `hc` | Health cost | Rename to `health_cost` | Keep |
| `cd`, `cd__v_bool` | Cooldown; dlt split this into two columns because the source returns either a number or `false` | Normalize both into one `cooldown_seconds` (`NULL` when `cd__v_bool = false`) | Keep, normalized |
| `dmg_type` | Damage type of the active effect | Rename to `damage_type` | Keep |
| `dispellable` | Whether the effect can be dispelled | Rename to `is_dispellable`, cast boolean | Keep |
| `bkbpierce` | Whether the effect pierces debuff immunity | Rename to `pierces_debuff_immunity`, cast boolean | Keep |
| `img` | Icon path | Rename to `item_image_path` | Keep, low priority |
| `notes`, `lore` | Descriptive text | Drop | Not used analytically |
| `_dlt_id` / `_dlt_load_id` | dlt technical columns | Keep as `dlt_row_id` / `dlt_load_id` | Lineage only |

## 7. `raw.public_matches` → *No staging model*

**Decision:** `raw.public_matches` stays in the raw layer only and is
**not** promoted to staging. It exists purely to discover `match_id`
values for the detail pipeline — `/matches/{match_id}` provides the same
match-level fields plus full player detail, so building a staging model on
top of `public_matches` would create two competing sources for the same
match. It's read directly by `read_public_matches.py` (Python, not dbt) and
stays available for pipeline monitoring/troubleshooting.

## 8. `raw.matches` → `stg_opendota__matches`

| Source column | Meaning | Staging transformation | Decision |
|---|---|---|---|
| `match_id` | Unique match identifier | Cast to `NUMBER(38,0)` | Keep — business key |
| `match_seq_num` | Valve's processing-order sequence number | Rename to `match_sequence_number` | Keep |
| `radiant_win` | `TRUE` if Radiant won | Cast boolean; derive `winning_team` (`'radiant'`/`'dire'`) | Keep |
| `duration` | Match length in seconds | Rename to `duration_seconds`; derive `duration_minutes` | Keep |
| `pre_game_duration` | Seconds between game entry and official start | Rename to `pre_game_duration_seconds` | Keep |
| `start_time` | Unix start timestamp | Convert to `started_at` (`TIMESTAMP_NTZ`); derive `match_date` | Keep |
| `tower_status_radiant` / `_dire` | Bitmask of towers left standing | Rename to `radiant_tower_status_bitmask` / `dire_tower_status_bitmask` | Keep raw; decode later only if needed |
| `barracks_status_radiant` / `_dire` | Bitmask of barracks left standing | Rename to `radiant_barracks_status_bitmask` / `dire_barracks_status_bitmask` | Keep raw; decode later only if needed |
| `first_blood_time` | Seconds to first kill | Rename to `first_blood_time_seconds` | Keep |
| `radiant_score` / `dire_score` | Team kill totals | Rename to `radiant_kill_count` / `dire_kill_count` | Keep |
| `human_players` | Human player count (10 = full match) | Cast integer | Keep |
| `lobby_type` | Numeric lobby code | Rename to `lobby_type_id` | Keep — joins to `stg_opendota__lobby_types` |
| `game_mode` | Numeric game mode code | Rename to `game_mode_id` | Keep — joins to `stg_opendota__game_modes` |
| `region` | Numeric region code | Rename to `region_id` | Keep — joins to `stg_opendota__regions` |
| `cluster` | Technical server cluster | Rename to `server_cluster_id` | Keep in staging; usually excluded from marts |
| `patch` | Patch identifier | Rename to `patch_id` | Keep |
| `leagueid` | League/tournament id, usually `0`/null | Rename to `league_id` | Keep |
| `series_id`, `series_type` | Pro match series info | Rename to `series_id`, `series_type_id` | Keep, optional |
| `version` | OpenDota parse-format version | Rename to `parse_version` | Keep — used for quality/dedup logic later |
| `flags`, `engine` | Internal technical values | Keep as raw integers | Low priority; usually excluded from marts |
| `replay_salt`, `replay_url` | Replay download info | Keep as raw strings | Excluded from analytical use |
| `od_data__has_api` | OpenDota has basic API data | Rename to `has_api_data`, cast boolean | Keep |
| `od_data__has_gcdata` | OpenDota has Game Coordinator data | Rename to `has_game_coordinator_data`, cast boolean | Keep |
| `od_data__has_parsed` | Replay has been parsed | Rename to `is_parsed`, cast boolean | **Keep — important quality field**, used to pick the preferred version of a match |
| `od_data__has_archive` | Archived data exists | Rename to `has_archive_data`, cast boolean | Keep |
| `_dlt_id` | dlt row id | Rename to `dlt_row_id` | Lineage; **not** the business key |
| `_dlt_load_id` | dlt batch id | Join to `_dlt_loads.load_id` → `loaded_at` | Keep — needed to pick the most-recently-loaded version of a repeated match |

**Explicitly dropped, not brought into staging:** `throw`, `loss` (need
verification of their real source/grain before use), and every
`all_word_counts__*` column (chat word counts — flattening these into the
match grain would cause uncontrolled schema growth; model separately as a
key-value table later if chat analysis is ever needed).

**Note carried over from raw:** `raw.matches` is append-only, so
`stg_opendota__matches` can contain multiple rows per `match_id`.
Deduplication (preferring the parsed, complete, most-recent version) is an
**intermediate-model** decision, not a staging one — staging keeps every
row.

## 9. Match detail child tables — scope decision

`/matches/{match_id}` returns a large nested payload — dlt splits every
nested list into its own child table under `raw.matches__*`. Ingestion
loads all of them as-is (raw immutability applies here too), but only a
subset is worth carrying into staging. Decision made per table:

| Table | What it holds | Decision |
|---|---|---|
| `matches__players` | Player + hero performance per match | 🟢 Staging + mart — [Section 10](#10-rawmatches__players--stg_opendota__match_players) |
| `matches__radiant_gold_adv` | Radiant's gold lead over Dire, per minute | 🟢 Staging + mart — [Section 11](#11-rawmatches__radiant_gold_adv--stg_opendota__match_gold_advantage) |
| `matches__radiant_xp_adv` | Same, but XP lead | 🟡 Kept raw — not needed for V1 |
| `matches__objectives`, `matches__picks_bans`, `matches__teamfights`, `matches__teamfights_players` | Match events, drafts, teamfight detail | 🟡 Kept raw — possible V2 |
| `matches__chat`, `matches__pauses`, and ~20 granular per-player time-series/log tables (gold/XP/LH/DN over time, purchases, wards, kills, buybacks, connections, ability upgrades, etc.) | Very fine-grained event logs | ⚪ Ignored — not planned for staging |

Full table-by-table list and rationale lives in the ingestion notes; this
section only summarizes the outcome relevant to staging scope.

## 10. `raw.matches__players` → `stg_opendota__match_players`

Child table — one row per player per match. Target mart object is
`fct_match_players` (out of scope for this raw → staging pass), but the
grain and relationship are decided already:

**Relationship:** `matches__players._dlt_parent_id` → `matches._dlt_id`.
Resolve this in staging to attach the real `match_id` — the mart-facing
fact table should use `match_id`, never `_dlt_parent_id`.

| Source column | Meaning | Staging transformation | Decision |
|---|---|---|---|
| `account_id` | Player identifier | Cast integer, nullable | Keep — missing for private profiles |
| `player_slot` | Player's slot in the match | Cast integer | Keep |
| `hero_id` | Hero played | Cast integer | Keep — joins to `stg_opendota__heroes.hero_id` |
| `is_radiant` | Radiant or Dire | Cast boolean | Keep |
| `win` | Whether this player won | Cast boolean | Keep |
| `kills`, `deaths`, `assists` | Kill/death/assist counts | Cast integer | Keep |
| `kda` | Overall KDA performance | Cast numeric | Keep |
| `gold_per_min`, `xp_per_min` | Gold/XP earn rate | Rename to `gold_per_minute`, `xp_per_minute` | Keep |
| `level` | Final hero level | Cast integer | Keep |
| `net_worth` | Final economic value | Cast integer | Keep |
| `last_hits`, `denies` | Farming stats | Cast integer | Keep |
| `hero_damage`, `tower_damage`, `hero_healing` | Damage/healing totals | Cast integer | Keep |
| `teamfight_participation` | Share of teamfights participated in | Cast numeric (0–1) | Keep |
| `towers_killed`, `roshans_killed` | Objective kills by this player | Cast integer | Keep |
| `lane` | Lane played | Cast integer/code | Keep raw code; decode to a readable label in the mart layer |
| `lane_role` | Assigned lane role | Cast integer/code | Keep raw code; decode to a readable label in the mart layer |
| `lane_efficiency` | Laning-phase efficiency | Cast numeric | Keep |
| `actions_per_min` | Player activity rate (APM) | Rename to `actions_per_minute` | Keep |
| `_dlt_id` | dlt row id | Rename to `dlt_row_id` | Lineage only |
| `_dlt_parent_id` | Links to `matches._dlt_id` | Resolve to `match_id` via `stg_opendota__matches` | Keep, resolved |

**Explicitly out of scope for V1 (kept in raw only, not brought to
staging):** `personaname`, `rank_tier`, `gold`, `gold_spent`, item slots
(`item_0`–`item_5`, `backpack_0`–`backpack_2`), purchase/ability/kill/ward
logs, damage-target breakdowns, lane-position-over-time, and the
`benchmarks` child table. These stay available in the raw layer and can be
pulled into staging later if a specific analysis needs them.

## 11. `raw.matches__radiant_gold_adv` → `stg_opendota__match_gold_advantage`

Child table from a flat array on the match response — one row per minute
of the match, giving Radiant's gold lead (negative = Dire is ahead) at
that point in time. This is what enables comeback/momentum analysis.

> **Note:** unlike the tables above, the exact raw column names here
> weren't confirmed against real data yet — dlt's usual pattern for a list
> of plain numbers (the same pattern as `heroes__roles`) is assumed below.
> Confirm against the live Snowflake schema before building this model.

| Source column (assumed) | Meaning | Staging transformation | Decision |
|---|---|---|---|
| `value` | Gold advantage at this minute | Rename to `radiant_gold_advantage` | Keep |
| `_dlt_list_idx` | Position in the array | Rename to `minute_mark` — this *is* the business-meaningful minute index | Keep — this is the key to deriving comeback metrics |
| `_dlt_parent_id` | Links to `matches._dlt_id` | Resolve to `match_id` via `stg_opendota__matches` | Keep, resolved |
| `_dlt_id` | dlt row id | Rename to `dlt_row_id` | Lineage only |

**Why this matters:** with `match_id`, `minute_mark`, and
`radiant_gold_advantage`, later modeling can derive things like "biggest
gold deficit overcome," "lead changes," or "gold advantage at the 10-minute
mark vs. final outcome" — see the corresponding addition to the [dashboard
wireframe](./dashboard_wireframe.md).

## 12. Not yet in scope

Tables/columns that exist in raw but aren't mapped to staging yet —
flagged here so they aren't forgotten, not because they're unimportant:

- `matches__radiant_xp_adv`, `matches__objectives`, `matches__picks_bans`, `matches__teamfights`, `matches__teamfights_players` — kept raw per the [scope decision](#9-match-detail-child-tables--scope-decision), possible V2.
- `matches__players__benchmarks` and the ~20 granular per-player log/time-series tables listed in [Section 9](#9-match-detail-child-tables--scope-decision) — kept raw, not planned for staging.
- `constants_items__*` child tables (`abilities`, `attrib`, `behavior`, `components`, `hint`, `notes`, `target_team`, `target_type`) — nested item properties.

---

## Status

Covers `heroes`, `constants_*`, `matches`, `matches__players`, and
`matches__radiant_gold_adv` — the tables scoped for V1. Mart-level mapping
(dimensions, facts, bridges, surrogate keys) is deliberately out of scope
until the mart model is designed.
