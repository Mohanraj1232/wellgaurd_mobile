import 'package:dio/dio.dart';
import 'package:wellguard_ai/models/api_response.dart';
import 'package:wellguard_ai/models/login_request.dart';
import 'package:wellguard_ai/models/onboarding_request.dart';
import 'package:wellguard_ai/models/user_data.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  // Login API
  Future<ApiResponse<Map<String, dynamic>>> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: request.toJson(),
      );
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Save contacts (onboarding) API
  Future<ApiResponse<dynamic>> saveContacts(OnboardingRequest request) async {
    try {
      final response = await _dio.post(
        '/api/auth/onboarding',
        data: request.toJson(),
      );
      
      return ApiResponse<dynamic>.fromJson(
        response.data,
        (json) => json,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get user info API
  Future<ApiResponse<UserData>> getUserInfo(int userId) async {
    try {
      final response = await _dio.get('/api/info/user/$userId');
      
      return ApiResponse<UserData>.fromJson(
        response.data,
        (json) => UserData.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }
}
