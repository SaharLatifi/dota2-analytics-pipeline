{{
    config(
        materialized = 'table'
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['source_region_id']) }} as region_id,
    source_region_id,
    staging_region_id,
    region_name,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
from {{ ref('stg_master_data__region') }}
