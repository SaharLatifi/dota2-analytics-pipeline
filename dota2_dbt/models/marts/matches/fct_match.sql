-- Using 'on_schema_change=sync_all_columns' to ensure that any schema changes in the source are automatically reflected in the incremental model during runs.
-- This helps prevent errors if columns are added or removed in the upstream sources.
{{ config(
    materialized='incremental',
    unique_key='match_id',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns',
    merge_exclude_columns = ['created_at']
) }}


with source_matches as
(
    select 
        row_number() over(partition by source_match_id order by dlt_load_id desc) as row_num,
        staging_match_id ,
        source_match_id,
        match_date,
        started_at,
        duration_min, 
        radiant_win,
        radiant_tower_status_bitmask,
        dire_tower_status_bitmask,
        radiant_barracks_status_bitmask,
        dire_barracks_status_bitmask,
        radiant_kill_count,
        dire_kill_count,
        first_blood_time_sec,
        human_players , 
        source_lobby_type_id,
        source_game_mode_id,
        source_region_id,
        patch, 
        parse_version,
        is_parsed,
        dlt_row_id, 
        dlt_load_id
    from {{ ref('stg_matches__matches')}}    
        
    {% if is_incremental() %}
        where dlt_load_id > (select coalesce(max(dlt_load_id),0) from {{ this }})
    {% endif %}

) , source_matches_dedup as (
    select *
    from source_matches
    where row_num = 1

) , match_with_surrogate_key as (
    select 
        {{ dbt_utils.generate_surrogate_key(['source_match_id']) }} as match_id,
        staging_match_id ,
        source_match_id,
        match_date,
        started_at,
        duration_min,
        radiant_win, 
        case --radiant team id = 1, dire team id = 2
            when radiant_win = true then 1 
            when radiant_win = false then 2
            else null
        end as winner_team_id,
        radiant_tower_status_bitmask,
        dire_tower_status_bitmask,
        radiant_barracks_status_bitmask,
        dire_barracks_status_bitmask,
        radiant_kill_count,
        dire_kill_count,
        first_blood_time_sec,
        human_players ,
        -- null or unmapped source ids fall back to the 'Unknown' member (-1) of each dimension
        coalesce(lt.lobby_type_id, '-1') as lobby_type_id,
        coalesce(gm.game_mode_id, '-1') as game_mode_id,
        coalesce(r.region_id, '-1') as region_id,
        patch,
        parse_version,
        is_parsed,
        dlt_row_id,
        dlt_load_id,
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from source_matches_dedup   m
        left join {{ ref('dim_lobby_type') }} lt on m.source_lobby_type_id = lt.source_lobby_type_id
        left join {{ ref('dim_game_mode') }} gm on m.source_game_mode_id = gm.source_game_mode_id
        left join {{ ref('dim_region') }} r on m.source_region_id = r.source_region_id
)

select    *
from match_with_surrogate_key 