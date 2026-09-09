


import os
import sys
from pathlib import Path

import snowflake.connector
from dotenv import load_dotenv

# Make the ingestion package importable regardless of how this script is invoked
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from ingestion.read.read_public_matches import read_public_matches
from extract.get_data_match import get_data_match
from load.dlt_loader import load_to_snowflake



def update_match_status(table_name, dlt_id, match_id, status, last_error=None):
    # Records per-match load outcome in the control table for retries/auditing
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

    query = f"""
    MERGE INTO {table_name} AS target
    USING (
        SELECT
            %(dlt_id)s     AS dlt_id,
            %(match_id)s   AS match_id,
            %(status)s     AS status,
            %(last_error)s AS last_error
    ) AS source
    ON target.dlt_id = source.dlt_id
    WHEN MATCHED THEN
        UPDATE SET
            status     = source.status,
            attempts   = target.attempts + 1,
            last_error = source.last_error,
            updated_at = CURRENT_TIMESTAMP()

    WHEN NOT MATCHED THEN
        INSERT (dlt_id, match_id, status, attempts, last_error, created_at, updated_at)
        VALUES (source.dlt_id, source.match_id, source.status, 1, source.last_error, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());
    """

    params = {
        "dlt_id": dlt_id,
        "match_id": match_id,
        "status": status,
        "last_error": last_error
    }

    try:
        cursor = connection.cursor()
        try:
            cursor.execute(query, params)
            connection.commit()
        finally:
            cursor.close()
    finally:
        connection.close()


def main():
    # 1. Load environment variables
    load_dotenv()

    pipeline_name = "dota2_match_data_pipeline"
    schema_name = os.getenv("SNOWFLAKE_SCHEMA")
    table_name = os.getenv("SNOWFLAKE_MATCH_TABLE")
    control_table_name = os.getenv("SNOWFLAKE_CONTROL_TABLE")

    if not schema_name:
        raise ValueError("SNOWFLAKE_SCHEMA is missing from the .env file")
    if not table_name:
        raise ValueError("SNOWFLAKE_MATCH_TABLE is missing from the .env file")
    if not control_table_name:
        raise ValueError("SNOWFLAKE_CONTROL_TABLE is missing from the .env file")

    df_matches = read_public_matches()
    # print(df_matches.head())
    # print("Shape:", df_matches.shape)
    # print("Columns:", df_matches.columns.tolist())

    for row in df_matches.itertuples(index=False):
        print(row._fields)
        match_data = get_data_match(row.MATCH_ID)
        print(match_data)
        if not match_data:
            raise ValueError(f"No match data was returned by the API for {row.MATCH_ID}")

        load_info = None
        try:
            # Per-match try/except so one failure doesn't stop the rest of the loop
             # 3. Run the pipeline
            load_info = load_to_snowflake(
                pipeline_name,
                [match_data],  # Wrap match_data in a list to make it iterable
                schema_name,
                table_name,
                "append",
            )
            update_match_status(
                control_table_name, row.DLT_ID, row.MATCH_ID, "success"
            )
        except Exception as e:
            print(f"Error loading match {row.MATCH_ID}: {e}")
            update_match_status(
                control_table_name, row.DLT_ID, row.MATCH_ID, "failed", str(e)
            )
        finally:
            print(f"Load info for {row.MATCH_ID}: {load_info}")


if __name__ == "__main__":
    main()