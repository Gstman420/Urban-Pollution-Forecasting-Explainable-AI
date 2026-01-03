# Urban Pollution Prediction with Factor Attribution

This project predicts daily air pollution levels using time-series machine
learning techniques.

## Model
- Algorithm: XGBoost Regressor
- Features: Weather data, lag features, rolling-window statistics
- Validation: Time-based train/test split

## Performance
- R² Score: 0.94
- MAE: 12.06
- RMSE: 20.54

## Explainability
The model uses SHAP (SHapley Additive Explanations) to attribute each prediction
to contributing factors such as recent pollution trends, wind speed, temperature,
and atmospheric pressure.

## LLM-style Explanation
Predictions are accompanied by a human-readable explanation describing why
pollution levels are high or low, making the system understandable to non-technical
users.

## Use Case
Supports urban pollution monitoring and decision-making by explaining not only
what the pollution level is, but why it occurs.
