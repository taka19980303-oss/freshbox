import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ingredient.dart';
import 'hive_service.dart';
import '../../presentation/providers/ingredient_provider.dart';
import '../../presentation/providers/shopping_provider.dart';

/// iCloud 家族間自動同期サービス (Key-Value Store)
///
/// ── 【重要】iOS側 (AppDelegate.swift) の実装例 ──
/// ```swift
/// import Flutter
/// import UIKit
///
/// @main
/// @objc class AppDelegate: FlutterAppDelegate {
///   override func application(
///     _ application: UIApplication,
///     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
///   ) -> Bool {
///     let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
///     let syncChannel = FlutterMethodChannel(name: "jp.freshbox.app/icloud_sync",
///                                            binaryMessenger: controller.binaryMessenger)
///     let store = NSUbiquitousKeyValueStore.default
///
///     syncChannel.setMethodCallHandler({
///       (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
///       if call.method == "upload" {
///         if let args = call.arguments as? [String: Any],
///            let key = args["key"] as? String,
///            let data = args["value"] as? String {
///              store.set(data, forKey: key)
///              store.synchronize()
///         }
///         result(nil)
///       } else if call.method == "download" {
///         if let args = call.arguments as? [String: Any],
///            let key = args["key"] as? String {
///              let value = store.string(forKey: key)
///              result(value)
///         } else {
///              result(nil)
///         }
///       } else {
///         result(FlutterMethodNotImplemented)
///       }
///     })
///
///     // iCloudの外部更新通知を監視
///     NotificationCenter.default.addObserver(
///       forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
///       object: store,
///       queue: .main
///     ) { _ in
///       // Flutter側へiCloudの更新を通知
///       syncChannel.invokeMethod("onICloudUpdate", arguments: nil)
///     }
///
///     GeneratedPluginRegistrant.register(with: self)
///     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
///   }
/// }
/// ```
class ICloudSyncService {
  static const _channel = MethodChannel('jp.freshbox.app/icloud_sync');
  static ProviderContainer? _container;

  // 自演ループ同期を防ぐガードフラグ
  static bool _isSyncing = false;

  /// アプリ起動時に呼び出し、iCloud更新通知のMethodChannelリスナーを登録
  static Future<void> initialize(ProviderContainer container) async {
    _container = container;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onICloudUpdate') {
        print('[ICloudSyncService] iCloudからデータ変更通知を受信しました。同期を開始します。');
        await pullFromICloud();
      }
    });

    // 起動時の初期ダウンロード同期
    await pullFromICloud();
  }

  /// iCloudから最新データを取得し、タイムスタンプが新しければローカルに適用
  static Future<void> pullFromICloud() async {
    if (_isSyncing || _container == null) return;
    _isSyncing = true;

    try {
      // 1. 食材在庫の同期
      final ingJsonStr = await _channel.invokeMethod<String>('download', {'key': 'ingredients_sync'});
      if (ingJsonStr != null && ingJsonStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(ingJsonStr);
        final int cloudTimestamp = data['lastUpdated'] as int;
        
        final localTimestamp = HiveService.ingredientBox.get('__last_updated_time', defaultValue: 0) as int;

        if (cloudTimestamp > localTimestamp) {
          print('[ICloudSyncService] iCloudの在庫データが新しいため、ローカルを更新します。');
          final List<dynamic> itemsList = data['items'];
          
          await HiveService.clearAll();
          for (final itemMap in itemsList) {
            await HiveService.saveIngredient(Ingredient.fromMap(itemMap));
          }
          await HiveService.ingredientBox.put('__last_updated_time', cloudTimestamp);
          
          // UIをリロード
          _container!.read(ingredientsProvider.notifier).reload();
        }
      }

      // 2. 買い物リストの同期
      final shopJsonStr = await _channel.invokeMethod<String>('download', {'key': 'shopping_sync'});
      if (shopJsonStr != null && shopJsonStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(shopJsonStr);
        final int cloudTimestamp = data['lastUpdated'] as int;
        
        final localTimestamp = HiveService.shoppingBox.get('__last_updated_time', defaultValue: 0) as int;

        if (cloudTimestamp > localTimestamp) {
          print('[ICloudSyncService] iCloudの買い物データが新しいため、ローカルを更新します。');
          final List<dynamic> itemsList = data['items'];
          
          await HiveService.clearAllShopping();
          for (final itemMap in itemsList) {
            await HiveService.saveShoppingItem(Ingredient.fromMap(itemMap));
          }
          await HiveService.shoppingBox.put('__last_updated_time', cloudTimestamp);
          
          // UIをリロード
          _container!.read(shoppingListProvider.notifier).reload();
        }
      }
    } on MissingPluginException {
      print('[ICloudSyncService] iCloud MethodChannelが未実装です。非iOS環境として同期をスキップします。');
    } catch (e) {
      print('[ICloudSyncService] iCloudデータ取得エラー: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// 在庫データをiCloudへアップロード
  static Future<void> pushIngredientsToICloud(List<Ingredient> list) async {
    if (_isSyncing) return;
    
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      await HiveService.ingredientBox.put('__last_updated_time', timestamp);

      final Map<String, dynamic> data = {
        'lastUpdated': timestamp,
        'items': list.map((item) => item.toMap()).toList(),
      };

      final jsonStr = jsonEncode(data);
      await _channel.invokeMethod('upload', {
        'key': 'ingredients_sync',
        'value': jsonStr,
      });
      print('[ICloudSyncService] 在庫データをiCloudへアップロードしました。');
    } on MissingPluginException {
      // Android / シミュレーターでは静かにスキップ
    } catch (e) {
      print('[ICloudSyncService] 在庫アップロードエラー: $e');
    }
  }

  /// 買い物リストデータをiCloudへアップロード
  static Future<void> pushShoppingToICloud(List<Ingredient> list) async {
    if (_isSyncing) return;
    
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      await HiveService.shoppingBox.put('__last_updated_time', timestamp);

      final Map<String, dynamic> data = {
        'lastUpdated': timestamp,
        'items': list.map((item) => item.toMap()).toList(),
      };

      final jsonStr = jsonEncode(data);
      await _channel.invokeMethod('upload', {
        'key': 'shopping_sync',
        'value': jsonStr,
      });
      print('[ICloudSyncService] 買い物データをiCloudへアップロードしました。');
    } on MissingPluginException {
      // Android / シミュレーターでは静かにスキップ
    } catch (e) {
      print('[ICloudSyncService] 買い物アップロードエラー: $e');
    }
  }
}
