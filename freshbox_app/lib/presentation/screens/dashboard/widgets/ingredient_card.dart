import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/ingredient.dart';
import '../../../providers/ingredient_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../../screens/add_ingredient/add_ingredient_screen.dart';
import 'expiry_badge.dart';

const _uuid = Uuid();

class IngredientCard extends ConsumerWidget {
  final Ingredient ingredient;
  final int index;

  const IngredientCard({
    super.key,
    required this.ingredient,
    required this.index,
  });

  Color get _leftBorderColor {
    final days = ingredient.daysUntilExpiry;
    if (days < 0) return AppColors.expiryExpired;
    if (days <= 2) return AppColors.expiryUrgent;
    if (days <= 4) return AppColors.expiryWarning;
    return AppColors.expiryFresh;
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('食材を削除'),
        content: Text('「${ingredient.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(ingredientsProvider.notifier).delete(ingredient.id);
    }
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddIngredientScreen(editTarget: ingredient),
      ),
    );
  }

  Future<void> _decreaseQuantity(BuildContext context, WidgetRef ref) async {
    await HapticFeedback.lightImpact();
    final double step = (ingredient.unit == 'g' || ingredient.unit == 'ml') ? 50 : 1;
    final newQty = ingredient.quantity - step;

    if (newQty <= 0) {
      // 0になったら自動で買い物リストへ移動
      await ref.read(ingredientsProvider.notifier).delete(ingredient.id);
      await ref.read(shoppingListProvider.notifier).add(
        ingredient.copyWith(
          id: _uuid.v4(),
          quantity: ingredient.quantity, // 元の基準数をセット
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${ingredient.name}」を使い切りました。買い物リストへ追加しました！'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      await ref.read(ingredientsProvider.notifier).update(
        ingredient.copyWith(quantity: newQty),
      );
    }
  }

  Future<void> _increaseQuantity(BuildContext context, WidgetRef ref) async {
    await HapticFeedback.lightImpact();
    final double step = (ingredient.unit == 'g' || ingredient.unit == 'ml') ? 50 : 1;
    await ref.read(ingredientsProvider.notifier).update(
      ingredient.copyWith(quantity: ingredient.quantity + step),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final days = ingredient.daysUntilExpiry;

    return Dismissible(
      key: ValueKey(ingredient.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('食材を削除'),
            content: Text('「${ingredient.name}」を削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('削除'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) {
        ref.read(ingredientsProvider.notifier).delete(ingredient.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${ingredient.name}」を削除しました'),
            action: SnackBarAction(
              label: '元に戻す',
              onPressed: () {
                ref.read(ingredientsProvider.notifier).add(ingredient);
              },
            ),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              '削除',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        child: InkWell(
          onTap: () => _openEdit(context),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border(
                left: BorderSide(color: _leftBorderColor, width: 4),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      ingredient.category.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ingredient.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${ingredient.quantity % 1 == 0 ? ingredient.quantity.toInt() : ingredient.quantity}${ingredient.unit}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ＋ / － の数量調整ボタン
                          GestureDetector(
                            onTap: () => _decreaseQuantity(context, ref),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.08),
                              ),
                              child: const Icon(
                                Icons.remove,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _increaseQuantity(context, ref),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.08),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ingredient.category.label,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  ingredient.storageLocation.emoji,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  ingredient.storageLocation.label,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                          if (ingredient.memo != null) ...
                          [
                            const SizedBox(width: 6),
                            Icon(
                              Icons.sticky_note_2_outlined,
                              size: 13,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ExpiryDaysDisplay(days: days),
                    const SizedBox(height: 6),
                    ExpiryBadge(daysUntilExpiry: days, compact: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}
