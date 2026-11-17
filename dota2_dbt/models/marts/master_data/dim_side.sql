{{
    config(
        materialized = 'table'
    )
}}

select
    source_side_id as side_id,
    source_side_id,
   -- staging_side_id,
    side_name,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
from {{ ref('stg_master_data__side') }}




