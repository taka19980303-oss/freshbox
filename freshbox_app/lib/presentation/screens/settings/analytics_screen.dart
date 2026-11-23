import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/ingredient.dart';
import '../../providers/ingredient_provider.dart';
import '../../../data/services/hive_service.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ingredients = ref.watch(ingredientsProvider);
    final isDark = theme.brightness == Brightness.dark;

    // カテゴリごとの数をカウント
    final Map<IngredientCategory, int> catCounts = {};
    for (final item in ingredients) {
      catCounts[item.category] = (catCounts[item.category] ?? 0) + 1;
    }

    final totalCount = ingredients.length;

    // ソートして比率の高い順にする
    final sortedCats = catCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Hive から累積節約額・廃棄額を取得
    final box = HiveService.ingredientBox;
    final savings = (box.get('__total_savings_amount', defaultValue: 0) as num).toInt();
    final waste = (box.get('__total_waste_amount', defaultValue: 0) as num).toInt();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── ヘッダー ──
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B6B3A), Color(0xFF0F3A20)],
                  ),
                ),
              ),
              title: Text(
                '冷蔵庫分析レポート',
                style: theme.textTheme.titleLarge?.copyWith(
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
                  if (totalCount == 0)
                    _buildEmptyState(context)
                  else ...[
                    // ── 栄養バランス円グラフ ──
                    Text(
                      '🥗 在庫の栄養カテゴリ分布',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildPieChartCard(context, sortedCats, totalCount, isDark),
                    const SizedBox(height: 24),

                    // ── AI健康アドバイス ──
                    Text(
                      '💡 AI栄養バランス評価',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildNutritionAdviceCard(context, sortedCats.first.key),
                    const SizedBox(height: 24),

                    // ── フードロス・家計ダッシュボード ──
                    Text(
                      '📉 フードロス節約効果',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildFoodWasteCard(context, isDark, savings, waste),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(
    BuildContext context,
    List<MapEntry<IngredientCategory, int>> sortedCats,
    int totalCount,
    bool isDark,
  ) {
    // スライス比率のリスト作成
    final List<double> chartRatios = [];
    final List<Color> chartColors = [];
    
    for (final entry in sortedCats) {
      chartRatios.add(entry.value / totalCount);
      chartColors.add(_getCategoryColor(entry.key));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // グラフ本体 (左側)
            SizedBox(
              width: 140,
              height: 140,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return CustomPaint(
                    painter: _PieChartPainter(
                      ratios: chartRatios,
                      colors: chartColors,
                      animationValue: value,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 24),
            // 凡例 (右側)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < sortedCats.length; i++) ...[
                    _buildLegendRow(
                      context,
                      sortedCats[i].key,
                      sortedCats[i].value,
                      totalCount,
                      chartColors[i],
                    ),
                    if (i < sortedCats.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(
    BuildContext context,
    IngredientCategory cat,
    int count,
    int total,
    Color color,
  ) {
    final ratioPct = ((count / total) * 100).toStringAsFixed(0);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          cat.emoji,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            cat.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$ratioPct% ($count品)',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildNutritionAdviceCard(BuildContext context, IngredientCategory primaryCategory) {
    String title = '';
    String description = '';
    String icon = '';

    switch (primaryCategory) {
      case IngredientCategory.vegetable:
        icon = '🥬';
        title = '健康的なベジタブル比率！';
        description = '現在、野菜類の比率が最も高い状態です。食物繊維やビタミン類が十分に蓄えられており、ヘルシーな食卓が作れます。ここに高タンパクな肉・魚を合わせることで、さらに栄養価が高まります。';
        break;
      case IngredientCategory.meat:
        icon = '🥩';
        title = 'タンパク源が非常に豊富！';
        description = '肉類の比率が高く、高タンパクな食材構成です。筋力維持や疲労回復に適しています。ビタミンの吸収を助けるために、緑黄色野菜（キャベツ、ピーマン等）も少し買い足して一緒に調理するのがおすすめです。';
        break;
      case IngredientCategory.fish:
        icon = '🐟';
        title = 'DHA・EPAが充実 of 健康構成！';
        description = '魚介類の比率が最も高く、良質な脂質とアミノ酸が豊富です。生活習慣病予防などに役立ちます。豆腐や味噌と組み合わせることで、すっきりヘルシーな和食メニューが簡単に作れます。';
        break;
      case IngredientCategory.dairy:
        icon = '🥛';
        title = 'カルシウム補給が完璧です！';
        description = '卵や乳製品が多く、カルシウムや必須アミノ酸がバランス良く揃っています。朝食の栄養補給はばっちり。繊維質の多い根菜類やきのこと組み合わせることで消化もよくなります。';
        break;
      default:
        icon = '🍱';
        title = '非常にバランスの良い構成！';
        description = '特定の食材に偏らず、多種多様なカテゴリが揃っています。この構成であれば、AIレシピ提案からも非常に豊富な種類のメニューを提案することができます。フードロスに気をつけて使い切りましょう。';
    }

    return Card(
      color: AppColors.primaryContainer.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodWasteCard(BuildContext context, bool isDark, int savings, int waste) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,###');
    
    final total = savings + waste;
    final double reductionRate = total > 0 ? (savings / total) : 1.0;
    final reductionPct = (reductionRate * 100).round();
    
    String message = '食材の消費・廃棄実績から家計節約度とロス削減率を自動計算します。';
    if (total > 0) {
      if (reductionPct >= 90) {
        message = '素晴らしい！目標の90%を超えています！';
      } else if (reductionPct >= 70) {
        message = '順調です！さらなるロス削減を目指しましょう！';
      } else {
        message = '期限前の消費を意識して、ロスを減らしていきましょう。';
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ロス削減率ゲージ
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '今月のフードロス削減率',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 削減率パーセント表示
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    total > 0 ? '$reductionPct%' : '-',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            // 節約家計簿
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.savings_outlined, color: AppColors.primary, size: 24),
                      const SizedBox(height: 6),
                      const Text('今月の推定節約額', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '¥${formatter.format(savings)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.divider),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.delete_sweep_outlined, color: AppColors.error, size: 24),
                      const SizedBox(height: 6),
                      const Text('廃棄（期限切れロス）', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '¥${formatter.format(waste)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 24),
        child: Column(
          children: [
            const Text('📊', style: TextStyle(fontSize: 54)),
            const SizedBox(height: 16),
            const Text(
              '分析レポート用のデータがありません',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              '冷蔵庫に食材が登録されると、カテゴリ別栄養比率やAIアドバイスがここに表示されるようになります。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(IngredientCategory category) {
    switch (category) {
      case IngredientCategory.meat:
        return const Color(0xFFE05C2A); // 赤橙
      case IngredientCategory.vegetable:
        return const Color(0xFF1B6B3A); // 緑
      case IngredientCategory.fish:
        return const Color(0xFF2B5FA6); // 藍
      case IngredientCategory.dairy:
        return const Color(0xFFE08020); // 橙
      case IngredientCategory.seasoning:
        return const Color(0xFF8E9390); // 灰
      case IngredientCategory.frozen:
        return const Color(0xFF00ACC1); // 青緑
      case IngredientCategory.other:
      default:
        return const Color(0xFF8D6E63); // 茶
    }
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> ratios;
  final List<Color> colors;
  final double animationValue;
  final bool isDark;

  _PieChartPainter({
    required this.ratios,
    required this.colors,
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    double startAngle = -math.pi / 2; // 真上から開始

    for (int i = 0; i < ratios.length; i++) {
      final sweepAngle = ratios[i] * 2 * math.pi * animationValue;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // ドーナツチャートにするために真ん中を白（ダークモード時はダーク表面色）でくり抜く
    final centerPaint = Paint()
      ..color = isDark ? AppColors.darkCard : Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 3.2,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark ||
        oldDelegate.ratios != ratios;
  }
}
