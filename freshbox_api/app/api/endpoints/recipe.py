import asyncio
import uuid
from datetime import datetime
from fastapi import APIRouter
from app.schemas import RecipeRequest, RecipeResponse, RecipeSuggestion

router = APIRouter()

# --- モックレシピデータ ---
MOCK_RECIPES_DB = [
    {
        "id": "1",
        "title": "豚肩ロースと白菜のレモン塩鍋",
        "description": "さっぱりとしたレモンの酸味が豚の旨味を引き立てる、体の芯から温まる塩鍋です。白菜のとろとろ食感が絶品。〆は雑炊で。",
        "required": [
            "豚肩ロース",
            "白菜",
            "レモン"
        ],
        "optional": [
            "長ネギ",
            "鶏ガラスープ"
        ],
        "cooking_time": "25分",
        "difficulty": "簡単",
        "calories_estimate": "約420kcal",
        "tags": [
            "鍋料理",
            "冬",
            "さっぱり",
            "家族向け"
        ]
    },
    {
        "id": "2",
        "title": "牛タンしゃぶしゃぶ 〜ポン酢仕立て〜",
        "description": "薄切り牛タンをさっとしゃぶしゃぶ。レモンを絞ったポン酢だれでいただく、とことん贅沢な一品。白菜との相性も抜群です。",
        "required": [
            "牛タン",
            "白菜"
        ],
        "optional": [
            "レモン",
            "ポン酢"
        ],
        "cooking_time": "20分",
        "difficulty": "簡単",
        "calories_estimate": "約380kcal",
        "tags": [
            "しゃぶしゃぶ",
            "おもてなし",
            "さっぱり"
        ]
    },
    {
        "id": "3",
        "title": "豚肩ロースのレモン塩焼き",
        "description": "厚切り豚肩ロースをレモン塩ダレに漬け込んで焼き上げる、ジューシーな一品。ご飯が進む定番の主菜です。",
        "required": [
            "豚肩ロース",
            "レモン"
        ],
        "optional": [
            "長ネギ",
            "にんにく"
        ],
        "cooking_time": "30分",
        "difficulty": "普通",
        "calories_estimate": "約510kcal",
        "tags": [
            "焼き物",
            "定番",
            "ボリューム"
        ]
    },
    {
        "id": "4",
        "title": "白菜と豚肉の重ね蒸し",
        "description": "白菜と豚肉を交互に重ね、電子レンジで蒸すだけの超簡単レシピ。ポン酢でさっぱりいただきます。",
        "required": [
            "白菜",
            "豚肩ロース"
        ],
        "optional": [
            "ポン酢",
            "ごま油"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約290kcal",
        "tags": [
            "時短",
            "ヘルシー",
            "電子レンジ"
        ]
    },
    {
        "id": "5",
        "title": "定番の肉じゃが",
        "description": "ほくほくのじゃがいもに味がしっかり染み込んだ、日本の家庭料理の定番です。冷めるとより味が馴染みます。",
        "required": [
            "じゃがいも",
            "にんじん",
            "たまねぎ",
            "豚バラ肉"
        ],
        "optional": [
            "醤油",
            "砂糖",
            "みりん"
        ],
        "cooking_time": "35分",
        "difficulty": "普通",
        "calories_estimate": "約360kcal",
        "tags": [
            "和食",
            "定番",
            "煮物",
            "作り置き"
        ]
    },
    {
        "id": "6",
        "title": "キャベツと豚バラ肉の回鍋肉",
        "description": "シャキシャキのキャベツと濃厚な味噌ダレが絡み合い、ご飯が止まらなくなる本格中華です。",
        "required": [
            "キャベツ",
            "豚バラ肉",
            "長ネギ"
        ],
        "optional": [
            "味噌",
            "醤油",
            "にんにく"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約410kcal",
        "tags": [
            "中華",
            "時短",
            "フライパン",
            "がっつり"
        ]
    },
    {
        "id": "7",
        "title": "鮭のバターホイル焼き",
        "description": "ホイルに包んで蒸し焼きにすることで、鮭の身がふっくらジューシーに仕上がります。バターの香りがたまりません。",
        "required": [
            "鮭の切り身",
            "バター"
        ],
        "optional": [
            "レモン",
            "醤油"
        ],
        "cooking_time": "20分",
        "difficulty": "簡単",
        "calories_estimate": "約280kcal",
        "tags": [
            "洋食",
            "ヘルシー",
            "簡単",
            "ホイル焼き"
        ]
    },
    {
        "id": "8",
        "title": "とろとろ卵の親子丼",
        "description": "だし汁で煮た鶏もも肉とたまねぎを、ふわふわとろとろの卵でとじた定番丼。お昼ご飯にもぴったりです。",
        "required": [
            "鶏もも肉",
            "卵",
            "たまねぎ"
        ],
        "optional": [
            "醤油",
            "砂糖",
            "だし汁"
        ],
        "cooking_time": "15分",
        "difficulty": "普通",
        "calories_estimate": "約550kcal",
        "tags": [
            "和食",
            "丼もの",
            "時短",
            "定番"
        ]
    },
    {
        "id": "9",
        "title": "照り焼きチキン",
        "description": "甘辛い醤油タレが鶏もも肉のパリッとした皮目に絡む、大人気の照り焼きです。お弁当のおかずにも最適。",
        "required": [
            "鶏もも肉"
        ],
        "optional": [
            "醤油",
            "砂糖",
            "みりん"
        ],
        "cooking_time": "20分",
        "difficulty": "簡単",
        "calories_estimate": "約430kcal",
        "tags": [
            "和食",
            "おかず",
            "定番",
            "お弁当"
        ]
    },
    {
        "id": "10",
        "title": "ふわとろフレンチトースト",
        "description": "卵と牛乳の液にじっくり浸した食パンを、バターで焼き上げました。ふんわり甘い香りが広がる朝食です。",
        "required": [
            "食パン",
            "卵",
            "牛乳"
        ],
        "optional": [
            "砂糖",
            "バター",
            "はちみつ"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約310kcal",
        "tags": [
            "スイーツ",
            "パン",
            "朝食",
            "子供向け"
        ]
    },
    {
        "id": "11",
        "title": "絶品牛丼",
        "description": "薄切りの牛細切れ肉とたまねぎを甘辛いタレで煮込んだ、おうちで簡単にできる本格牛丼です。",
        "required": [
            "牛細切れ肉",
            "たまねぎ"
        ],
        "optional": [
            "醤油",
            "砂糖",
            "紅生姜"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約600kcal",
        "tags": [
            "丼もの",
            "時短",
            "がっつり",
            "定番"
        ]
    },
    {
        "id": "12",
        "title": "本格麻婆豆腐",
        "description": "ひき肉とねぎの香ばしさ、味噌と醤油のコクが豆腐に染み渡る、ピリッと辛い本格麻婆豆腐です。",
        "required": [
            "合い挽き肉",
            "豆腐",
            "長ネギ"
        ],
        "optional": [
            "味噌",
            "醤油",
            "にんにく"
        ],
        "cooking_time": "20分",
        "difficulty": "普通",
        "calories_estimate": "約340kcal",
        "tags": [
            "中華",
            "辛い",
            "豆腐料理",
            "おかず"
        ]
    },
    {
        "id": "13",
        "title": "白菜とウインナーのスープ",
        "description": "白菜の甘みとウインナーの旨味が溶け出した、優しく温まるコンソメベースのスープです。",
        "required": [
            "白菜",
            "ウインナー",
            "にんじん"
        ],
        "optional": [
            "コンソメ",
            "塩",
            "コショウ"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約120kcal",
        "tags": [
            "スープ",
            "温活",
            "野菜摂取",
            "簡単"
        ]
    },
    {
        "id": "14",
        "title": "旨味たっぷり豚の生姜焼き",
        "description": "ジューシーな豚肩ロースとたまねぎに、生姜の効いたタレを絡めて焼き上げる定番のスタミナおかずです。",
        "required": [
            "豚肩ロース",
            "たまねぎ"
        ],
        "optional": [
            "醤油",
            "生姜",
            "キャベツ"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約480kcal",
        "tags": [
            "和食",
            "おかず",
            "定番",
            "がっつり"
        ]
    },
    {
        "id": "15",
        "title": "納豆おろしうどん",
        "description": "コシのある冷凍うどんに、ネバネバの納豆を合わせたさっぱり冷たいうどんです。夏バテ予防にも効果的。",
        "required": [
            "冷凍うどん",
            "納豆"
        ],
        "optional": [
            "醤油",
            "卵",
            "めんつゆ"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約350kcal",
        "tags": [
            "麺類",
            "うどん",
            "さっぱり",
            "時短"
        ]
    },
    {
        "id": "16",
        "title": "ちくわの磯辺揚げ",
        "description": "青のりの香ばしさと、ちくわのもちもちした食感が絶妙にマッチするおつまみの王道です。",
        "required": [
            "ちくわ"
        ],
        "optional": [
            "青のり",
            "小麦粉"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約180kcal",
        "tags": [
            "揚げ物",
            "おつまみ",
            "お弁当",
            "簡単"
        ]
    },
    {
        "id": "17",
        "title": "具だくさんのポテトサラダ",
        "description": "ほくほくじゃがいもに、にんじんを加え、マヨネーズでクリーミーに仕上げました。作り置きにも最適。",
        "required": [
            "じゃがいも",
            "にんじん"
        ],
        "optional": [
            "マヨネーズ",
            "塩",
            "ウインナー"
        ],
        "cooking_time": "20分",
        "difficulty": "普通",
        "calories_estimate": "約240kcal",
        "tags": [
            "サラダ",
            "作り置き",
            "定番",
            "副菜"
        ]
    },
    {
        "id": "18",
        "title": "サバの味噌煮",
        "description": "脂ののったサバの塩焼きを甘みのある味噌ベースでじっくり煮込みました。こっくりとした旨味がご飯に合います。",
        "required": [
            "サバの塩焼き",
            "味噌"
        ],
        "optional": [
            "醤油",
            "生姜",
            "砂糖"
        ],
        "cooking_time": "25分",
        "difficulty": "普通",
        "calories_estimate": "約320kcal",
        "tags": [
            "和食",
            "定番",
            "魚料理",
            "おかず"
        ]
    },
    {
        "id": "19",
        "title": "チキンカレー",
        "description": "鶏もも肉、たまねぎ、にんじん、じゃがいもをコトコト煮込んだスパイシーでコクのある定番カレー。",
        "required": [
            "鶏もも肉",
            "たまねぎ",
            "にんじん",
            "じゃがいも"
        ],
        "optional": [
            "カレールー",
            "バター"
        ],
        "cooking_time": "30分",
        "difficulty": "普通",
        "calories_estimate": "約650kcal",
        "tags": [
            "カレー",
            "定番",
            "煮物"
        ]
    },
    {
        "id": "20",
        "title": "牛カレー",
        "description": "牛細切れ肉の旨味がルー全体に溶け出した、贅沢な味わいの欧風カレー。",
        "required": [
            "牛細切れ肉",
            "たまねぎ",
            "にんじん",
            "じゃがいも"
        ],
        "optional": [
            "カレールー"
        ],
        "cooking_time": "30分",
        "difficulty": "普通",
        "calories_estimate": "約680kcal",
        "tags": [
            "カレー",
            "定番",
            "牛肉"
        ]
    },
    {
        "id": "21",
        "title": "カレーうどん",
        "description": "出汁の効いたカレーベースに、コシのあるうどんが絡む、お蕎麦屋さんのような一杯。",
        "required": [
            "冷凍うどん",
            "豚バラ肉",
            "たまねぎ"
        ],
        "optional": [
            "だし汁",
            "カレールー"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約520kcal",
        "tags": [
            "うどん",
            "カレー",
            "時短"
        ]
    },
    {
        "id": "22",
        "title": "キャベツとウインナーの炒め物",
        "description": "さっと炒めるだけで完成する、朝食やお弁当の隙間に最適なシンプルおかず。",
        "required": [
            "キャベツ",
            "ウインナー"
        ],
        "optional": [
            "塩",
            "コショウ",
            "醤油"
        ],
        "cooking_time": "8分",
        "difficulty": "簡単",
        "calories_estimate": "約150kcal",
        "tags": [
            "時短",
            "朝食",
            "お弁当"
        ]
    },
    {
        "id": "23",
        "title": "牛しゃぶサラダ",
        "description": "さっと茹でた牛肉をキャベツやごまだれでいただく、さっぱりヘルシーなサラダ主菜。",
        "required": [
            "牛細切れ肉",
            "キャベツ"
        ],
        "optional": [
            "ごまだれ",
            "ポン酢"
        ],
        "cooking_time": "12分",
        "difficulty": "簡単",
        "calories_estimate": "約290kcal",
        "tags": [
            "サラダ",
            "牛肉",
            "ヘルシー"
        ]
    },
    {
        "id": "24",
        "title": "たまご焼きそば風うどん",
        "description": "冷凍うどんをキャベツと豚バラ肉で香ばしく炒め、目玉焼きをのせた大満足メニュー。",
        "required": [
            "冷凍うどん",
            "キャベツ",
            "豚バラ肉",
            "卵"
        ],
        "optional": [
            "ソース",
            "塩"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約490kcal",
        "tags": [
            "麺類",
            "うどん",
            "時短"
        ]
    },
    {
        "id": "25",
        "title": "豆腐と長ネギの味噌汁",
        "description": "お味噌汁の王道。滑らかな豆腐と、甘みのある長ネギのコンビネーションが抜群です。",
        "required": [
            "豆腐",
            "長ネギ",
            "味噌"
        ],
        "optional": [
            "だし汁"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約60kcal",
        "tags": [
            "和食",
            "味噌汁",
            "定番"
        ]
    },
    {
        "id": "26",
        "title": "じゃがいもとたまねぎの味噌汁",
        "description": "じゃがいものホクホク感とたまねぎの甘みが溶け出した、食べ応えのあるお味噌汁です。",
        "required": [
            "じゃがいも",
            "たまねぎ",
            "味噌"
        ],
        "optional": [
            "だし汁"
        ],
        "cooking_time": "12分",
        "difficulty": "簡単",
        "calories_estimate": "約90kcal",
        "tags": [
            "和食",
            "味噌汁",
            "定番"
        ]
    },
    {
        "id": "27",
        "title": "旨味たっぷりの豚汁",
        "description": "多くの野菜と豚肉を炒めてから煮込むことで、コクと旨味が格段にアップしたごちそう汁です。",
        "required": [
            "豚バラ肉",
            "じゃがいも",
            "にんじん",
            "長ネギ",
            "味噌"
        ],
        "optional": [
            "だし汁"
        ],
        "cooking_time": "20分",
        "difficulty": "普通",
        "calories_estimate": "約210kcal",
        "tags": [
            "和食",
            "汁物",
            "具だくさん"
        ]
    },
    {
        "id": "28",
        "title": "鮭とレモンのチャーハン",
        "description": "パラパラのチャーハンに、ほぐした鮭の塩気とレモンのさっぱりとした風味を加えた爽やかな炒飯。",
        "required": [
            "鮭の切り身",
            "卵",
            "長ネギ",
            "レモン"
        ],
        "optional": [
            "醤油",
            "塩"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約450kcal",
        "tags": [
            "ご飯もの",
            "チャーハン",
            "魚"
        ]
    },
    {
        "id": "29",
        "title": "ウインナーピザトースト",
        "description": "食パンにケチャップを塗り、ウインナーとチーズをたっぷりのせて焼き上げた喫茶店風トースト。",
        "required": [
            "食パン",
            "ウインナー",
            "チーズ",
            "たまねぎ"
        ],
        "optional": [
            "ケチャップ"
        ],
        "cooking_time": "8分",
        "difficulty": "簡単",
        "calories_estimate": "約320kcal",
        "tags": [
            "パン",
            "朝食",
            "子供向け"
        ]
    },
    {
        "id": "30",
        "title": "マヨマヨたまごトースト",
        "description": "パンの縁にマヨネーズで堤防を作り、中央に卵を落としてトーストした大人気朝ごはん。",
        "required": [
            "食パン",
            "卵",
            "マヨネーズ"
        ],
        "optional": [
            "塩",
            "コショウ"
        ],
        "cooking_time": "8分",
        "difficulty": "簡単",
        "calories_estimate": "約350kcal",
        "tags": [
            "パン",
            "朝食",
            "卵料理"
        ]
    },
    {
        "id": "31",
        "title": "ハニーバタートースト",
        "description": "厚切り食パンに切れ目を入れ、バターとハチミツを染み込ませた背徳の甘さのトースト。",
        "required": [
            "食パン",
            "バター"
        ],
        "optional": [
            "はちみつ"
        ],
        "cooking_time": "6分",
        "difficulty": "簡単",
        "calories_estimate": "約280kcal",
        "tags": [
            "パン",
            "スイーツ",
            "簡単"
        ]
    },
    {
        "id": "32",
        "title": "シーチキンマヨうどん",
        "description": "ゆでたうどんにシーチキンとマヨネーズ、醤油を和えるだけの超高速ずぼら飯。",
        "required": [
            "冷凍うどん",
            "シーチキン",
            "マヨネーズ"
        ],
        "optional": [
            "醤油"
        ],
        "cooking_time": "7分",
        "difficulty": "簡単",
        "calories_estimate": "約380kcal",
        "tags": [
            "麺類",
            "うどん",
            "時短",
            "ずぼら"
        ]
    },
    {
        "id": "33",
        "title": "シーチキンとキャベツのサラダ",
        "description": "千切りキャベツにシーチキンを合わせ、マヨネーズで和えたシンプルで飽きのこない副菜。",
        "required": [
            "キャベツ",
            "シーチキン",
            "マヨネーズ"
        ],
        "optional": [
            "コショウ"
        ],
        "cooking_time": "5分",
        "difficulty": "簡単",
        "calories_estimate": "約120kcal",
        "tags": [
            "サラダ",
            "副菜",
            "時短"
        ]
    },
    {
        "id": "34",
        "title": "キャベツの味噌汁",
        "description": "キャベツの自然な甘みが引き立つ、朝ごはんにぴったりな優しいお味噌汁。",
        "required": [
            "キャベツ",
            "味噌"
        ],
        "optional": [
            "だし汁"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約50kcal",
        "tags": [
            "和食",
            "味噌汁",
            "野菜"
        ]
    },
    {
        "id": "35",
        "title": "卵雑炊",
        "description": "風邪のときや胃が疲れているときに優しい、出汁を含んだご飯とふんわり卵の雑炊。",
        "required": [
            "卵"
        ],
        "optional": [
            "ご飯",
            "だし汁",
            "塩",
            "醤油"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約220kcal",
        "tags": [
            "和食",
            "ご飯もの",
            "消化が良い"
        ]
    },
    {
        "id": "36",
        "title": "餃子と長ネギのスープ",
        "description": "冷凍餃子を中華だしで煮るだけで、ボリューム満点のおかずスープが完成します。",
        "required": [
            "冷凍餃子",
            "長ネギ"
        ],
        "optional": [
            "中華だし",
            "醤油"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約180kcal",
        "tags": [
            "スープ",
            "中華",
            "時短"
        ]
    },
    {
        "id": "37",
        "title": "焼き餃子",
        "description": "冷凍餃子をパリッと羽つきに焼き上げた、定番のビールのお供であり主菜です。",
        "required": [
            "冷凍餃子"
        ],
        "optional": [
            "ごま油"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約240kcal",
        "tags": [
            "おかず",
            "定番",
            "時短"
        ]
    },
    {
        "id": "38",
        "title": "牛タン塩焼きレモン添え",
        "description": "極上の牛タンをシンプルに塩コショウで焼き上げ、絞りたてのレモンでいただく一品。",
        "required": [
            "牛タン",
            "レモン"
        ],
        "optional": [
            "塩",
            "コショウ"
        ],
        "cooking_time": "8分",
        "difficulty": "簡単",
        "calories_estimate": "約260kcal",
        "tags": [
            "焼き物",
            "おつまみ",
            "高級感"
        ]
    },
    {
        "id": "39",
        "title": "鶏もも肉とじゃがいもの塩炒め",
        "description": "鶏肉のジューシーな脂がじゃがいもに染み渡る、香ばしい塩ニンニク風味の炒め物。",
        "required": [
            "鶏もも肉",
            "じゃがいも"
        ],
        "optional": [
            "塩",
            "にんにく",
            "コショウ"
        ],
        "cooking_time": "18分",
        "difficulty": "普通",
        "calories_estimate": "約390kcal",
        "tags": [
            "おかず",
            "肉",
            "じゃがいも"
        ]
    },
    {
        "id": "40",
        "title": "キャベツとシーチキンの和え物",
        "description": "キャベツをレンジで加熱し、シーチキンとごま油で和えるだけの簡単常備菜。",
        "required": [
            "キャベツ",
            "シーチキン"
        ],
        "optional": [
            "ごま油",
            "醤油"
        ],
        "cooking_time": "7分",
        "difficulty": "簡単",
        "calories_estimate": "約90kcal",
        "tags": [
            "副菜",
            "作り置き",
            "レンジ"
        ]
    },
    {
        "id": "41",
        "title": "ちくわと長ネギの醤油炒め",
        "description": "ちくわの甘みと長ネギの香ばしさを醤油で引き締めた、お弁当の定番副菜。",
        "required": [
            "ちくわ",
            "長ネギ"
        ],
        "optional": [
            "醤油",
            "みりん"
        ],
        "cooking_time": "8分",
        "difficulty": "簡単",
        "calories_estimate": "約110kcal",
        "tags": [
            "お弁当",
            "和食",
            "ちくわ"
        ]
    },
    {
        "id": "42",
        "title": "豆腐ステーキ",
        "description": "水切りした豆腐を両面カリッと焼き、甘辛い醤油タレを絡めたヘルシー主菜。",
        "required": [
            "豆腐"
        ],
        "optional": [
            "醤油",
            "砂糖",
            "片栗粉"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約180kcal",
        "tags": [
            "ヘルシー",
            "豆腐料理",
            "簡単"
        ]
    },
    {
        "id": "43",
        "title": "納豆卵かけご飯",
        "description": "日本のソウルフード。ふわふわに泡立てた納豆と卵をご飯にかけていただきます。",
        "required": [
            "納豆",
            "卵"
        ],
        "optional": [
            "ご飯",
            "醤油"
        ],
        "cooking_time": "3分",
        "difficulty": "簡単",
        "calories_estimate": "約320kcal",
        "tags": [
            "朝食",
            "定番",
            "超時短"
        ]
    },
    {
        "id": "44",
        "title": "たまごスープ",
        "description": "ふんわりかき卵と長ネギのシンプルな中華風スープ。とろみをつけて温まります。",
        "required": [
            "卵",
            "長ネギ"
        ],
        "optional": [
            "中華だし",
            "塩",
            "片栗粉"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約70kcal",
        "tags": [
            "スープ",
            "中華",
            "定番"
        ]
    },
    {
        "id": "45",
        "title": "クリームシチュー",
        "description": "牛乳とバターを使ったクリーミーなルーで、鶏肉と温野菜を煮込んだ冬の定番シチュー。",
        "required": [
            "鶏もも肉",
            "じゃがいも",
            "にんじん",
            "たまねぎ",
            "牛乳"
        ],
        "optional": [
            "コンソメ",
            "バター",
            "小麦粉"
        ],
        "cooking_time": "35分",
        "difficulty": "普通",
        "calories_estimate": "約450kcal",
        "tags": [
            "シチュー",
            "洋食",
            "温まる"
        ]
    },
    {
        "id": "46",
        "title": "ポトフ",
        "description": "ウインナーと大きく切った野菜をじっくり煮込み、素材の甘みを出したフレンチスープ。",
        "required": [
            "ウインナー",
            "キャベツ",
            "じゃがいも",
            "にんじん",
            "たまねぎ"
        ],
        "optional": [
            "コンソメ",
            "塩"
        ],
        "cooking_time": "25分",
        "difficulty": "簡単",
        "calories_estimate": "約190kcal",
        "tags": [
            "スープ",
            "フランス料理",
            "野菜"
        ]
    },
    {
        "id": "47",
        "title": "牛肉とじゃがいもの甘辛炒め",
        "description": "牛細切れ肉とじゃがいもをすき焼き風の甘辛ダレで炒めた、ご飯が豪快に進むおかず。",
        "required": [
            "牛細切れ肉",
            "じゃがいも",
            "たまねぎ"
        ],
        "optional": [
            "醤油",
            "砂糖",
            "みりん"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約420kcal",
        "tags": [
            "おかず",
            "牛肉",
            "ボリューム"
        ]
    },
    {
        "id": "48",
        "title": "キャベツと豚肉の塩麹炒め",
        "description": "豚バラ肉の甘みとキャベツの旨味を、まろやかな塩麹が引き立てる優しい炒め物。",
        "required": [
            "キャベツ",
            "豚バラ肉"
        ],
        "optional": [
            "塩麹",
            "にんにく"
        ],
        "cooking_time": "12分",
        "difficulty": "簡単",
        "calories_estimate": "約330kcal",
        "tags": [
            "おかず",
            "時短",
            "豚肉"
        ]
    },
    {
        "id": "49",
        "title": "ウインナーのスクランブルエッグ",
        "description": "ふんわり卵とパリッとウインナーを一緒に炒めた、みんな大好きな朝食メニュー。",
        "required": [
            "卵",
            "ウインナー"
        ],
        "optional": [
            "塩",
            "バター"
        ],
        "cooking_time": "8分",
        "difficulty": "簡単",
        "calories_estimate": "約210kcal",
        "tags": [
            "朝食",
            "卵料理",
            "ウインナー"
        ]
    },
    {
        "id": "50",
        "title": "牛乳プリン",
        "description": "牛乳、卵、砂糖だけで作る、どこか懐かしい味わいのシンプル手作りデザート。",
        "required": [
            "牛乳",
            "卵"
        ],
        "optional": [
            "砂糖"
        ],
        "cooking_time": "30分",
        "difficulty": "普通",
        "calories_estimate": "約160kcal",
        "tags": [
            "スイーツ",
            "デザート",
            "子供向け"
        ]
    },
    {
        "id": "51",
        "title": "ヨーグルトスムージー",
        "description": "プレーンヨーグルトと牛乳をミックスした、朝の栄養補給にぴったりなドリンク。",
        "required": [
            "ヨーグルト",
            "牛乳"
        ],
        "optional": [
            "はちみつ"
        ],
        "cooking_time": "5分",
        "difficulty": "簡単",
        "calories_estimate": "約140kcal",
        "tags": [
            "ドリンク",
            "朝食",
            "ヘルシー"
        ]
    },
    {
        "id": "52",
        "title": "豚バラキムチ炒め風",
        "description": "豚バラ肉とキャベツをピリ辛ダレで香ばしく炒め上げた、スタミナ抜群のおかず。",
        "required": [
            "豚バラ肉",
            "キャベツ"
        ],
        "optional": [
            "キムチの素",
            "醤油"
        ],
        "cooking_time": "12分",
        "difficulty": "簡単",
        "calories_estimate": "約380kcal",
        "tags": [
            "おかず",
            "辛い",
            "がっつり"
        ]
    },
    {
        "id": "53",
        "title": "鮭のクリームうどん",
        "description": "鮭の旨味とまろやかな牛乳スープが冷凍うどんに絡む、濃厚カルボナーラ風和風うどん。",
        "required": [
            "鮭の切り身",
            "牛乳",
            "冷凍うどん"
        ],
        "optional": [
            "コンソメ",
            "バター",
            "醤油"
        ],
        "cooking_time": "20分",
        "difficulty": "普通",
        "calories_estimate": "約520kcal",
        "tags": [
            "うどん",
            "洋風",
            "鮭"
        ]
    },
    {
        "id": "54",
        "title": "チーズトースト",
        "description": "食パンにチーズをのせてトーストするだけ。とろけるチーズが香ばしい超シンプル朝食。",
        "required": [
            "食パン",
            "チーズ"
        ],
        "optional": [],
        "cooking_time": "5分",
        "difficulty": "簡単",
        "calories_estimate": "約250kcal",
        "tags": [
            "パン",
            "朝食",
            "超簡単"
        ]
    },
    {
        "id": "55",
        "title": "納豆チーズオムレツ",
        "description": "納豆ととろけるチーズを卵で包み込んだ、おつまみにもなる和洋折衷オムレツ。",
        "required": [
            "卵",
            "納豆",
            "チーズ"
        ],
        "optional": [
            "醤油",
            "バター"
        ],
        "cooking_time": "12分",
        "difficulty": "普通",
        "calories_estimate": "約290kcal",
        "tags": [
            "卵料理",
            "納豆",
            "おつまみ"
        ]
    },
    {
        "id": "56",
        "title": "ちくわのチーズ詰め",
        "description": "ちくわの穴にチーズを詰め、ひと口大に切るだけの火を使わない超スピードおつまみ。",
        "required": [
            "ちくわ",
            "チーズ"
        ],
        "optional": [],
        "cooking_time": "3分",
        "difficulty": "簡単",
        "calories_estimate": "約90kcal",
        "tags": [
            "おつまみ",
            "ちくわ",
            "超簡単"
        ]
    },
    {
        "id": "57",
        "title": "ウインナー食パンロール",
        "description": "食パンでウインナーとチーズを巻き、フライパンで香ばしく焼いたロールサンドイッチ。",
        "required": [
            "食パン",
            "ウインナー",
            "チーズ"
        ],
        "optional": [
            "ケチャップ",
            "マヨネーズ"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約310kcal",
        "tags": [
            "パン",
            "子供向け",
            "お弁当"
        ]
    },
    {
        "id": "58",
        "title": "マヨねぎうどん",
        "description": "冷凍うどんにたっぷりの長ネギとマヨネーズ、醤油を絡めたジャンキーな温うどん。",
        "required": [
            "冷凍うどん",
            "長ネギ",
            "マヨネーズ"
        ],
        "optional": [
            "醤油"
        ],
        "cooking_time": "8分",
        "difficulty": "簡単",
        "calories_estimate": "約390kcal",
        "tags": [
            "うどん",
            "時短",
            "簡単"
        ]
    },
    {
        "id": "59",
        "title": "餃子鍋",
        "description": "白菜と長ネギ、冷凍餃子を醤油だしでグツグツ煮込む、手軽で温まる一人鍋。",
        "required": [
            "冷凍餃子",
            "白菜",
            "長ネギ"
        ],
        "optional": [
            "和風だし",
            "醤油"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約280kcal",
        "tags": [
            "鍋料理",
            "温活",
            "時短"
        ]
    },
    {
        "id": "60",
        "title": "鶏の唐揚げ風焼き",
        "description": "鶏もも肉を醤油と生姜で下味をつけ、フライパンで揚げ焼きにしたジューシーおかず。",
        "required": [
            "鶏もも肉"
        ],
        "optional": [
            "醤油",
            "生姜",
            "片栗粉",
            "油"
        ],
        "cooking_time": "20分",
        "difficulty": "普通",
        "calories_estimate": "約450kcal",
        "tags": [
            "定番",
            "おかず",
            "子供向け"
        ]
    },
    {
        "id": "61",
        "title": "豚肩ロースのさっぱり角煮風",
        "description": "豚肩ロースを醤油と砂糖、お酢で煮込んでさっぱりと柔らかく仕上げた簡単角煮。",
        "required": [
            "豚肩ロース"
        ],
        "optional": [
            "醤油",
            "砂糖",
            "酢"
        ],
        "cooking_time": "40分",
        "difficulty": "難しい",
        "calories_estimate": "約520kcal",
        "tags": [
            "和食",
            "煮物",
            "ごちそう"
        ]
    },
    {
        "id": "62",
        "title": "釜玉うどん",
        "description": "熱々の冷凍うどんに生卵を落とし、醤油を回しかけて混ぜて食べる讃岐名物うどん。",
        "required": [
            "冷凍うどん",
            "卵"
        ],
        "optional": [
            "醤油",
            "だし醤油"
        ],
        "cooking_time": "5分",
        "difficulty": "簡単",
        "calories_estimate": "約310kcal",
        "tags": [
            "うどん",
            "定番",
            "超簡単"
        ]
    },
    {
        "id": "63",
        "title": "にんじんしりしり",
        "description": "沖縄の郷土料理。千切りにしたにんじんとシーチキンを炒め、卵でとじた甘みのある副菜。",
        "required": [
            "にんじん",
            "卵",
            "シーチキン"
        ],
        "optional": [
            "醤油",
            "だしの素"
        ],
        "cooking_time": "12分",
        "difficulty": "簡単",
        "calories_estimate": "約160kcal",
        "tags": [
            "和食",
            "副菜",
            "にんじん"
        ]
    },
    {
        "id": "64",
        "title": "じゃがバター",
        "description": "レンジでホクホクに温めたじゃがいもにバターをのせた、北海道の味覚をご家庭で。",
        "required": [
            "じゃがいも",
            "バター"
        ],
        "optional": [
            "塩"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約140kcal",
        "tags": [
            "副菜",
            "超簡単",
            "じゃがいも"
        ]
    },
    {
        "id": "65",
        "title": "たまねぎのレンジ蒸し",
        "description": "たまねぎを丸ごと電子レンジで加熱し、バターと醤油で味付けした甘み溢れる時短一品。",
        "required": [
            "たまねぎ",
            "バター"
        ],
        "optional": [
            "醤油"
        ],
        "cooking_time": "8分",
        "difficulty": "簡単",
        "calories_estimate": "約90kcal",
        "tags": [
            "副菜",
            "レンジ",
            "たまねぎ"
        ]
    },
    {
        "id": "66",
        "title": "白菜の浅漬け",
        "description": "白菜を塩もみして半日置き、シャキシャキした食感とさっぱり塩味を楽しむ箸休め。",
        "required": [
            "白菜"
        ],
        "optional": [
            "塩"
        ],
        "cooking_time": "5分",
        "difficulty": "簡単",
        "calories_estimate": "約20kcal",
        "tags": [
            "副菜",
            "和食",
            "さっぱり"
        ]
    },
    {
        "id": "67",
        "title": "豆腐の冷奴",
        "description": "ひんやり冷たい豆腐に長ネギをのせ、醤油をかけた日本の食卓に欠かせない一品。",
        "required": [
            "豆腐",
            "長ネギ"
        ],
        "optional": [
            "醤油"
        ],
        "cooking_time": "3分",
        "difficulty": "簡単",
        "calories_estimate": "約70kcal",
        "tags": [
            "副菜",
            "豆腐料理",
            "超簡単"
        ]
    },
    {
        "id": "68",
        "title": "ちくわとマヨネーズの醤油炒め",
        "description": "ちくわをマヨネーズで炒め、仕上げに醤油を焦がし絡めたコクのあるスピードおつまみ。",
        "required": [
            "ちくわ",
            "マヨネーズ"
        ],
        "optional": [
            "醤油"
        ],
        "cooking_time": "7分",
        "difficulty": "簡単",
        "calories_estimate": "約130kcal",
        "tags": [
            "おつまみ",
            "ちくわ",
            "時短"
        ]
    },
    {
        "id": "69",
        "title": "豚肉とブロッコリーの炒め物",
        "description": "豚バラ肉と冷凍ブロッコリーを塩コショウと醤油でシャキッと炒めた彩りの良いおかず。",
        "required": [
            "豚バラ肉",
            "冷凍ブロッコリー"
        ],
        "optional": [
            "塩",
            "コショウ",
            "醤油"
        ],
        "cooking_time": "12分",
        "difficulty": "簡単",
        "calories_estimate": "約320kcal",
        "tags": [
            "おかず",
            "ブロッコリー",
            "豚肉"
        ]
    },
    {
        "id": "70",
        "title": "ブロッコリーのチーズ焼き",
        "description": "ブロッコリーにチーズをかけてトースターで焼いた、焦げたチーズが美味しい副菜。",
        "required": [
            "冷凍ブロッコリー",
            "チーズ"
        ],
        "optional": [
            "塩",
            "コショウ"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約160kcal",
        "tags": [
            "副菜",
            "洋風",
            "簡単"
        ]
    },
    {
        "id": "71",
        "title": "ブロッコリーと卵のサラダ",
        "description": "ゆで卵とブロッコリーをマヨネーズで和えた、ボリュームと色彩が豊かな洋風サラダ。",
        "required": [
            "卵",
            "冷凍ブロッコリー",
            "マヨネーズ"
        ],
        "optional": [
            "塩",
            "コショウ"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約210kcal",
        "tags": [
            "サラダ",
            "卵",
            "副菜"
        ]
    },
    {
        "id": "72",
        "title": "鶏肉とブロッコリーのシチュー風",
        "description": "鶏もも肉とブロッコリーを牛乳で煮込み、片栗粉でとろみをつけた簡易ホワイトシチュー。",
        "required": [
            "鶏もも肉",
            "冷凍ブロッコリー",
            "牛乳"
        ],
        "optional": [
            "コンソメ",
            "片栗粉"
        ],
        "cooking_time": "20分",
        "difficulty": "普通",
        "calories_estimate": "約380kcal",
        "tags": [
            "おかず",
            "牛乳",
            "温まる"
        ]
    },
    {
        "id": "73",
        "title": "シーチキンたまねぎトースト",
        "description": "食パンにスライスたまねぎとシーチキンマヨ、チーズをのせて焼いたピザ風朝食パン。",
        "required": [
            "食パン",
            "シーチキン",
            "たまねぎ",
            "チーズ"
        ],
        "optional": [
            "マヨネーズ"
        ],
        "cooking_time": "8分",
        "difficulty": "簡単",
        "calories_estimate": "約340kcal",
        "tags": [
            "パン",
            "朝食",
            "シーチキン"
        ]
    },
    {
        "id": "74",
        "title": "牛肉と長ネギの甘辛炒め",
        "description": "牛細切れ肉と長ネギを醤油とみりんで炒め、ねぎの甘さと肉の旨味を凝縮させた丼の具にもなるおかず。",
        "required": [
            "牛細切れ肉",
            "長ネギ"
        ],
        "optional": [
            "醤油",
            "みりん",
            "砂糖"
        ],
        "cooking_time": "12分",
        "difficulty": "簡単",
        "calories_estimate": "約390kcal",
        "tags": [
            "おかず",
            "牛肉",
            "甘辛"
        ]
    },
    {
        "id": "75",
        "title": "白菜と卵の甘辛とじ",
        "description": "白菜を出汁でコトコト煮て、仕上げに溶き卵でふわっととじた和風の優しいおかず。",
        "required": [
            "白菜",
            "卵"
        ],
        "optional": [
            "和風だし",
            "醤油",
            "砂糖"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約160kcal",
        "tags": [
            "和食",
            "おかず",
            "白菜"
        ]
    },
    {
        "id": "76",
        "title": "鮭のホイル蒸しポン酢",
        "description": "鮭と白菜をホイルに包んで蒸し、仕上げにポン酢をかけてさっぱりいただくローカロリーおかず。",
        "required": [
            "鮭の切り身",
            "白菜"
        ],
        "optional": [
            "ポン酢"
        ],
        "cooking_time": "18分",
        "difficulty": "簡単",
        "calories_estimate": "約210kcal",
        "tags": [
            "鮭",
            "ヘルシー",
            "ポン酢"
        ]
    },
    {
        "id": "77",
        "title": "豆腐とシーチキンのチャンプルー",
        "description": "木綿豆腐とシーチキン、キャベツを炒めて卵で閉じた、沖縄風の食べ応えある炒め物。",
        "required": [
            "豆腐",
            "シーチキン",
            "卵",
            "キャベツ"
        ],
        "optional": [
            "だし醤油",
            "塩"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約290kcal",
        "tags": [
            "和食",
            "豆腐",
            "おかず"
        ]
    },
    {
        "id": "78",
        "title": "カリカリじゃがいものガレット",
        "description": "千切りにしたじゃがいもにチーズを混ぜて平らに押し付け、外はカリカリ中はモチモチに焼いた一品。",
        "required": [
            "じゃがいも",
            "チーズ"
        ],
        "optional": [
            "塩",
            "コショウ"
        ],
        "cooking_time": "15分",
        "difficulty": "普通",
        "calories_estimate": "約240kcal",
        "tags": [
            "副菜",
            "じゃがいも",
            "チーズ"
        ]
    },
    {
        "id": "79",
        "title": "合い挽きそぼろのじゃが煮",
        "description": "合い挽き肉のそぼろと小さく切ったじゃがいもを、甘辛だれでとろっと煮たお惣菜。",
        "required": [
            "合い挽き肉",
            "じゃがいも"
        ],
        "optional": [
            "醤油",
            "砂糖",
            "片栗粉"
        ],
        "cooking_time": "22分",
        "difficulty": "普通",
        "calories_estimate": "約290kcal",
        "tags": [
            "和食",
            "煮物",
            "ひき肉"
        ]
    },
    {
        "id": "80",
        "title": "豆腐ハンバーグ照り焼きソース",
        "description": "合い挽き肉に豆腐を混ぜてヘルシーにふんわり仕上げ、甘辛い照り焼き醤油タレをかけました。",
        "required": [
            "合い挽き肉",
            "豆腐"
        ],
        "optional": [
            "醤油",
            "砂糖",
            "パン粉"
        ],
        "cooking_time": "25分",
        "difficulty": "難しい",
        "calories_estimate": "約310kcal",
        "tags": [
            "おかず",
            "ヘルシー",
            "豆腐"
        ]
    },
    {
        "id": "81",
        "title": "サバとたまねぎのマヨ和え",
        "description": "焼いたサバをほぐし、たまねぎスライスとマヨネーズで和えた、サンドイッチの具にもなる副菜。",
        "required": [
            "サバの塩焼き",
            "たまねぎ",
            "マヨネーズ"
        ],
        "optional": [
            "黒コショウ"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約210kcal",
        "tags": [
            "副菜",
            "魚",
            "マヨネーズ"
        ]
    },
    {
        "id": "82",
        "title": "ウインナーの醤油バター炒め",
        "description": "ウインナーをバターで炒め、最後に醤油を数滴垂らして焦がした香ばしい一品。",
        "required": [
            "ウインナー",
            "バター"
        ],
        "optional": [
            "醤油"
        ],
        "cooking_time": "6分",
        "difficulty": "簡単",
        "calories_estimate": "約190kcal",
        "tags": [
            "時短",
            "ウインナー",
            "おつまみ"
        ]
    },
    {
        "id": "83",
        "title": "パンペルデュ風トースト",
        "description": "食パンを卵・牛乳・砂糖の液に浸してバターでこんがり焼いた、フランス風のおやつパン。",
        "required": [
            "食パン",
            "卵",
            "牛乳"
        ],
        "optional": [
            "砂糖",
            "バター"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約310kcal",
        "tags": [
            "パン",
            "スイーツ",
            "朝食"
        ]
    },
    {
        "id": "84",
        "title": "豚バラねぎ塩カルビ丼風",
        "description": "豚バラ肉をカリッと炒め、たっぷりの長ネギとレモン汁、塩コショウで味付けしたスタミナ丼の具。",
        "required": [
            "豚バラ肉",
            "長ネギ",
            "レモン"
        ],
        "optional": [
            "塩",
            "コショウ",
            "ごま油"
        ],
        "cooking_time": "12分",
        "difficulty": "簡単",
        "calories_estimate": "約450kcal",
        "tags": [
            "丼もの",
            "がっつり",
            "時短"
        ]
    },
    {
        "id": "85",
        "title": "卵と納豆の巾着焼き",
        "description": "油揚げの代わりに食パンや豆腐と合わせても美味しい、卵と納豆を混ぜて焼いたヘルシー和食。",
        "required": [
            "卵",
            "納豆"
        ],
        "optional": [
            "醤油",
            "ごま油"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約210kcal",
        "tags": [
            "和食",
            "納豆",
            "卵料理"
        ]
    },
    {
        "id": "86",
        "title": "キャベツとちくわの胡麻和え",
        "description": "キャベツとちくわを茹で、すりごまと醤油、砂糖で和えた、お弁当に彩りを添える副菜。",
        "required": [
            "キャベツ",
            "ちくわ"
        ],
        "optional": [
            "醤油",
            "砂糖",
            "すりごま"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約90kcal",
        "tags": [
            "副菜",
            "和食",
            "お弁当"
        ]
    },
    {
        "id": "87",
        "title": "にんじんとたまねぎのコンソメスープ",
        "description": "にんじんとたまねぎの千切りをコンソメスープでじっくり煮て、甘みを引き出した温スープ。",
        "required": [
            "にんじん",
            "たまねぎ"
        ],
        "optional": [
            "コンソメ",
            "塩",
            "コショウ"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約80kcal",
        "tags": [
            "スープ",
            "野菜",
            "洋風"
        ]
    },
    {
        "id": "88",
        "title": "豚肩ロースステーキ和風だれ",
        "description": "豚肩ロースの厚切りをフライパンでジューシーに焼き上げ、醤油とレモンの和風ソースをかけたごちそう。",
        "required": [
            "豚肩ロース",
            "レモン"
        ],
        "optional": [
            "醤油",
            "みりん",
            "ニンニク"
        ],
        "cooking_time": "20分",
        "difficulty": "普通",
        "calories_estimate": "約480kcal",
        "tags": [
            "おかず",
            "ごちそう",
            "肉"
        ]
    },
    {
        "id": "89",
        "title": "鮭と卵の和風雑炊",
        "description": "鮭の塩気が出汁に染み渡る、熱々のご飯とふんわりかき卵を合わせたお腹に優しい雑炊。",
        "required": [
            "鮭の切り身",
            "卵"
        ],
        "optional": [
            "ご飯",
            "だし醤油"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約290kcal",
        "tags": [
            "和食",
            "ご飯もの",
            "優しい"
        ]
    },
    {
        "id": "90",
        "title": "うどん餃子風おやき",
        "description": "ひき肉とねぎ、刻んだ冷凍うどんを混ぜてフライパンで丸く平らに焼いた、大阪生まれの人気おやつメニュー。",
        "required": [
            "冷凍うどん",
            "合い挽き肉",
            "長ネギ",
            "卵"
        ],
        "optional": [
            "醤油",
            "塩",
            "片栗粉"
        ],
        "cooking_time": "18分",
        "difficulty": "普通",
        "calories_estimate": "約380kcal",
        "tags": [
            "うどん",
            "おやつ",
            "簡単"
        ]
    },
    {
        "id": "91",
        "title": "ウインナーナポリタン風うどん",
        "description": "冷凍うどんをウインナー、たまねぎ、ピーマンの代わりにキャベツとケチャップで炒めたどこか懐かしい洋風うどん。",
        "required": [
            "冷凍うどん",
            "ウインナー",
            "たまねぎ",
            "キャベツ"
        ],
        "optional": [
            "ケチャップ",
            "バター"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約420kcal",
        "tags": [
            "うどん",
            "洋風",
            "ナポリタン"
        ]
    },
    {
        "id": "92",
        "title": "豆腐と卵のトロミ中華スープ",
        "description": "滑らかな豆腐とふんわり卵を鶏ガラスープでまとめ、長ねぎを散らしたとろみスープ。",
        "required": [
            "豆腐",
            "卵",
            "長ネギ"
        ],
        "optional": [
            "中華だし",
            "醤油",
            "片栗粉"
        ],
        "cooking_time": "10分",
        "difficulty": "簡単",
        "calories_estimate": "約90kcal",
        "tags": [
            "スープ",
            "中華",
            "簡単"
        ]
    },
    {
        "id": "93",
        "title": "鶏もも肉とたまねぎの味噌炒め",
        "description": "鶏もも肉とたまねぎを甘辛いコクのある味噌ダレで焼き上げた、ご飯のおかずに最適な一品。",
        "required": [
            "鶏もも肉",
            "たまねぎ"
        ],
        "optional": [
            "味噌",
            "醤油",
            "砂糖"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約410kcal",
        "tags": [
            "おかず",
            "鶏肉",
            "味噌"
        ]
    },
    {
        "id": "94",
        "title": "じゃがウインナーのジャーマン風",
        "description": "ゆでたじゃがいもとウインナーをバターで炒め、黒コショウをたっぷり振ったジャーマンポテト風おつまみ。",
        "required": [
            "じゃがいも",
            "ウインナー"
        ],
        "optional": [
            "バター",
            "塩",
            "黒コショウ"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約260kcal",
        "tags": [
            "おつまみ",
            "じゃがいも",
            "洋風"
        ]
    },
    {
        "id": "95",
        "title": "白菜とちくわのさっと煮",
        "description": "白菜とちくわを和風の出汁でさっと煮て、優しい醤油味で仕上げた短時間副菜。",
        "required": [
            "白菜",
            "ちくわ"
        ],
        "optional": [
            "和風だし",
            "醤油",
            "みりん"
        ],
        "cooking_time": "12分",
        "difficulty": "簡単",
        "calories_estimate": "約90kcal",
        "tags": [
            "和食",
            "副菜",
            "白菜"
        ]
    },
    {
        "id": "96",
        "title": "牛肉の卵とじすき焼き風",
        "description": "牛細切れ肉とたまねぎを甘辛い割り下で煮煮て、卵でふんわりとじたご飯の進むおかず。",
        "required": [
            "牛細切れ肉",
            "卵",
            "たまねぎ"
        ],
        "optional": [
            "醤油",
            "砂糖",
            "みりん"
        ],
        "cooking_time": "15分",
        "difficulty": "普通",
        "calories_estimate": "約460kcal",
        "tags": [
            "おかず",
            "牛肉",
            "すき焼き風"
        ]
    },
    {
        "id": "97",
        "title": "豚バラとじゃがいもの照り焼き炒め",
        "description": "カリカリに炒めた豚バラ肉とレンジ加熱したじゃがいもを、醤油と砂糖の照り焼きダレで絡めた一品。",
        "required": [
            "豚バラ肉",
            "じゃがいも"
        ],
        "optional": [
            "醤油",
            "砂糖",
            "バター"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約390kcal",
        "tags": [
            "和食",
            "おかず",
            "じゃがいも"
        ]
    },
    {
        "id": "98",
        "title": "鶏もも肉と長ネギの塩だれ焼き",
        "description": "ジューシーな鶏もも肉を香ばしく焼き、長ネギたっぷりのレモン塩だれをたっぷり絡めました。",
        "required": [
            "鶏もも肉",
            "長ネギ",
            "レモン"
        ],
        "optional": [
            "塩",
            "ごま油",
            "コショウ"
        ],
        "cooking_time": "15分",
        "difficulty": "簡単",
        "calories_estimate": "約380kcal",
        "tags": [
            "焼き物",
            "鶏肉",
            "レモン"
        ]
    },
    {
        "id": "99",
        "title": "ウインナーとキャベツのコンソメ煮",
        "description": "キャベツとウインナーをコンソメスープでくたくたになるまで煮込んだ、お野菜の甘みが美味しい煮物。",
        "required": [
            "キャベツ",
            "ウインナー"
        ],
        "optional": [
            "コンソメ",
            "塩"
        ],
        "cooking_time": "18分",
        "difficulty": "簡単",
        "calories_estimate": "約160kcal",
        "tags": [
            "スープ",
            "温活",
            "野菜"
        ]
    },
    {
        "id": "100",
        "title": "豆腐と納豆のヘルシー温やっこ",
        "description": "温めた豆腐に納豆とチーズをのせ、醤油を垂らしてレンジでさらに加熱した、簡単スタミナ冷奴。",
        "required": [
            "豆腐",
            "納豆",
            "チーズ"
        ],
        "optional": [
            "醤油"
        ],
        "cooking_time": "8分",
        "difficulty": "簡単",
        "calories_estimate": "約220kcal",
        "tags": [
            "豆腐",
            "ヘルシー",
            "レンジ"
        ]
    }
]


def _build_gemini_prompt(ingredients: list[str], preferences: dict | None) -> str:
    """Gemini APIに渡すプロンプトを構築する（実際のAPI連携時に使用）"""
    pref_text = ""
    if preferences:
        style = preferences.get("style", "")
        max_time = preferences.get("cook_time_max", "")
        if style:
            pref_text += f"\n- 料理スタイル: {style}"
        if max_time:
            pref_text += f"\n- 調理時間の上限: {max_time}分以内"

    prompt = f"""あなたは日本の家庭料理の専門シェフです。
以下の在庫食材を使ったレシピを3〜5品提案してください。

## 在庫食材
{chr(10).join(f'- {ing}' for ing in ingredients)}

## 条件{pref_text}
- 家庭で作りやすいレシピ
- 食材を無駄なく使い切る提案
- 足りない食材がある場合は「買い足し推奨食材」も記載

## 出力形式
各レシピについて以下を記載:
1. レシピ名
2. 説明（2〜3行）
3. 使用する在庫食材
4. 買い足し推奨食材（あれば）
5. 調理時間
6. 難易度（簡単/普通/難しい）
"""
    return prompt


def _match_recipes(ingredients: list[str]) -> list[RecipeSuggestion]:
    """在庫食材に基づいてレシピをマッチングする（モック）"""
    ing_set = set(ingredients)
    matched = []

    for recipe in MOCK_RECIPES_DB:
        required = set(recipe["required"])
        # 必須食材の50%以上が在庫にあればマッチ
        overlap = required & ing_set
        if len(overlap) / len(required) >= 0.5:
            missing = list(set(recipe.get("optional", [])) - ing_set)
            matched.append(
                RecipeSuggestion(
                    id=str(uuid.uuid4()),
                    title=recipe["title"],
                    description=recipe["description"],
                    used_ingredients=list(overlap),
                    missing_ingredients=missing[:2],  # 最大2品の買い足し提案
                    cooking_time=recipe["cooking_time"],
                    difficulty=recipe["difficulty"],
                    calories_estimate=recipe.get("calories_estimate"),
                    tags=recipe.get("tags", []),
                )
            )

    # マッチしなかった場合は全レシピを返す（フォールバック）
    if not matched:
        matched = [
            RecipeSuggestion(
                id=str(uuid.uuid4()),
                title=r["title"],
                description=r["description"],
                used_ingredients=r["required"],
                missing_ingredients=r.get("optional", [])[:2],
                cooking_time=r["cooking_time"],
                difficulty=r["difficulty"],
                calories_estimate=r.get("calories_estimate"),
                tags=r.get("tags", []),
            )
            for r in MOCK_RECIPES_DB[:2]
        ]

    return matched


@router.post(
    "/suggest-recipe",
    response_model=RecipeResponse,
    summary="在庫食材からAIレシピを提案する",
    description="""
    現在の在庫食材を元にGemini APIへのプロンプトを構築し、
    最適なレシピを提案します。現在はモックデータを返します。
    """,
)
async def suggest_recipe(request: RecipeRequest) -> RecipeResponse:
    # Geminiプロンプト構築（ログ/デバッグ用）
    prompt = _build_gemini_prompt(request.ingredients, request.preferences)
    print(f"[DEBUG] Gemini Prompt:\n{prompt}")

    # モックAI処理遅延をシミュレート
    await asyncio.sleep(1.2)

    recipes = _match_recipes(request.ingredients)

    return RecipeResponse(
        recipes=recipes,
        total=len(recipes),
        generated_at=datetime.now().isoformat(),
    )
