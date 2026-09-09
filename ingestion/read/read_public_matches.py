import os
from dotenv import load_dotenv
import snowflake.connector

load_dotenv()  # Load environment variables from .env file

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

    query = """
    select m.match_id, m._dlt_id as dlt_id , s.status , s.attempts ,  d.load_id
    from public_matches m
        inner join _dlt_loads d on m._dlt_load_id = d.load_id
        left join control_match_processing_status  s on m._dlt_id = s.dlt_id
    where s.status is  null or s.status <>'success'
    order by d.inserted_at , m.match_id
    limit 50;
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