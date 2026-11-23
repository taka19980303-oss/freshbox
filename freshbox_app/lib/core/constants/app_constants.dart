/// アプリ定数
abstract final class AppConstants {
  // 賞味期限しきい値
  static const int expiryWarningDays = 4;  // 4日以下でもうすぐ
  static const int expiryUrgentDays = 2;   // 2日以下で今日使って

  // UI
  static const double borderRadius = 16.0;
  static const double borderRadiusLarge = 20.0;
  static const double cardElevation = 2.0;
  static const double pagePadding = 16.0;
}
