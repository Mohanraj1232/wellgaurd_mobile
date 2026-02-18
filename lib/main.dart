import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wellguard_ai/screens/splash_screen.dart';
import 'package:wellguard_ai/screens/login.dart';
import 'package:wellguard_ai/screens/onboarding.dart';
import 'package:wellguard_ai/screens/home.dart';
import 'package:wellguard_ai/screens/greivance.dart';
import 'package:wellguard_ai/screens/add_grievance.dart';
import 'package:wellguard_ai/screens/view_grievances.dart';
import 'package:wellguard_ai/screens/emergency_sos.dart';
import 'package:wellguard_ai/screens/location_entry_page.dart';
import 'package:wellguard_ai/screens/map_page.dart';
import 'package:wellguard_ai/screens/news_feed.dart';
import 'package:wellguard_ai/screens/chat_page.dart';
import 'package:wellguard_ai/providers/journey_provider.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Greivex',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
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
        '/news_feed': (context) => const NewsFeedScreen(),
        '/chat': (context) => const ChatPage(),
      },
    );
  }
}
