import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:wellguard_ai/screens/home.dart';
import 'package:wellguard_ai/screens/login.dart';
import 'package:wellguard_ai/theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _textFadeAnim;
  late Animation<Offset> _taglineSlideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _textFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.85, curve: Curves.easeIn),
    );

    _taglineSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Check auth after animation has had time to breathe
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // Ensure splash is visible for at least 2.5 seconds
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2500)),
      _doCheckLogin(),
    ]);
  }

  Future<void> _doCheckLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      DioClient.setToken(token);
      Navigator.pushReplacement(
        context,
        _fadeRoute(const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        _fadeRoute(const LoginScreen()),
      );
    }
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with glow
            ScaleTransition(
              scale: _scaleAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 50,
                        spreadRadius: 5,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'lib/assests/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // App name
            FadeTransition(
              opacity: _textFadeAnim,
              child: const Text(
                'GrievX',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            FadeTransition(
              opacity: _textFadeAnim,
              child: SlideTransition(
                position: _taglineSlideAnim,
                child: const Text(
                  'Your voice. Heard. Resolved.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 64),

            // Loading indicator
            FadeTransition(
              opacity: _textFadeAnim,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primary.withValues(alpha: 0.7),
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
