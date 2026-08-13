import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

// --- Models ---
class DashboardData {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final List<dynamic> recentTransactions;
  final List<dynamic> chartData;

  DashboardData({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.recentTransactions,
    required this.chartData,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalBalance: (json['total_balance'] ?? 0).toDouble(),
      monthlyIncome: (json['monthly_income'] ?? 0).toDouble(),
      monthlyExpense: (json['monthly_expense'] ?? 0).toDouble(),
      recentTransactions: json['recent_transactions'] ?? [],
      chartData: json['chart_data'] ?? [],
    );
  }
}

// --- Provider ---

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  // Assuming a hardcoded user or an auth token interceptor is set later.
  // Using user_id=1 as a dummy parameter. In reality, you'd use a Bearer token.
  try {
    final response = await ApiClient.instance.get('/dashboard/');
    return DashboardData.fromJson(response.data);
  } catch (e) {
    throw Exception('Failed to load dashboard data: $e');
  }
});
