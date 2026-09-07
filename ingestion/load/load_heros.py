import os
import snowflake.connector
from dotenv import load_dotenv
from extract.get_data_heros import get_data

hero_data=get_data()

print(f"Number of heros: {len(hero_data)}")

load_dotenv()  # Load environment variables from .env file  

connection = snowflake.connector.connect(
    user=os.getenv("SNOWFLAKE_USER"),
    password=os.getenv("SNOWFLAKE_PASSWORD"),
    account=os.getenv("SNOWFLAKE_ACCOUNT"),
    warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
    database=os.getenv("SNOWFLAKE_DATABASE"),
    schema=os.getenv("SNOWFLAKE_SCHEMA"),
    role=os.getenv("SNOWFLAKE_ROLE")
)


cursor = connection.cursor()

try:
    # Create the table if it doesn't exist
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS test_table (
            id INT,
            name STRING
        )
    """)
    print("Table created successfully or already exists.")  

except Exception as e:
    print(f"Error occurred: {e}")
finally:
    cursor.close()
    connection.close()