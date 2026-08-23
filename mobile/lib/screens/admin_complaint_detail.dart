/// Admin Complaint Detail screen with status and department update controls.
library;

import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/theme.dart';

class AdminComplaintDetail extends StatefulWidget {
  const AdminComplaintDetail({super.key});

  @override
  State<AdminComplaintDetail> createState() => _AdminComplaintDetailState();
}

class _AdminComplaintDetailState extends State<AdminComplaintDetail> {
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _complaint;
  bool _loading = true;
  String? _error;

  final List<String> _statuses = ['Submitted', 'Assigned', 'In Progress', 'Resolved'];
  final List<String> _departments = [
    'Municipal Corporation', 'Electricity Department', 'Water Department',
    'Sanitation Department', 'Police Department', 'Health Department',
    'Education Department', 'General Administration', 'Other',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_complaint == null) {
      final ticketId = ModalRoute.of(context)?.settings.arguments as String?;
      if (ticketId != null) {
        _load(ticketId);
      } else if (_loading) {
        // Reached without a ticket (e.g. a direct /admin/detail deep link) —
        // show a message instead of spinning forever. Assigned directly rather
        // than via setState, since a build always follows this callback.
        _loading = false;
        _error = 'No complaint selected.';
      }
    }
  }

  Future<void> _load(String ticketId) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getGrievance(ticketId);
      if (!mounted) return; // Session may have been ended mid-request.
      setState(() { _complaint = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load complaint.';
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_complaint == null) return;
    try {
      await _api.updateStatus(_complaint!['ticket_id'], newStatus);
      if (!mounted) return; // Guard the setState too, not just the SnackBar.
      setState(() => _complaint!['status'] = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus'),
            backgroundColor: AppColors.resolved),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateDepartment(String newDept) async {
    if (_complaint == null) return;
    try {
      await _api.updateDepartment(_complaint!['ticket_id'], newDept);
      if (!mounted) return; // Guard the setState too, not just the SnackBar.
      setState(() => _complaint!['department'] = newDept);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Department updated to $newDept'),
            backgroundColor: AppColors.resolved),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update department: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!),
                    TextButton(onPressed: () {
                      final tid = ModalRoute.of(context)?.settings.arguments as String?;
                      if (tid != null) _load(tid);
                    }, child: const Text('Retry')),
                  ],
                ))
              : _complaint == null
                  ? const Center(child: Text('No data'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildDetail(),
                    ),
    );
  }

  Widget _buildDetail() {
    final c = _complaint!;
    final imageUrl = c['image'] != null ? c['image']['url'] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ticket header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.confirmation_number_rounded,
                  color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['ticket_id'] ?? '',
                        style: const TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text(c['title'] ?? '', style: const TextStyle(fontSize: 13,
                        color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: getPriorityColor(c['priority'] ?? '').withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(c['priority'] ?? '', style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12,
                    color: getPriorityColor(c['priority'] ?? ''))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Admin controls
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded,
                        color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text('Admin Controls',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
                const Divider(height: 20),

                // Status dropdown
                const Text('Update Status',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _statuses.contains(c['status']) ? c['status'] : null,
                  items: _statuses.map((s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(getStatusIcon(s), size: 16, color: getStatusColor(s)),
                        const SizedBox(width: 8),
                        Text(s),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) { if (v != null) _updateStatus(v); },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.sync_rounded),
                  ),
                ),
                const SizedBox(height: 14),

                // Department dropdown
                const Text('Update Department',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _departments.contains(c['department'])
                      ? c['department'] : null,
                  items: _departments.map((d) => DropdownMenuItem(
                    value: d, child: Text(d, style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) { if (v != null) _updateDepartment(v); },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Full details
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Full Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Divider(height: 20),
                _Row('Title', c['title'] ?? 'N/A'),
                _Row('Description', c['description'] ?? 'N/A'),
                _Row('Category', c['category'] ?? 'N/A'),
                _Row('Issue Type', c['issue_type'] ?? 'N/A'),
                _Row('Priority', c['priority'] ?? 'N/A',
                    valueColor: getPriorityColor(c['priority'] ?? '')),
                _Row('Department', c['department'] ?? 'N/A'),
                _Row('Status', c['status'] ?? 'N/A',
                    valueColor: getStatusColor(c['status'] ?? '')),
                _Row('Location', c['location'] ?? 'Not specified'),
                _Row('AI Summary', c['summary'] ?? 'N/A'),
                _Row('Created', _formatDate(c['created_at'])),
                _Row('Updated', _formatDate(c['updated_at'])),
              ],
            ),
          ),
        ),

        // Evidence
        if (imageUrl != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.photo_camera_rounded,
                          color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text('Evidence',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showFullImage(imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(imageUrl,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Text('Could not load image')),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Tap to view full size',
                      style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  void _showFullImage(String url) {
    Navigator.push(context, MaterialPageRoute(
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text('Evidence Image'),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Text('Could not load image',
                        style: TextStyle(color: Colors.white))),
          ),
        ),
      ),
    ));
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Row(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13,
                    color: valueColor ?? AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
