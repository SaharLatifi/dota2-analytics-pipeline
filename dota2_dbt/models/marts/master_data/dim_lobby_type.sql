{{
    config(
        materialized = 'table'
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['source_lobby_type_id']) }} as lobby_type_id,
    source_lobby_type_id,
    staging_lobby_type_id,
    lobby_type_name,
    is_balanced,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
from {{ ref('stg_master_data__lobby_type') }}
