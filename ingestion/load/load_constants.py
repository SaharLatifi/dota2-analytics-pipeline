import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Make the ingestion package importable regardless of how this script is invoked
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from extract.get_data_constants import get_data_constants
from load.dlt_loader import load_to_snowflake


def main():
    # 1. Load environment variables
    load_dotenv()

    pipeline_name = "dota2_constants_pipeline"
    schema_name = os.getenv("SNOWFLAKE_SCHEMA")
    table_name_fixed_part = os.getenv("SNOWFLAKE_CONSTANTS_TABLE")

    if not schema_name:
        raise ValueError("SNOWFLAKE_SCHEMA is missing from the .env file")
    if not table_name_fixed_part:
        raise ValueError("SNOWFLAKE_CONSTANTS_TABLE is missing from the .env file")

    # 2. Extract constants
    resources =  ['game_mode','lobby_type','region','items']
    for  res in resources:
        constants_data = get_data_constants(res)
        print(constants_data)
        if not constants_data:
            raise ValueError(f"No constants data was returned by the API for {res}")

        # Some constants endpoints return a dict keyed by id; normalize to a list of records
        if isinstance(constants_data, dict):
            constants_data = list(constants_data.values())
    # 3. Run the pipeline
        load_info = load_to_snowflake(
            pipeline_name,
            constants_data,
            schema_name,
            table_name_fixed_part + "_" + res,  # one table per resource
            "replace"
        )

        print(f"Load info for {res}: {load_info}")
   


if __name__ == "__main__":
    main()
