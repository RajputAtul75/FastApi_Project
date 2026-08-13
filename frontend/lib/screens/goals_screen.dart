import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Financial Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildGoalCard(
            title: 'Emergency Fund',
            current: 5000,
            target: 10000,
            icon: Icons.shield,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildGoalCard(
            title: 'Maldives Vacation',
            current: 1200,
            target: 3000,
            icon: Icons.flight_takeoff,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 16),
          _buildGoalCard(
            title: 'New MacBook Pro',
            current: 800,
            target: 2500,
            icon: Icons.laptop_mac,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required double current,
    required double target,
    required IconData icon,
    required Color color,
  }) {
    final double progress = current / target;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.background,
              color: color,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${current.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMain,
                ),
              ),
              Text(
                'Target: ₹${target.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
