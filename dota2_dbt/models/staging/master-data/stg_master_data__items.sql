with source_constants_items as
(
    select
        {{ dbt_utils.generate_surrogate_key(['_dlt_id']) }} as staging_item_id ,
        id              as      source_item_id,
        trim(dname)     as      item_name,
        cost            as      item_cost,
        _dlt_id         as      dtl_row_id,
        _dlt_load_id    as      dtl_load_id  

    from {{ source('raw_master_data' , 'constants_items')}}

)

select *
from source_constants_items