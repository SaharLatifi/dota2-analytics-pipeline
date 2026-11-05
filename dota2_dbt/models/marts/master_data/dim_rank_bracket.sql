{{
    config(
        materialized = 'table'
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(['source_rank_bracket_id']) }} as rank_bracket_id,
    source_rank_bracket_id,
    rank_bracket_name,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
from {{ ref('stg_master_data__rank_bracket') }}




