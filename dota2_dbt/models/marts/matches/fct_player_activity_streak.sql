-- Full rebuild every run: a streak can span several load batches, so an
-- incremental build would split one streak into several rows.
{{ config(materialized='table') }}

with player_match_date_dedup as
(
    select distinct
        player_id,
        match_date
    from {{ ref('fct_match_player') }}
    where player_id <> '-1'
)

, player_match_date_with_rn as
(
    select
        player_id,
        match_date,
        row_number() over (partition by player_id order by match_date) as rn
    from player_match_date_dedup
)

-- Gaps-and-islands: on consecutive days, match_date - (rn - 1) stays constant,
-- so it identifies the streak each date belongs to.
, with_streak_group as
(
    select
        player_id,
        match_date,
        dateadd(day, -(rn - 1), match_date) as streak_group_date
    from player_match_date_with_rn
)

, streaks as
(
    select
        player_id,
        min(match_date) as streak_start_date,
        max(match_date) as streak_end_date,
        count(*) as streak_length_days
    from with_streak_group
    group by player_id, streak_group_date
)

select
    {{ dbt_utils.generate_surrogate_key(['player_id', 'streak_start_date']) }} as player_activity_streak_id,
    player_id,
    streak_start_date,
    streak_end_date,
    streak_length_days,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
from streaks
