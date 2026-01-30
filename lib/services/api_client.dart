import 'package:dio/dio.dart';
import 'package:wellguard_ai/models/api_response.dart';
import 'package:wellguard_ai/models/login_request.dart';
import 'package:wellguard_ai/models/onboarding_request.dart';
import 'package:wellguard_ai/models/user_data.dart';
import 'package:wellguard_ai/models/route_data.dart';

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

  // ============= MAP ENDPOINTS =============

  // Fetch route with safety score
  Future<ApiResponse<RouteData>> fetchRoute({
    required int userId,
    required String destination,
    required int timeLimit,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        '/api/map/fetch-route',
        data: {
          'userId': userId,
          'destination': destination,
          'timeLimit': timeLimit,
          'currentLocation': {
            'latitude': latitude,
            'longitude': longitude,
          },
        },
      );

      return ApiResponse<RouteData>.fromJson(
        response.data,
        (json) => RouteData.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update location during journey
  Future<ApiResponse<LocationUpdateResponse>> updateLocation({
    required String routeId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.put(
        '/api/map/update-location',
        data: {
          'routeId': routeId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return ApiResponse<LocationUpdateResponse>.fromJson(
        response.data,
        (json) => LocationUpdateResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Trigger SOS alert
  Future<ApiResponse<SOSResponse>> triggerSOS({
    required int userId,
    required String routeId,
    String message = 'Emergency! I need help immediately!',
  }) async {
    try {
      final response = await _dio.post(
        '/api/map/sos',
        data: {
          'userId': userId,
          'routeId': routeId,
          'message': message,
        },
      );

      return ApiResponse<SOSResponse>.fromJson(
        response.data,
        (json) => SOSResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Cancel route
  Future<ApiResponse<dynamic>> cancelRoute({
    required String routeId,
    required int userId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/map/cancel-route',
        data: {
          'routeId': routeId,
          'userId': userId,
        },
      );

      return ApiResponse<dynamic>.fromJson(
        response.data,
        (json) => json,
      );
    } catch (e) {
      rethrow;
    }
  }
}
