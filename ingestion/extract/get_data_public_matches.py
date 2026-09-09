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



def get_data_public_matches():

    base_url = os.getenv("OPENDOTA_BASE_URL")
    api_key = os.getenv("API_KEY")
    endpoint= "publicmatches"

    
    if not base_url:
        raise ValueError(
        "OPENDOTA_BASE_URL is missing from the environment variables"
    )

    public_matches_data = get_data(base_url, api_key, endpoint)    
      
    if not public_matches_data:
        raise ValueError("OpenDota returned no public matches data.")

    if not isinstance(public_matches_data, list):
        raise TypeError(
            "Expected the public matches response to be a list."
        )

    return public_matches_data

if __name__ == "__main__":
    public_matches_data = get_data_public_matches()
    if public_matches_data:
        # Convert to DataFrame
        df_public_matches = pd.DataFrame(public_matches_data) 
        print(df_public_matches.head())      

