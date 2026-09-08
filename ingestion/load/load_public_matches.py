import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Make the ingestion package importable regardless of how this script is invoked
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from extract.get_data_public_matches import get_data_public_matches
from load.dlt_loader import load_to_snowflake


def main():
    # 1. Load environment variables
    load_dotenv()

    pipeline_name = "dota2_public_matches_pipeline"
    schema_name = os.getenv("SNOWFLAKE_SCHEMA")
    table_name = os.getenv("SNOWFLAKE_PUBLIC_MATCHES_TABLE")

    if not schema_name:
        raise ValueError("SNOWFLAKE_SCHEMA is missing from the .env file")
    if not table_name:
        raise ValueError("SNOWFLAKE_PUBLIC_MATCHES_TABLE is missing from the .env file")

    # 2. Extract public matches
    public_matches_data = get_data_public_matches()

    if not public_matches_data:
        raise ValueError("No public matches data was returned by the API")

    # 3. Run the pipeline
    load_info = load_to_snowflake(
        pipeline_name,
        public_matches_data,
        schema_name,
        table_name,
        "append"
    )

    print(f"Load info: {load_info}")


if __name__ == "__main__":
    main()
