{{
    config(
        materialized = 'table'
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['source_game_mode_id']) }} as game_mode_id,
    source_game_mode_id,
    staging_game_mode_id,
    game_mode_name,
    is_balanced,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
from {{ ref('stg_master_data__game_mode') }}
