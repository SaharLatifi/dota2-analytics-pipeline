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



def get_data_heroes():

    base_url = os.getenv("OPENDOTA_BASE_URL")
    api_key = os.getenv("API_KEY")
    endpoint= "heroes"

    
    if not base_url:
        raise ValueError(
        "OPENDOTA_BASE_URL is missing from the environment variables"
    )

    heroes_data = get_data(base_url, api_key, endpoint)    
      
    if not heroes_data:
        raise ValueError("OpenDota returned no hero data.")

    if not isinstance(heroes_data, list):
        raise TypeError(
            "Expected the heroes response to be a list."
        )

    return heroes_data

if __name__ == "__main__":
    heroes_data = get_data_heroes()
    if heroes_data:
        # Convert to DataFrame
        df_heroes = pd.DataFrame(heroes_data) 
        print(df_heroes.head())      

