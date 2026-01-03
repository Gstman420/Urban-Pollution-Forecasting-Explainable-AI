import pandas as pd

def build_features(df: pd.DataFrame):
    """
    Build lag and rolling features from historical pollution data
    using the latest available records.
    """

    df = df.copy()

    # Lag features
    df["pollution_2_days_ago"] = df["pollution_today"].shift(2)
    df["pollution_3_days_ago"] = df["pollution_today"].shift(3)
    df["pollution_7_days_ago"] = df["pollution_today"].shift(7)

    # Rolling statistics
    df["pollution_3day_mean"] = df["pollution_today"].shift(1).rolling(3).mean()
    df["pollution_7day_mean"] = df["pollution_today"].shift(1).rolling(7).mean()
    df["pollution_7day_std"]  = df["pollution_today"].shift(1).rolling(7).std()

    # Remove rows with missing values
    df = df.dropna()

    # Take the latest row for prediction
    latest = df.iloc[-1]

    feature_columns = [
        "dew",
        "temp",
        "press",
        "wnd_spd",
        "snow",
        "rain",
        "pollution_yesterday",
        "pollution_2_days_ago",
        "pollution_3_days_ago",
        "pollution_7_days_ago",
        "pollution_3day_mean",
        "pollution_7day_mean",
        "pollution_7day_std"
    ]

    return latest[feature_columns].values.reshape(1, -1)
