with source_heroes as
(
    select 
        {{ dbt_utils.generate_surrogate_key(['_dlt_id']) }} as staging_hero_id,
        id                  as      source_hero_id, 
        localized_name      as      hero_name, 
        primary_attr        as      primary_attribute,
        attack_type , 
        legs                as      leg_count,
        _dlt_id             as      dlt_row_id    ,
        _dlt_load_id        as      dlt_load_id
    from {{ source('raw_master_data','heroes') }}
)

select *
from source_heroes