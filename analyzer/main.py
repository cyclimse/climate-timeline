from datetime import timedelta, date
import logging
import os

import polars as pl
import openmeteo_requests
import requests_cache
import niquests

from retry_requests import retry

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_DIR = os.path.join(ROOT_DIR, "data")
START_YEAR = 1980

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class ClimateAnalyzer:
    session: niquests.Session
    openmeteo_client: openmeteo_requests.Client

    def __init__(self):
        # Setup the Open-Meteo API client with cache and retry on error
        cache_session = requests_cache.CachedSession(
            ".cache", expire_after=-1
        )  # Never expire
        retry_session = retry(
            cache_session,
            retries=10,
            backoff_factor=3,
            status_to_retry=(500, 502, 504, 429),
        )

        self.session = retry_session
        self.openmeteo_client = openmeteo_requests.Client(session=retry_session)

    def __fetch_weather_data(
        self,
        latitude: float,
        longitude: float,
        start_date: date,
        end_date: date,
    ):
        url = "https://archive-api.open-meteo.com/v1/archive"
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
            "daily": "temperature_2m_mean",
            "timezone": "auto",
        }
        responses = self.openmeteo_client.weather_api(url, params=params)

        return responses[0]  # Assuming single location for simplicity

    def __process_weather_data(self, start_date: date, response) -> pl.DataFrame:
        # Process daily data. The order of variables needs to be the same as requested.
        daily = response.Daily()
        daily_temperature_2m = daily.Variables(0).ValuesAsNumpy()

        # Get days as datetime objects
        days = [
            start_date + timedelta(days=i) for i in range(len(daily_temperature_2m))
        ]

        # Create a DataFrame with the results
        df = pl.DataFrame(
            {
                "date": days,
                "temperature_celsius": daily_temperature_2m,
            }
        )

        return df

    def __compute_historical_avg(self, df: pl.DataFrame) -> pl.DataFrame:
        # Calculate historical average using the computed lookback window for each date
        # Add month and day columns for grouping
        df = df.with_columns(
            [
                pl.col("date").dt.month().alias("month"),
                pl.col("date").dt.day().alias("day"),
                pl.col("date").dt.year().alias("year"),
            ]
        )

        # Calculate historical average excluding current year and future years
        # Use a cumulative mean grouped by month and day, shifted by 1 to exclude current year
        df = df.sort("date").with_columns(
            [
                pl.col("temperature_celsius")
                .cum_sum()
                .over(["month", "day"])
                .alias("cumsum_temp"),
                pl.col("temperature_celsius")
                .cum_count()
                .over(["month", "day"])
                .alias("cumcount_temp"),
            ]
        )

        # Shift to get cumulative values up to (but not including) current year
        df = df.with_columns(
            [
                (
                    pl.col("cumsum_temp").shift(1).over(["month", "day"])
                    / pl.col("cumcount_temp").shift(1).over(["month", "day"])
                ).alias("historical_average_temperature_celsius")
            ]
        )

        # Clean up temporary columns
        df = df.drop(["cumsum_temp", "cumcount_temp", "year", "month", "day"])

        return df

    def __geocode_city(self, city_name: str) -> tuple[float, float]:
        url = "https://geocoding-api.open-meteo.com/v1/search"
        params = {"name": city_name, "count": 1}
        response = self.session.get(url, params=params)

        data = response.json()

        results = data.get("results")
        if not results or len(results) == 0:
            raise RuntimeError(f"City '{city_name}' not found in geocoding API.")

        return results[0]["latitude"], results[0]["longitude"]

    def analyze_for_city(
        self,
        city_name: str,
        start_date: date,
        end_date: date,
    ) -> pl.DataFrame:
        latitude, longitude = self.__geocode_city(city_name)
        response = self.__fetch_weather_data(
            latitude=latitude,
            longitude=longitude,
            start_date=start_date,
            end_date=end_date,
        )

        df = self.__process_weather_data(start_date, response)
        df_with_avg = self.__compute_historical_avg(df)

        return df_with_avg


def main():
    analyzer = ClimateAnalyzer()
    start_date = date(START_YEAR, 1, 1)
    end_date = date.today()

    # Prepare output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    with open(os.path.join(ROOT_DIR, "cities.txt"), "r") as f:
        city_names = f.readlines()

    for city_name in city_names:
        city_name = city_name.strip()

        logger.info(f"Analyzing climate data for {city_name}")

        df = analyzer.analyze_for_city(
            city_name=city_name,
            start_date=start_date,
            end_date=end_date,
        )

        logger.info(f"Finished analyzing climate data for {city_name}")

        print(df.head())

        data = df.write_json()

        with open(f"{OUTPUT_DIR}/climate_data_{city_name.lower()}.json", "w") as f:
            f.write(data)


if __name__ == "__main__":
    main()
