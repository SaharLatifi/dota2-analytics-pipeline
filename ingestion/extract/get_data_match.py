import requests
import pandas as pd
from dotenv import load_dotenv
import os
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from extract.utils.api_client import get_data


load_dotenv()  # Load environment variables from .env file



def get_data_match(match_id):

    base_url = os.getenv("OPENDOTA_BASE_URL")
    api_key = os.getenv("API_KEY")

    
    if not base_url:
        raise ValueError(
        "OPENDOTA_BASE_URL is missing from the environment variables"
    )


    match_data = get_data(base_url, api_key, "matches/" + str(match_id))    
      
    if not match_data:
        raise ValueError("OpenDota returned no match data.")

   

    return match_data

if __name__ == "__main__":
    match_data = get_data_match(12345)
    if match_data:
        # Convert to DataFrame
        df_matches = pd.DataFrame(match_data) 
        print(df_matches.head())      

