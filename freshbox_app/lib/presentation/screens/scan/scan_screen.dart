import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/ingredient.dart';
import '../../../data/services/api_service.dart';
import '../../providers/ingredient_provider.dart';

const _uuid = Uuid();

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

enum ScanStep {
  initial,
  scanning,
  verifyResults,
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  
  ScanStep _currentStep = ScanStep.initial;
  String? _selectedImagePath;
  String _storeName = 'サンプルスーパー';
  DateTime _purchasedDate = DateTime.now();
  List<Ingredient> _scannedIngredients = [];

  // ── 画像選択・撮影 ──
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
          _currentStep = ScanStep.scanning;
        });
        
        final bytes = await pickedFile.readAsBytes();
        _sendToBackend(pickedFile.path, bytes, pickedFile.name);
      }
    } catch (e) {
      print('ScanScreen: Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像の取得に失敗しました。モックデータでシミュレートします。'),
          action: SnackBarAction(
            label: '試す',
            onPressed: () => _simulateMockScan(),
          ),
        ),
      );
    }
  }

  // ── サンプルレシートで試す ──
  void _simulateMockScan() {
    setState(() {
      _selectedImagePath = null;
      _currentStep = ScanStep.scanning;
    });
    _sendToBackend('', [], 'mock_receipt.png');
  }

  // ── バックエンド送信 ──
  Future<void> _sendToBackend(String path, List<int> bytes, String fileName) async {
    final response = await _apiService.scanReceipt(
      filePath: path,
      bytes: bytes,
      fileName: fileName,
    );

    if (response['success'] == true) {
      final List<dynamic> itemsJson = response['ingredients'] ?? [];
      final parsedDateStr = response['purchased_date']?.toString();
      final parsedDate = parsedDateStr != null 
          ? DateTime.tryParse(parsedDateStr) ?? DateTime.now()
          : DateTime.now();

      final parsedIngredients = itemsJson.map((item) {
        final name = item['name']?.toString() ?? '不明な食材';
        final qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;
        final unit = item['unit']?.toString() ?? '個';
        final expiryDays = (item['estimated_expiry_days'] as num?)?.toInt() ?? 7;
        
        // カテゴリの推測
        IngredientCategory category = IngredientCategory.other;
        if (name.contains('肉') || name.contains('牛') || name.contains('豚') || name.contains('鶏')) {
          category = IngredientCategory.meat;
        } else if (name.contains('菜') || name.contains('レモン') || name.contains('ネギ') || name.contains('キャベツ')) {
          category = IngredientCategory.vegetable;
        } else if (name.contains('魚') || name.contains('マグロ') || name.contains('鮭')) {
          category = IngredientCategory.fish;
        } else if (name.contains('卵') || name.contains('牛乳') || name.contains('チーズ') || name.contains('豆腐')) {
          category = IngredientCategory.dairy;
        }

        return Ingredient(
          id: _uuid.v4(),
          name: name,
          category: category,
          quantity: qty,
          unit: unit,
          expiryDate: DateTime.now().add(Duration(days: expiryDays)),
          purchasedDate: parsedDate,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _storeName = response['store_name']?.toString() ?? 'サンプルスーパー';
          _purchasedDate = parsedDate;
          _scannedIngredients = parsedIngredients;
          _currentStep = ScanStep.verifyResults;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('レシートの解析に失敗しました。'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _currentStep = ScanStep.initial;
        });
      }
    }
  }

  // ── 保存処理 ──
  Future<void> _saveAll() async {
    final notifier = ref.read(ingredientsProvider.notifier);
    for (final ing in _scannedIngredients) {
      await notifier.add(ing);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_scannedIngredients.length}品の食材を登録しました！'),
          backgroundColor: AppColors.primary,
        ),
      );
      setState(() {
        _currentStep = ScanStep.initial;
        _scannedIngredients = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (_currentStep) {
      case ScanStep.initial:
        return _buildInitialView(theme);
      case ScanStep.scanning:
        return _buildScanningView(theme);
      case ScanStep.verifyResults:
        return _buildVerifyResultsView(theme);
    }
  }

  // ── 初期画面 ──
  Widget _buildInitialView(ThemeData theme) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE05C2A), Color(0xFFB53D10)],
                  ),
                ),
              ),
              title: Text(
                'レシートスキャン',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            backgroundColor: AppColors.secondary,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // スキャンエリア
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('🧾', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          'レシートから自動で食材を追加',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '買い物後のレシートを撮影すると、\n食材名・数量・賞味期限をAIが自動推定します。',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: AppColors.secondary),
                                  foregroundColor: AppColors.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('写真から選ぶ'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1,
                                ),
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('カメラ起動'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _simulateMockScan,
                          child: const Text(
                            'サンプルレシートで試す',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),
                  const SizedBox(height: 32),
                  // スキャンのコツ
                  _buildScanTips(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTips(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'きれいスキャンのコツ 💡',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildTipItem('明るい場所で', '陰が入らないように撮影してください。'),
        _buildTipItem('まっすぐ・平らに', 'シワや折れのない平らな状態で撮ると認識率が上がります。'),
        _buildTipItem('品名が見えるように', '品名と金額が平行になるよう、真上から撮影してください。'),
      ],
    );
  }

  Widget _buildTipItem(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.secondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── スキャン中画面 ──
  Widget _buildScanningView(ThemeData theme) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text('🧾', style: TextStyle(fontSize: 48)),
                  ),
                ),
                // レーザースキャン線のアニメーション
                Positioned(
                  child: Container(
                    width: 150,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .moveY(begin: -70, end: 70, duration: 1500.ms, curve: Curves.easeInOut),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'レシートを解析中...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AIが品名と賞味期限を抽出しています。しばらくお待ちください。',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── スキャン結果確認・編集画面 ──
  Widget _buildVerifyResultsView(ThemeData theme) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        title: const Text('レシートの確認', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _currentStep = ScanStep.initial;
            });
          },
        ),
      ),
      body: Column(
        children: [
          // 店舗情報・日付ヘッダー
          Container(
            color: AppColors.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.storefront, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _storeName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                ),
                Text(
                  dateFormat.format(_purchasedDate),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              itemCount: _scannedIngredients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final ing = _scannedIngredients[i];
                return Dismissible(
                  key: ValueKey(ing.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    setState(() {
                      _scannedIngredients.removeAt(i);
                    });
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // カテゴリ絵文字
                        GestureDetector(
                          onTap: () => _pickCategory(i),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                ing.category.emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // 内容
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 食材名
                              TextFormField(
                                initialValue: ing.name,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                onChanged: (val) {
                                  _scannedIngredients[i] = ing.copyWith(name: val.trim());
                                },
                              ),
                              const SizedBox(height: 6),
                              
                              Row(
                                children: [
                                  // 数量・単位
                                  Text(
                                    '${ing.quantity % 1 == 0 ? ing.quantity.toInt() : ing.quantity}${ing.unit}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // 賞味期限表示
                                  GestureDetector(
                                    onTap: () => _pickExpiryDate(i),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_month, size: 12, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            dateFormat.format(ing.expiryDate),
                                            style: const TextStyle(
                                              fontSize: 11, 
                                              fontWeight: FontWeight.w600, 
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 保存場所表示
                                  GestureDetector(
                                    onTap: () => _pickStorageLocation(i),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            ing.storageLocation.emoji,
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            ing.storageLocation.label,
                                            style: const TextStyle(
                                              fontSize: 11, 
                                              fontWeight: FontWeight.w600, 
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // 削除ボタン
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
                          onPressed: () {
                            setState(() {
                              _scannedIngredients.removeAt(i);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // ボトムアクションバー
          Container(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            decoration: BoxDecoration(
              color: AppColors.card,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentStep = ScanStep.initial;
                      });
                    },
                    child: const Text('キャンセル'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _scannedIngredients.isEmpty ? null : _saveAll,
                    child: Text('冷蔵庫に登録 (${_scannedIngredients.length}品)'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 日付ピッカー ──
  Future<void> _pickExpiryDate(int index) async {
    final ing = _scannedIngredients[index];
    final picked = await showDatePicker(
      context: context,
      initialDate: ing.expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('ja'),
    );
    if (picked != null) {
      setState(() {
        _scannedIngredients[index] = ing.copyWith(expiryDate: picked);
      });
    }
  }

  // ── カテゴリ変更シート ──
  void _pickCategory(int index) {
    final ing = _scannedIngredients[index];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'カテゴリを選択',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IngredientCategory.values.map((cat) {
                  return ChoiceChip(
                    label: Text('${cat.emoji} ${cat.label}'),
                    selected: ing.category == cat,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _scannedIngredients[index] = ing.copyWith(category: cat);
                        });
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 保存場所変更シート ──
  void _pickStorageLocation(int index) {
    final ing = _scannedIngredients[index];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '保存場所を選択',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: StorageLocation.values.map((loc) {
                  return ChoiceChip(
                    label: Text('${loc.emoji} ${loc.label}'),
                    selected: ing.storageLocation == loc,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _scannedIngredients[index] = ing.copyWith(storageLocation: loc);
                        });
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
