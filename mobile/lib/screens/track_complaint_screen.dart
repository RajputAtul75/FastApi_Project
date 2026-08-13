/// Track Complaint screen - citizen enters ticket ID to see details and status timeline.
library;

import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/theme.dart';

class TrackComplaintScreen extends StatefulWidget {
  const TrackComplaintScreen({super.key});

  @override
  State<TrackComplaintScreen> createState() => _TrackComplaintScreenState();
}

class _TrackComplaintScreenState extends State<TrackComplaintScreen> {
  final _ticketController = TextEditingController();
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _complaint;
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && arg.isNotEmpty && _ticketController.text.isEmpty) {
      _ticketController.text = arg;
      _search();
    }
  }

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final id = _ticketController.text.trim();
    if (id.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });

    try {
      final data = await _api.getGrievance(id);
      setState(() {
        _complaint = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.statusCode == 404
            ? 'Complaint not found. Please check the ticket ID.'
            : e.message;
        _complaint = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not connect to server. Please try again.';
        _complaint = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter Ticket ID',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ticketController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. GRV-2026-0001',
                              prefixIcon: Icon(Icons.confirmation_number_rounded),
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _search(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _search,
                            child: _loading
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.search_rounded),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_error!,
                          style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ),
            ],

            if (_complaint != null) ...[
              const SizedBox(height: 20),
              _buildStatusTimeline(_complaint!['status'] ?? 'Submitted'),
              const SizedBox(height: 20),
              _buildDetails(_complaint!),
            ] else if (_searched && !_loading && _error == null) ...[
              const SizedBox(height: 40),
              const Center(child: Text('No results')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    const statuses = ['Submitted', 'Assigned', 'In Progress', 'Resolved'];
    final currentIndex = statuses.indexOf(currentStatus);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status Timeline',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...List.generate(statuses.length, (i) {
              final isActive = i <= currentIndex;
              final isCurrent = i == currentIndex;
              final isLast = i == statuses.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? getStatusColor(statuses[i])
                              : Colors.grey.shade200,
                          border: isCurrent ? Border.all(
                            color: getStatusColor(statuses[i]),
                            width: 3,
                          ) : null,
                          boxShadow: isCurrent ? [
                            BoxShadow(
                              color: getStatusColor(statuses[i]).withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ] : null,
                        ),
                        child: Icon(
                          isActive ? getStatusIcon(statuses[i]) : Icons.circle_outlined,
                          size: 16,
                          color: isActive ? Colors.white : Colors.grey.shade400,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 32,
                          color: isActive && i < currentIndex
                              ? getStatusColor(statuses[i])
                              : Colors.grey.shade200,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(statuses[i],
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.w700 : FontWeight.w500,
                                fontSize: isCurrent ? 15 : 14,
                                color: isActive
                                    ? AppColors.textPrimary
                                    : AppColors.textLight,
                              )),
                          if (isCurrent)
                            Text('Current Status',
                                style: TextStyle(fontSize: 11,
                                    color: getStatusColor(statuses[i]),
                                    fontWeight: FontWeight.w600)),
                          SizedBox(height: isLast ? 0 : 16),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(Map<String, dynamic> c) {
    final imageUrl = c['image'] != null ? c['image']['url'] : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Complaint Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Divider(height: 20),
            _DetailRow('Ticket ID', c['ticket_id'] ?? 'N/A'),
            _DetailRow('Title', c['title'] ?? 'N/A'),
            _DetailRow('Description', c['description'] ?? 'N/A'),
            _DetailRow('Category', c['category'] ?? 'N/A'),
            _DetailRow('Issue Type', c['issue_type'] ?? 'N/A'),
            _DetailRow('Priority', c['priority'] ?? 'N/A',
                valueColor: getPriorityColor(c['priority'] ?? '')),
            _DetailRow('Department', c['department'] ?? 'N/A'),
            _DetailRow('Location', c['location'] ?? 'N/A'),
            _DetailRow('AI Summary', c['summary'] ?? 'N/A'),
            if (imageUrl != null) ...[
              const SizedBox(height: 12),
              const Text('Submitted Evidence',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow(this.label, this.value, {this.valueColor});

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
