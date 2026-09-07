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

  
    try:
          response = requests.get(url, params=param,   timeout = 30)
          response.raise_for_status()
          heros_data = response.json()
    except requests.exceptions.Timeout
        print("Request timed out. Please try again later.")
        raise

    except  requests.exceptions.ConnectionError
        print("Could  not connect to OpenDota")
        raise

    except requests.exceptions.HTTPError as error:
      print(f"OpenDota returned an HTTP error: {os.error}")
      raise

    except requests.exceptions.JSONDecodeError:
       print("OpenDota returned invalid JSON")
       raise


if __name__ == "__main__":
    heros_data = get_data()
    if heros_data:
        # Convert to DataFrame
        df_heros = pd.DataFrame(heros_data) 
        print(df_heros.head())      

