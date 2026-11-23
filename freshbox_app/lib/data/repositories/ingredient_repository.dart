import '../models/ingredient.dart';
import '../services/hive_service.dart';

/// 食材リポジトリ（データ操作の窓口）
class IngredientRepository {
  List<Ingredient> getAll() => HiveService.getAllIngredients();

  Future<void> add(Ingredient ingredient) =>
      HiveService.saveIngredient(ingredient);

  Future<void> update(Ingredient ingredient) =>
      HiveService.saveIngredient(ingredient);

  Future<void> delete(String id) =>
      HiveService.deleteIngredient(id);

  // ── 買い物リスト ──

  List<Ingredient> getAllShopping() => HiveService.getAllShoppingItems();

  Future<void> addShopping(Ingredient item) =>
      HiveService.saveShoppingItem(item);

  Future<void> updateShopping(Ingredient item) =>
      HiveService.saveShoppingItem(item);

  Future<void> deleteShopping(String id) =>
      HiveService.deleteShoppingItem(id);

  Future<void> clearShopping() =>
      HiveService.clearAllShopping();
}
