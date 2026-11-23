import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/ingredient.dart';
import '../../providers/ingredient_provider.dart';
import '../../../data/services/hive_service.dart';
import 'widgets/category_selector.dart';

const _uuid = Uuid();

class AddIngredientScreen extends ConsumerStatefulWidget {
  /// 編集時は既存の食材を渡す。nullなら新規追加
  final Ingredient? editTarget;

  const AddIngredientScreen({super.key, this.editTarget});

  @override
  ConsumerState<AddIngredientScreen> createState() =>
      _AddIngredientScreenState();
}

class _AddIngredientScreenState extends ConsumerState<AddIngredientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _memoController = TextEditingController();
  final _priceController = TextEditingController();
  final _nameFocusNode = FocusNode();

  List<Map<String, dynamic>> _history = [];

  IngredientCategory? _selectedCategory;
  StorageLocation _selectedStorageLocation = StorageLocation.refrigerator;
  String _selectedUnit = 'g';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;

  bool get _isEditing => widget.editTarget != null;

  static const List<String> _units = [
    'g', 'kg', 'ml', 'L',
    '個', 'パック', '本', '束',
    '枚', '切れ', '丁', '缶',
    '袋', '食',
  ];

  @override
  void initState() {
    super.initState();
    _history = HiveService.getHistory();
    if (_isEditing) {
      final t = widget.editTarget!;
      _nameController.text = t.name;
      _quantityController.text =
          t.quantity % 1 == 0 ? t.quantity.toInt().toString() : t.quantity.toString();
      _memoController.text = t.memo ?? '';
      _priceController.text = t.price != null ? t.price.toString() : '';
      _selectedCategory = t.category;
      _selectedStorageLocation = t.storageLocation;
      _selectedUnit = t.unit;
      _expiryDate = t.expiryDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _memoController.dispose();
    _priceController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      locale: const Locale('ja'),
      helpText: '賞味期限を選択',
      confirmText: '決定',
      cancelText: 'キャンセル',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _save({bool addAnother = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('カテゴリを選択してください'),
          backgroundColor: AppColors.secondary,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final ingredient = Ingredient(
      id: _isEditing ? widget.editTarget!.id : _uuid.v4(),
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      quantity: double.tryParse(_quantityController.text) ?? 1.0,
      unit: _selectedUnit,
      expiryDate: _expiryDate,
      purchasedDate: _isEditing
          ? widget.editTarget!.purchasedDate
          : DateTime.now(),
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      storageLocation: _selectedStorageLocation,
      price: int.tryParse(_priceController.text.trim()),
    );

    final notifier = ref.read(ingredientsProvider.notifier);
    if (_isEditing) {
      await notifier.update(ingredient);
    } else {
      await notifier.add(ingredient);
    }

    if (!mounted) return;

    if (addAnother && !_isEditing) {
      // 連続追加: フォームを初期化して同じ画面にとどまる。
      // カテゴリと保存場所は引き継ぐ（同じ売り場の食材を続けて入れやすいように）。
      setState(() {
        _isSaving = false;
        _nameController.clear();
        _quantityController.clear();
        _memoController.clear();
        _priceController.clear();
        _expiryDate = DateTime.now().add(const Duration(days: 7));
      });
      _nameFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${ingredient.name}」を追加しました。続けて入力できます。'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        DateFormat('yyyy年M月d日（E）', 'ja').format(_expiryDate);
    final daysLeft = _expiryDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          _isEditing ? '食材を編集' : '食材を追加',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          children: [
            if (!_isEditing && _history.isNotEmpty) ...[
              _buildHistorySuggestions(),
              const SizedBox(height: 20),
            ],

            // ── カテゴリ選択 ──
            _SectionLabel(label: 'カテゴリ *'),
            const SizedBox(height: 10),
            CategorySelector(
              selected: _selectedCategory,
              onSelected: (cat) => setState(() => _selectedCategory = cat),
            ),

            if (!_isEditing && _selectedCategory != null) ...[
              const SizedBox(height: 12),
              _buildQuickSuggestions(_selectedCategory!),
            ],

            const SizedBox(height: 20),

            // ── 保存場所 ──
            _SectionLabel(label: '保存場所 *'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: StorageLocation.values.map((loc) {
                final isSelected = _selectedStorageLocation == loc;
                return ChoiceChip(
                  label: Text('${loc.emoji} ${loc.label}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStorageLocation = loc);
                    }
                  },
                  selectedColor: AppColors.primaryContainer,
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── 食材名 ──
            _SectionLabel(label: '食材名 *'),
            const SizedBox(height: 8),
            RawAutocomplete<String>(
              textEditingController: _nameController,
              focusNode: _nameFocusNode,
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
                IngredientTemplate? selectedTmpl;
                for (final t in Ingredient.templates) {
                  if (t.name == selection) {
                    selectedTmpl = t;
                    break;
                  }
                }
                if (selectedTmpl != null) {
                  setState(() {
                    _selectedCategory = selectedTmpl!.category;
                    _quantityController.text = selectedTmpl!.quantity % 1 == 0
                        ? selectedTmpl!.quantity.toInt().toString()
                        : selectedTmpl!.quantity.toString();
                    _selectedUnit = selectedTmpl!.unit;
                    _expiryDate = DateTime.now().add(Duration(days: selectedTmpl!.expiryDays));
                    _selectedStorageLocation = selectedTmpl!.storageLocation;
                    _priceController.text = selectedTmpl!.price.toString();
                  });
                }
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onFieldSubmitted: (v) => onFieldSubmitted(),
                  decoration: _inputDecoration(
                    hint: '例: 豚肩ロース（ブロック）',
                    icon: Icons.restaurant_menu_outlined,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '食材名を入力してください';
                    if (v.trim().length > 30) return '30文字以内で入力してください';
                    return null;
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 6.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    color: Colors.white,
                    child: Container(
                      width: MediaQuery.of(context).size.width - (AppConstants.pagePadding * 2),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          IngredientTemplate? tmpl;
                          for (final t in Ingredient.templates) {
                            if (t.name == option) {
                              tmpl = t;
                              break;
                            }
                          }
                          return ListTile(
                            dense: true,
                            title: Text(
                              option,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: tmpl != null
                                ? Text(
                                    '${tmpl.category.label} ・ ${tmpl.storageLocation.label} (目安: ${tmpl.expiryDays}日)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                : null,
                            trailing: const Icon(
                              Icons.arrow_outward,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ── 数量 + 単位 ──
            _SectionLabel(label: '数量 *'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: _inputDecoration(
                      hint: '例: 300',
                      icon: Icons.scale_outlined,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '数量を入力してください';
                      if (double.tryParse(v) == null) return '数値を入力してください';
                      if (double.parse(v) <= 0) return '0より大きい値を入力してください';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: _inputDecoration(
                      hint: '単位',
                      icon: Icons.straighten_outlined,
                    ),
                    items: _units
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedUnit = v);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── 価格（任意） ──
            _SectionLabel(label: '価格（任意）'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              decoration: _inputDecoration(
                hint: '例: 298',
                icon: Icons.currency_yen_outlined,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final price = int.tryParse(v);
                  if (price == null) return '数値を入力してください';
                  if (price < 0) return '0以上の値を入力してください';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ── 賞味期限 ──
            _SectionLabel(label: '賞味期限 *'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickExpiryDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dateStr,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: daysLeft <= 2
                            ? AppColors.secondaryContainer
                            : daysLeft <= 4
                                ? AppColors.warningContainer
                                : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        daysLeft < 0
                            ? '期限切れ'
                            : daysLeft == 0
                                ? '今日'
                                : '残り$daysLeft日',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: daysLeft <= 2
                              ? AppColors.secondary
                              : daysLeft <= 4
                                  ? AppColors.warning
                                  : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickDateChip(label: '＋3日', days: 3),
                _buildQuickDateChip(label: '＋1週間', days: 7),
                _buildQuickDateChip(label: '＋2週間', days: 14),
                _buildQuickDateChip(label: '＋1ヶ月', days: 30),
              ],
            ),

            const SizedBox(height: 20),

            // ── メモ (任意) ──
            _SectionLabel(label: 'メモ（任意）'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _memoController,
              decoration: _inputDecoration(
                hint: '例: 薄切り済み、冷凍保存可',
                icon: Icons.edit_note_outlined,
              ),
              maxLines: 2,
              maxLength: 100,
            ),

            const SizedBox(height: 32),

            // ── 保存ボタン ──
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_isEditing ? Icons.save_outlined : Icons.add),
                label: Text(
                  _isEditing ? '変更を保存' : '食材を追加する',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // ── 連続追加ボタン（新規追加時のみ） ──
            if (!_isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => _save(addAnother: true),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('保存して続けて追加'),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateChip({required String label, required int days}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 36),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _expiryDate = DateTime.now().add(Duration(days: days));
            });
          },
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  Widget _buildQuickSuggestions(IngredientCategory category) {
    final templates = _categoryTemplates[category] ?? [];
    if (templates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_outlined, size: 16, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              'クイック選択（タップで自動入力）',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final t = templates[i];
              return ActionChip(
                backgroundColor: AppColors.card,
                surfaceTintColor: Colors.transparent,
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                label: Text(
                  '${t.name} (${t.quantity % 1 == 0 ? t.quantity.toInt() : t.quantity}${t.unit})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _nameController.text = t.name;
                    _quantityController.text =
                        t.quantity % 1 == 0 ? t.quantity.toInt().toString() : t.quantity.toString();
                    _selectedUnit = t.unit;
                    _expiryDate = DateTime.now().add(Duration(days: t.expiryDays));
                    _selectedStorageLocation = t.storageLocation;
                    _priceController.text = t.price.toString();
                  });
                },
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildHistorySuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'よく使う食材（タップで自動入力）',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _history.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final h = _history[i];
              final name = h['name'] as String;
              final categoryLabel = h['category'] as String;
              final qty = h['quantity'] as double;
              final unit = h['unit'] as String;
              final expiryDays = h['expiryDays'] as int;
              final locLabel = h['storageLocation'] as String;
              final price = h['price'] as int?;

              final cat = IngredientCategory.fromLabel(categoryLabel);

              return ActionChip(
                backgroundColor: AppColors.card,
                surfaceTintColor: Colors.transparent,
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                label: Text(
                  '${cat.emoji} $name',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _nameController.text = name;
                    _quantityController.text = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
                    _selectedUnit = unit;
                    _expiryDate = DateTime.now().add(Duration(days: expiryDays));
                    _selectedStorageLocation = StorageLocation.fromLabel(locLabel);
                    _selectedCategory = cat;
                    _priceController.text = price != null ? price.toString() : '';
                  });
                },
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _IngredientTemplate {
  final String name;
  final double quantity;
  final String unit;
  final int expiryDays;
  final StorageLocation storageLocation;
  final int price;

  const _IngredientTemplate({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.expiryDays,
    required this.storageLocation,
    this.price = 250,
  });
}

final Map<IngredientCategory, List<_IngredientTemplate>> _categoryTemplates = {
  IngredientCategory.meat: const [
    _IngredientTemplate(name: '豚バラ肉', quantity: 200, unit: 'g', expiryDays: 3, storageLocation: StorageLocation.refrigerator, price: 398),
    _IngredientTemplate(name: '鶏もも肉', quantity: 250, unit: 'g', expiryDays: 3, storageLocation: StorageLocation.refrigerator, price: 298),
    _IngredientTemplate(name: '牛細切れ肉', quantity: 200, unit: 'g', expiryDays: 2, storageLocation: StorageLocation.refrigerator, price: 580),
    _IngredientTemplate(name: '合い挽き肉', quantity: 250, unit: 'g', expiryDays: 2, storageLocation: StorageLocation.refrigerator, price: 350),
    _IngredientTemplate(name: 'ウインナー', quantity: 1, unit: '袋', expiryDays: 10, storageLocation: StorageLocation.refrigerator, price: 298),
    _IngredientTemplate(name: '豚ヒレ肉', quantity: 250, unit: 'g', expiryDays: 3, storageLocation: StorageLocation.refrigerator, price: 498),
    _IngredientTemplate(name: '牛ステーキ肉', quantity: 180, unit: 'g', expiryDays: 2, storageLocation: StorageLocation.refrigerator, price: 980),
    _IngredientTemplate(name: '鶏レバー', quantity: 200, unit: 'g', expiryDays: 1, storageLocation: StorageLocation.refrigerator, price: 198),
    _IngredientTemplate(name: '豚ロース薄切り', quantity: 200, unit: 'g', expiryDays: 3, storageLocation: StorageLocation.refrigerator, price: 350),
    _IngredientTemplate(name: '鶏むね肉', quantity: 300, unit: 'g', expiryDays: 3, storageLocation: StorageLocation.refrigerator, price: 198),
    _IngredientTemplate(name: 'ささみ', quantity: 4, unit: '本', expiryDays: 3, storageLocation: StorageLocation.refrigerator, price: 228),
    _IngredientTemplate(name: '牛すじ肉', quantity: 300, unit: 'g', expiryDays: 5, storageLocation: StorageLocation.refrigerator, price: 480),
    _IngredientTemplate(name: '豚肩ロース', quantity: 300, unit: 'g', expiryDays: 4, storageLocation: StorageLocation.refrigerator, price: 450),
    _IngredientTemplate(name: 'ベーコン', quantity: 1, unit: 'パック', expiryDays: 7, storageLocation: StorageLocation.refrigerator, price: 198),
    _IngredientTemplate(name: 'ハム', quantity: 1, unit: 'パック', expiryDays: 7, storageLocation: StorageLocation.refrigerator, price: 198),
    _IngredientTemplate(name: '生ハム', quantity: 1, unit: 'パック', expiryDays: 10, storageLocation: StorageLocation.refrigerator, price: 298),
    _IngredientTemplate(name: '鶏手羽元', quantity: 8, unit: '本', expiryDays: 3, storageLocation: StorageLocation.refrigerator, price: 398),
    _IngredientTemplate(name: '豚小間切れ肉', quantity: 250, unit: 'g', expiryDays: 3, storageLocation: StorageLocation.refrigerator, price: 298),
    _IngredientTemplate(name: 'シャウエッセン', quantity: 1, unit: '袋', expiryDays: 10, storageLocation: StorageLocation.refrigerator, price: 398),
  ],
  IngredientCategory.vegetable: const [
    _IngredientTemplate(name: 'キャベツ', quantity: 1, unit: '玉', expiryDays: 10, storageLocation: StorageLocation.refrigerator, price: 198),
    _IngredientTemplate(name: 'たまねぎ', quantity: 3, unit: '個', expiryDays: 30, storageLocation: StorageLocation.pantry, price: 198),
    _IngredientTemplate(name: 'にんじん', quantity: 2, unit: '本', expiryDays: 14, storageLocation: StorageLocation.pantry, price: 158),
    _IngredientTemplate(name: 'じゃがいも', quantity: 4, unit: '個', expiryDays: 30, storageLocation: StorageLocation.pantry, price: 198),
    _IngredientTemplate(name: '白菜', quantity: 0.25, unit: '個', expiryDays: 7, storageLocation: StorageLocation.refrigerator, price: 158),
    _IngredientTemplate(name: 'レモン', quantity: 3, unit: '個', expiryDays: 14, storageLocation: StorageLocation.refrigerator, price: 298),
    _IngredientTemplate(name: '長ネギ', quantity: 1, unit: '本', expiryDays: 10, storageLocation: StorageLocation.refrigerator, price: 128),
    _IngredientTemplate(name: 'アボカド', quantity: 1, unit: '個', expiryDays: 6, storageLocation: StorageLocation.refrigerator, price: 150),
    _IngredientTemplate(name: 'ミニトマト', quantity: 1, unit: 'パック', expiryDays: 7, storageLocation: StorageLocation.refrigerator, price: 248),
    _IngredientTemplate(name: 'レタス', quantity: 1, unit: '個', expiryDays: 5, storageLocation: StorageLocation.refrigerator, price: 198),
    _IngredientTemplate(name: 'ほうれん草', quantity: 1, unit: '袋', expiryDays: 4, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'しいたけ', quantity: 1, unit: 'パック', expiryDays: 6, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'ブロッコリー', quantity: 1, unit: '個', expiryDays: 7, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'トマト', quantity: 2, unit: '個', expiryDays: 5, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'ピーマン', quantity: 4, unit: '個', expiryDays: 9, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'ニンニク', quantity: 1, unit: '個', expiryDays: 40, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: '生姜', quantity: 1, unit: '袋', expiryDays: 15, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'もやし', quantity: 1, unit: '袋', expiryDays: 1, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'きゅうり', quantity: 3, unit: '本', expiryDays: 5, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'なす', quantity: 3, unit: '本', expiryDays: 6, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: '大根', quantity: 0.5, unit: '本', expiryDays: 10, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'さつまいも', quantity: 2, unit: '本', expiryDays: 30, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'かぼちゃ', quantity: 0.25, unit: '個', expiryDays: 14, storageLocation: StorageLocation.refrigerator),
  ],
  IngredientCategory.fish: const [
    _IngredientTemplate(name: '鮭の切り身', quantity: 2, unit: '切れ', expiryDays: 2, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'サバの塩焼き', quantity: 2, unit: '枚', expiryDays: 2, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'ちくわ', quantity: 1, unit: 'パック', expiryDays: 7, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'シーチキン', quantity: 1, unit: '缶', expiryDays: 365, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'アジの開き', quantity: 2, unit: '枚', expiryDays: 3, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'エビ', quantity: 150, unit: 'g', expiryDays: 2, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'イカ', quantity: 1, unit: '杯', expiryDays: 2, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'しじみ', quantity: 1, unit: 'パック', expiryDays: 3, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: '明太子', quantity: 1, unit: 'パック', expiryDays: 7, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'タラ切り身', quantity: 2, unit: '切れ', expiryDays: 2, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'ぶり切り身', quantity: 2, unit: '切れ', expiryDays: 2, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'サバの切り身', quantity: 2, unit: '切れ', expiryDays: 2, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'あさり', quantity: 1, unit: 'パック', expiryDays: 2, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'かにかま', quantity: 1, unit: 'パック', expiryDays: 7, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'しらす干し', quantity: 1, unit: 'パック', expiryDays: 5, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'かつおぶし', quantity: 1, unit: 'パック', expiryDays: 180, storageLocation: StorageLocation.pantry),
  ],
  IngredientCategory.dairy: const [
    _IngredientTemplate(name: '卵', quantity: 10, unit: '個', expiryDays: 14, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: '牛乳', quantity: 1, unit: 'L', expiryDays: 7, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'ヨーグルト', quantity: 1, unit: '個', expiryDays: 10, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'チーズ', quantity: 1, unit: 'パック', expiryDays: 20, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'バター', quantity: 1, unit: '個', expiryDays: 90, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: '生クリーム', quantity: 1, unit: 'パック', expiryDays: 10, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'スライスチーズ', quantity: 1, unit: '袋', expiryDays: 30, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: '飲むヨーグルト', quantity: 1, unit: '本', expiryDays: 8, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: '豆乳', quantity: 1, unit: 'L', expiryDays: 10, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'モッツァレラチーズ', quantity: 1, unit: '個', expiryDays: 14, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'クリームチーズ', quantity: 1, unit: '個', expiryDays: 30, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'カルピス原液', quantity: 1, unit: '本', expiryDays: 180, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: '粉チーズ', quantity: 1, unit: '本', expiryDays: 90, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'マーガリン', quantity: 1, unit: '個', expiryDays: 90, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: '明治おいしい牛乳', quantity: 1, unit: 'L', expiryDays: 7, storageLocation: StorageLocation.refrigerator, price: 248),
    _IngredientTemplate(name: '明治ブルガリアヨーグルト', quantity: 1, unit: '個', expiryDays: 10, storageLocation: StorageLocation.refrigerator, price: 198),
  ],
  IngredientCategory.seasoning: const [
    _IngredientTemplate(name: '醤油', quantity: 1, unit: '本', expiryDays: 180, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: '味噌', quantity: 1, unit: '個', expiryDays: 90, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'マヨネーズ', quantity: 1, unit: '本', expiryDays: 120, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: '塩', quantity: 1, unit: '個', expiryDays: 730, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: '砂糖', quantity: 1, unit: '個', expiryDays: 730, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: '味ぽん', quantity: 1, unit: '本', expiryDays: 180, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'ケチャップ', quantity: 1, unit: '本', expiryDays: 180, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'コショウ', quantity: 1, unit: '本', expiryDays: 365, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'ごま油', quantity: 1, unit: '本', expiryDays: 180, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: '中華だし', quantity: 1, unit: '袋', expiryDays: 180, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'みりん', quantity: 1, unit: '本', expiryDays: 180, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: '料理酒', quantity: 1, unit: '本', expiryDays: 180, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'めんつゆ', quantity: 1, unit: '本', expiryDays: 60, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'カレールー', quantity: 1, unit: '箱', expiryDays: 180, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'ポン酢', quantity: 1, unit: '本', expiryDays: 120, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: '酢', quantity: 1, unit: '本', expiryDays: 365, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'オリーブオイル', quantity: 1, unit: '本', expiryDays: 180, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'サラダ油', quantity: 1, unit: '本', expiryDays: 180, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'わさびチューブ', quantity: 1, unit: '本', expiryDays: 90, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'からしチューブ', quantity: 1, unit: '本', expiryDays: 90, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'バーモントカレー', quantity: 1, unit: '箱', expiryDays: 180, storageLocation: StorageLocation.pantry, price: 228),
    _IngredientTemplate(name: 'キッコーマン いつでも新鮮 しょうゆ', quantity: 1, unit: '本', expiryDays: 180, storageLocation: StorageLocation.pantry, price: 298),
    _IngredientTemplate(name: 'キユーピー マヨネーズ', quantity: 1, unit: '本', expiryDays: 120, storageLocation: StorageLocation.refrigerator, price: 328),
  ],
  IngredientCategory.frozen: const [
    _IngredientTemplate(name: '冷凍うどん', quantity: 3, unit: '食', expiryDays: 60, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍餃子', quantity: 1, unit: '袋', expiryDays: 45, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍ブロッコリー', quantity: 1, unit: '袋', expiryDays: 30, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍たこ焼き', quantity: 1, unit: '袋', expiryDays: 60, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍フライドポテト', quantity: 1, unit: '袋', expiryDays: 90, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍チャーハン', quantity: 1, unit: '袋', expiryDays: 60, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍パスタ', quantity: 1, unit: '食', expiryDays: 45, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: 'アイスクリーム', quantity: 2, unit: '個', expiryDays: 120, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍おにぎり', quantity: 1, unit: '袋', expiryDays: 60, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍えだまめ', quantity: 1, unit: '袋', expiryDays: 90, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍パイシート', quantity: 1, unit: '袋', expiryDays: 90, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍ブルーベリー', quantity: 1, unit: '袋', expiryDays: 90, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍ピラフ', quantity: 1, unit: '袋', expiryDays: 60, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍唐揚げ', quantity: 1, unit: '袋', expiryDays: 60, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '冷凍エビフライ', quantity: 1, unit: '袋', expiryDays: 60, storageLocation: StorageLocation.freezer),
    _IngredientTemplate(name: '味の素 ギョーザ', quantity: 1, unit: '袋', expiryDays: 60, storageLocation: StorageLocation.freezer, price: 218),
    _IngredientTemplate(name: 'ニチレイ 特から', quantity: 1, unit: '袋', expiryDays: 90, storageLocation: StorageLocation.freezer, price: 398),
    _IngredientTemplate(name: 'ハーゲンダッツ ミニカップ', quantity: 1, unit: '個', expiryDays: 180, storageLocation: StorageLocation.freezer, price: 320),
  ],
  IngredientCategory.other: const [
    _IngredientTemplate(name: '食パン', quantity: 6, unit: '枚', expiryDays: 4, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: '納豆', quantity: 3, unit: 'パック', expiryDays: 7, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: '豆腐', quantity: 1, unit: '丁', expiryDays: 5, storageLocation: StorageLocation.refrigerator),
    _IngredientTemplate(name: 'ポテトチップス', quantity: 1, unit: '袋', expiryDays: 60, storageLocation: StorageLocation.snackShelf),
    _IngredientTemplate(name: 'クッキー', quantity: 1, unit: '箱', expiryDays: 90, storageLocation: StorageLocation.snackShelf),
    _IngredientTemplate(name: '食パン（8枚切り）', quantity: 8, unit: '枚', expiryDays: 3, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'ポテトチップス（のり塩）', quantity: 1, unit: '袋', expiryDays: 60, storageLocation: StorageLocation.snackShelf),
    _IngredientTemplate(name: 'バームクーヘン', quantity: 1, unit: '個', expiryDays: 20, storageLocation: StorageLocation.snackShelf),
    _IngredientTemplate(name: 'チョコレート', quantity: 2, unit: '枚', expiryDays: 120, storageLocation: StorageLocation.snackShelf),
    _IngredientTemplate(name: 'おせんべい', quantity: 1, unit: '袋', expiryDays: 90, storageLocation: StorageLocation.snackShelf),
    _IngredientTemplate(name: 'カップラーメン', quantity: 1, unit: '個', expiryDays: 180, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'パスタ麺', quantity: 1, unit: '袋', expiryDays: 365, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'そうめん', quantity: 1, unit: '袋', expiryDays: 365, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: '炭酸水', quantity: 1, unit: '本', expiryDays: 90, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: '缶ビール', quantity: 6, unit: '本', expiryDays: 180, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: '紅茶ティーバッグ', quantity: 1, unit: '箱', expiryDays: 365, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'ミックスナッツ', quantity: 1, unit: '袋', expiryDays: 90, storageLocation: StorageLocation.pantry),
    _IngredientTemplate(name: 'グミ', quantity: 1, unit: '袋', expiryDays: 90, storageLocation: StorageLocation.snackShelf),
    _IngredientTemplate(name: 'ガム', quantity: 1, unit: '個', expiryDays: 180, storageLocation: StorageLocation.snackShelf),
    _IngredientTemplate(name: 'おかめ納豆 極小粒', quantity: 3, unit: 'パック', expiryDays: 7, storageLocation: StorageLocation.refrigerator, price: 98),
    _IngredientTemplate(name: 'コカ・コーラ', quantity: 1, unit: '本', expiryDays: 180, storageLocation: StorageLocation.pantry, price: 158),
    _IngredientTemplate(name: 'アサヒ スーパードライ', quantity: 6, unit: '本', expiryDays: 180, storageLocation: StorageLocation.pantry, price: 1280),
    _IngredientTemplate(name: 'サントリー 伊右衛門', quantity: 1, unit: '本', expiryDays: 90, storageLocation: StorageLocation.pantry, price: 98),
    _IngredientTemplate(name: '日清 カップヌードル', quantity: 1, unit: '個', expiryDays: 180, storageLocation: StorageLocation.pantry, price: 198),
    _IngredientTemplate(name: 'カルビー ポテトチップス うすしお味', quantity: 1, unit: '袋', expiryDays: 60, storageLocation: StorageLocation.snackShelf, price: 128),
    _IngredientTemplate(name: 'ブルボン アルフォート', quantity: 1, unit: '箱', expiryDays: 90, storageLocation: StorageLocation.snackShelf, price: 118),
    _IngredientTemplate(name: '明治 果汁グミ', quantity: 1, unit: '袋', expiryDays: 90, storageLocation: StorageLocation.snackShelf, price: 108),
  ],
};

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
