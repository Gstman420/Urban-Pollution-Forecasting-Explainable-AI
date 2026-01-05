# Urban Pollution Prediction with Explainable AI

Predicts daily Air Quality Index (AQI) using historical pollution and weather data with factor-level explainability.

---

## Overview
- Sensor-less AQI prediction
- Time-series machine learning model
- Explainable outputs for each prediction

---

## Data
- Historical pollution data
- Historical weather data

---

## Model
- Algorithm: XGBoost Regressor
- Features:
  - Weather parameters
  - Lag-based pollution features
  - Rolling-window statistics
- Validation: Time-based train/test split

---

## Performance
- R² Score: 0.94
- MAE: 12.06
- RMSE: 20.54

---

## Explainability
- Uses SHAP (SHapley Additive Explanations)
- Identifies key contributing factors such as:
  - Recent pollution trends
  - Wind speed
  - Temperature
  - Atmospheric pressure

---

## Prediction Flow
1. User selects region and date  
2. Backend processes request  
3. Model predicts AQI  
4. Explainability module identifies factors  
5. Results returned to frontend  

---

## Use Cases
- Urban air quality awareness
- Pollution trend analysis
- Decision-making in regions without monitoring infrastructure

---

## Future Work
- Integration with real-time data sources
- Support for additional regions
- Advanced time-series models
