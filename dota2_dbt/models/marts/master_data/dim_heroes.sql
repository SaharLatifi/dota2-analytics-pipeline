select
    {{ dbt_utils.generate_surrogate_key(['dbt_scd_id']) }} as hero_id,
    source_hero_id,
    staging_hero_id,
    hero_name,
    primary_attribute,
    attack_type,
    leg_count,
    dbt_scd_id,
    dbt_valid_from,
    dbt_valid_to,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
from {{ ref('scd_master_data_heroes') }}



