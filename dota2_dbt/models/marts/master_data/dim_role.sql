{{ config(materialized = 'table') }}

with distinct_roles as
(
    select distinct role_name
    from {{ ref('scd_master_data_heroes__roles') }}
)

, roles as
(
    select
        {{ dbt_utils.generate_surrogate_key(['role_name']) }} as role_id,
        role_name,
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from distinct_roles
)

select * from roles

union all

select
    '-1' as role_id,
    'Unknown' as role_name,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
