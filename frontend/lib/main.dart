import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FinCopilotApp(),
    ),
  );
}

class FinCopilotApp extends ConsumerWidget {
  const FinCopilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FinCopilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
