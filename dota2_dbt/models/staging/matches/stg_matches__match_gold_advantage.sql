with source_match_gold_advantage as 
(
    select
        {{ dbt_utils.generate_surrogate_key(['_dlt_id']) }} as staging_match_gold_adv_id ,
        value                   as radiant_gold_advantage,
        _dlt_list_idx           as minute_mark,
        _dlt_parent_id          as dlt_parent_id,  
        _dlt_id                 as dlt_row_id
    from {{ source('raw_matches','matches__radiant_gold_adv')}}
), matches as 
(
    select 
        source_match_id,
        staging_match_id,
        dlt_row_id
    from {{ ref('stg_matches__matches') }}
)

select 
    g.staging_match_gold_adv_id,
    m.source_match_id,
    m.staging_match_id,
    g.radiant_gold_advantage,
    g.minute_mark,
    g.dlt_row_id
from source_match_gold_advantage g
    inner join matches m on g.dlt_parent_id = m.dlt_row_id 