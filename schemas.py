from typing import List
from pydantic import BaseModel


class PredictionRequest(BaseModel):
    location: str
    date: str


class TrendPoint(BaseModel):
    day: str
    value: float


class Factor(BaseModel):
    name: str
    impact: float


class PredictionResponse(BaseModel):
    location: str
    predicted_pollution: float
    category: str
    confidence_r2: float
    explanation: str
    trend_data: List[TrendPoint]
    factors: List[Factor]
