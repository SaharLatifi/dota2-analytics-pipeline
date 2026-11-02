{{ config(materialized = 'ephemeral') }}

with source_heroes_roles as
(
    select 
            trim(value)     as   role_name,
            _dlt_id         as   dlt_row_id ,
            _dlt_parent_id  as   dlt_parent_id
    from {{ source('raw_master_data' , 'heroes__roles')}}
) , heroes as
(
    select 
        staging_hero_id,
        source_hero_id, 
        dlt_row_id    ,
        dlt_load_id
    from {{ ref('stg_master_data__heroes')}}
)


select  
    {{ dbt_utils.generate_surrogate_key(['source_hero_id', 'role_name']) }} as staging_hero_role_id,
    r.role_name,
    h.staging_hero_id,
    h.source_hero_id,
    r.dlt_row_id,
    h.dlt_load_id
from source_heroes_roles r
    left join heroes h on r.dlt_parent_id = h.dlt_row_id
