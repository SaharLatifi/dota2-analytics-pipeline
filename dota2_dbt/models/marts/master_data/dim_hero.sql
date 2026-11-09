{{ config(materialized = 'table') }}

with heroes as
(
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
)

select * from heroes

union all

select
    '-1' as hero_id,
    cast(null as number) as source_hero_id,
    cast(null as text) as staging_hero_id,
    'Unknown' as hero_name,
    cast(null as text) as primary_attribute,
    cast(null as text) as attack_type,
    cast(null as number) as leg_count,
    cast(null as text) as dbt_scd_id,
    cast(null as timestamp_ntz) as dbt_valid_from,
    cast(null as timestamp_ntz) as dbt_valid_to,
    current_timestamp() as created_at,
    current_timestamp() as updated_at



