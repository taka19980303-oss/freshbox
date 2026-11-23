import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/ingredient.dart';
import '../../providers/shopping_provider.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _add(String name) {
    if (name.trim().isEmpty) return;

    // 名前からテンプレートを検索してメタデータを自動補完する（Shufu-Friendly）
    final matched = Ingredient.templates.firstWhere(
      (t) => t.name.toLowerCase() == name.trim().toLowerCase(),
      orElse: () => const IngredientTemplate(
        name: '',
        category: IngredientCategory.other,
        quantity: 1.0,
        unit: '個',
        expiryDays: 7,
        storageLocation: StorageLocation.refrigerator,
      ),
    );

    final item = Ingredient(
      id: _uuid.v4(),
      name: name.trim(),
      category: matched.name.isNotEmpty ? matched.category : IngredientCategory.other,
      quantity: matched.name.isNotEmpty ? matched.quantity : 1.0,
      unit: matched.name.isNotEmpty ? matched.unit : '個',
      expiryDate: DateTime.now(), // 買い物リスト時点ではダミー
      purchasedDate: null,
      storageLocation: matched.name.isNotEmpty ? matched.storageLocation : StorageLocation.refrigerator,
    );

    ref.read(shoppingListProvider.notifier).add(item);
    _textController.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final shoppingList = ref.watch(shoppingListProvider);

    // カテゴリ別グループ分け
    final Map<IngredientCategory, List<Ingredient>> grouped = {};
    for (final item in shoppingList) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final sortedCategories = grouped.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── ヘッダー ──
          SliverAppBar(
            expandedHeight: 140,
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
                            const Text('🛒', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 8),
                            Text(
                              '買い物リスト',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shoppingList.isEmpty ? '買うものはありません' : '残りの買い物: ${shoppingList.length}品',
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
                '買い物リスト',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            backgroundColor: AppColors.primary,
            actions: [
              if (shoppingList.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                  tooltip: 'リストを一括クリア',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('リストをクリア'),
                        content: const Text('買い物リストのすべてのアイテムを削除しますか？'),
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
                    if (confirm == true) {
                      ref.read(shoppingListProvider.notifier).clearAll();
                    }
                  },
                ),
            ],
          ),

          // ── 入力フォーム ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: RawAutocomplete<String>(
                textEditingController: _textController,
                focusNode: _focusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  final input = textEditingValue.text.toLowerCase();
                  return Ingredient.templates
                      .where((t) => t.name.toLowerCase().contains(input))
                      .map((t) => t.name);
                },
                onSelected: (String selection) {
                  _add(selection);
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onSubmitted: (val) {
                      _add(val);
                    },
                    decoration: InputDecoration(
                      hintText: '買いたい食材を入力... (例: キャベツ)',
                      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                      prefixIcon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                        onPressed: () => _add(controller.text),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 6.0,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      child: Container(
                        width: MediaQuery.of(context).size.width - (AppConstants.pagePadding * 2),
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            final tmpl = Ingredient.templates.firstWhere((t) => t.name == option);
                            return ListTile(
                              dense: true,
                              leading: Text(tmpl.category.emoji, style: const TextStyle(fontSize: 18)),
                              title: Text(
                                option,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              subtitle: Text(
                                '${tmpl.category.label} ・ 目安賞味期限: ${tmpl.expiryDays}日',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              trailing: const Icon(Icons.subdirectory_arrow_left, size: 14, color: AppColors.primary),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── 空の状態 ──
          if (shoppingList.isEmpty)
            const SliverToBoxAdapter(
              child: _EmptyShoppingState(),
            )
          else ...[
            // ── グループ別リスト表示 ──
            for (final cat in sortedCategories) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
                sliver: SliverToBoxAdapter(
                  child: _CategoryHeader(
                    category: cat,
                    count: grouped[cat]!.length,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = grouped[cat]![index];
                      return _ShoppingItemCard(item: item, index: index);
                    },
                    childCount: grouped[cat]!.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final IngredientCategory category;
  final int count;

  const _CategoryHeader({
    required this.category,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Row(
        children: [
          Text(
            category.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            category.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingItemCard extends ConsumerWidget {
  final Ingredient item;
  final int index;

  const _ShoppingItemCard({
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        ref.read(shoppingListProvider.notifier).delete(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${item.name}」を買い物リストから削除しました'),
            action: SnackBarAction(
              label: '元に戻す',
              onPressed: () {
                ref.read(shoppingListProvider.notifier).add(item);
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
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(height: 2),
            Text(
              '削除',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // ── チェックボックス ──
                GestureDetector(
                  onTap: () async {
                    await HapticFeedback.mediumImpact();
                    // 購入処理を実行（買い物リストから削除し、冷蔵庫へ自動追加）
                    await ref.read(shoppingListProvider.notifier).buy(item);

                    // 推奨賞味期限の日数を計算
                    final templates = Ingredient.templates;
                    final matched = templates.firstWhere(
                      (t) => t.name.toLowerCase() == item.name.toLowerCase(),
                      orElse: () => const IngredientTemplate(
                        name: '',
                        category: IngredientCategory.other,
                        quantity: 1.0,
                        unit: '個',
                        expiryDays: 7,
                        storageLocation: StorageLocation.refrigerator,
                      ),
                    );

                    final recommendedDate = DateTime.now().add(Duration(days: matched.expiryDays));
                    final dateStr = ExpiryUtils.formatDateJa(recommendedDate);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '「${item.name}」を購入完了！冷蔵庫へ追加しました。（賞味期限目安: $dateStr）',
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.primary,
                    ).animate(target: 0).scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
                  ),
                ),
                const SizedBox(width: 14),

                // ── 食材名 ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.storageLocation.label,
                              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 数量 ──
                Text(
                  '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}${item.unit}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: kIsWeb ? Duration.zero : (index * 40).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

class _EmptyShoppingState extends StatelessWidget {
  const _EmptyShoppingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_checkout,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '買い物リストは空です',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '冷蔵庫の食材の数量が0になると、自動でここに登録されます。上の入力欄から直接手動で追加することもできます。',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
