-- Every Dota 2 match is 5v5, so raw matches__players should have exactly
-- 10 rows per match (one per _dlt_parent_id). Returns any match that doesn't.
select
    _dlt_parent_id,
    count(*) as player_count
from {{ source('raw_matches', 'matches__players') }}
group by 1
having count(*) <> 10
