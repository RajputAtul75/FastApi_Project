/// Admin Dashboard with stat cards and charts.
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_client.dart';
import '../utils/theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getDashboardStats();
      setState(() {
        _stats = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load dashboard data.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'View All Complaints',
            onPressed: () => Navigator.pushNamed(context, '/admin/complaints'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_error!),
                  TextButton(onPressed: _loadStats, child: const Text('Retry')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _buildDashboard(),
              ),
            ),
    );
  }

  Widget _buildDashboard() {
    if (_stats == null) return const SizedBox.shrink();

    final total = _stats!['total'] ?? 0;
    final byStatus = Map<String, int>.from(
      (_stats!['by_status'] ?? {}).map(
        (k, v) => MapEntry(k.toString(), v as int),
      ),
    );
    final byPriority = Map<String, int>.from(
      (_stats!['by_priority'] ?? {}).map(
        (k, v) => MapEntry(k.toString(), v as int),
      ),
    );
    final byCategory = Map<String, int>.from(
      (_stats!['by_category'] ?? {}).map(
        (k, v) => MapEntry(k.toString(), v as int),
      ),
    );
    final byDepartment = Map<String, int>.from(
      (_stats!['by_department'] ?? {}).map(
        (k, v) => MapEntry(k.toString(), v as int),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stat cards row 1
        Row(
          children: [
            _StatCard(
              'Total',
              '$total',
              AppColors.primary,
              Icons.list_alt_rounded,
            ),
            const SizedBox(width: 10),
            _StatCard(
              'Pending',
              '${byStatus['Submitted'] ?? 0}',
              AppColors.submitted,
              Icons.inbox_rounded,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatCard(
              'In Progress',
              '${byStatus['In Progress'] ?? 0}',
              AppColors.inProgress,
              Icons.autorenew_rounded,
            ),
            const SizedBox(width: 10),
            _StatCard(
              'Resolved',
              '${byStatus['Resolved'] ?? 0}',
              AppColors.resolved,
              Icons.check_circle_rounded,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatCard(
              'High Priority',
              '${(byPriority['High'] ?? 0) + (byPriority['Critical'] ?? 0)}',
              AppColors.critical,
              Icons.priority_high_rounded,
            ),
            const SizedBox(width: 10),
            _StatCard(
              'Assigned',
              '${byStatus['Assigned'] ?? 0}',
              AppColors.assigned,
              Icons.assignment_ind_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/admin/complaints'),
            icon: const Icon(Icons.view_list_rounded),
            label: const Text('View All Complaints'),
          ),
        ),
        const SizedBox(height: 24),

        // Charts
        if (byStatus.isNotEmpty) ...[
          _ChartCard(
            title: 'Status Distribution',
            legend: byStatus.entries
                .map((e) => _LegendItem(e.key, e.value, getStatusColor(e.key)))
                .toList(),
            child: _buildPieChart(byStatus, _statusColors),
          ),
          const SizedBox(height: 16),
        ],

        if (byPriority.isNotEmpty) ...[
          _ChartCard(
            title: 'Priority Distribution',
            legend: byPriority.entries
                .map(
                  (e) => _LegendItem(e.key, e.value, getPriorityColor(e.key)),
                )
                .toList(),
            child: _buildPieChart(byPriority, _priorityColors),
          ),
          const SizedBox(height: 16),
        ],

        if (byCategory.isNotEmpty) ...[
          _ChartCard(
            title: 'Complaints by Category',
            child: _buildBarChart(byCategory),
          ),
          const SizedBox(height: 16),
        ],

        if (byDepartment.isNotEmpty) ...[
          _ChartCard(
            title: 'Complaints by Department',
            child: _buildBarChart(byDepartment),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Map<String, Color> get _statusColors => {
    'Submitted': AppColors.submitted,
    'Assigned': AppColors.assigned,
    'In Progress': AppColors.inProgress,
    'Resolved': AppColors.resolved,
  };

  Map<String, Color> get _priorityColors => {
    'Low': AppColors.low,
    'Medium': AppColors.medium,
    'High': AppColors.high,
    'Critical': AppColors.critical,
  };

  Widget _buildPieChart(Map<String, int> data, Map<String, Color> colorMap) {
    final total = data.values.fold(0, (a, b) => a + b);
    if (total == 0) return const Center(child: Text('No data'));

    final sections = data.entries.map((e) {
      final pct = (e.value / total * 100);
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${pct.round()}%',
        color: colorMap[e.key] ?? Colors.grey,
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
    }).toList();

    return SizedBox(
      height: 160,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 30,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    final entries = data.entries.toList();
    if (entries.isEmpty) return const Center(child: Text('No data'));

    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final colors = [
      AppColors.primary,
      AppColors.primaryLight,
      AppColors.accent,
      AppColors.submitted,
      AppColors.inProgress,
      AppColors.resolved,
      AppColors.assigned,
      AppColors.high,
      AppColors.critical,
    ];

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: (maxVal + 1).toDouble(),
          barGroups: List.generate(entries.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  color: colors[i % colors.length],
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) return const Text('');
                  final label = entries[idx].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: Text(
                        label.length > 12
                            ? '${label.substring(0, 10)}...'
                            : label,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final List<_LegendItem>? legend;

  const _ChartCard({required this.title, required this.child, this.legend});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            child,
            if (legend != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: legend!
                    .map(
                      (item) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.label} (${item.value})',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendItem {
  final String label;
  final int value;
  final Color color;
  const _LegendItem(this.label, this.value, this.color);
}
