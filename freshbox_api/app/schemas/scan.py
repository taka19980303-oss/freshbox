from pydantic import BaseModel
from datetime import date
from typing import Optional
from .ingredient import ScannedIngredient


class ScanReceiptResponse(BaseModel):
    success: bool
    purchased_date: Optional[date] = None
    store_name: Optional[str] = None
    ingredients: list[ScannedIngredient] = []
    raw_text: Optional[str] = None
    confidence: float = 0.0
    message: str = ""
