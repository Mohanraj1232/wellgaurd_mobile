import 'package:dio/dio.dart';
import 'package:wellguard_ai/constants.dart';
import 'package:wellguard_ai/services/api_client.dart';

class DioClient {
  static Dio? _dio;
  static ApiClient? _apiClient;

  static Dio getDio() {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.fullApiUrl,
          connectTimeout: AppConstants.connectionTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Add interceptors for logging (optional)
      _dio!.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => print(obj),
        ),
      );

      // Add error interceptor
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onError: (DioException error, ErrorInterceptorHandler handler) {
            print('DioError: ${error.message}');
            print('Response: ${error.response?.data}');
            return handler.next(error);
          },
        ),
      );
    }
    return _dio!;
  }

  static ApiClient getApiClient() {
    _apiClient ??= ApiClient(getDio());
    return _apiClient!;
  }

  static void clearInstance() {
    _dio = null;
    _apiClient = null;
  }
}
