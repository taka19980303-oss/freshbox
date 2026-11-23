import 'ingredient.dart';

class MealRecipe {
  final String title;
  final String category; // 和食, 洋食, 中華
  final String calories;
  final String protein;
  final String carb;
  final List<MealIngredientReq> ingredients;
  final List<String> instructions;

  const MealRecipe({
    required this.title,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carb,
    required this.ingredients,
    required this.instructions,
  });
}

class MealIngredientReq {
  final String name;
  final double quantity;
  final String unit;
  final IngredientCategory category;

  const MealIngredientReq({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
  });
}

class MealPlanDay {
  final int day;
  final MealRecipe recipe;
  final List<Ingredient> usedFromInventory;
  final List<MealIngredientReq> missingToBuy;

  const MealPlanDay({
    required this.day,
    required this.recipe,
    required this.usedFromInventory,
    required this.missingToBuy,
  });
}

abstract final class MealPlannerEngine {
  /// レシピデータベース (全15種類)
  static const List<MealRecipe> recipeDb = [
    MealRecipe(
      title: '豚バラ肉とキャベツの回鍋肉',
      category: '中華',
      calories: '450 kcal',
      protein: '18 g',
      carb: '12 g',
      ingredients: [
        MealIngredientReq(name: '豚バラ肉', quantity: 200, unit: 'g', category: IngredientCategory.meat),
        MealIngredientReq(name: 'キャベツ', quantity: 0.25, unit: '個', category: IngredientCategory.vegetable),
        MealIngredientReq(name: 'ピーマン', quantity: 2, unit: '個', category: IngredientCategory.vegetable),
        MealIngredientReq(name: '醤油', quantity: 1, unit: '大さじ', category: IngredientCategory.seasoning),
        MealIngredientReq(name: '味噌', quantity: 1, unit: '大さじ', category: IngredientCategory.seasoning),
      ],
      instructions: [
        '豚バラ肉とキャベツ、ピーマンを食べやすい大きさにカットします。',
        'フライパンに油を熱し、豚肉を炒め、色が変わったらキャベツとピーマンを加えます。',
        '全体に火が通ったら、醤油と味噌を混ぜ合わせた調味料を回し入れ、強火でサッと炒め合わせます。'
      ],
    ),
    MealRecipe(
      title: 'ふんわり卵とトマトの中華炒め',
      category: '中華',
      calories: '280 kcal',
      protein: '12 g',
      carb: '8 g',
      ingredients: [
        MealIngredientReq(name: '卵', quantity: 3, unit: '個', category: IngredientCategory.dairy),
        MealIngredientReq(name: 'トマト', quantity: 1, unit: '個', category: IngredientCategory.vegetable),
        MealIngredientReq(name: 'ごま油', quantity: 1, unit: '大さじ', category: IngredientCategory.seasoning),
        MealIngredientReq(name: '中華だし', quantity: 1, unit: '小さじ', category: IngredientCategory.seasoning),
      ],
      instructions: [
        'トマトはくし形に切り、卵はボウルに割り入れて軽く塩をふり混ぜ合わせておきます。',
        '熱したフライパンにごま油を入れ、卵を流し込んで半熟状になったら一度取り出します。',
        '同じフライパンでトマトを炒め、しんなりしたら卵を戻し入れ、中華だしで味を調えてサッと和えます。'
      ],
    ),
    MealRecipe(
      title: '鶏もも肉とじゃがいもの照り焼き',
      category: '和食',
      calories: '490 kcal',
      protein: '24 g',
      carb: '22 g',
      ingredients: [
        MealIngredientReq(name: '鶏もも肉', quantity: 250, unit: 'g', category: IngredientCategory.meat),
        MealIngredientReq(name: 'じゃがいも', quantity: 2, unit: '個', category: IngredientCategory.vegetable),
        MealIngredientReq(name: '醤油', quantity: 2, unit: '大さじ', category: IngredientCategory.seasoning),
        MealIngredientReq(name: '砂糖', quantity: 1, unit: '大さじ', category: IngredientCategory.seasoning),
        MealIngredientReq(name: 'みりん', quantity: 1, unit: '大さじ', category: IngredientCategory.seasoning),
      ],
      instructions: [
        '鶏もも肉は一口大にカットし、じゃがいもは一口大に切って電子レンジで2分加熱しておきます。',
        'フライパンに油を引き、鶏肉を皮目から焼いて焼き色をつけます。裏返してじゃがいもを加えます。',
        '醤油、砂糖、みりんを入れ、汁気がなくなりツヤが出るまで中火で煮絡めます。'
      ],
    ),
    MealRecipe(
      title: 'サバの味噌煮 ほっこり仕立て',
      category: '和食',
      calories: '350 kcal',
      protein: '20 g',
      carb: '10 g',
      ingredients: [
        MealIngredientReq(name: 'サバの切り身', quantity: 2, unit: '切れ', category: IngredientCategory.fish),
        MealIngredientReq(name: '生姜', quantity: 1, unit: 'かけ', category: IngredientCategory.seasoning),
        MealIngredientReq(name: '味噌', quantity: 2, unit: '大さじ', category: IngredientCategory.seasoning),
        MealIngredientReq(name: 'みりん', quantity: 1, unit: '大さじ', category: IngredientCategory.seasoning),
      ],
      instructions: [
        'サバは皮目に十字の切れ目を入れ、熱湯をかけて臭みを取っておきます。生姜は薄切りにします。',
        '鍋に水、みりん、薄切り生姜を入れて沸騰させ、サバを入れます。',
        '味噌を煮汁に溶かし入れ、落とし蓋をして弱火で約10分、煮汁がトロリとするまで煮詰めます。'
      ],
    ),
    MealRecipe(
      title: 'とろ〜り豆腐と挽肉のピリ辛麻婆豆腐',
      category: '中華',
      calories: '390 kcal',
      protein: '22 g',
      carb: '9 g',
      ingredients: [
        MealIngredientReq(name: '豆腐', quantity: 1, unit: '丁', category: IngredientCategory.other),
        MealIngredientReq(name: '合い挽き肉', quantity: 150, unit: 'g', category: IngredientCategory.meat),
        MealIngredientReq(name: '長ネギ', quantity: 0.5, unit: '本', category: IngredientCategory.vegetable),
        MealIngredientReq(name: '醤油', quantity: 1, unit: '大さじ', category: IngredientCategory.seasoning),
        MealIngredientReq(name: 'ごま油', quantity: 1, unit: '小さじ', category: IngredientCategory.seasoning),
      ],
      instructions: [
        '豆腐は2cmの角切りに、長ネギはみじん切りにします。',
        'フライパンで合い挽き肉を炒め、色が変わってみじん切りのネギを加えて炒め合わせます。',
        '水、醤油、豆腐を入れてひと煮立ちさせ、水溶き片栗粉でとろみをつけ、最後にごま油を振ります。'
      ],
    ),
    MealRecipe(
      title: '鮭とほうれん草の和風クリームパスタ',
      category: '洋食',
      calories: '550 kcal',
      protein: '26 g',
      carb: '62 g',
      ingredients: [
        MealIngredientReq(name: '鮭の切り身', quantity: 2, unit: '切れ', category: IngredientCategory.fish),
        MealIngredientReq(name: 'ほうれん草', quantity: 1, unit: '袋', category: IngredientCategory.vegetable),
        MealIngredientReq(name: '生クリーム', quantity: 1, unit: 'パック', category: IngredientCategory.dairy),
        MealIngredientReq(name: 'パスタ麺', quantity: 200, unit: 'g', category: IngredientCategory.other),
        MealIngredientReq(name: '醤油', quantity: 1, unit: '小さじ', category: IngredientCategory.seasoning),
      ],
      instructions: [
        'パスタ麺を表示通りに茹でます。鮭は一口大に、ほうれん草は茹でて3cm幅に切ります。',
        'フライパンで鮭を焼き、両面焼き色がついたらほうれん草と生クリームを加えます。',
        '茹で上がったパスタと醤油を加え、弱火でソースとよく絡めます。'
      ],
    ),
    MealRecipe(
      title: '丸ごと玉ねぎとウインナーの洋風スープ',
      category: '洋食',
      calories: '210 kcal',
      protein: '8 g',
      carb: '18 g',
      ingredients: [
        MealIngredientReq(name: 'たまねぎ', quantity: 2, unit: '個', category: IngredientCategory.vegetable),
        MealIngredientReq(name: 'ウインナー', quantity: 1, unit: '袋', category: IngredientCategory.meat),
        MealIngredientReq(name: 'にんじん', quantity: 0.5, unit: '本', category: IngredientCategory.vegetable),
        MealIngredientReq(name: '塩', quantity: 1, unit: '少し', category: IngredientCategory.seasoning),
      ],
      instructions: [
        'たまねぎは半分に切り、にんじんは乱切りに、ウインナーは斜めに切り目を入れます。',
        '鍋に水、たまねぎ、にんじん、ウインナーを入れて中火にかけ、沸騰したら弱火にします。',
        'コンソメや塩で味を調え、たまねぎが口の中でとろけるほど柔らかくなるまで煮込みます。'
      ],
    ),
    MealRecipe(
      title: '牛肉とミニトマトのガーリック炒め',
      category: '洋食',
      calories: '420 kcal',
      protein: '22 g',
      carb: '7 g',
      ingredients: [
        MealIngredientReq(name: '牛ステーキ肉', quantity: 180, unit: 'g', category: IngredientCategory.meat),
        MealIngredientReq(name: 'ミニトマト', quantity: 1, unit: 'パック', category: IngredientCategory.vegetable),
        MealIngredientReq(name: 'ニンニク', quantity: 1, unit: '個', category: IngredientCategory.vegetable),
        MealIngredientReq(name: 'コショウ', quantity: 1, unit: '少し', category: IngredientCategory.seasoning),
      ],
      instructions: [
        '牛肉はサイコロ状にカットし、ニンニクはスライスします。トマトはヘタを取っておきます。',
        'フライパンにオリーブオイルとスライスニンニクを入れて弱火で香りが出るまで炒めます。',
        '強火にして牛肉とミニトマトを加え、サッと炒めて塩コショウで味を調えます。'
      ],
    ),
    MealRecipe(
      title: 'サバとキャベツの塩コショウパスタ',
      category: '洋食',
      calories: '510 kcal',
      protein: '21 g',
      carb: '58 g',
      ingredients: [
        MealIngredientReq(name: 'サバの塩焼き', quantity: 1, unit: '枚', category: IngredientCategory.fish),
        MealIngredientReq(name: 'キャベツ', quantity: 0.25, unit: '個', category: IngredientCategory.vegetable),
        MealIngredientReq(name: 'パスタ麺', quantity: 160, unit: 'g', category: IngredientCategory.other),
        MealIngredientReq(name: 'コショウ', quantity: 1, unit: '少し', category: IngredientCategory.seasoning),
      ],
      instructions: [
        'パスタを茹でます。サバの塩焼きはほぐして骨を取ります。キャベツは一口大に切ります。',
        'オリーブオイルを引いたフライパンでキャベツを炒め、しんなりしたらほぐしたサバを加えます。',
        '茹で上がったパスタ、パスタの茹で汁少し、塩コショウを加えて全体を手早く炒め合わせます。'
      ],
    ),
    MealRecipe(
      title: 'ちくわとブロッコリーのマヨ胡麻和え',
      category: '和食',
      calories: '180 kcal',
      protein: '9 g',
      carb: '8 g',
      ingredients: [
        MealIngredientReq(name: 'ちくわ', quantity: 1, unit: 'パック', category: IngredientCategory.fish),
        MealIngredientReq(name: 'ブロッコリー', quantity: 0.5, unit: '個', category: IngredientCategory.vegetable),
        MealIngredientReq(name: 'マヨネーズ', quantity: 1.5, unit: '大さじ', category: IngredientCategory.seasoning),
      ],
      instructions: [
        'ブロッコリーは小房に分けて電子レンジで1分半加熱します。ちくわは5mm幅の輪切りにします。',
        'ボウルにブロッコリーとちくわを入れます。',
        'マヨネーズとすりごま（お好みで醤油少々）を加えて、全体をよく和えます。'
      ],
    ),
  ];

