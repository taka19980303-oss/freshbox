import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/ingredient.dart';
import '../../providers/ingredient_provider.dart';
import '../add_ingredient/add_ingredient_screen.dart';

const _uuid = Uuid();

/// まとめて追加画面。
///
/// 買い物帰りに、よく買う食材テンプレートをタップで選んで一括登録する。
/// 数量と賞味期限はその場で微調整できる。手入力したい場合は
/// 食材追加画面へ遷移する。
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _BatchItem {
  Ingredient ingredient;
  final double step;
  _BatchItem(this.ingredient, this.step);
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  IngredientCategory? _categoryFilter;
  final List<_BatchItem> _selected = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<IngredientTemplate> get _filteredTemplates {
    return Ingredient.templates.where((t) {
      if (_categoryFilter != null && t.category != _categoryFilter) {
        return false;
      }
      if (_query.isNotEmpty && !t.name.contains(_query)) return false;
      return true;
    }).toList();
  }

  void _addTemplate(IngredientTemplate t) {
    setState(() {
      final idx = _selected.indexWhere(
        (e) => e.ingredient.name == t.name && e.ingredient.unit == t.unit,
      );
      if (idx >= 0) {
        final cur = _selected[idx].ingredient;
        _selected[idx].ingredient =
            cur.copyWith(quantity: cur.quantity + t.quantity);
      } else {
        _selected.add(_BatchItem(
          Ingredient(
            id: _uuid.v4(),
            name: t.name,
            category: t.category,
            quantity: t.quantity,
            unit: t.unit,
            expiryDate: DateTime.now().add(Duration(days: t.expiryDays)),
            purchasedDate: DateTime.now(),
            storageLocation: t.storageLocation,
            price: t.price,
          ),
          t.quantity,
        ));
      }
    });
  }

  void _changeQuantity(int i, double delta) {
    setState(() {
      final item = _selected[i];
      final next = item.ingredient.quantity + delta;
      if (next < item.step) return;
      item.ingredient = item.ingredient.copyWith(quantity: next);
    });
  }

  Future<void> _pickExpiry(int i) async {
    final current = _selected[i].ingredient.expiryDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selected[i].ingredient =
            _selected[i].ingredient.copyWith(expiryDate: picked);
      });
    }
  }

  Future<void> _saveAll() async {
    if (_selected.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    final notifier = ref.read(ingredientsProvider.notifier);
    for (final item in _selected) {
      await notifier.add(item.ingredient);
    }
    if (!mounted) return;
    final count = _selected.length;
    setState(() {
      _selected.clear();
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count品の食材を登録しました！'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String _formatQuantity(double q) {
    return q == q.roundToDouble() ? q.toInt().toString() : q.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = _filteredTemplates;
    final dateFormat = DateFormat('M/d');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'まとめて追加',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ── 検索 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '食材名で探す（例：豚、卵、牛乳）',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),

          // ── カテゴリ絞り込み ──
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('すべて'),
                    selected: _categoryFilter == null,
                    onSelected: (_) =>
                        setState(() => _categoryFilter = null),
                  ),
                ),
                for (final cat in IngredientCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${cat.emoji} ${cat.label}'),
                      selected: _categoryFilter == cat,
                      onSelected: (_) =>
                          setState(() => _categoryFilter = cat),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              children: [
                // ── 登録リスト ──
                if (_selected.isNotEmpty) ...[
                  Text(
                    '登録リスト（${_selected.length}品）',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _selected.length; i++)
                    _buildSelectedRow(i, dateFormat),
                  const SizedBox(height: 24),
                ],

                // ── テンプレート一覧 ──
                Text(
                  'よく買う食材',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'タップで登録リストに追加。数量と期限はあとから直せます。',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (templates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        '見つかりませんでした。下の手入力から追加できます。',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  for (final t in templates) _buildTemplateRow(t),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddIngredientScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('リストにない食材を手入力で追加'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── 登録ボタン ──
          if (_selected.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveAll,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      '${_selected.length}品をまとめて登録',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemplateRow(IngredientTemplate t) {
    final inList =
        _selected.any((e) => e.ingredient.name == t.name && e.ingredient.unit == t.unit);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(t.category.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(t.name),
        subtitle: Text(
          '${_formatQuantity(t.quantity)}${t.unit} ・ 期限の目安 ${t.expiryDays}日 ・ ${t.storageLocation.label}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(
            inList ? Icons.check_circle : Icons.add_circle,
            color: inList ? AppColors.primary : AppColors.primaryLight,
            size: 30,
          ),
          onPressed: () => _addTemplate(t),
        ),
        onTap: () => _addTemplate(t),
      ),
    );
  }

  Widget _buildSelectedRow(int i, DateFormat dateFormat) {
    final item = _selected[i];
    final ing = item.ingredient;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryContainer),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(ing.category.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ing.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => _pickExpiry(i),
                  child: Text(
                    '期限 ${dateFormat.format(ing.expiryDate)} まで（タップで変更）',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _changeQuantity(i, -item.step),
          ),
          Text(
            '${_formatQuantity(ing.quantity)}${ing.unit}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _changeQuantity(i, item.step),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => setState(() => _selected.removeAt(i)),
          ),
        ],
      ),
    );
  }
}
