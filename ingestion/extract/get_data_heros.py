import requests
from pprint import pprint
import pandas as pd
from dotenv import load_dotenv
import os

load_dotenv()  # Load environment variables from .env file



def get_data():

    # API key is optional for this endpoint, only append it if present
    base_url = os.getenv("OPENDOTA_BASE_URL")
    api_key = os.getenv("API_KEY")

    # API key is optional for this endpoint, only append it if present
    url = f"{base_url}/heroes?api_key={api_key}" if api_key else f"{base_url}/heroes"

    param = {}

    if api_key:
        param['api_key'] = api_key

    response = requests.get(url, params=param,   timeout = 30)
    if response.status_code == 200:
        heros_data = response.json()
        print("Request successful")
        print(type(heros_data))
        print(type(heros_data))
        #print(heros_data)
        print(f"Number of heros: {len(heros_data)}")
        print(heros_data[0])
        pprint(heros_data[0]['name'])
        return heros_data
    else:
        print(f"Request failed with status code: {response.status_code}")
        return None

if __name__ == "__main__":
    heros_data = get_data()
    if heros_data:
        # Convert to DataFrame
        df_heros = pd.DataFrame(heros_data)
        print(df_heros.head())      

