import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ingredient.dart';
import '../../data/repositories/ingredient_repository.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/widget_sync_service.dart';
import '../../data/services/icloud_sync_service.dart';
import '../../data/services/hive_service.dart';

// ── Repository プロバイダー ──
final ingredientRepositoryProvider = Provider<IngredientRepository>(
  (_) => IngredientRepository(),
);

// ── 食材リスト StateNotifier ──
class IngredientNotifier extends StateNotifier<List<Ingredient>> {
  final IngredientRepository _repo;

  IngredientNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
    WidgetSyncService.syncWidgetData(state);
    ICloudSyncService.pushIngredientsToICloud(state);
  }

  int _categoryDefaultPrice(IngredientCategory category) {
    switch (category) {
      case IngredientCategory.meat:
      case IngredientCategory.fish:
        return 400;
      case IngredientCategory.vegetable:
        return 150;
      case IngredientCategory.dairy:
        return 200;
      case IngredientCategory.seasoning:
        return 300;
      case IngredientCategory.frozen:
        return 250;
      case IngredientCategory.other:
      default:
        return 150;
    }
  }

  Future<void> _addSavings(int amount) async {
    if (amount <= 0) return;
    final box = HiveService.ingredientBox;
    final current = (box.get('__total_savings_amount', defaultValue: 0) as num).toInt();
    await box.put('__total_savings_amount', current + amount);
  }

  Future<void> _addWaste(int amount) async {
    if (amount <= 0) return;
    final box = HiveService.ingredientBox;
    final current = (box.get('__total_waste_amount', defaultValue: 0) as num).toInt();
    await box.put('__total_waste_amount', current + amount);
  }

  Future<void> add(Ingredient ingredient) async {
    await HiveService.saveToHistory(ingredient);
    await _repo.add(ingredient);
    await NotificationService.scheduleExpiryNotification(
      id: ingredient.id,
      name: ingredient.name,
      expiryDate: ingredient.expiryDate,
    );
    _load();
  }

  Future<void> update(Ingredient ingredient) async {
    Ingredient? oldItem;
    try {
      oldItem = state.firstWhere((e) => e.id == ingredient.id);
    } catch (_) {}

    if (oldItem != null && ingredient.quantity < oldItem.quantity) {
      final diff = oldItem.quantity - ingredient.quantity;
      final ratio = diff / oldItem.quantity;
      final basePrice = oldItem.price ?? _categoryDefaultPrice(oldItem.category);
      final portionPrice = (basePrice * ratio).round();

      if (oldItem.daysUntilExpiry < 0) {
        await _addWaste(portionPrice);
      } else {
        await _addSavings(portionPrice);
      }
    }

    await _repo.update(ingredient);
    await NotificationService.scheduleExpiryNotification(
      id: ingredient.id,
      name: ingredient.name,
      expiryDate: ingredient.expiryDate,
    );
    _load();
  }

  Future<void> delete(String id) async {
    Ingredient? target;
    try {
      target = state.firstWhere((e) => e.id == id);
    } catch (_) {}

    if (target != null) {
      final basePrice = target.price ?? _categoryDefaultPrice(target.category);
      if (target.daysUntilExpiry < 0) {
        await _addWaste(basePrice);
      } else {
        await _addSavings(basePrice);
      }
    }

    await _repo.delete(id);
    await NotificationService.cancelNotification(id);
    _load();
  }

  void reload() => _load();
}

final ingredientsProvider =
    StateNotifierProvider<IngredientNotifier, List<Ingredient>>((ref) {
  final repo = ref.watch(ingredientRepositoryProvider);
  return IngredientNotifier(repo);
});

// ── 派生プロバイダー ──

/// 賞味期限2日以内の食材
final urgentIngredientsProvider = Provider<List<Ingredient>>((ref) {
  return ref
      .watch(ingredientsProvider)
      .where((e) => e.daysUntilExpiry <= 2 && e.daysUntilExpiry >= 0)
      .toList();
});

/// カテゴリ別食材数
final ingredientCountProvider = Provider<int>((ref) {
  return ref.watch(ingredientsProvider).length;
});
