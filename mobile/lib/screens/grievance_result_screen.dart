/// Grievance Result screen - shows AI classification and ticket ID after submission.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';

class GrievanceResultScreen extends StatelessWidget {
  const GrievanceResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No data available')),
      );
    }

    final ticketId = data['ticket_id'] ?? 'N/A';
    final aiStatus = data['ai_status'] ?? 'success';
    final imageUrl = data['image'] != null ? data['image']['url'] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Submitted'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Success banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.resolved, Color(0xFF43A047)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 56, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text('Grievance Submitted Successfully!',
                      style: TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Ticket ID: ',
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Text(ticketId,
                            style: const TextStyle(color: Colors.white, fontSize: 18,
                                fontWeight: FontWeight.w800, letterSpacing: 1)),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: ticketId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ticket ID copied!'),
                                  duration: Duration(seconds: 1)),
                            );
                          },
                          child: const Icon(Icons.copy_rounded,
                              color: Colors.white70, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (aiStatus == 'fallback') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'AI classification was unavailable. Your complaint has been submitted with default classification.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // AI Classification
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.psychology_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text('AI Classification',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const Divider(height: 20),
                    _InfoRow('Category', data['category'] ?? 'N/A',
                        Icons.category_rounded),
                    _InfoRow('Issue Type', data['issue_type'] ?? 'N/A',
                        Icons.label_rounded),
                    _InfoRow('Priority', data['priority'] ?? 'N/A',
                        Icons.flag_rounded,
                        valueColor: getPriorityColor(data['priority'] ?? '')),
                    _InfoRow('Department', data['department'] ?? 'N/A',
                        Icons.business_rounded),
                    _InfoRow('AI Summary', data['summary'] ?? 'N/A',
                        Icons.summarize_rounded),
                  ],
                ),
              ),
            ),

            // Submitted evidence
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
                          Text('Submitted Evidence',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const SizedBox.shrink()),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/track',
                    arguments: ticketId),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Track This Complaint'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, '/citizen'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back to Dashboard'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, this.icon, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                    color: valueColor ?? AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
