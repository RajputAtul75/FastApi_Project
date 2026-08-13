/// Citizen Dashboard - shows recent complaints and quick actions.
library;

import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/theme.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  final ApiClient _api = ApiClient();
  List<dynamic> _complaints = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.listGrievances(limit: 20);
      setState(() {
        _complaints = data['grievances'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load complaints. Please check your connection.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _complaints.length;
    final active = _complaints.where((c) => c['status'] != 'Resolved').length;
    final resolved = _complaints.where((c) => c['status'] == 'Resolved').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NyayaAI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadComplaints,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadComplaints,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              const Text('Welcome, Citizen',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Track and manage your complaints',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _StatCard(label: 'Total', value: '$total',
                      color: AppColors.primary, icon: Icons.list_alt_rounded),
                  const SizedBox(width: 10),
                  _StatCard(label: 'Active', value: '$active',
                      color: AppColors.assigned, icon: Icons.pending_actions_rounded),
                  const SizedBox(width: 10),
                  _StatCard(label: 'Resolved', value: '$resolved',
                      color: AppColors.resolved, icon: Icons.check_circle_outline_rounded),
                ],
              ),
              const SizedBox(height: 24),

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_circle_rounded,
                      label: 'Submit\nGrievance',
                      color: AppColors.primary,
                      onTap: () async {
                        await Navigator.pushNamed(context, '/submit');
                        _loadComplaints();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.search_rounded,
                      label: 'Track\nComplaint',
                      color: AppColors.primaryLight,
                      onTap: () => Navigator.pushNamed(context, '/track'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent complaints
              const Text('Recent Complaints',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                _ErrorCard(message: _error!, onRetry: _loadComplaints)
              else if (_complaints.isEmpty)
                _EmptyState()
              else
                ..._complaints.map((c) => _ComplaintCard(
                  complaint: c,
                  onTap: () => Navigator.pushNamed(context, '/track',
                      arguments: c['ticket_id']),
                )),
            ],
          ),
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

  const _StatCard({required this.label, required this.value,
    required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(
                fontSize: 12, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final VoidCallback onTap;

  const _ComplaintCard({required this.complaint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = complaint['status'] ?? 'Unknown';
    final priority = complaint['priority'] ?? 'Medium';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(complaint['ticket_id'] ?? '',
                        style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  const Spacer(),
                  _StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 8),
              Text(complaint['title'] ?? 'No Title',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.category_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(complaint['category'] ?? 'Other',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: getPriorityColor(priority).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(priority,
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: getPriorityColor(priority))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: getStatusColor(status).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getStatusIcon(status), size: 13, color: getStatusColor(status)),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: getStatusColor(status))),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Colors.red),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 48,
                color: AppColors.textLight),
            const SizedBox(height: 12),
            const Text('No complaints yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Submit your first grievance to get started',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
