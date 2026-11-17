{{ config(static_analysis='off') }}

with
    date_spine as (
        {{ dbt_utils.date_spine(
                datepart="day",
                start_date="cast('2010-01-01' as date)",
                end_date="cast('2027-12-31' as date)"
        ) }}
    )

    , enriched_date_spine as (
        select
            {{ dbt_utils.generate_surrogate_key(['date_day']) }}  as date_id , 
            * , 
            year(date_day) as year_number ,
            month(date_day) as month_number ,
            monthname(date_day) as month_name ,
            day(date_day) as day_number  ,
            dayofweek(date_day) as day_of_week , -- 0 = Sunday ... 6 = Saturday (Snowflake default WEEK_START)
            dayofyear(date_day) as day_of_year ,
            weekofyear(date_day) as week_number ,
            case
                when dayofweek(date_day) in (0, 6) then true
                else false
            end as is_weekend ,
           case
                when month(date_day) in (11, 12) then 'Holiday Season'
                when month(date_day) in (6, 7, 8) then 'Summer Season'
                when month(date_day) in (3, 4, 5) then 'Spring Season'
                else 'Off Season'
            end as business_season
        from date_spine
    )

select *
from enriched_date_spine