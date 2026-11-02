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
| `dim_game_mode`, `dim_lobby_type`, `dim_region`, `dim_rank_tier` | One row per business entity | Standard conformed dimension, SCD Type 1 |
| `dim_team`, `dim_date` | One row per business entity (seeded / generated) | `dim_team`: Radiant or Dire (2 rows, seed). `dim_date`: one calendar day (generated spine) |
| `bridge_hero_role` | Hero × Role | One hero-role classification (many-to-many resolved) |

## SCD Type 2: `dim_hero` and `dim_item`

Every other dimension here is SCD Type 1 — overwrite in place, no history.
`dim_hero` and `dim_item` are the exception, because both represent things
that genuinely change in the game itself over time: heroes get reworked
(roles, primary attribute) and items get rebalanced (cost, stats) almost
every patch. Keeping history means a match's stats stay tied to what the
hero or item actually was when that match was played, not whatever it's
since been changed to.

| Table | Grain | What changes get versioned |
|---|---|---|
| `dim_hero` | One row per hero per version | Role classification and primary attribute/attack type |
| `dim_item` | One row per item per version (not yet wired to a fact table) | Cost and stats |

### How `dim_hero`'s history is actually built

`stg_master_data__heroes` and `stg_master_data__heroes_roles` are
materialized as `ephemeral` — neither one gets a real table or view in
Snowflake, they're inlined as CTEs wherever they're referenced. Their only
job is feeding two dbt snapshots, `scd_master_data_heroes` and
`scd_master_data_heroes__roles`, which are what actually hold the history.
`dim_item` will follow the same shape once it's built.

Two things had to change from how the SCD Type 1 dimensions are built for
this to work:

- **The surrogate key can't be hashed from `_dlt_id` here.** Every other
  staging model hashes its `staging_<table>_id` off `_dlt_id`, which is fine
  for SCD1 because nothing needs that value to survive across runs. A
  snapshot's `unique_key` is the opposite — it has to mean "the same real
  hero" on every run, and `_dlt_id` gets reassigned on every reload
  (`disposition="replace"` truncates and reinserts everything each sync).
  So `stg_master_data__heroes.staging_hero_id` hashes off `id` instead, and
  `stg_master_data__heroes_roles.staging_hero_role_id` hashes off
  `(source_hero_id, role_name)` — the actual business key of "this hero" and
  "this hero's role," which stays the same hash value every single run.
- **The snapshot uses `strategy: check`, not `timestamp`.** `timestamp`
  would compare `updated_at` against `dlt_load_id`'s load time — but that
  timestamp changes on every sync regardless of whether the hero's data
  actually changed, so it would record a "new version" on every single
  `dbt snapshot` run, for every hero, forever. `check` compares the real
  tracked columns (`hero_name`, `primary_attribute`, `attack_type`,
  `leg_count` for heroes; `role_name` for roles) and only versions a row
  when one of those genuinely changed.

One more wrinkle specific to `heroes_roles`: a role's identity (the
`unique_key`) is itself built from `role_name`, so `check_cols` can never
actually catch "the same role changed" — any change to `role_name` produces
a brand-new key instead. The real history event for this table is a hero
gaining or losing a role entirely, which shows up as a new key appearing or
an old one disappearing from the source. `hard_deletes: new_record` is set
so that when a role disappears, it's recorded as its own explicit row
instead of silently vanishing from the snapshot.
