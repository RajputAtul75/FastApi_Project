/// Submit Grievance screen with form, image picker, and AI analysis.
library;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/api_client.dart';
import '../utils/theme.dart';

class SubmitGrievanceScreen extends StatefulWidget {
  const SubmitGrievanceScreen({super.key});

  @override
  State<SubmitGrievanceScreen> createState() => _SubmitGrievanceScreenState();
}

class _SubmitGrievanceScreenState extends State<SubmitGrievanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedCategory;
  final ApiClient _api = ApiClient();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _submitting = false;

  final List<String> _categories = [
    'Road & Infrastructure', 'Electricity', 'Water Supply',
    'Sanitation', 'Waste Management', 'Public Safety',
    'Healthcare', 'Education', 'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image too large. Maximum size is 5 MB.'),
                  backgroundColor: Colors.red),
            );
          }
          return;
        }
        setState(() {
          _imageBytes = bytes;
          _imageName = picked.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      // Upload image first if present
      Map<String, dynamic>? imageData;
      if (_imageBytes != null && _imageName != null) {
        try {
          imageData = await _api.uploadImage(_imageBytes!, _imageName!);
        } catch (e) {
          // Image upload failed — continue without it
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image upload unavailable. Submitting without image.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      final result = await _api.createGrievance(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null : _locationController.text.trim(),
        category: _selectedCategory,
        image: imageData,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/result', arguments: result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Failed to submit. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Grievance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report Your Concern',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Our AI will analyze and classify your complaint',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Complaint Title *',
                  hintText: 'e.g. Large pothole near college',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Title must be at least 3 characters' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Complaint Description *',
                  hintText: 'Describe your complaint in detail...',
                  prefixIcon: Icon(Icons.description_rounded),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                minLines: 3,
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Description must be at least 10 characters' : null,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. College Main Gate, Sector 15',
                  prefixIcon: Icon(Icons.location_on_rounded),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: _categories.map((c) =>
                    DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 20),

              // Image picker
              const Text('Evidence Photo (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Camera or Gallery • JPG, PNG, WEBP • Max 5 MB',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 10),

              if (_imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_imageBytes!,
                      height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _showImageSourceDialog(),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Replace'),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _imageBytes = null;
                        _imageName = null;
                      }),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ] else
                InkWell(
                  onTap: _showImageSourceDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300,
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.add_a_photo_rounded, size: 36,
                            color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        const Text('Add Evidence Photo',
                            style: TextStyle(fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                  label: Text(_submitting ? 'Analyzing & Submitting...' : 'Analyze & Submit',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Image Source',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
