import 'package:flutter/material.dart';

/// FreshBox カラーパレット（和モダン × 清潔感 / 日本市場向け）
abstract final class AppColors {
  // ── Primary: 深緑・抹茶 ──
  static const Color primary = Color(0xFF1B6B3A);
  static const Color primaryLight = Color(0xFF4CAF70);
  static const Color primaryContainer = Color(0xFFD4EDDA);
  static const Color onPrimaryContainer = Color(0xFF0A3D1F);

  // ── Secondary: 朱色・和橙（警告・期限切れ） ──
  static const Color secondary = Color(0xFFE05C2A);
  static const Color secondaryLight = Color(0xFFF28B5F);
  static const Color secondaryContainer = Color(0xFFFFEDE5);

  // ── Tertiary: 藍色（冷凍・情報） ──
  static const Color tertiary = Color(0xFF2B5FA6);
  static const Color tertiaryContainer = Color(0xFFDDE8FF);

  // ── Warning: 橙（もうすぐ期限） ──
  static const Color warning = Color(0xFFE08020);
  static const Color warningContainer = Color(0xFFFFF3E0);

  // ── Error: 深紅（期限超過） ──
  static const Color error = Color(0xFFC62828);
  static const Color errorContainer = Color(0xFFFFEBEE);

  // ── Surface ──
  static const Color surface = Color(0xFFFAFAF8);       // 生成り白
  static const Color surfaceVariant = Color(0xFFF3F4F1);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE8EAE6);

  // ── Dark Mode Surface ──
  static const Color darkSurface = Color(0xFF111310);
  static const Color darkSurfaceVariant = Color(0xFF1B1E1B);
  static const Color darkCard = Color(0xFF1E211E);
  static const Color darkDivider = Color(0xFF2E322E);

  // ── Text ──
  static const Color textPrimary = Color(0xFF1A1C19);
  static const Color textSecondary = Color(0xFF5C6360);
  static const Color textTertiary = Color(0xFF8B9390);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Dark Mode Text ──
  static const Color darkTextPrimary = Color(0xFFE2E3DF);
  static const Color darkTextSecondary = Color(0xFFC0C4C0);
  static const Color darkTextTertiary = Color(0xFF8F938F);

  // ── Expiry Status Colors ──
  static const Color expiryFresh = Color(0xFF1B6B3A);   // 余裕あり (5日以上)
  static const Color expiryWarning = Color(0xFFE08020); // もうすぐ (3〜4日)
  static const Color expiryUrgent = Color(0xFFE05C2A);  // 今日使って (1〜2日)
  static const Color expiryExpired = Color(0xFF9E9E9E); // 期限切れ

  // ── 背景グラデーション（ヘッダー） ──
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B6B3A), Color(0xFF2E8B57)],
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D331C), Color(0xFF174227)],
  );

  static const LinearGradient recipeCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B6B3A), Color(0xFF4CAF70)],
  );
}
