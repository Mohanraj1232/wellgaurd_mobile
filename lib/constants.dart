class AppConstants {
  // API Configuration
  // Use 10.0.2.2 for Android emulator, or your computer's IP address for physical devices
  // Example: 'http://192.168.1.100' (replace with your actual IP)
  static const String apiBaseUrl = 'http://10.0.2.2';  // Android emulator
  static const int apiPort = 8080;
  
  // Alternative configurations (uncomment the one you need):
  // static const String apiBaseUrl = 'http://192.168.1.100';  // Physical device (replace with your IP)
  // static const String apiBaseUrl = 'https://your-api-domain.com';  // Production server
  
  // API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String onboardingEndpoint = '/api/auth/onboarding';
  static const String userInfoEndpoint = '/api/info/user';

  // Full URLs
  static String get fullApiUrl => '$apiBaseUrl:$apiPort';
  static String get loginUrl => '$fullApiUrl$loginEndpoint';
  static String get onboardingUrl => '$fullApiUrl$onboardingEndpoint';
  static String getUserInfoUrl(int userId) => '$fullApiUrl$userInfoEndpoint/$userId';
  
  // Connection timeout settings
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
