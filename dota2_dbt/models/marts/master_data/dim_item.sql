{{ config(materialized = 'table') }}

with items as
(
    select
        {{ dbt_utils.generate_surrogate_key(['dbt_scd_id']) }} as item_id,
        source_item_id,
        staging_item_id,
        item_name,
        item_cost,
        case when dbt_is_deleted = 'True' then true else false end as is_deleted,
        dbt_scd_id,
        dbt_valid_from,
        dbt_valid_to,
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from {{ ref('scd_master_data_items') }}
)

select * from items

union all

select
    {{ dbt_utils.generate_surrogate_key(["'unknown_item'"]) }} as item_id,
    cast(null as number) as source_item_id,
    cast(null as text) as staging_item_id,
    'Unknown' as item_name,
    cast(null as number) as item_cost,
    false as is_deleted,
    cast(null as text) as dbt_scd_id,
    cast(null as timestamp_ntz) as dbt_valid_from,
    cast(null as timestamp_ntz) as dbt_valid_to,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
