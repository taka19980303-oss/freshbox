import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recipe.dart';
import '../../data/services/api_service.dart';
import 'ingredient_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final recipeSuggestionsProvider = FutureProvider<List<RecipeSuggestion>>((ref) async {
  final ingredients = ref.watch(ingredientsProvider);
  final apiService = ref.watch(apiServiceProvider);
  
  if (ingredients.isEmpty) {
    return [];
  }
  
  final ingredientNames = ingredients.map((e) => e.name).toList();
  return apiService.suggestRecipes(ingredients: ingredientNames);
});
