class AppConstants {
  // API Configuration
  // Use 10.0.2.2 for Android emulator, or your computer's IP address for physical devices
  // Example: 'http://192.168.1.100' (replace with your actual IP)
  static const String apiBaseUrl = 'http://10.0.2.2';  // Android emulator
  static const int apiPort = 8080;
  
  // Alternative configurations (uncomment the one you need):
  // static const String apiBaseUrl = 'http://192.168.1.100';  // Physical device (replace with your IP)
  // static const String apiBaseUrl = 'https://your-api-domain.com';  // Production server
  
  // Auth API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String onboardingEndpoint = '/api/auth/onboarding';
  static const String userInfoEndpoint = '/api/info/user';
  
  // Map API Endpoints
  static const String fetchRouteEndpoint = '/api/map/fetch-route';
  static const String updateLocationEndpoint = '/api/map/update-location';
  static const String sosEndpoint = '/api/map/sos';
  static const String cancelRouteEndpoint = '/api/map/cancel-route';

  // Full URLs
  static String get fullApiUrl => '$apiBaseUrl:$apiPort';
  static String get loginUrl => '$fullApiUrl$loginEndpoint';
  static String get onboardingUrl => '$fullApiUrl$onboardingEndpoint';
  static String getUserInfoUrl(int userId) => '$fullApiUrl$userInfoEndpoint/$userId';
  
  // Map URLs
  static String get fetchRouteUrl => '$fullApiUrl$fetchRouteEndpoint';
  static String get updateLocationUrl => '$fullApiUrl$updateLocationEndpoint';
  static String get sosUrl => '$fullApiUrl$sosEndpoint';
  static String get cancelRouteUrl => '$fullApiUrl$cancelRouteEndpoint';
  
  // Connection timeout settings
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  
  // Location update interval
  static const Duration locationUpdateInterval = Duration(seconds: 1);
}

