import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ingredient.dart';

/// ホーム画面ウィジェット用データ同期サービス
///
/// 冷蔵庫の在庫から「賞味期限が近い上位3件」のデータを抽出し、
/// プラットフォームネイティブ領域（iOSのApp Group / AndroidのShared Preferences）へ書き出します。
///
/// ── 【重要】ネイティブ側での設定手順 ──
///
/// 1. iOS側 (AppDelegate.swift) の実装例:
/// ```swift
/// import Flutter
/// import UIKit
/// import WidgetKit
///
/// @main
/// @objc class AppDelegate: FlutterAppDelegate {
///   override func application(
///     _ application: UIApplication,
///     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
///   ) -> Bool {
///     let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
///     let channel = FlutterMethodChannel(name: "jp.freshbox.app/widget_sync",
///                                       binaryMessenger: controller.binaryMessenger)
///     channel.setMethodCallHandler({
///       (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
///       if call.method == "sync" {
///         if let args = call.arguments as? [String: Any],
///            let data = args["data"] as? String {
///              // App GroupsのSuite名でUserDefaultsを初期化 (Xcode側で要設定)
///              if let defaults = UserDefaults(suiteName: "group.jp.freshbox.app") {
///                  defaults.set(data, forKey: "expiring_ingredients")
///                  defaults.synchronize()
///                  
///                  // ウィジェットの再描画を要求
///                  if #available(iOS 14.0, *) {
///                      WidgetCenter.shared.reloadAllTimelines()
///                  }
///              }
///         }
///         result(nil)
///       } else {
///         result(FlutterMethodNotImplemented)
///       }
///     })
///
///     GeneratedPluginRegistrant.register(with: self)
///     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
///   }
/// }
/// ```
///
/// 2. Android側 (MainActivity.kt) の実装例:
/// ```kotlin
/// package jp.freshbox.app
///
/// import io.flutter.embedding.android.FlutterActivity
/// import io.flutter.embedding.engine.FlutterEngine
/// import io.flutter.plugin.common.MethodChannel
/// import android.content.Context
///
/// class MainActivity: FlutterActivity() {
///     private val CHANNEL = "jp.freshbox.app/widget_sync"
///
///     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
///         super.configureFlutterEngine(flutterEngine)
///         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
///             call, result ->
///             if (call.method == "sync") {
///                 val data = call.argument<String>("data")
///                 // ウィジェットプロセスからもアクセス可能なSharedPreferencesに保存
///                 val sharedPref = context.getSharedPreferences("jp.freshbox.app.widget", Context.MODE_PRIVATE)
///                 with (sharedPref.edit()) {
///                     putString("expiring_ingredients", data)
///                     apply()
///                 }
///                 result.success(null)
///             } else {
///                 result.notImplemented()
///             }
///         }
///     }
/// }
/// ```
class WidgetSyncService {
  static const _channel = MethodChannel('jp.freshbox.app/widget_sync');

  /// 食材リストから賞味期限が迫っている上位3品をウィジェットに同期する
  static Future<void> syncWidgetData(List<Ingredient> ingredients) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 期限切れしていない（または今日が期限の）食材を対象にする
      final activeIngredients = ingredients
          .where((item) => !item.expiryDate.isBefore(today))
          .toList();

      // 賞味期限の近い順（昇順）にソート
      activeIngredients.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

      // 直近3品をJSONに整形
      final top3 = activeIngredients.take(3).map((item) {
        return {
          'id': item.id,
          'name': item.name,
          'days': item.daysUntilExpiry,
          'emoji': item.category.emoji,
          'category': item.category.label,
          'location': item.storageLocation.label,
          'qty': '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}${item.unit}',
        };
      }).toList();

      final jsonStr = jsonEncode(top3);

      // プラットフォームネイティブ側へ送信
      await _channel.invokeMethod('sync', {
        'data': jsonStr,
        'count': activeIngredients.length,
      });
      
      print('[WidgetSyncService] 同期成功: $jsonStr');
    } on MissingPluginException {
      // プラットフォーム側がまだ未実装の場合は無視（開発中のエラー防止）
      print('[WidgetSyncService] プラットフォームのMethodChannelが見つかりません。ネイティブ側実装を完了してください。');
    } catch (e) {
      print('[WidgetSyncService] 同期中にエラーが発生しました: $e');
    }
  }
}
