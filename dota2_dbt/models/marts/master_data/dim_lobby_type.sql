{{ config(materialized = 'table') }}

with lobby_types as
(
    select
        {{ dbt_utils.generate_surrogate_key(['source_lobby_type_id']) }} as lobby_type_id,
        source_lobby_type_id,
        staging_lobby_type_id,
        lobby_type_name,
        is_balanced,
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from {{ ref('stg_master_data__lobby_type') }}
)

select * from lobby_types

union all

select
    '-1' as lobby_type_id,
    cast(null as number) as source_lobby_type_id,
    cast(null as text) as staging_lobby_type_id,
    'Unknown' as lobby_type_name,
    cast(null as boolean) as is_balanced,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
