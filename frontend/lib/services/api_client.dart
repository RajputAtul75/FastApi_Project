import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../router.dart';

class ApiClient {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token is invalid or expired
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('jwt_token');
          // Navigate back to auth
          router.go('/auth');
        }
        return handler.next(e);
      },
    ),
  );

  static Dio get instance => _dio;
}
