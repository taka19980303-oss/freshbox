from fastapi import APIRouter
from app.api.endpoints import scan, recipe

api_router = APIRouter(prefix="/api")

api_router.include_router(scan.router, tags=["レシートスキャン"])
api_router.include_router(recipe.router, tags=["レシピ提案"])
