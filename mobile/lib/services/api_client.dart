/// NyayaAI API client service.
/// Handles all HTTP communication with the backend.
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'runtime_config.dart';

class ApiClient {
  /// Compile-time backend URL, set with `--dart-define=API_BASE_URL=...`.
  ///
  /// On web this value is baked into `main.dart.js`, so it cannot be changed
  /// after a build — see [resolvedBaseUrl] for the escape hatch.
  /// For an Android emulator talking to a host machine, use `http://10.0.2.2:8000`.
  static const String _compileTimeBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// The backend URL this app will actually use, resolved once at startup from
  /// the first source that supplies a non-blank value:
  ///
  ///   1. `window.NYAYA_API_BASE_URL`, set by `web/config.js` (web only).
  ///      Editable in `build/web/config.js` after a build, so a deployed site
  ///      can be repointed without a Flutter rebuild.
  ///   2. The `API_BASE_URL` dart-define.
  ///   3. `http://localhost:8000`.
  ///
  /// Order matters: the runtime value wins so that a web build made without
  /// the dart-define cannot silently ship a `localhost` URL to real visitors,
  /// which resolves to the *visitor's own machine* and fails for everyone.
  static final String resolvedBaseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    var chosen = _compileTimeBaseUrl;
    final override = runtimeApiBaseUrl();
    // Only accept an absolute http(s) URL. A value like 'api.example.com'
    // (scheme forgotten while hand-editing config.js) parses as a *relative*
    // URI, so on web every request would quietly hit the Flutter site itself
    // and return 404 HTML, and on mobile it would throw — both baffling to
    // debug. Ignoring it here fails far more legibly.
    if (override != null &&
        (override.startsWith('http://') || override.startsWith('https://'))) {
      chosen = override;
    }
    // A trailing slash would turn '$baseUrl/api/health' into '...//api/health',
    // which some proxies 404 rather than normalise.
    while (chosen.endsWith('/')) {
      chosen = chosen.substring(0, chosen.length - 1);
    }
    return chosen;
  }

  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? resolvedBaseUrl;

  /// Timeout for requests that gate the UI.
  ///
  /// Free-tier hosts (Render, Fly, Railway) suspend idle web services and take
  /// 30-60s to wake, and the backend also opens its first MongoDB Atlas
  /// connection during that window. The first request after a quiet period pays
  /// that whole cost. A short timeout here surfaces as "Could not reach the
  /// NyayaAI server" while the server is in fact booting perfectly well, so be
  /// generous — a slow success beats a fast, wrong error message.
  static const Duration _coldStartTimeout = Duration(seconds: 60);

  // --- Health ---
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/health'))
        .timeout(_coldStartTimeout);
    return _handleResponse(response);
  }

  // --- Auth ---
  /// Authenticates an admin against `POST /api/auth/login`.
  ///
  /// The backend is the only authority on credentials — nothing is verified
  /// locally. On failure this throws an [ApiException] whose [statusCode]
  /// tells the caller what went wrong:
  ///   * `401` — the username or password was rejected.
  ///   * `0`   — the server could not be reached at all (offline, wrong
  ///             `API_BASE_URL`, backend not running).
  Future<Map<String, dynamic>> adminLogin({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_coldStartTimeout);
      final result = _handleResponse(response);

      // Don't infer success from the status code alone — require the backend's
      // own success flag, so a 200 carrying a failure payload can't sign anyone in.
      if (result['success'] != true) {
        throw ApiException(
          statusCode: 401,
          message: 'Invalid username or password.',
        );
      }
      return result;
    } on ApiException {
      rethrow; // A real HTTP response — let the caller read the status code.
    } catch (_) {
      // SocketException / ClientException / TimeoutException / bad JSON.
      throw ApiException(
        statusCode: 0,
        message: 'Could not reach the NyayaAI server. '
            'Check that the backend is running at $baseUrl.',
      );
    }
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
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      // Body isn't JSON — e.g. an HTML error page from a proxy or gateway.
      // Keep the real status code so callers don't mistake this for being
      // offline.
      if (isSuccess) return {};
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }

    if (isSuccess) {
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
