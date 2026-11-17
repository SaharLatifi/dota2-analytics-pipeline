with source_side as
(
    select
       -- {{ dbt_utils.generate_surrogate_key(['side_key']) }} as staging_side_id ,
        cast(side_key as integer)   as source_side_id,
        trim(side_name)             as side_name
    from {{ ref('seed_side')}}
)
select *
from  source_side