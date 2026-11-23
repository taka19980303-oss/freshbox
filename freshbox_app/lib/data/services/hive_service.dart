import 'package:hive_flutter/hive_flutter.dart';
import '../models/ingredient.dart';

/// Hive ローカルDB 管理サービス
class HiveService {
  static const String _ingredientBoxName = 'ingredients';
  static const String _shoppingBoxName = 'shopping_list';

  static Box? _ingredientBox;
  static Box? _shoppingBox;

  /// アプリ起動時に呼び出す初期化処理
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _ingredientBox = await Hive.openBox(_ingredientBoxName);
    _shoppingBox = await Hive.openBox(_shoppingBoxName);

    // 初回起動時（空の場合）に初期データを投入
    if (_ingredientBox!.isEmpty) {
      await _prepopulateDefaultIngredients();
    }
  }

  static Future<void> _prepopulateDefaultIngredients() async {
    final defaults = Ingredient.sampleData;
    for (final ing in defaults) {
      await saveIngredient(ing);
    }
  }

  static Box get ingredientBox {
    if (_ingredientBox == null || !_ingredientBox!.isOpen) {
      throw StateError('HiveService not initialized. Call initialize() first.');
    }
    return _ingredientBox!;
  }

  static Box get shoppingBox {
    if (_shoppingBox == null || !_shoppingBox!.isOpen) {
      throw StateError('HiveService not initialized. Call initialize() first.');
    }
    return _shoppingBox!;
  }

  // ── CRUD ──

  /// 全食材を取得（賞味期限近い順）
  static List<Ingredient> getAllIngredients() {
    final box = ingredientBox;
    final list = box.values
        .whereType<Map>()
        .map((m) => Ingredient.fromMap(m))
        .toList();
    list.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return list;
  }

  /// 食材を追加・更新
  static Future<void> saveIngredient(Ingredient ingredient) async {
    await ingredientBox.put(ingredient.id, ingredient.toMap());
  }

  /// 食材を削除
  static Future<void> deleteIngredient(String id) async {
    await ingredientBox.delete(id);
  }

  /// 全食材を削除
  static Future<void> clearAll() async {
    await ingredientBox.clear();
  }

  // ── 買い物リスト CRUD ──

  /// 全買い物アイテムを取得
  static List<Ingredient> getAllShoppingItems() {
    final box = shoppingBox;
    final list = box.values
        .whereType<Map>()
        .map((m) => Ingredient.fromMap(m))
        .toList();
    // カテゴリのラベル順にソート
    list.sort((a, b) => a.category.label.compareTo(b.category.label));
    return list;
  }

  /// 買い物アイテムを追加・更新
  static Future<void> saveShoppingItem(Ingredient item) async {
    await shoppingBox.put(item.id, item.toMap());
  }

  /// 買い物アイテムを削除
  static Future<void> deleteShoppingItem(String id) async {
    await shoppingBox.delete(id);
  }

  /// 全買い物アイテムを削除
  static Future<void> clearAllShopping() async {
    await shoppingBox.clear();
  }

  /// 購入履歴（よく使う食材）を追加
  static Future<void> saveToHistory(Ingredient ingredient) async {
    final box = ingredientBox;
    final historyList = box.get('__recent_history', defaultValue: []) as List<dynamic>;
    
    // List<dynamic> を List<Map> に変換してミュータブルなリストにする
    final list = historyList
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // 重複を削除
    final nameLower = ingredient.name.trim().toLowerCase();
    list.removeWhere((item) => (item['name'] as String).trim().toLowerCase() == nameLower);

    // 今回登録した賞味期限と購入日（または今日）の差分を日数として保持
    final purchaseDate = ingredient.purchasedDate ?? DateTime.now();
    final expiryDays = ingredient.expiryDate.difference(purchaseDate).inDays;
    final finalExpiryDays = (expiryDays <= 0 || expiryDays > 365) ? 7 : expiryDays;

    // 先頭に挿入
    list.insert(0, {
      'name': ingredient.name,
      'category': ingredient.category.label,
      'quantity': ingredient.quantity,
      'unit': ingredient.unit,
      'expiryDays': finalExpiryDays,
      'storageLocation': ingredient.storageLocation.label,
      'price': ingredient.price,
    });

    // 最大15件に制限
    if (list.length > 15) {
      list.removeRange(15, list.length);
    }

    await box.put('__recent_history', list);
  }

  /// 購入履歴（よく使う食材）を取得
  static List<Map<String, dynamic>> getHistory() {
    try {
      final box = ingredientBox;
      final historyList = box.get('__recent_history', defaultValue: []) as List<dynamic>;
      return historyList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
