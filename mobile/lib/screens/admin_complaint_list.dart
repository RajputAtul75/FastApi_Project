/// Admin Complaint List screen.
library;

import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/theme.dart';

class AdminComplaintList extends StatefulWidget {
  const AdminComplaintList({super.key});

  @override
  State<AdminComplaintList> createState() => _AdminComplaintListState();
}

class _AdminComplaintListState extends State<AdminComplaintList> {
  final ApiClient _api = ApiClient();
  List<dynamic> _complaints = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.listGrievances(limit: 100);
      setState(() {
        _complaints = data['grievances'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load complaints.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Complaints'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _complaints.isEmpty
                  ? const Center(child: Text('No complaints found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _complaints.length,
                        itemBuilder: (ctx, i) => _ComplaintTile(
                          complaint: _complaints[i],
                          onTap: () async {
                            await Navigator.pushNamed(ctx, '/admin/detail',
                                arguments: _complaints[i]['ticket_id']);
                            _load(); // Refresh after returning
                          },
                        ),
                      ),
                    ),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final VoidCallback onTap;

  const _ComplaintTile({required this.complaint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = complaint['status'] ?? '';
    final priority = complaint['priority'] ?? '';
    final hasImage = complaint['image'] != null;
    final created = complaint['created_at'] ?? '';
    final createdShort = created.length >= 10 ? created.substring(0, 10) : created;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: ticket ID + status
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: getStatusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status, style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w600, color: getStatusColor(status))),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(complaint['title'] ?? 'No Title',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),

              // Meta row
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  _MetaChip(Icons.category_rounded, complaint['category'] ?? ''),
                  _MetaChip(Icons.business_rounded, complaint['department'] ?? ''),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: getPriorityColor(priority).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(priority, style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: getPriorityColor(priority))),
                  ),
                  if (hasImage)
                    const Icon(Icons.image_rounded, size: 16,
                        color: AppColors.textSecondary),
                  Text(createdShort, style: const TextStyle(fontSize: 10,
                      color: AppColors.textLight)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(label.length > 18 ? '${label.substring(0, 16)}...' : label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
