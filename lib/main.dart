import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellguard_ai/screens/login.dart';
import 'package:wellguard_ai/screens/onboarding.dart';
import 'package:wellguard_ai/screens/home.dart';
import 'package:wellguard_ai/screens/greivance.dart';
import 'package:wellguard_ai/screens/emergency_sos.dart';
import 'package:wellguard_ai/screens/location_entry_page.dart';
import 'package:wellguard_ai/screens/map_page.dart';
import 'package:wellguard_ai/providers/journey_provider.dart';
import 'package:wellguard_ai/theme/colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    final isLoggedIn = prefs.getBool('isloggedin') ?? false;
    
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isCheckingLogin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WellGaurd AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: _isCheckingLogin
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : (_isLoggedIn ? const HomeScreen() : const LoginScreen()),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) {
          final userId = ModalRoute.of(context)?.settings.arguments as int? ?? 1;
          return OnboardingScreen(userId: userId);
        },
        '/home': (context) => const HomeScreen(),
        '/greivance' : (context) => const GrievancePage(),
        '/emergency_sos': (context) => const EmergencySOSScreen(),
        '/location_entry': (context) => const LocationEntryPage(),
        '/map': (context) => const MapPage(),
      },
    );
  }
}
