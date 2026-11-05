{{
    config(
        materialized = 'table'
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['source_team_id']) }} as team_id,
    source_team_id,
   -- staging_team_id,
    team_name,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
from {{ ref('stg_master_data__team') }}




