from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.router import api_router
from app.config import get_settings

settings = get_settings()

app = FastAPI(
    title="FreshBox API",
    description="""
## 🍱 FreshBox - 冷蔵庫管理 × AIレシピ提案 API

### 主なエンドポイント
- **POST /api/scan-receipt** - レシート画像OCR解析
- **POST /api/suggest-recipe** - AIレシピ提案

> **Note**: 現在フェーズ1のモック実装です。
    """,
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ルーター登録
app.include_router(api_router)


@app.get("/", tags=["ヘルスチェック"])
async def root():
    return {
        "service": "FreshBox API",
        "version": "0.1.0",
        "status": "healthy",
        "environment": settings.app_env,
        "docs": "/docs",
    }


@app.get("/health", tags=["ヘルスチェック"])
async def health_check():
    return {"status": "ok"}
