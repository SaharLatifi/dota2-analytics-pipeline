with source_game_mode as
(
    select 
        {{ dbt_utils.generate_surrogate_key(['_dlt_id']) }} as staging_game_mode_id ,
        id              as source_game_mode_id,
        trim(regexp_replace(name, '^game_mode_',''))  as game_mode_name,
        balanced        as is_balanced, 
        _dlt_id         as dlt_row_id ,
        _dlt_load_id    as dlt_load_id
    from {{ source('raw_master_data' , 'constants_game_mode')}}
)

select *
from  source_game_mode 
