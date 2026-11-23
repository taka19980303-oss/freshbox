from pydantic import BaseModel, Field
from datetime import date
from typing import Optional
from enum import Enum


class IngredientCategory(str, Enum):
    MEAT = "肉類"
    VEGETABLE = "野菜"
    FISH = "魚介"
    DAIRY = "乳製品"
    SEASONING = "調味料"
    FROZEN = "冷凍"
    OTHER = "その他"


class IngredientBase(BaseModel):
    name: str = Field(..., examples=["豚肩ロース（ブロック）"])
    category: IngredientCategory = IngredientCategory.OTHER
    quantity: float = Field(..., gt=0, examples=[300.0])
    unit: str = Field(..., examples=["g"])
    expiry_date: Optional[date] = None
    purchased_date: Optional[date] = None
    memo: Optional[str] = None


class IngredientCreate(IngredientBase):
    pass


class IngredientResponse(IngredientBase):
    id: str
    days_until_expiry: Optional[int] = None
    status: str = "normal"  # normal / warning / urgent / expired

    model_config = {"from_attributes": True}


class ScannedIngredient(BaseModel):
    """レシートスキャン後の食材候補"""
    name: str
    quantity: float = 1.0
    unit: str = "個"
    estimated_expiry_days: int = 7
    confidence: float = Field(default=0.9, ge=0.0, le=1.0)
