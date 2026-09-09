import requests
import pandas as pd
from dotenv import load_dotenv
import os
import sys
from pathlib import Path
# Make 'extract' importable no matter how/from where this script is run
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from extract.utils.api_client import get_data


load_dotenv()  # Load environment variables from .env file



def get_data_constants(resource_name):

    base_url = os.getenv("OPENDOTA_BASE_URL")
    api_key = os.getenv("API_KEY")

    
    if not base_url:
        raise ValueError(
        "OPENDOTA_BASE_URL is missing from the environment variables"
    )


    # OpenDota constants are namespaced by resource, e.g. constants/game_mode
    constants_data = get_data(base_url, api_key, "constants/" + resource_name)
      
    if not constants_data:
        raise ValueError("OpenDota returned no constant data.")

   

    return constants_data

if __name__ == "__main__":
    constants_data = get_data_constants("game_mode")
    if constants_data:
        # Convert to DataFrame
        df_constants = pd.DataFrame(constants_data) 
        print(df_constants.head())      

