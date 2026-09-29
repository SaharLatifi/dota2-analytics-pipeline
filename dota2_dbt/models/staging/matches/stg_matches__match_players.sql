with source_match_players as 
(
    select
        {{ dbt_utils.generate_surrogate_key(['_dlt_id']) }} as staging_match_player_id ,
        account_id ,
        floor(rank_tier/10) as rank_bracket_id ,
        mod(rank_tier,10) as rank_star ,
        player_slot,
        hero_id as source_hero_id, 
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
        _dlt_parent_id          as dlt_parent_id,  
        _dlt_id                 as dlt_row_id
    from {{ source('raw_matches','matches__players')}}
), matches as 
(
    select 
        source_match_id,
        staging_match_id,
        dlt_row_id
    from {{ ref('stg_matches__matches') }}
)

select 
        p.staging_match_player_id ,
        m.source_match_id,
        m.staging_match_id,        
        p.account_id ,
        p.rank_bracket_id ,
        p.rank_star ,
        p.player_slot,
        p.source_hero_id, 
        p.is_radiant,
        p.kills,
        p.deaths,
        p.assists,
        p.kda,
        p.gold_per_min,
        p.xp_per_min,
        p.level,
        p.net_worth,
        p.last_hits,
        p.denies,
        p.hero_damage,
        p.tower_damage,
        p.teamfight_participation,
        p.towers_killed,
        p.roshans_killed,
        p.lane,
        p.lane_role,
        p.lane_efficiency,
        p.actions_per_min,
        p.dlt_row_id
from source_match_players p
    inner join matches m on p.dlt_parent_id = m.dlt_row_id 