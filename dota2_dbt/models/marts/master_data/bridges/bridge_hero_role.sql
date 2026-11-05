{{ config(materialized = 'table') }}

with hero_roles as
(
    select
        dbt_scd_id,
        source_hero_id,
        role_name,
        case when dbt_is_deleted = 'True' then true else false end as is_deleted,
        dbt_valid_from,
        dbt_valid_to
    from {{ ref('scd_master_data_heroes__roles') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['hero_roles.dbt_scd_id']) }} as hero_role_id,
    h.hero_id,
    r.role_id,
    hero_roles.source_hero_id,
    hero_roles.role_name,
    hero_roles.is_deleted,
    hero_roles.dbt_scd_id,
    hero_roles.dbt_valid_from,
    hero_roles.dbt_valid_to,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
from hero_roles
left join {{ ref('dim_heroes') }} h
    on hero_roles.source_hero_id = h.source_hero_id
    and h.dbt_valid_to is null
left join {{ ref('dim_role') }} r
    on hero_roles.role_name = r.role_name
