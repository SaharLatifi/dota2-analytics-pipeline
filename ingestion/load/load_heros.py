import os
#import snowflake.connector
from dotenv import load_dotenv
from extract.get_data_heros import get_data
from load.dlt_loader import load_to_snowflake

# 1. Load environment variables
load_dotenv()  

pipeline_name="dota2_hero_data_pipeline"
schema_name= os.getenv("SNOWFLAKE_SCHEMA")
table_name= os.getenv("SNOWFLAKE_HEROES_TABLE") 

if not schema_name:
    raise ValueError("SNOWFLAKE_SCHEMA is missing from the .env file")
if not table_name:
    raise ValueError("SNOWFLAKE_HEROES_TABLE is missing from the .env file")

# 2. Extract heroes
heros_data=get_data()

if not heros_data:
    raise ValueError("No heroes data was returned by the API")



# 4. Run the pipeline
load_info = load_to_snowflake(
    pipeline_name,
    heros_data,
    schema_name,
    table_name ,
    "replace"
    )

print(f"Load info: {load_info}")



#connection = snowflake.connector.connect(
#    user=os.getenv("SNOWFLAKE_USER"),
#    password=os.getenv("SNOWFLAKE_PASSWORD"),
#    account=os.getenv("SNOWFLAKE_ACCOUNT"),
#    warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
#    database=os.getenv("SNOWFLAKE_DATABASE"),
#    schema=os.getenv("SNOWFLAKE_SCHEMA"),
#    role=os.getenv("SNOWFLAKE_ROLE")
#)

#cursor = connection.cursor()

#try:
#    # Create the table if it doesn't exist
#    cursor.execute("""
#        CREATE TABLE IF NOT EXISTS test_table (
#            id INT,
#            name STRING
#        )
#    """)
#    print("Table created successfully or already exists.")  

#except Exception as e:
#    print(f"Error occurred: {e}")
#finally:
#    cursor.close()
#    connection.close()