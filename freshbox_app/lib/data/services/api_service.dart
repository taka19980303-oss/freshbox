import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/recipe.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// 在庫食材のリストからAIレシピ提案を取得する
  /// サーバーが起動していないかエラーが発生した場合は、ローカルのモックデータにフォールバックします。
  Future<List<RecipeSuggestion>> suggestRecipes({
    required List<String> ingredients,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.suggestRecipeEndpoint}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'ingredients': ingredients,
          'preferences': preferences,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> recipesJson = decoded['recipes'] ?? [];
        return recipesJson.map((r) => _parseRecipe(r)).toList();
      } else {
        throw HttpException('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      // ログ出力し、モックデータを返す（フォールバック）
      print('ApiService: Recipe suggestion API failed ($e). Falling back to mock data.');
      return _getMockRecipes(ingredients);
    }
  }

  /// レシートの画像ファイルを送信してOCRスキャンを実行する
  /// サーバーが起動していないかエラーが発生した場合は、シミュレートされた結果にフォールバックします。
  Future<Map<String, dynamic>> scanReceipt({
    required String filePath,
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.scanReceiptEndpoint}');
      final request = http.MultipartRequest('POST', url);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        throw HttpException('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService: Receipt scan API failed ($e). Falling back to mock simulation.');
      // モック遅延シミュレーション
      await Future.delayed(const Duration(milliseconds: 1200));
      return _getMockScanResponse();
    }
  }

  RecipeSuggestion _parseRecipe(Map<String, dynamic> json) {
    return RecipeSuggestion(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      usedIngredients: List<String>.from(json['used_ingredients'] ?? []),
      missingIngredients: List<String>.from(json['missing_ingredients'] ?? []),
      cookingTime: json['cooking_time']?.toString() ?? '15分',
      difficulty: json['difficulty']?.toString() ?? '簡単',
      caloriesEstimate: json['calories_estimate']?.toString(),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  /// 在庫食材の組み合わせに基づいてモックレシピを返す
  List<RecipeSuggestion> _getMockRecipes(List<String> userIngredients) {
    final userIngSet = userIngredients.map((e) => e.trim()).toSet();
    final allMocks = RecipeSuggestion.sampleData;
    
    // ユーザーの食材とマッチするレシピを優先する
    final matched = <RecipeSuggestion>[];
    for (final recipe in allMocks) {
      final requiredSet = recipe.usedIngredients.toSet();
      final intersection = requiredSet.intersection(userIngSet);
      if (intersection.isNotEmpty) {
        matched.add(recipe);
      }
    }

    if (matched.isNotEmpty) {
      return matched;
    }
    return allMocks;
  }

  /// オフライン・エラー時のモックOCRレスポンス
  Map<String, dynamic> _getMockScanResponse() {
    return {
      'success': true,
      'purchased_date': DateTime.now().toIso8601String().split('T').first,
      'store_name': 'サンプルスーパー（オフラインモード）',
      'confidence': 0.90,
      'ingredients': [
        {
          'name': '豚肩ロース',
          'quantity': 300.0,
          'unit': 'g',
          'estimated_expiry_days': 5,
          'confidence': 0.95
        },
        {
          'name': '白菜',
          'quantity': 1.0,
          'unit': '個',
          'estimated_expiry_days': 7,
          'confidence': 0.92
        },
        {
          'name': 'レモン',
          'quantity': 2.0,
          'unit': '個',
          'estimated_expiry_days': 14,
          'confidence': 0.88
        }
      ],
      'raw_text': 'レシートスキャン（モック）',
      'message': 'オフラインモードでレシートを解析しました。'
    };
  }
}
