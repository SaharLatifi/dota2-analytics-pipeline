import dlt


def load_to_snowflake(
        pipeline_name,
        data, 
        schema_name,
        table_name,
        write_disposition="replace"
):


    if not data:
        raise ValueError("No data was provided for loading to Snowflake")

    if not pipeline_name:
        raise ValueError("Pipeline name is required")

    if not schema_name:
        raise ValueError("Schema name is required")

    if not table_name:
        raise ValueError("Table name is required")  

    
    # 1. Define the pipeline
    pipeline = dlt.pipeline(
        pipeline_name=pipeline_name,
        destination="snowflake",
        dataset_name=schema_name
    )



    # 2. Run the pipeline
    load_info = pipeline.run(
        data,
        table_name = table_name,
        write_disposition = write_disposition
        )

    return load_info

