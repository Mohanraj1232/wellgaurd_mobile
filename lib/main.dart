import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellguard_ai/screens/login.dart';
import 'package:wellguard_ai/screens/onboarding.dart';
import 'package:wellguard_ai/screens/home.dart';
import 'package:wellguard_ai/screens/greivance.dart';
import 'package:wellguard_ai/screens/add_grievance.dart';
import 'package:wellguard_ai/screens/view_grievances.dart';
import 'package:wellguard_ai/screens/emergency_sos.dart';
import 'package:wellguard_ai/screens/location_entry_page.dart';
import 'package:wellguard_ai/screens/map_page.dart';
import 'package:wellguard_ai/providers/journey_provider.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:wellguard_ai/theme/app_theme.dart';
import 'package:wellguard_ai/theme/colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgMain,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JourneyProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _isCheckingLogin = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    // Check if token exists (user is logged in)
    if (token != null && token.isNotEmpty) {
      // Initialize DioClient with the saved token
      DioClient.setToken(token);
    }
    
    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      _isCheckingLogin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GrievX',
      theme: AppTheme.darkTheme,
      home: _isCheckingLogin
          ? Scaffold(
              backgroundColor: AppColors.bgMain,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowPrimary,
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'GX',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            )
          : (_isLoggedIn ? const HomeScreen() : const LoginScreen()),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          int userId = 1;
          String token = '';
          String userName = '';
          String phoneNumber = '';
          if (args is Map<String, dynamic>) {
            userId = args['userId'] as int? ?? 1;
            token = args['token'] as String? ?? '';
            userName = args['name'] as String? ?? '';
            phoneNumber = args['phoneNumber'] as String? ?? '';
          } else if (args is int) {
            userId = args;
          }
          return OnboardingScreen(userId: userId, token: token, userName: userName, phoneNumber: phoneNumber);
        },
        '/home': (context) => const HomeScreen(),
        '/greivance': (context) => const GrievancePage(),
        '/add_grievance': (context) => const AddGrievanceScreen(),
        '/view_grievances': (context) => const ViewGrievancesScreen(),
        '/emergency_sos': (context) => const EmergencySOSScreen(),
        '/location_entry': (context) => const LocationEntryPage(),
        '/map': (context) => const MapPage(),
      },
    );
  }
}
