import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await ApiClient.instance.post(
        '/auth/login',
        data: {
          'username': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['access_token'];
        if (token != null) {
          await setToken(token);
          return true;
        }
      }
      return false;
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Login failed');
      }
      throw Exception('Login failed. Please check your connection.');
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      final response = await ApiClient.instance.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.statusCode == 201 && response.data != null) {
        final token = response.data['access_token'];
        if (token != null) {
          await setToken(token);
          return true;
        }
      }
      return false;
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Registration failed');
      }
      throw Exception('Registration failed. Please check your connection.');
    }
  }
}
