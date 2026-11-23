import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/ingredient.dart';
import '../../../data/models/meal_planner_model.dart';
import '../../../data/models/recipe.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/shopping_provider.dart';
import 'widgets/recipe_card.dart';
import 'widgets/suggestion_banner.dart';

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key});

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 献立計画関連の状態
  List<MealPlanDay>? _activePlan;
  bool _isLoadingPlan = false;
  String _loadingMessage = '';
  final Set<String> _addedToShopping = {};
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 献立生成（ローカルルールエンジンで即時生成する）
  Future<void> _generateMealPlan(List<Ingredient> inventory) async {
    setState(() {
      _isLoadingPlan = true;
      _loadingMessage = '在庫から献立を組み立てています... 🍱';
    });
    await HapticFeedback.mediumImpact();

    final plan = MealPlannerEngine.generate3DayPlan(inventory);
    setState(() {
      _activePlan = plan;
      _isLoadingPlan = false;
      _addedToShopping.clear();
    });
    await HapticFeedback.mediumImpact();
  }

  Future<void> _addMissingIngredient(MealIngredientReq req) async {
    await HapticFeedback.mediumImpact();
    
    final missingItem = Ingredient(
      id: _uuid.v4(),
      name: req.name,
      category: req.category,
      quantity: req.quantity,
      unit: req.unit,
      expiryDate: DateTime.now(), // ダミー
      storageLocation: StorageLocation.refrigerator,
    );

    await ref.read(shoppingListProvider.notifier).add(missingItem);

    setState(() {
      _addedToShopping.add(req.name);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${req.name}」を買い物リストに追加しました 🛒'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ingredients = ref.watch(ingredientsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? AppColors.darkCard : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        toolbarHeight: 0, // SliverAppBar/TabBarを使用するため高さを0に
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: appBarColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: isDark ? AppColors.primaryLight : Colors.white,
              labelColor: isDark ? AppColors.primaryLight : Colors.white,
              unselectedLabelColor: isDark ? AppColors.darkTextTertiary : Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: const [
                Tab(text: '今日のレシピ提案'),
                Tab(text: '3日間の献立'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── タブ1: 今日のレシピ提案 ──
          _buildTodayRecipesTab(context, theme, ingredients),

          // ── タブ2: 3日間の献立 ──
          _buildMealPlannerTab(context, theme, ingredients),
        ],
      ),
    );
  }

  Widget _buildTodayRecipesTab(BuildContext context, ThemeData theme, List<Ingredient> ingredients) {
    final urgentIngredients = ref.watch(urgentIngredientsProvider);
    final suggestionsAsync = ref.watch(recipeSuggestionsProvider);

    return suggestionsAsync.when(
      data: (recipes) {
        if (ingredients.isEmpty) {
          return _buildEmptyRefrigeratorState(context);
        }
        if (recipes.isEmpty) {
          return _buildNoRecipesState(context);
        }

        final firstMissing = recipes
            .where((r) => r.missingIngredients.isNotEmpty)
            .firstOrNull;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 使用予定食材 ──
                      if (urgentIngredients.isNotEmpty) ...[
                        _UsedIngredientsRow(ingredients: urgentIngredients),
                        const SizedBox(height: 20),
                      ],

                      // ── 買い足し提案バナー ──
                      if (firstMissing != null &&
                          firstMissing.missingIngredients.isNotEmpty) ...[
                        SuggestionBanner(
                          missingIngredient: firstMissing.missingIngredients.first,
                          recipeName: firstMissing.title,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── おすすめレシピ (featured) ──
                      Text(
                        '✨ 今日のおすすめ',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      RecipeCard(
                        recipe: recipes.first,
                        index: 0,
                        featured: true,
                      ),

                      if (recipes.length > 1) ...[
                        const SizedBox(height: 24),
                        Text(
                          'その他のレシピ',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),

              // ── レシピ一覧（featured以外） ──
              if (recipes.length > 1)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.pagePadding,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final recipe = recipes.skip(1).toList()[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: RecipeCard(
                            recipe: recipe,
                            index: i + 1,
                          ),
                        );
                      },
                      childCount: recipes.length - 1,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              ref.invalidate(recipeSuggestionsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('レシピを更新しました'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('レシピを更新'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ).animate().scale(delay: 500.ms, duration: 300.ms),
        );
      },
      loading: () => _buildLoadingState(context),
      error: (err, stack) => _buildErrorState(context, err),
    );
  }

  Widget _buildMealPlannerTab(BuildContext context, ThemeData theme, List<Ingredient> ingredients) {
    if (ingredients.isEmpty) {
      return _buildEmptyRefrigeratorState(context);
    }

    if (_isLoadingPlan) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _loadingMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate(key: ValueKey(_loadingMessage)).fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      );
    }

    if (_activePlan == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('📅', style: TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '3日間の献立作成',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '冷蔵庫にある消費期限の短い食材を優先的に使い切り、無駄なく健康的な3日間の夕食献立メニューを自動作成します。',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _generateMealPlan(ingredients),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('3日間の献立を作成する'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📅 提案された3日間の献立',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() => _activePlan = null);
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('リセット'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 各日のカード表示
        for (final dayPlan in _activePlan!) ...[
          _buildDayPlanCard(context, theme, dayPlan),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDayPlanCard(BuildContext context, ThemeData theme, MealPlanDay dayPlan) {
    final recipe = dayPlan.recipe;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: dayPlan.day == 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Day ${dayPlan.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recipe.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0, left: 52),
          child: Wrap(
            spacing: 8,
            children: [
              Text('🔥 ${recipe.calories}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('💪 たんぱく質 ${recipe.protein}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('🍱 ${recipe.category}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // ── 使用・不足食材 ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 使用する冷蔵庫内食材
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✅ 冷蔵庫から使う', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 6),
                    if (dayPlan.usedFromInventory.isEmpty)
                      const Text('該当なし', style: TextStyle(fontSize: 12, color: AppColors.textTertiary))
                    else
                      for (final item in dayPlan.usedFromInventory)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text('・${item.name} (${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}${item.unit})', style: const TextStyle(fontSize: 12)),
                        ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              // 不足食材 (買い物リスト追加可)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🛒 足りない食材 (買い足し)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary)),
                    const SizedBox(height: 6),
                    if (dayPlan.missingToBuy.isEmpty)
                      const Text('不足なし！バッチリです', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold))
                    else
                      for (final req in dayPlan.missingToBuy)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '・${req.name}', 
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: _addedToShopping.contains(req.name)
                                    ? null
                                    : () => _addMissingIngredient(req),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _addedToShopping.contains(req.name)
                                        ? AppColors.primaryContainer
                                        : AppColors.secondary.withOpacity(0.08),
                                  ),
                                  child: Icon(
                                    _addedToShopping.contains(req.name)
                                        ? Icons.check
                                        : Icons.add,
                                    size: 14,
                                    color: _addedToShopping.contains(req.name)
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // ── 作り方手順 ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🍳 簡単な作り方の手順', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              for (int stepIdx = 0; stepIdx < recipe.instructions.length; stepIdx++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: AppColors.surfaceVariant,
                        child: Text('${stepIdx + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recipe.instructions[stepIdx],
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'レシピを探しています...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            '冷蔵庫の食材を組み合わせて最適なメニューを探しています',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'レシピの取得に失敗しました',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(recipeSuggestionsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('再試行する'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRefrigeratorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍳', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              '冷蔵庫が空っぽです',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'レシピを提案するには、まず冷蔵庫に食材を追加してください。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              '「冷蔵庫」タブの右下の「＋」ボタンから追加するか、\n「まとめて追加」タブから一括登録もできます。',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecipesState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'レシピが見つかりませんでした',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'お持ちの食材では提案できるレシピがありませんでした。他の食材を追加してみてください。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(recipeSuggestionsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('再提案をリクエスト'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 使用予定食材タグ行 ──
class _UsedIngredientsRow extends StatelessWidget {
  final List<Ingredient> ingredients;
  const _UsedIngredientsRow({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '使用期限の近い食材（優先使用）',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: ingredients
              .map(
                (ing) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ing.category.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ing.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ing.daysUntilExpiry < 0
                            ? '期限切れ'
                            : ing.daysUntilExpiry == 0
                                ? '今日'
                                : '残り${ing.daysUntilExpiry}日',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
