import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../theme/app_theme.dart';
import '../services/api_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isUploading = false;
  String? _uploadMessage;

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'pdf'],
        allowMultiple: false,
        withData: kIsWeb, // Important for web
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isUploading = true;
        _uploadMessage = "Uploading file...";
      });

      final file = result.files.first;
      FormData formData;

      if (kIsWeb) {
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            file.bytes!, 
            filename: file.name
          ),
        });
      } else {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path!, 
            filename: file.name
          ),
        });
      }

      final response = await ApiClient.instance.post(
        '/upload/statement',
        data: formData,
      );

      if (response.statusCode == 201) {
        final parsed = response.data['transactions_parsed'];
        setState(() {
          _uploadMessage = "Success! Loaded $parsed transactions.";
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Processed $parsed transactions successfully."),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Upload Statement'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Import your bank statements for AI categorization and insights.',
              style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 80,
                      color: AppTheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Drag & Drop your CSV or PDF here',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Supported formats: .csv, .pdf, .xls',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_isUploading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton.icon(
                        onPressed: _pickAndUploadFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Browse Files'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
                    if (_uploadMessage != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        _uploadMessage!,
                        style: const TextStyle(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Security Guaranteed',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your financial data is encrypted and securely processed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: const Color.fromARGB(255, 206, 216, 230), fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
