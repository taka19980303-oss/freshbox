import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ingredient.dart';
import '../../data/repositories/ingredient_repository.dart';
import 'ingredient_provider.dart';
import '../../data/services/icloud_sync_service.dart';

/// 買い物リスト StateNotifier
class ShoppingNotifier extends StateNotifier<List<Ingredient>> {
  final IngredientRepository _repo;
  final Ref _ref;

  ShoppingNotifier(this._repo, this._ref) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAllShopping();
    ICloudSyncService.pushShoppingToICloud(state);
  }

  void reload() => _load();

  Future<void> add(Ingredient item) async {
    await _repo.addShopping(item);
    _load();
  }

  Future<void> update(Ingredient item) async {
    await _repo.updateShopping(item);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.deleteShopping(id);
    _load();
  }

  /// 買い物リストのアイテムを購入完了し、冷蔵庫（在庫）へ移動
  Future<void> buy(Ingredient item) async {
    // 1. 買い物リストから削除
    await _repo.deleteShopping(item.id);

    // 2. 推奨賞味期限を名前とカテゴリから自動判定して、冷蔵庫（在庫）へ追加
    final expiryDays = _getRecommendedExpiryDays(item.name, item.category);
    final purchasedItem = item.copyWith(
      expiryDate: DateTime.now().add(Duration(days: expiryDays)),
      purchasedDate: DateTime.now(),
    );

    await _ref.read(ingredientsProvider.notifier).add(purchasedItem);

    // 3. リロード
    _load();
  }

  /// 全てクリア
  Future<void> clearAll() async {
    await _repo.clearShopping();
    _load();
  }

  /// 食材名とカテゴリから推奨の保存可能日数を返す（自動賞味期限判定）
  int _getRecommendedExpiryDays(String name, IngredientCategory category) {
    final n = name.toLowerCase();
    if (category == IngredientCategory.meat) {
      if (n.contains('ウインナー') || n.contains('ベーコン') || n.contains('ハム')) return 10;
      return 3;
    }
    if (category == IngredientCategory.vegetable) {
      if (n.contains('たまねぎ') || n.contains('じゃがいも') || n.contains('さつまいも')) return 30;
      if (n.contains('にんじん')) return 14;
      if (n.contains('キャベツ') || n.contains('大根') || n.contains('長ネギ')) return 10;
      if (n.contains('もやし')) return 1;
      return 7;
    }
    if (category == IngredientCategory.fish) {
      if (n.contains('シーチキン') || n.contains('缶')) return 365;
      if (n.contains('ちくわ') || n.contains('かにかま')) return 7;
      return 2;
    }
    if (category == IngredientCategory.dairy) {
      if (n.contains('卵')) return 14;
      if (n.contains('牛乳') || n.contains('豆乳')) return 7;
      if (n.contains('ヨーグルト')) return 10;
      if (n.contains('バター') || n.contains('マーガリン')) return 90;
      return 20;
    }
    if (category == IngredientCategory.seasoning) {
      if (n.contains('塩') || n.contains('砂糖') || n.contains('コショウ')) return 365;
      return 180;
    }
    if (category == IngredientCategory.frozen) {
      return 60;
    }
    if (category == IngredientCategory.other) {
      if (n.contains('食パン')) return 4;
      if (n.contains('納豆')) return 7;
      if (n.contains('豆腐')) return 5;
      return 60;
    }
    return 7; // デフォルト
  }
}

final shoppingListProvider =
    StateNotifierProvider<ShoppingNotifier, List<Ingredient>>((ref) {
  final repo = ref.watch(ingredientRepositoryProvider);
  return ShoppingNotifier(repo, ref);
});
