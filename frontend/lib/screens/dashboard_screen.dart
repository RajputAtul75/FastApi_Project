import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: dashboardDataAsync.when(
          data: (data) => _buildBody(context, data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildBalanceCard(data),
          const SizedBox(height: 32),
          _buildSectionTitle('Analytics'),
          const SizedBox(height: 16),
          _buildChartCard(data),
          const SizedBox(height: 32),
          _buildSectionTitle('Recent Transactions'),
          const SizedBox(height: 16),
          _buildTransactionList(data),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning,',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Alex 🚀',
              style: TextStyle(
                fontSize: 28,
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: AppTheme.primary, size: 28),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(DashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.more_horiz,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${data.totalBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseStat(
                label: 'Income',
                amount: '+₹${data.monthlyIncome.toStringAsFixed(2)}',
                icon: Icons.arrow_downward,
                color: AppTheme.accent,
              ),
              _buildIncomeExpenseStat(
                label: 'Expense',
                amount: '-₹${data.monthlyExpense.toStringAsFixed(2)}',
                icon: Icons.arrow_upward,
                color: Colors.redAccent,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseStat({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryDark,
      ),
    );
  }

  Widget _buildChartCard(DashboardData data) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 6,
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, 3),
                FlSpot(1, 2),
                FlSpot(2, 5),
                FlSpot(3, 3.1),
                FlSpot(4, 4),
                FlSpot(5, 3),
                FlSpot(6, 4),
              ],
              isCurved: true,
              color: AppTheme.accent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.accent.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(DashboardData data) {
    if (data.recentTransactions.isEmpty) {
      return const Center(child: Text("No recent transactions"));
    }
    final transactions = [
      {'title': 'Starbucks Coffee', 'date': 'Today, 10:30 AM', 'amount': '-₹4.50', 'icon': Icons.coffee},
      {'title': 'Salary Deposit', 'date': 'Yesterday', 'amount': '+₹3,200.00', 'icon': Icons.business_center, 'isIncome': true},
      {'title': 'Apple Music', 'date': 'May 12, 2026', 'amount': '-₹9.99', 'icon': Icons.music_note},
      {'title': 'Uber Ride', 'date': 'May 11, 2026', 'amount': '-₹24.50', 'icon': Icons.directions_car},
    ];

    return Column(
      children: transactions.map((tx) {
        final isIncome = tx['isIncome'] == true;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    tx['icon'] as IconData,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx['date'] as String,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  tx['amount'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isIncome ? AppTheme.accent : AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
