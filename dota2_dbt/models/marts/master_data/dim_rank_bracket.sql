{{
    config(
        materialized = 'table'
    )
}}

with rank_brackets as
(
    select
        {{ dbt_utils.generate_surrogate_key(['source_rank_bracket_id']) }} as rank_bracket_id,
        source_rank_bracket_id,
        rank_bracket_name,
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from {{ ref('stg_master_data__rank_bracket') }}
)

select * from rank_brackets

union all

select
    {{ dbt_utils.generate_surrogate_key(["'unknown_rank_bracket'"]) }} as rank_bracket_id,
    cast(null as number) as source_rank_bracket_id,
    'Unknown' as rank_bracket_name,
    current_timestamp() as created_at,
    current_timestamp() as updated_at




