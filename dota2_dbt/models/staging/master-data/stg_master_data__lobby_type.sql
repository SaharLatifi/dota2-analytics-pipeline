with source_lobby_type as
(
    select 
        {{ dbt_utils.generate_surrogate_key(['_dlt_id']) }} as staging_lobby_type_id ,
        id               as source_lobby_type_id ,
        trim(regexp_replace(name__name,'^lobby_type_',''))             as lobby_type_name ,
        balanced         as is_balanced,
        _dlt_id          as dlt_row_id,
        _dlt_load_id     as dlt_load_id

    from {{source('raw_master_data' , 'constants_lobby_type') }}
)

select *
from source_lobby_type