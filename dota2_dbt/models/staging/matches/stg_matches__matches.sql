with source_matches as 
(
    select 
         {{ dbt_utils.generate_surrogate_key(['_dlt_id']) }} as staging_match_id ,
         match_id                          as      source_match_id,
         to_timestamp(start_time)          as      started_at,
         to_date(to_timestamp(start_time)) as      match_date,
         round(duration/60, 0)             as      duration_min, 
         radiant_win,
         tower_status_radiant              as radiant_tower_status_bitmask,
         tower_status_dire                 as dire_tower_status_bitmask,
         barracks_status_radiant           as radiant_barracks_status_bitmask,
         barracks_status_dire              as dire_barracks_status_bitmask,
         first_blood_time                  as first_blood_time_sec,
         radiant_score                     as radiant_kill_count,
         dire_score                        as dire_kill_count,
         human_players , 
         lobby_type                        as source_lobby_type_id,
         game_mode                         as source_game_mode_id,
         region                            as source_region_id,
         patch, 
         version                           as parse_version,
         od_data__has_parsed               as is_parsed,
         _dlt_id                           as dlt_row_id, 
         _dlt_load_id                      as dlt_load_id

    from {{ source('raw_matches','matches')}}
)

select *
from source_matches