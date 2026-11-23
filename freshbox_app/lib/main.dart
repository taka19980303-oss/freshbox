import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/services/hive_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/icloud_sync_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 日本語ロケール初期化
  await initializeDateFormatting('ja', null);

  // Hive 初期化
  await HiveService.initialize();

  // 通知初期化
  await NotificationService.initialize();

  // Riverpodの独自コンテナ作成 (MethodChannel連携用)
  final container = ProviderContainer();

  // iCloud 初期化
  await ICloudSyncService.initialize(container);

  // ステータスバーを透過
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // 縦向き固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FreshBoxApp(),
    ),
  );
}
