/// NyayaAI API client service.
/// Handles all HTTP communication with the backend.
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiClient {
  // For Flutter Web on same machine, localhost works.
  // For Android emulator, use 10.0.2.2.
  static const String _defaultBaseUrl = 'http://10.0.2.2:8000';
  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl;

  // --- Health ---
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/health'))
        .timeout(const Duration(seconds: 5));
    return _handleResponse(response);
  }

  // --- Grievances ---
  Future<Map<String, dynamic>> createGrievance({
    required String title,
    required String description,
    String? location,
    String? category,
    Map<String, dynamic>? image,
  }) async {
    final body = {
      'title': title,
      'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
      if (category != null && category.isNotEmpty) 'category': category,
      'image': ?image,
    };
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/grievances'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> listGrievances({
    String? status,
    String? department,
    String? category,
    String? priority,
    int skip = 0,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (status != null) params['status'] = status;
    if (department != null) params['department'] = department;
    if (category != null) params['category'] = category;
    if (priority != null) params['priority'] = priority;

    final uri = Uri.parse('$baseUrl/api/grievances').replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getGrievance(String ticketId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/grievances/$ticketId'))
        .timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateStatus(String ticketId, String status) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/grievances/$ticketId/status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateDepartment(String ticketId, String department) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/grievances/$ticketId/department'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'department': department}),
        )
        .timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  // --- Dashboard ---
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/dashboard/stats'))
        .timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  // --- Upload ---
  Future<Map<String, dynamic>> uploadImage(Uint8List bytes, String filename) async {
    final mimeType = lookupMimeType(filename) ?? 'image/jpeg';
    final parts = mimeType.split('/');
    final mediaType = MediaType(parts[0], parts.length > 1 ? parts[1] : 'jpeg');

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/upload/image'));
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: mediaType,
    ));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // --- Seed ---
  Future<Map<String, dynamic>> seedData() async {
    final response = await http
        .post(Uri.parse('$baseUrl/api/seed'))
        .timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  // --- Helper ---
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: body is Map ? (body['detail'] ?? 'Unknown error').toString() : response.body,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
