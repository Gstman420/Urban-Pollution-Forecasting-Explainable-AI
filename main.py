from fastapi import FastAPI
import pandas as pd
import joblib
import os
import google.generativeai as genai
import numpy as np
from datetime import datetime, timedelta
from fastapi.middleware.cors import CORSMiddleware



from schemas import PredictionRequest, PredictionResponse
from utils.feature_builder import build_features

# -------------------------------
# BASE DIRECTORY
# -------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# -------------------------------
# Gemini configuration (optional)
# -------------------------------
GEMINI_API_KEY = os.getenv("GOOGLE_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

# -------------------------------
# FastAPI app
# -------------------------------
app = FastAPI(title="Urban Pollution Prediction API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://urban-pollution-frontend.web.app",
        "http://localhost:58360"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -------------------------------
# Load model and dataset
# -------------------------------
model = joblib.load(os.path.join(BASE_DIR, "model", "pollution_model.pkl"))
df = pd.read_csv(os.path.join(BASE_DIR, "data", "air_pollution_2021_2025.csv"))
df["date"] = pd.to_datetime(df["date"])

CONFIDENCE_R2 = 0.94
ANCHOR_WINDOW = 10
MAX_ADJUSTMENT = 0.30

# -------------------------------
# Region-based rule
# -------------------------------
def apply_region_rules(prediction, region):
    rules = {
        "Rainy Area": 0.90,
        "Windy Area": 0.95,
        "Normal Urban Area": 1.00,
        "Seasonal Variation Area": 1.10,
        "High Pollution Area": 1.25
    }
    return prediction * rules.get(region, 1.0)

# -------------------------------
# Anchor window selector
# -------------------------------
def get_anchor_window(df, target_date, window=10):
    idx = (df["date"] - target_date).abs().idxmin()
    start = max(idx - window + 1, 0)
    return df.iloc[start:idx + 1]

# -------------------------------
# Adjustment logic (EXISTING)
# -------------------------------
def calculate_adjustment(window_df):
    avg_wind = window_df["wnd_spd"].mean()
    avg_press = window_df["press"].mean()
    total_rain = window_df["rain"].sum()
    total_snow = window_df["snow"].sum()

    adjustment = 0.0

    if total_rain > 0 or total_snow > 0:
        adjustment -= 0.20
    else:
        if avg_wind < 5:
            adjustment += 0.15
        elif avg_wind > 15:
            adjustment -= 0.15

        if avg_press > 1025:
            adjustment += 0.10
        elif avg_press < 1010:
            adjustment -= 0.10

    adjustment = max(-MAX_ADJUSTMENT, min(MAX_ADJUSTMENT, adjustment))
    return adjustment

# -------------------------------
# NEW: Future AQI evolution logic
# -------------------------------
def apply_future_evolution(prediction, days_ahead, region):
    """
    Applies small, bounded AQI drift for future dates only.
    Change happens every ~7 days.
    """

    # Number of 7-day blocks
    steps = days_ahead // 7
    if steps <= 0:
        return prediction

    # Base small delta (low but noticeable)
    base_delta = 0.03  # 3% per step (small)

    # Region sensitivity
    region_multiplier = {
        "Rainy Area": 0.8,
        "Windy Area": 0.9,
        "Normal Urban Area": 1.0,
        "Seasonal Variation Area": 1.1,
        "High Pollution Area": 1.2
    }.get(region, 1.0)

    total_delta = steps * base_delta * region_multiplier

    # Safety cap: never exceed 20% future drift
    total_delta = min(total_delta, 0.20)

    return prediction * (1 + total_delta)

# -------------------------------
# Health check
# -------------------------------
@app.get("/")
def health_check():
    return {"status": "Backend is running"}

# -------------------------------
# Prediction endpoint
# -------------------------------
@app.post("/predict", response_model=PredictionResponse)
def predict_pollution(request: PredictionRequest):

    # -------------------------------
    # Step 1: Baseline ML prediction
    # -------------------------------
    X = build_features(df)
    base_prediction = float(model.predict(X)[0])

    # -------------------------------
    # Step 2: Anchor window
    # -------------------------------
    target_date = pd.to_datetime(request.date)
    window_df = get_anchor_window(df, target_date, ANCHOR_WINDOW)

    # -------------------------------
    # Step 3: Real-world adjustment
    # -------------------------------
    adjustment_factor = calculate_adjustment(window_df)
    adjusted_prediction = base_prediction * (1 + adjustment_factor)

    # -------------------------------
    # Step 4: Region adjustment
    # -------------------------------
    prediction = apply_region_rules(adjusted_prediction, request.location)

    # -------------------------------
    # NEW Step 5: Future-only evolution
    # -------------------------------
    today = pd.to_datetime(datetime.utcnow().date())
    if target_date > today:
        days_ahead = (target_date - today).days
        if days_ahead <= 180:  # max 6 months
            prediction = apply_future_evolution(
                prediction, days_ahead, request.location
            )

    # -------------------------------
    # Category
    # -------------------------------
    if prediction < 50:
        category = "Good"
    elif prediction < 100:
        category = "Moderate"
    elif prediction < 150:
        category = "Unhealthy"
    else:
        category = "Severe"

    # -------------------------------
    # Explanation (SAFE)
    # -------------------------------
    explanation = (
        "The predicted air quality is based on recent pollution patterns and "
        "historical variability. For future dates, a controlled short-term "
        "simulation is applied to avoid flat predictions."
    )

    # -------------------------------
    # Trend graph (UNCHANGED)
    # -------------------------------
    trend_data = [
        {"day": "Day-4", "value": float(df["pollution_today"].iloc[-5])},
        {"day": "Day-3", "value": float(df["pollution_today"].iloc[-4])},
        {"day": "Day-2", "value": float(df["pollution_today"].iloc[-3])},
        {"day": "Day-1", "value": float(df["pollution_today"].iloc[-2])},
        {"day": "Today", "value": round(prediction, 2)}
    ]

    factors = [
        {"name": "Wind Speed", "impact": 0.5},
        {"name": "Rain / Snow", "impact": 0.3},
        {"name": "Air Pressure", "impact": 0.2}
    ]

    return PredictionResponse(
        location=request.location,
        predicted_pollution=round(prediction, 2),
        category=category,
        confidence_r2=CONFIDENCE_R2,
        explanation=explanation,
        trend_data=trend_data,
        factors=factors
    )
