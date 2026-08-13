import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/goals_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (int index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'AI Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/upload')) return 2;
    if (location.startsWith('/chat')) return 3;
    if (location.startsWith('/goals')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/transactions');
        break;
      case 2:
        context.go('/upload');
        break;
      case 3:
        context.go('/chat');
        break;
      case 4:
        context.go('/goals');
        break;
    }
  }
}

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/auth',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    final isAuthRoute = state.uri.path == '/auth';
    
    // If no token exists and user is not on auth screen, redirect to auth
    if (token == null && !isAuthRoute) {
      return '/auth';
    }
    
    // If user has a token and is on auth screen, go to dashboard
    if (token != null && isAuthRoute) {
      return '/dashboard';
    }
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionsScreen(),
        ),
        GoRoute(
          path: '/upload',
          builder: (context, state) => const UploadScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => const ChatScreen(),
        ),
        GoRoute(
          path: '/goals',
          builder: (context, state) => const GoalsScreen(),
        ),
      ],
    ),
  ],
);
