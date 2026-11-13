-- Using 'on_schema_change=sync_all_columns' to ensure that any schema changes in the source are automatically reflected in the incremental model during runs.
-- This helps prevent errors if columns are added or removed in the upstream sources.
{{ config(
    materialized='incremental',
    unique_key='match_performance_team_id',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns',
    merge_exclude_columns = ['created_at']
) }}


with source_matches as
(
    select 
        match_id,
        winner_team_id,
        radiant_win,
        coalesce(radiant_tower_status_bitmask, 0) as radiant_tower_status_bitmask,
        coalesce(dire_tower_status_bitmask, 0) as dire_tower_status_bitmask,
        coalesce(radiant_barracks_status_bitmask, 0) as radiant_barracks_status_bitmask,
        coalesce(dire_barracks_status_bitmask, 0) as dire_barracks_status_bitmask,
        radiant_kill_count,
        dire_kill_count,
        dlt_row_id, 
        dlt_load_id
    from {{ ref('fct_match')}}    
        
    {% if is_incremental() %}
        where dlt_load_id > (select coalesce(max(dlt_load_id),0) from {{ this }})
    {% endif %}

) , match_team_performance_radiant as (
    select 
        {{ dbt_utils.generate_surrogate_key(['match_id',"'1'"]) }} as match_performance_team_id,
        match_id,
        1 as team_id,
        radiant_win  as is_winner, 

        getbit(radiant_tower_status_bitmask,0) as top_tier_1,
        getbit(radiant_tower_status_bitmask,1) as top_tier_2,
        getbit(radiant_tower_status_bitmask,2) as top_tier_3,
        getbit(radiant_tower_status_bitmask,3) as middle_tier_1,
        getbit(radiant_tower_status_bitmask,4) as middle_tier_2,
        getbit(radiant_tower_status_bitmask,5) as middle_tier_3,
        getbit(radiant_tower_status_bitmask,6) as bottom_tier_1,
        getbit(radiant_tower_status_bitmask,7) as bottom_tier_2,
        getbit(radiant_tower_status_bitmask,8) as bottom_tier_3,
        getbit(radiant_tower_status_bitmask,9) as ancient_top,
        getbit(radiant_tower_status_bitmask,10) as ancient_bottom,

        getbit(radiant_barracks_status_bitmask,0) as top_melee,
        getbit(radiant_barracks_status_bitmask,1) as top_ranged,
        getbit(radiant_barracks_status_bitmask,2) as middle_melee,
        getbit(radiant_barracks_status_bitmask,3) as middle_ranged,
        getbit(radiant_barracks_status_bitmask,4) as bottom_melee,
        getbit(radiant_barracks_status_bitmask,5) as bottom_ranged,

        radiant_kill_count as kill_count ,

        radiant_tower_status_bitmask,
        radiant_barracks_status_bitmask ,
            
        dlt_row_id,
        dlt_load_id,
            
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from source_matches  


    ) , match_team_performance_dire as 
    (
    select 
        {{ dbt_utils.generate_surrogate_key(['match_id',"'2'"]) }} as match_performance_team_id,
        match_id ,
        2 as team_id,
        not radiant_win as is_winner,
        getbit(dire_tower_status_bitmask,0) as top_tier_1,
        getbit(dire_tower_status_bitmask,1) as top_tier_2,
        getbit(dire_tower_status_bitmask,2) as top_tier_3,
        getbit(dire_tower_status_bitmask,3) as middle_tier_1,
        getbit(dire_tower_status_bitmask,4) as middle_tier_2,
        getbit(dire_tower_status_bitmask,5) as middle_tier_3,
        getbit(dire_tower_status_bitmask,6) as bottom_tier_1,
        getbit(dire_tower_status_bitmask,7) as bottom_tier_2,
        getbit(dire_tower_status_bitmask,8) as bottom_tier_3,
        getbit(dire_tower_status_bitmask,9) as ancient_top,
        getbit(dire_tower_status_bitmask,10) as ancient_bottom,

        getbit(dire_barracks_status_bitmask,0) as top_melee,
        getbit(dire_barracks_status_bitmask,1) as top_ranged,
        getbit(dire_barracks_status_bitmask,2) as middle_melee,
        getbit(dire_barracks_status_bitmask,3) as middle_ranged,
        getbit(dire_barracks_status_bitmask,4) as bottom_melee,
        getbit(dire_barracks_status_bitmask,5) as bottom_ranged,

        dire_kill_count as kill_count ,

        dire_tower_status_bitmask,
        dire_barracks_status_bitmask ,

        dlt_row_id,
        dlt_load_id,

        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from source_matches  


)
select    
        match_performance_team_id,
        match_id,
        team_id,
        is_winner, 

        top_tier_1,
        top_tier_2,
        top_tier_3,
        middle_tier_1,
        middle_tier_2,
        middle_tier_3,
        bottom_tier_1,
        bottom_tier_2,
        bottom_tier_3,
        ancient_top,
        ancient_bottom,

        top_melee,
        top_ranged,
        middle_melee,
        middle_ranged,
        bottom_melee,
        bottom_ranged,

        top_tier_1 + top_tier_2 + top_tier_3 + middle_tier_1 + middle_tier_2 + middle_tier_3 + bottom_tier_1 + bottom_tier_2 + bottom_tier_3 + ancient_top + ancient_bottom as total_tower_count ,
        top_melee + top_ranged + middle_melee + middle_ranged + bottom_melee + bottom_ranged as total_barracks_count ,
        
        kill_count ,

        radiant_tower_status_bitmask,
        radiant_barracks_status_bitmask ,
               
        dlt_row_id,
        dlt_load_id,
        
        created_at,
        updated_at 

from match_team_performance_radiant

union all

select  
        match_performance_team_id,
        match_id ,
        team_id,
        is_winner,
        top_tier_1,
        top_tier_2,
        top_tier_3,
        middle_tier_1,
        middle_tier_2,
        middle_tier_3,
        bottom_tier_1,
        bottom_tier_2,
        bottom_tier_3,
        ancient_top,
        ancient_bottom,

        top_melee,
        top_ranged,
        middle_melee,
        middle_ranged,
        bottom_melee,
        bottom_ranged,

        top_tier_1 + top_tier_2 + top_tier_3 + middle_tier_1 + middle_tier_2 + middle_tier_3 + bottom_tier_1 + bottom_tier_2 + bottom_tier_3 + ancient_top + ancient_bottom as total_tower_count ,
        top_melee + top_ranged + middle_melee + middle_ranged + bottom_melee + bottom_ranged as total_barracks_count ,

        kill_count ,

        dire_tower_status_bitmask,
        dire_barracks_status_bitmask ,
        
        dlt_row_id,
        dlt_load_id,

        created_at,
        updated_at

from match_team_performance_dire 