{{ config(
    materialized='incremental',
    unique_key='match_player_id',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns',
    merge_exclude_columns = ['created_at']
) }}


with match_player as
(
    select 
        m.match_id,
        mp.source_match_id,
        mp.staging_match_id,      
        mp.staging_match_player_id  ,
        mp.account_id,
        rank_bracket_id ,
        rank_star ,
        player_slot,
        h.hero_id, 
        is_radiant,
        kills,
        deaths,
        assists,
        kda,
        gold_per_min,
        xp_per_min,
        level,
        net_worth,
        last_hits,
        denies,
        hero_damage,
        tower_damage,
        teamfight_participation,
        towers_killed,
        roshans_killed,
        lane,
        lane_role,
        lane_efficiency,
        actions_per_min,
        mp.dlt_row_id,
        mp.dlt_load_id
    from {{ ref('stg_matches__match_players')}}   mp
        inner join  {{ ref('fct_match') }} m on m.staging_match_id = mp.staging_match_id
        inner join {{ ref('dim_hero') }} h on h.source_hero_id = mp.source_hero_id and h.dbt_valid_to is null
        
    {% if is_incremental() %}
        where mp.dlt_load_id > (select coalesce(max(dlt_load_id),0) from {{ this }})
    {% endif %}
        
) , match_player_with_surrogate_key as (
    select 
        {{ dbt_utils.generate_surrogate_key(['match_id', 'mp.account_id']) }} as match_player_id,
        match_id,
        staging_match_player_id ,
        coalesce(p.player_id, '-1') as player_id,
        rank_bracket_id ,
        rank_star ,
        player_slot,
        hero_id,
        case --radiant team id = 1, dire team id = 2
            when is_radiant = true then 1 
            when is_radiant = false then 2
            else null
        end as team_id,
        kills,
        deaths,
        assists,
        kda,
        gold_per_min,
        xp_per_min,
        level,
        net_worth,
        last_hits,
        denies,
        hero_damage,
        tower_damage,
        teamfight_participation,
        towers_killed,
        roshans_killed,
        lane,
        lane_role,
        lane_efficiency,
        actions_per_min,
        mp.dlt_load_id,
        mp.dlt_row_id    ,
        current_timestamp() as created_at,
        current_timestamp() as updated_at    
    from match_player mp
        left join {{ ref('dim_player') }} p on mp.account_id = p.account_id
)

select *
from match_player_with_surrogate_key


