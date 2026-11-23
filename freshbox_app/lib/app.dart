import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/recipe/recipe_screen.dart';
import 'presentation/screens/scan/scan_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/shopping/shopping_screen.dart';
import 'presentation/widgets/app_bottom_nav.dart';

class FreshBoxApp extends StatelessWidget {
  const FreshBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshBox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('ja', 'JP'),
      home: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    RecipeScreen(),
    ScanScreen(),
    ShoppingScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
