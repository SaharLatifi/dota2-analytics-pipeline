import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Make the ingestion package importable regardless of how this script is invoked
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from extract.get_data_heroes import get_data
from load.dlt_loader import load_to_snowflake


def main():
    # 1. Load environment variables
    load_dotenv()

    pipeline_name = "dota2_hero_data_pipeline"
    schema_name = os.getenv("SNOWFLAKE_SCHEMA")
    table_name = os.getenv("SNOWFLAKE_HEROES_TABLE")

    if not schema_name:
        raise ValueError("SNOWFLAKE_SCHEMA is missing from the .env file")
    if not table_name:
        raise ValueError("SNOWFLAKE_HEROES_TABLE is missing from the .env file")

    # 2. Extract heroes
    heroes_data = get_data_heroes()

    if not heroes_data:
        raise ValueError("No heroes data was returned by the API")

    # 3. Run the pipeline
    load_info = load_to_snowflake(
        pipeline_name,
        heroes_data,
        schema_name,
        table_name,
        "replace"
    )

    print(f"Load info: {load_info}")


if __name__ == "__main__":
    main()
