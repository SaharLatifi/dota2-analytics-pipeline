import os
from pathlib import Path
from dotenv import load_dotenv
import snowflake.connector

load_dotenv(Path(__file__).resolve().parents[2] / "dota2_dbt" / ".env")  # Load environment variables from .env file

def read_public_matches():

    # Establish a connection to Snowflake   
    connection = snowflake.connector.connect(
        user=os.getenv("DESTINATION__SNOWFLAKE__CREDENTIALS__USERNAME"),
        password=os.getenv("DESTINATION__SNOWFLAKE__CREDENTIALS__PASSWORD"),
        account=os.getenv("DESTINATION__SNOWFLAKE__CREDENTIALS__HOST"),     
        warehouse=os.getenv("DESTINATION__SNOWFLAKE__CREDENTIALS__WAREHOUSE"),
        database=os.getenv("DESTINATION__SNOWFLAKE__CREDENTIALS__DATABASE"),
        schema=os.getenv("SNOWFLAKE_SCHEMA"),
        role=os.getenv("DESTINATION__SNOWFLAKE__CREDENTIALS__ROLE")
    )

    # Matches not yet successfully processed (new or previously failed/stuck), capped per run.
    # Never-attempted matches (status is null) are ordered ahead of retries so a batch of
    # matches that keep failing/never reach 'success' can't occupy every slot forever and
    # starve out matches that haven't been tried even once. attempts < 3 caps retries for
    # the same reason — past that, a match is left alone rather than retried indefinitely.
    query = """
    select m.match_id, m._dlt_id as dlt_id , s.status , s.attempts ,  d.load_id
    from public_matches m
        inner join _dlt_loads d on m._dlt_load_id = d.load_id
        left join control_match_processing_status  s on m._dlt_id = s.dlt_id
    where (s.status is  null or s.status <>'success')
        and coalesce(s.attempts, 0) < 3
    order by case when s.status is null then 0 else 1 end, d.inserted_at , m.match_id
    limit 200;
    """
    try:
        cursor = connection.cursor()

        try:
            cursor.execute(query)
            df = cursor.fetch_pandas_all()
         
        finally:
            cursor.close()

    finally:
        connection.close()

    return df


def main():
    df = read_public_matches()
    print(df.head())
    print("Shape:", df.shape)
    print("Columns:", df.columns.tolist())

if __name__ == "__main__":
    main()        