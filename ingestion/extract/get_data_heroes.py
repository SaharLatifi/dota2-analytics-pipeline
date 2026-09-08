import requests
import pandas as pd
from dotenv import load_dotenv
import os

load_dotenv()  # Load environment variables from .env file



def get_data():

    base_url = os.getenv("OPENDOTA_BASE_URL")
    api_key = os.getenv("API_KEY")

    
    if not base_url:
        raise ValueError(
        "OPENDOTA_BASE_URL is missing from the environment variables"
    )

    url = f"{base_url}/heroes"

    param = {}
    # API key is optional for this endpoint, only append it if present
    if api_key:
        param['api_key'] = api_key

  
    try:
          response = requests.get(url, params=param,   timeout = 30)
          response.raise_for_status()
          heroes_data = response.json()

    except requests.exceptions.Timeout:
        print("Request timed out. Please try again later.")
        raise

    except  requests.exceptions.ConnectionError:
        print("Could  not connect to OpenDota")
        raise

    except requests.exceptions.HTTPError :
      print(f"OpenDota returned an HTTP error: {response.status_code}")
      raise

    except requests.exceptions.JSONDecodeError:
       print("OpenDota returned invalid JSON")
       raise

    if not heroes_data:
        raise ValueError("OpenDota returned no hero data.")

    if not isinstance(heroes_data, list):
        raise TypeError(
            "Expected the heroes response to be a list."
        )

    return heroes_data

if __name__ == "__main__":
    heroes_data = get_data()
    if heroes_data:
        # Convert to DataFrame
        df_heroes = pd.DataFrame(heroes_data) 
        print(df_heroes.head())      

