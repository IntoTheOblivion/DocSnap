import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'core/providers/shared_prefs_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DocSnapApp(),
    ),
  );
}

class DocSnapApp extends StatelessWidget {
  const DocSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocSnap Scanner',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
