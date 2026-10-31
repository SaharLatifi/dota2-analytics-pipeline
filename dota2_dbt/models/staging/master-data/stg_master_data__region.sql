with source_region as
(
   select
     cast(id as number) as source_region_id,
     trim(name)      as region_name,
     _dlt_id         as dlt_row_id,
     _dlt_load_id    as dlt_load_id
    from {{ source('raw_master_data' , 'constants_region') }}
) 
    select     
     {{ dbt_utils.generate_surrogate_key(['source_region_id']) }} as staging_region_id ,
     source_region_id,
     region_name,
     dlt_row_id,
     dlt_load_id
    from source_region
