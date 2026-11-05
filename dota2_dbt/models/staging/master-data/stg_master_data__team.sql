with source_team as
(
    select 
       -- {{ dbt_utils.generate_surrogate_key(['team_key']) }} as staging_team_id ,
        cast(team_key as integer)   as source_team_id,
        trim(team_name)             as team_name
    from {{ ref('seed_team')}}
)
select *
from  source_team