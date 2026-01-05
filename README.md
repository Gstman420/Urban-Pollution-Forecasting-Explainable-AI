🌍 Urban Pollution Prediction with Explainable AI

This project is an AI-powered system that predicts daily Air Quality Index (AQI) for a given region and date using historical pollution and weather data.
The system focuses on sensor-less forecasting and provides explainable insights to help users understand why pollution levels are high or low.

🚀 Project Overview

Predicts air pollution levels without relying on physical sensors

Uses time-series machine learning techniques

Provides factor-level explainability for predictions

Designed as a lightweight, cost-efficient MVP

🧠 Model Details

Algorithm: XGBoost Regressor

Problem Type: Time-series regression

Target Variable: Air Quality Index (AQI)

Features Used

Weather parameters (temperature, wind speed, atmospheric pressure, etc.)

Lag features based on previous pollution values

Rolling-window statistics to capture trends and seasonality

Validation Strategy

Time-based train/test split to preserve temporal integrity

📊 Model Performance
Metric	Value
R² Score	0.94
MAE	12.06
RMSE	20.54

The results demonstrate strong predictive accuracy and stable trend forecasting.

🔍 Explainable AI (XAI)

The system uses SHAP (SHapley Additive Explanations) to identify how different factors contribute to each prediction.

Key Contributing Factors

Recent pollution trends

Wind speed

Temperature

Atmospheric pressure

Rainfall indicators

This improves transparency and trust in the model’s outputs.

🗣️ Human-Readable Explanations

Each prediction is accompanied by a natural language explanation that describes:

The reason behind high or low AQI values

The most influential environmental factors

How recent trends impacted the prediction

This makes the system understandable for non-technical users.

🏗️ System Architecture (High-Level)

Frontend: Flutter-based web interface

Backend: FastAPI REST service

ML Model: Pretrained XGBoost model loaded into the backend

Data Source: Historical pollution and weather dataset

User inputs are processed through the backend, where the trained model generates AQI predictions along with explainable insights, which are then visualized on the frontend.

🔄 Prediction Workflow

User selects a region and date

Backend processes the request

Machine learning model generates AQI prediction

Explainability module identifies contributing factors

Results are returned and displayed to the user

🎯 Use Case

The project supports:

Urban air quality awareness

Pollution trend analysis

Decision-making in regions without monitoring infrastructure

It explains not only what the pollution level is, but why it occurs.

🔮 Future Enhancements

Integration with real-time weather and pollution data sources

Expansion to multiple regions and country-specific datasets

Adoption of advanced deep learning models

Health impact recommendations based on AQI levels

Scalable deployment for higher user demand

📌 Conclusion

This project demonstrates a practical and explainable approach to air pollution prediction using historical data.
It highlights how machine learning and explainable AI can be applied to environmental monitoring in a cost-effective and accessible manner.
