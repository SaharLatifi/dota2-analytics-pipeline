{{ config(materialized = 'table') }}

with players as
(
    select
        p.account_id,
        p.source_hero_id,
        m.match_date
    from {{ ref('stg_matches__match_players') }} p
    inner join {{ ref('fct_match') }} m on p.staging_match_id = m.staging_match_id
    where p.account_id is not null

) , player_dates as
(
    select
        account_id,
        min(match_date) as first_seen_date,
        max(match_date) as last_seen_date
    from players
    group by account_id

) , hero_pick_counts as
(
    select
        account_id,
        source_hero_id,
        count(*) as pick_count
    from players
    group by account_id, source_hero_id

) , most_played_hero_ranked as
(
    select
        account_id,
        source_hero_id,
        row_number() over (partition by account_id order by pick_count desc, source_hero_id asc) as rn
    from hero_pick_counts

) , known_players as
(
    select
        {{ dbt_utils.generate_surrogate_key(['d.account_id']) }} as player_id,
        d.account_id,
        false as is_anonymous,
        d.first_seen_date,
        cast(date_trunc('week', d.first_seen_date) as date) as first_seen_week,
        d.last_seen_date,
        coalesce(h.hero_name, 'Unknown') as most_played_hero,
        current_timestamp() as created_at,
        current_timestamp() as updated_at
    from player_dates d
        left join most_played_hero_ranked r on d.account_id = r.account_id and r.rn = 1
        left join {{ ref('dim_hero') }} h on r.source_hero_id = h.source_hero_id and h.dbt_valid_to is null
)

select * from known_players

union all

select
    '-1' as player_id,
    cast(null as number) as account_id,
    true as is_anonymous,
    cast(null as date) as first_seen_date,
    cast(null as date) as first_seen_week,
    cast(null as date) as last_seen_date,
    'Unknown' as most_played_hero,
    current_timestamp() as created_at,
    current_timestamp() as updated_at
