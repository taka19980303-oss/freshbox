// FreshBox の基本ユニットテスト。
// （旧カウンターアプリ用テンプレートテストは実態に合わせて置き換え済み）

import 'package:flutter_test/flutter_test.dart';

import 'package:freshbox_app/data/models/ingredient.dart';

void main() {
  group('Ingredient.daysUntilExpiry', () {
    Ingredient build(DateTime expiry) => Ingredient(
          id: 'test',
          name: '牛乳',
          category: IngredientCategory.dairy,
          quantity: 1,
          unit: '本',
          expiryDate: expiry,
        );

    test('賞味期限が今日なら 0', () {
      expect(build(DateTime.now()).daysUntilExpiry, 0);
    });

    test('賞味期限が3日後なら 3', () {
      final in3 = DateTime.now().add(const Duration(days: 3));
      expect(build(in3).daysUntilExpiry, 3);
    });

    test('賞味期限が昨日なら -1', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(build(yesterday).daysUntilExpiry, -1);
    });
  });
}
