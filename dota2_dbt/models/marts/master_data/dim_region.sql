{{ config(materialized = 'table') }}

with regions as
(
    select
        {{ dbt_utils.generate_surrogate_key(['source_region_id']) }} as region_id,
        source_region_id,
        staging_region_id,
        region_name,
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from {{ ref('stg_master_data__region') }}
)

select * from regions

union all

select
    {{ dbt_utils.generate_surrogate_key(["'unknown_region'"]) }} as region_id,
    cast(null as number) as source_region_id,
    cast(null as text) as staging_region_id,
    'Unknown' as region_name,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
