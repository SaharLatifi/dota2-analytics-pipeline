{{ config(materialized = 'table') }}

with game_modes as
(
    select
        {{ dbt_utils.generate_surrogate_key(['source_game_mode_id']) }} as game_mode_id,
        source_game_mode_id,
        staging_game_mode_id,
        game_mode_name,
        is_balanced,
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from {{ ref('stg_master_data__game_mode') }}
)

select * from game_modes

union all

select
    {{ dbt_utils.generate_surrogate_key(["'unknown_game_mode'"]) }} as game_mode_id,
    cast(null as number) as source_game_mode_id,
    cast(null as text) as staging_game_mode_id,
    'Unknown' as game_mode_name,
    cast(null as boolean) as is_balanced,
    current_timestamp() as created_at,
    current_timestamp() as updated_at


