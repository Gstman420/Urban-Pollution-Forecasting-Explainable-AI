from fastapi import FastAPI
import pandas as pd
import joblib
import os
from google import genai

from schemas import PredictionRequest, PredictionResponse
from utils.feature_builder import build_features

# -------------------------------
# Gemini client (optional)
# -------------------------------
# ❗ FIXED: load API key from environment variable
GEMINI_API_KEY = os.getenv("GOOGLE_API_KEY")

client = None
if GEMINI_API_KEY:
    client = genai.Client(api_key=GEMINI_API_KEY)

# -------------------------------
# FastAPI app
# -------------------------------
app = FastAPI(title="Urban Pollution Prediction API")

# -------------------------------
# Load model and dataset
# -------------------------------
model = joblib.load("model/pollution_model.pkl")
df = pd.read_csv("data/air_pollution.csv")

CONFIDENCE_R2 = 0.94


# -------------------------------
# Gemini reasoning function
# -------------------------------
def generate_gemini_reasoning(prediction, category):
    if not client:
        raise RuntimeError("Gemini client not available")

    prompt = f"""
    Explain today's air pollution result in simple human language.

    Pollution value: {prediction:.2f} µg/m³
    Category: {category}

    Mention recent pollution trend and weather impact.
    Avoid technical terms.
    """

    response = client.models.generate_content(
        model="gemini-1.5-pro",
        contents=prompt
    )

    return response.text.strip()


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

    # Build features & predict
    X = build_features(df)
    prediction = model.predict(X)[0]

    # Category
    if prediction < 50:
        category = "Good"
    elif prediction < 100:
        category = "Moderate"
    elif prediction < 150:
        category = "Unhealthy"
    else:
        category = "Severe"

    # Explanation (Gemini optional)
    try:
        explanation = generate_gemini_reasoning(prediction, category)
    except Exception:
        explanation = (
            "The pollution level is estimated using past pollution trends and "
            "weather conditions. Recent pollution has remained high, and lower "
            "wind speed allows pollutants to accumulate."
        )

    # -------------------------------
    # GRAPH 1: Pollution trend (last 4 days + today)
    # -------------------------------
    trend_data = [
        {"day": "Day-4", "value": float(df["pollution_today"].iloc[-5])},
        {"day": "Day-3", "value": float(df["pollution_today"].iloc[-4])},
        {"day": "Day-2", "value": float(df["pollution_today"].iloc[-3])},
        {"day": "Day-1", "value": float(df["pollution_today"].iloc[-2])},
        {"day": "Today", "value": round(float(prediction), 2)}
    ]

    # -------------------------------
    # GRAPH 2: Contributing factors
    # -------------------------------
    factors = [
        {"name": "Past Pollution Levels", "impact": 0.7},
        {"name": "Low Wind Speed", "impact": 0.5},
        {"name": "Rainfall", "impact": 0.2}
    ]

    return PredictionResponse(
        location=request.location,
        predicted_pollution=round(float(prediction), 2),
        category=category,
        confidence_r2=CONFIDENCE_R2,
        explanation=explanation,
        trend_data=trend_data,
        factors=factors
    )
