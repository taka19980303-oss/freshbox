import asyncio
import random
from datetime import date, timedelta
from fastapi import APIRouter, File, UploadFile, HTTPException
from app.schemas import ScanReceiptResponse, ScannedIngredient

router = APIRouter()

# --- モックデータ ---
MOCK_RECEIPT_ITEMS = [
    {"name": "豚肩ロース（ブロック）", "quantity": 300, "unit": "g", "estimated_expiry_days": 5},
    {"name": "白菜",                  "quantity": 0.25, "unit": "個",  "estimated_expiry_days": 7},
    {"name": "レモン",                "quantity": 3,   "unit": "個",  "estimated_expiry_days": 14},
    {"name": "牛タン",                "quantity": 200, "unit": "g",  "estimated_expiry_days": 2},
    {"name": "長ネギ",                "quantity": 1,   "unit": "本",  "estimated_expiry_days": 10},
    {"name": "鶏ムネ肉",              "quantity": 2,   "unit": "枚",  "estimated_expiry_days": 3},
    {"name": "絹豆腐",               "quantity": 1,   "unit": "丁",  "estimated_expiry_days": 5},
    {"name": "卵",                   "quantity": 6,   "unit": "個",  "estimated_expiry_days": 21},
    {"name": "たまねぎ",              "quantity": 3,   "unit": "個",  "estimated_expiry_days": 30},
    {"name": "にんじん",              "quantity": 2,   "unit": "本",  "estimated_expiry_days": 14},
    {"name": "じゃがいも",            "quantity": 4,   "unit": "個",  "estimated_expiry_days": 30},
    {"name": "豚バラ肉",              "quantity": 200, "unit": "g",  "estimated_expiry_days": 3},
    {"name": "牛乳",                  "quantity": 1,   "unit": "L",   "estimated_expiry_days": 7},
    {"name": "ヨーグルト",            "quantity": 1,   "unit": "個",  "estimated_expiry_days": 10},
    {"name": "鮭の切り身",            "quantity": 2,   "unit": "切れ", "estimated_expiry_days": 2},
    {"name": "ちくわ",                "quantity": 1,   "unit": "パック", "estimated_expiry_days": 7},
    {"name": "冷凍うどん",            "quantity": 3,   "unit": "食",  "estimated_expiry_days": 60},
    {"name": "食パン",                "quantity": 6,   "unit": "枚",  "estimated_expiry_days": 4},
    {"name": "納豆",                  "quantity": 3,   "unit": "パック", "estimated_expiry_days": 7},
    {"name": "ポテトチップス",        "quantity": 1,   "unit": "袋",  "estimated_expiry_days": 60},
]


@router.post(
    "/scan-receipt",
    response_model=ScanReceiptResponse,
    summary="レシート画像をOCR解析して食材リストを返す",
    description="""
    アップロードされたレシート画像をOCR解析し、購入食材の一覧と
    推定賞味期限を返します。現在はモックデータを返します。
    """,
)
async def scan_receipt(
    image: UploadFile = File(..., description="レシートの画像ファイル (JPEG/PNG)"),
) -> ScanReceiptResponse:
    # バリデーション
    if image.content_type not in ["image/jpeg", "image/png", "image/webp"]:
        raise HTTPException(
            status_code=400,
            detail=f"サポートされていない画像形式です: {image.content_type}",
        )

    # 実際のOCR処理をシミュレート（モック）
    await asyncio.sleep(0.8)  # API呼び出しの遅延をシミュレート

    # ランダムに3〜5品をピックアップ（実際はOCR解析結果）
    num_items = random.randint(3, 5)
    selected_items = random.sample(MOCK_RECEIPT_ITEMS, min(num_items, len(MOCK_RECEIPT_ITEMS)))

    ingredients = [
        ScannedIngredient(
            name=item["name"],
            quantity=item["quantity"],
            unit=item["unit"],
            estimated_expiry_days=item["estimated_expiry_days"],
            confidence=round(random.uniform(0.85, 0.99), 2),
        )
        for item in selected_items
    ]

    return ScanReceiptResponse(
        success=True,
        purchased_date=date.today(),
        store_name="サンプルスーパー",  # OCRで店名を取得
        ingredients=ingredients,
        raw_text="（OCR生テキスト - モック）",
        confidence=0.93,
        message=f"{len(ingredients)}品の食材を検出しました。",
    )
