from pydantic import BaseModel, Field
from typing import Optional


class RecipeRequest(BaseModel):
    ingredients: list[str] = Field(
        ...,
        examples=[["豚肩ロース", "白菜", "レモン", "牛タン"]],
        description="現在の在庫食材名リスト",
    )
    preferences: Optional[dict] = Field(
        default=None,
        examples=[{"style": "和食", "cook_time_max": 30}],
    )


class RecipeSuggestion(BaseModel):
    id: str
    title: str
    description: str
    used_ingredients: list[str]
    missing_ingredients: list[str] = []
    cooking_time: str
    difficulty: str
    calories_estimate: Optional[str] = None
    tags: list[str] = []


class RecipeResponse(BaseModel):
    recipes: list[RecipeSuggestion]
    total: int
    generated_at: str
