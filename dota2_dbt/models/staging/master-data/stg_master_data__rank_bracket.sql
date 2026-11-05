with source_rank_bracket as
(
    select 
        --{{ dbt_utils.generate_surrogate_key(['rank_bracket_id']) }} as staging_rank_bracket_id ,
        rank_bracket_id              as source_rank_bracket_id,
        trim(rank_bracket_name)      as rank_bracket_name
    from {{ ref('seed_rank_tier')}}
)
select *
from  source_rank_bracket


