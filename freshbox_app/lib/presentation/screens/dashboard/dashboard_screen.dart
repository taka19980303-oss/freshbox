import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/ingredient.dart';
import '../../providers/ingredient_provider.dart';
import '../../screens/add_ingredient/add_ingredient_screen.dart';
import 'widgets/ingredient_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedStorage = 'すべて';
  String _selectedCategory = 'すべて';

  List<String> _categories(List<Ingredient> ingredients) {
    var list = ingredients;
    if (_selectedStorage != 'すべて') {
      list = list.where((e) => e.storageLocation.label == _selectedStorage).toList();
    }
    final cats = list.map((e) => e.category.label).toSet().toList();
    return ['すべて', ...cats];
  }

  List<Ingredient> _filtered(List<Ingredient> ingredients) {
    var list = ingredients;
    if (_selectedStorage != 'すべて') {
      list = list.where((e) => e.storageLocation.label == _selectedStorage).toList();
    }
    if (_selectedCategory != 'すべて') {
      list = list.where((e) => e.category.label == _selectedCategory).toList();
    }
    return list;
  }

  void _openAddScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddIngredientScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = ref.watch(ingredientsProvider);
    final urgent = ref.watch(urgentIngredientsProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('M月d日（E）', 'ja').format(now);
    final filtered = _filtered(ingredients);
    final categories = _categories(ingredients);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.read(ingredientsProvider.notifier).reload();
        },
        child: CustomScrollView(
          slivers: [
            // ── グラデーションヘッダー ──
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.headerGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.pagePadding,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Text('🧊', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 8),
                              Text(
                                'FreshBox',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ingredients.isEmpty
                                ? '食材を追加してみましょう 🍽'
                                : '食材が合計${ingredients.length}品あります 🍽',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'FreshBox',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              backgroundColor: AppColors.primary,
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 期限警告バナー ──
                    if (urgent.isNotEmpty)
                      _UrgentBanner(ingredients: urgent),

                    if (urgent.isNotEmpty) const SizedBox(height: 20),

                    // ── サマリー ──
                    _SummaryRow(ingredients: ingredients),

                    const SizedBox(height: 24),

                    // ── 保存場所・カテゴリフィルター ──
                    if (ingredients.isNotEmpty) ...
                    [
                      Text(
                        '保存場所から探す',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _StorageFilter(
                        selected: _selectedStorage,
                        onSelected: (loc) {
                          setState(() {
                            _selectedStorage = loc;
                            _selectedCategory = 'すべて';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'カテゴリで絞り込み',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _CategoryFilter(
                        categories: categories,
                        selected: _selectedCategory,
                        onSelected: (cat) =>
                            setState(() => _selectedCategory = cat),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── 食材リスト ──
            if (ingredients.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyState(onAdd: _openAddScreen),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.pagePadding,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: IngredientCard(
                        ingredient: filtered[i],
                        index: i,
                      ),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddScreen,
        icon: const Icon(Icons.add),
        label: const Text('食材を追加'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ).animate().scale(delay: kIsWeb ? Duration.zero : 400.ms, duration: 300.ms),
    );
  }
}

// ── 期限警告バナー ──
class _UrgentBanner extends StatelessWidget {
  final List<Ingredient> ingredients;
  const _UrgentBanner({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日・明日中に使いたい食材',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  ingredients.map((e) => e.name).join('、'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0, duration: 350.ms);
  }
}

// ── サマリー行 ──
class _SummaryRow extends StatelessWidget {
  final List<Ingredient> ingredients;
  const _SummaryRow({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    final urgent =
        ingredients.where((e) => e.daysUntilExpiry <= 2 && e.daysUntilExpiry >= 0).length;
    final expired = ingredients.where((e) => e.daysUntilExpiry < 0).length;
    final fresh = ingredients.where((e) => e.daysUntilExpiry > 4).length;

    return Row(
      children: [
        _SummaryCard(label: '合計', value: '${ingredients.length}品', icon: '🧊', color: AppColors.tertiary, index: 0),
        const SizedBox(width: 8),
        _SummaryCard(label: '要注意', value: '$urgent品', icon: '🔥', color: AppColors.expiryUrgent, index: 1),
        const SizedBox(width: 8),
        _SummaryCard(label: '余裕あり', value: '$fresh品', icon: '✅', color: AppColors.expiryFresh, index: 2),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;
  final int index;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    )
        .animate(delay: kIsWeb ? Duration.zero : (index * 80).ms)
        .fadeIn(duration: 350.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 300.ms,
        );
  }
}

// ── カテゴリフィルター ──
class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 保存場所フィルター ──
class _StorageFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _StorageFilter({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = ['すべて', ...StorageLocation.values.map((e) => e.label)];
    final emojis = ['', ...StorageLocation.values.map((e) => e.emoji)];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final opt = options[i];
          final emoji = emojis[i];
          final label = emoji.isNotEmpty ? '$emoji $opt' : opt;
          final isSelected = opt == selected;

          return GestureDetector(
            onTap: () => onSelected(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.secondary : AppColors.divider,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 空状態 ──
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          const Text('🧊', style: TextStyle(fontSize: 64))
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            '冷蔵庫が空です',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '右下の＋ボタンから\n食材を追加してみましょう',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('最初の食材を追加する'),
          ),
        ],
      ),
    );
  }
}
