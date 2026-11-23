import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import 'package:flutter/material.dart';

/// 賞味期限関連のユーティリティ
abstract final class ExpiryUtils {
  /// 残り日数を計算
  static int daysUntilExpiry(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  /// 残り日数からステータス文字列を返す
  static String statusLabel(int days) {
    if (days < 0) return '期限切れ';
    if (days == 0) return '今日まで！';
    if (days == 1) return '残り1日';
    if (days <= 2) return '今日使って！';
    if (days <= 4) return 'もうすぐ';
    return '余裕あり';
  }

  /// 残り日数から色を返す
  static Color statusColor(int days) {
    if (days < 0) return AppColors.expiryExpired;
    if (days <= 2) return AppColors.expiryUrgent;
    if (days <= 4) return AppColors.expiryWarning;
    return AppColors.expiryFresh;
  }

  /// 残り日数からアイコン絵文字を返す
  static String statusEmoji(int days) {
    if (days < 0) return '💀';
    if (days <= 2) return '🔥';
    if (days <= 4) return '⚠️';
    return '✅';
  }

  /// 日付を日本語形式で表示 (例: 6月25日（水）)
  static String formatDateJa(DateTime date) {
    final formatter = DateFormat('M月d日（E）', 'ja');
    return formatter.format(date);
  }

  /// 賞味期限を日本語形式で表示
  static String formatExpiryJa(DateTime expiryDate) {
    final days = daysUntilExpiry(expiryDate);
    if (days < 0) return '期限切れ';
    if (days == 0) return '今日まで';
    if (days == 1) return '明日まで';
    return '${DateFormat('M/d', 'ja').format(expiryDate)}まで（残り${days}日）';
  }
}
