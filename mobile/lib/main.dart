/// NyayaAI - AI-powered citizen grievance management platform.
/// Main entry point with routing and state management.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
// Scoped: landing_screen.dart also declares an `AppColors`, so an unscoped
// import of both would make the name ambiguous here.
import 'utils/theme.dart' show AppTheme;
import 'screens/landing_screen.dart';
import 'screens/citizen_dashboard.dart';
import 'screens/submit_grievance_screen.dart';
import 'screens/grievance_result_screen.dart';
import 'screens/track_complaint_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/admin_complaint_list.dart';
import 'screens/admin_complaint_detail.dart';
import 'screens/admin_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore any saved admin session before the first frame, so a returning
  // admin never sees the login screen flash before the dashboard.
  final appState = AppState();
  await appState.restoreSession();

  runApp(
    ChangeNotifierProvider(
      create: (_) => appState,
      child: const NyayaAIApp(),
    ),
  );
}

class NyayaAIApp extends StatelessWidget {
  const NyayaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NyayaAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (ctx) => const LandingScreen(),
        '/citizen': (ctx) => const CitizenDashboard(),
        '/submit': (ctx) => const SubmitGrievanceScreen(),
        '/result': (ctx) => const GrievanceResultScreen(),
        '/track': (ctx) => const TrackComplaintScreen(),
        '/admin/login': (ctx) =>
            const AdminLoginScreen(redirectRoute: '/admin'),
        // Every admin route is wrapped in AdminGuard, so an unauthenticated
        // visitor — including a direct deep link — gets the login screen
        // instead of the protected content.
        '/admin': (ctx) => const AdminGuard(child: AdminDashboard()),
        '/admin/complaints': (ctx) =>
            const AdminGuard(child: AdminComplaintList()),
        '/admin/detail': (ctx) =>
            const AdminGuard(child: AdminComplaintDetail()),
      },
    );
  }
}