  /// 冷蔵庫の在庫状況に基づき、3日間の献立を作成する
  /// 最も消費期限の短い食材を優先的に利用する
  static List<MealPlanDay> generate3DayPlan(List<Ingredient> inventory) {
    // 期限の迫っている食材順にソート (期限切れでないもの)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sortedUrgent = inventory
        .where((item) => !item.expiryDate.isBefore(today))
        .toList();
    sortedUrgent.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));

    final selectedRecipes = <MealRecipe>[];
    final Set<String> usedTitles = {};

    // 3日分の献立を順番に選出
    for (int day = 1; day <= 3; day++) {
      MealRecipe? matchedRecipe;

      // 1. 直近で期限が切れる食材のうち、まだレシピ選定に使用していない食材を優先
      for (final item in sortedUrgent) {
        final candidates = recipeDb.where((recipe) {
          if (usedTitles.contains(recipe.title)) return false;
          // レシピが必要とする食材のうち、在庫の名前が含まれるか部分一致でチェック
          return recipe.ingredients.any((req) =>
              req.name.contains(item.name) || item.name.contains(req.name));
        }).toList();

        if (candidates.isNotEmpty) {
          matchedRecipe = candidates.first;
          break;
        }
      }

      // 2. もし見つからなかった場合は、まだ使っていない残りの中からランダムで選出
      if (matchedRecipe == null) {
        final remaining = recipeDb
            .where((recipe) => !usedTitles.contains(recipe.title))
            .toList();
        if (remaining.isNotEmpty) {
          matchedRecipe = remaining.first;
        } else {
          // すべて選出済みの場合はダブりを許可して最初から選択
          matchedRecipe = recipeDb[day % recipeDb.length];
        }
      }

      selectedRecipes.add(matchedRecipe);
      usedTitles.add(matchedRecipe.title);
    }

    // 各日の詳細（在庫使用 vs 不足分）を計算
    final List<MealPlanDay> plan = [];
    for (int i = 0; i < 3; i++) {
      final recipe = selectedRecipes[i];
      final List<Ingredient> used = [];
      final List<MealIngredientReq> missing = [];

      for (final req in recipe.ingredients) {
        // 在庫内に部分一致する食材が存在するか確認
        final invMatch = inventory.where((inv) {
          return inv.name.toLowerCase().contains(req.name.toLowerCase()) ||
              req.name.toLowerCase().contains(inv.name.toLowerCase());
        }).toList();

        if (invMatch.isNotEmpty) {
          // 在庫あり
          used.add(invMatch.first);
        } else {
          // 在庫なし、買い物リスト追加候補
          missing.add(req);
        }
      }

      plan.add(MealPlanDay(
        day: i + 1,
        recipe: recipe,
        usedFromInventory: used,
        missingToBuy: missing,
      ));
    }

    return plan;
  }
}
