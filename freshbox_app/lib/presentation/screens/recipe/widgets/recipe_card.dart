import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final RecipeSuggestion recipe;
  final int index;
  final bool featured;
  final VoidCallback? onTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.index,
    this.featured = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ヘッダー（グラデーション） ──
            Container(
              height: featured ? 140 : 100,
              decoration: BoxDecoration(
                gradient: featured
                    ? AppColors.recipeCardGradient
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.tertiary.withOpacity(0.8),
                          AppColors.primary.withOpacity(0.6),
                        ],
                      ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  topRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Stack(
                children: [
                  // 装飾的な円
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: -10,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  // 料理アイコン
                  Center(
                    child: Text(
                      '🍳',
                      style: TextStyle(fontSize: featured ? 48 : 36),
                    ),
                  ),
                  // 難易度バッジ
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recipe.difficulty,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── コンテンツ ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (featured) ...[
                    const SizedBox(height: 6),
                    Text(
                      recipe.description,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),

                  // 調理時間・カロリー
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        recipe.cookingTime,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (recipe.caloriesEstimate != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.local_fire_department_outlined,
                            size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          recipe.caloriesEstimate!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 使用食材チップ
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...recipe.usedIngredients.map(
                        (ing) => _IngredientChip(
                            label: ing,
                            color: AppColors.primary,
                            bgColor: AppColors.primaryContainer),
                      ),
                    ],
                  ),

                  if (featured) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {},
                        child: const Text('今すぐ作る →'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 120).ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.15, end: 0, duration: 450.ms, curve: Curves.easeOut);
  }
}

class _IngredientChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _IngredientChip({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
