with source_region as 
(
   select 
     {{ dbt_utils.generate_surrogate_key(['_dlt_id']) }} as staging_region_id ,
     id              as source_region_id,
     trim(name)      as region_name,
     _dlt_id         as dlt_row_id,
     _dlt_load_id    as dlt_load_id
    from {{ source('raw_master_data' , 'constants_region') }}
)

select *
from source_region