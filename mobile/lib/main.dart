/// NyayaAI - AI-powered citizen grievance management platform.
/// Main entry point with routing and state management.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'utils/theme.dart';
import 'screens/landing_screen.dart';
import 'screens/citizen_dashboard.dart';
import 'screens/submit_grievance_screen.dart';
import 'screens/grievance_result_screen.dart';
import 'screens/track_complaint_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/admin_complaint_list.dart';
import 'screens/admin_complaint_detail.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
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
        '/admin': (ctx) => const AdminDashboard(),
        '/admin/complaints': (ctx) => const AdminComplaintList(),
        '/admin/detail': (ctx) => const AdminComplaintDetail(),
      },
    );
  }
}
