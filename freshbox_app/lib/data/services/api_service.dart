import '../models/recipe.dart';

/// レシピ提案サービス（完全ローカル動作）
///
/// サーバーやAI APIには接続せず、端末内のレシピデータベース
/// （RecipeSuggestion.sampleData）と在庫食材を照合して提案する。
/// ネットワーク不要で、オフラインでも同じ結果が返る。
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// 在庫食材のリストから作れるレシピを提案する。
  /// よく使う食材を多く含むレシピほど上位に並ぶ。
  Future<List<RecipeSuggestion>> suggestRecipes({
    required List<String> ingredients,
    Map<String, dynamic>? preferences,
  }) async {
    final userIngredients = ingredients
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (userIngredients.isEmpty) return [];

    // レシピ側の食材名と在庫名の照合。
    // 「豚肩ロース（ブロック）」のような在庫名でも「豚肩ロース」に当たるよう、
    // 完全一致ではなく相互の部分一致で判定する。
    bool matches(String recipeIngredient, String userIngredient) {
      return recipeIngredient == userIngredient ||
          userIngredient.contains(recipeIngredient) ||
          recipeIngredient.contains(userIngredient);
    }

    final scored = <(RecipeSuggestion, int)>[];
    for (final recipe in RecipeSuggestion.sampleData) {
      var score = 0;
      for (final required in recipe.usedIngredients) {
        if (userIngredients.any((u) => matches(required, u))) {
          score++;
        }
      }
      if (score > 0) scored.add((recipe, score));
    }

    if (scored.isEmpty) {
      // 何も当たらなければ全レシピを返す（提案ゼロで画面が空になるのを防ぐ）
      return RecipeSuggestion.sampleData;
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((e) => e.$1).toList();
  }
}
