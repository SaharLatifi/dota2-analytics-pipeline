import requests
import pandas as pd




def get_data(base_url, api_key, endpoint    ):
    
    if not base_url:
        raise ValueError(
        "OPENDOTA_BASE_URL is missing from the environment variables"
    )

    url = f"{base_url}/{endpoint}"

    param = {}
    # API key is optional for this endpoint, only append it if present
    if api_key:
        param['api_key'] = api_key

  
    try:
          response = requests.get(url, params=param,   timeout = 30)
          response.raise_for_status()
          raw_data = response.json()

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

    if not raw_data:
        raise ValueError("OpenDota returned no data.")

   

    return raw_data

if __name__ == "__main__":
    from dotenv import load_dotenv
    import os

    load_dotenv()  # Load environment variables from .env file

    base_url = os.getenv("OPENDOTA_BASE_URL")
    api_key = os.getenv("API_KEY")

    raw_data = get_data(base_url, api_key, "heroes")
    if raw_data:
        # Convert to DataFrame
        df_raw = pd.DataFrame(raw_data) 
        print(df_raw.head())      

