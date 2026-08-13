import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Recent Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildMonthSection('May 2026', [
            _TransactionItem(title: 'Apple Music', subtitle: 'Subscriptions', amount: '-₹9.99', icon: Icons.music_note, color: Colors.blue),
            _TransactionItem(title: 'Uber Ride', subtitle: 'Transport', amount: '-₹24.50', icon: Icons.directions_car, color: Colors.orange),
            _TransactionItem(title: 'Salary', subtitle: 'Income', amount: '+₹3,200.00', icon: Icons.business_center, color: AppTheme.accent, isIncome: true),
          ]),
          const SizedBox(height: 24),
          _buildMonthSection('April 2026', [
            _TransactionItem(title: 'Starbucks', subtitle: 'Food & Dining', amount: '-₹14.50', icon: Icons.coffee, color: Colors.brown),
            _TransactionItem(title: 'Amazon Web Services', subtitle: 'Work', amount: '-₹120.00', icon: Icons.cloud, color: Colors.amber),
            _TransactionItem(title: 'Gym Membership', subtitle: 'Health', amount: '-₹50.00', icon: Icons.fitness_center, color: Colors.purple),
          ]),
        ],
      ),
    );
  }

  Widget _buildMonthSection(String month, List<Widget> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          month,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: transactions,
          ),
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isIncome;

  const _TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.color,
    this.isIncome = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryDark,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 13,
        ),
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isIncome ? AppTheme.accent : AppTheme.primaryDark,
          fontSize: 16,
        ),
      ),
    );
  }
}
