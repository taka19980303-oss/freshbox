# 🍱 FreshBox - 冷蔵庫管理 × AIレシピ提案アプリ

> 食材の無駄をなくし、毎日の料理を豊かに。Gemini AI搭載の次世代冷蔵庫管理アプリ。

## 📁 プロジェクト構成

```
FreshBox/
├── freshbox_app/        # Flutter フロントエンド
└── freshbox_api/        # FastAPI バックエンド
```

---

## 🚀 クイックスタート

### バックエンド (FastAPI)

```bash
cd freshbox_api

# 仮想環境を作成・有効化
python -m venv venv
.\venv\Scripts\activate      # Windows

# 依存関係インストール
pip install -r requirements.txt

# 環境変数設定
copy .env.example .env

# サーバー起動
uvicorn app.main:app --reload --port 8000
```

#### API ドキュメント
- Swagger UI: http://localhost:8000/docs
- ReDoc:       http://localhost:8000/redoc

---

### フロントエンド (Flutter)

```bash
cd freshbox_app

# Flutter SDKが未インストールの場合:
# https://docs.flutter.dev/get-started/install

# 依存関係インストール
flutter pub get

# アプリ起動 (デバイス/エミュレータが必要)
flutter run

# コード生成 (freezed / riverpod)
dart run build_runner build --delete-conflicting-outputs
```

---

## 📡 APIエンドポイント (フェーズ1 モック)

### POST `/api/scan-receipt`
レシート画像をOCR解析して食材リストを返す

```bash
curl -X POST http://localhost:8000/api/scan-receipt \
  -F "image=@receipt.jpg"
```

**Response例:**
```json
{
  "success": true,
  "purchased_date": "2026-06-25",
  "store_name": "サンプルスーパー",
  "ingredients": [
    { "name": "豚肩ロース（ブロック）", "quantity": 300, "unit": "g", "estimated_expiry_days": 5, "confidence": 0.97 },
    { "name": "白菜", "quantity": 0.25, "unit": "個", "estimated_expiry_days": 7, "confidence": 0.92 }
  ],
  "confidence": 0.93,
  "message": "4品の食材を検出しました。"
}
```

### POST `/api/suggest-recipe`
在庫食材からAIレシピを提案する

```bash
curl -X POST http://localhost:8000/api/suggest-recipe \
  -H "Content-Type: application/json" \
  -d '{"ingredients": ["豚肩ロース", "白菜", "レモン", "牛タン"]}'
```

**Response例:**
```json
{
  "recipes": [
    {
      "id": "...",
      "title": "豚肩ロースと白菜のレモン塩鍋",
      "description": "さっぱりとしたレモンの酸味が豚の旨味を引き立てる...",
      "used_ingredients": ["豚肩ロース", "白菜", "レモン"],
      "missing_ingredients": ["長ネギ"],
      "cooking_time": "25分",
      "difficulty": "簡単",
      "calories_estimate": "約420kcal",
      "tags": ["鍋料理", "冬", "さっぱり"]
    }
  ],
  "total": 3,
  "generated_at": "2026-06-25T19:30:00"
}
```

---

## 🎨 UIデザイン方針 (日本向け)

| 要素 | 設計 |
|------|------|
| フォント | **Noto Sans JP** (日本語最適化) |
| プライマリカラー | `#1B6B3A` 深緑・抹茶 |
| セカンダリカラー | `#E05C2A` 朱色・和橙 |
| デザインコンセプト | 和モダン × 清潔感 |
| テーマ | ライトモードメイン |

### 賞味期限ステータス
| 残日数 | 色 | 表示 |
|--------|----|----|
| 5日以上 | 深緑 | ✅ 余裕あり |
| 3〜4日 | 橙 | ⚠️ もうすぐ |
| 1〜2日 | 朱色 (点滅) | 🔥 今日使って！ |
| 期限超過 | グレー | 💀 期限切れ |

---

## 🗺️ 実装フェーズ

| フェーズ | 内容 | 状態 |
|---------|------|------|
| **Phase 1** | コアUI + APIモック | ✅ 完了 |
| Phase 2 | Firebase Auth + Firestore | 🔜 次回 |
| Phase 3 | Gemini API 実連携 | 🔜 次回 |
| Phase 4 | レシートOCR (Cloud Vision) | 🔜 次回 |
| Phase 5 | 家族間共有機能 | 🔜 次回 |
| Phase 6 | プッシュ通知 (期限アラート) | 🔜 次回 |

---

## 🧑‍💻 技術スタック

### フロントエンド
- Flutter 3.16+
- Riverpod 2.x (状態管理)
- Material Design 3
- Noto Sans JP (Google Fonts)
- flutter_animate (マイクロアニメーション)

### バックエンド
- Python 3.12 + FastAPI 0.110
- Pydantic v2
- Gemini 1.5 Pro API (フェーズ3〜)
- Firebase Firestore (フェーズ2〜)
