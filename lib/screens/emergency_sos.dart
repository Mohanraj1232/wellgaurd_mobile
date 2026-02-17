import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/typography.dart';
import 'package:wellguard_ai/theme/spacing.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:wellguard_ai/providers/journey_provider.dart';
import 'package:wellguard_ai/widgets/widgets.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _sosSent = false;
  String? _errorMessage;
  int _notificationsSent = 0;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _triggerEmergencySOS();
  }
  
  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerEmergencySOS() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userid');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get current location
      double latitude = 0;
      double longitude = 0;

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (e) {
        // Try to get from journey provider if available
        final journeyProvider = Provider.of<JourneyProvider>(context, listen: false);
        latitude = journeyProvider.currentLatitude ?? 0;
        longitude = journeyProvider.currentLongitude ?? 0;
      }

      // Get route ID from journey provider if available
      final journeyProvider = Provider.of<JourneyProvider>(context, listen: false);
      final routeId = journeyProvider.routeId ?? '';

      // Call the SOS API with emergency message
      final apiClient = DioClient.getApiClient();
      final response = await apiClient.triggerSOS(
        userId: userId,
        routeId: routeId,
        latitude: latitude,
        longitude: longitude,
        message: 'EMERGENCY! I am in danger and need immediate help!',
      );

      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            _sosSent = true;
            _notificationsSent = response.data!.notificationsSent;
            _isLoading = false;
          });
        }
      } else {
        throw Exception(response.message ?? 'Failed to send Emergency SOS');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to send Emergency SOS alert';
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Cannot connect to server. Please try again.';
      } else if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData['message'] != null) {
          errorMessage = responseData['message'];
        }
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.bgMain,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Pulsing danger overlay
            if (_isLoading || _sosSent)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        AppColors.accentDanger.withValues(alpha: _sosSent ? 0.15 : 0.1),
                        AppColors.bgMain,
                      ],
                    ),
                  ),
                ),
              ),
            
            // Content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.65,
                        ),
                        child: Center(
                          child: _isLoading
                              ? _buildLoadingState()
                              : _errorMessage != null
                                  ? _buildErrorState()
                                  : _buildSuccessState(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: AppSpacing.allLG,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: GlassCard(
              padding: AppSpacing.allSM,
              borderRadius: AppSpacing.radiusMD,
              child: const Icon(Iconsax.arrow_left, color: AppColors.textMain, size: 24),
            ),
          ),
          AppSpacing.hGapMD,
          Expanded(
            child: Text(
              'Emergency SOS',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.accentDanger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: AppColors.accentDanger.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.warning_2, color: AppColors.accentDanger, size: 16),
                AppSpacing.hGapXS,
                Text('EMERGENCY', style: AppTypography.caption.copyWith(color: AppColors.accentDanger, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.dangerGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentDanger.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.textWhite,
                strokeWidth: 3,
              ),
            ),
          ),
        ),
        AppSpacing.vGapXL,
        Text(
          'Sending Emergency SOS...',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        AppSpacing.vGapMD,
        Padding(
          padding: AppSpacing.horizontalXL,
          child: Text(
            'Please wait while we alert your emergency contacts and services.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(delay: 400.ms),
        AppSpacing.vGapXL,
        // Pulsing rings
        const PulsingRings(
          color: AppColors.accentDanger,
          size: 100,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: AppSpacing.horizontalLG,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentDanger.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.accentDanger.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(
              Iconsax.close_circle,
              size: 60,
              color: AppColors.accentDanger,
            ),
          ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
          AppSpacing.vGapXL,
          Text(
            'SOS Failed',
            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 200.ms),
          AppSpacing.vGapMD,
          Text(
            _errorMessage ?? 'An error occurred',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          AppSpacing.vGapXL,
          Row(
            children: [
              Expanded(
                child: OutlinedGradientButton(
                  onPressed: () => Navigator.of(context).pop(),
                  text: 'Go Back',
                  gradient: AppColors.primaryGradient,
                ),
              ),
              AppSpacing.hGapMD,
              Expanded(
                child: GradientButton(
                  onPressed: _triggerEmergencySOS,
                  text: 'Retry',
                  gradient: AppColors.dangerGradient,
                  icon: Icon(Iconsax.refresh, color: AppColors.textWhite),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    HapticFeedback.heavyImpact();
    return Padding(
      padding: AppSpacing.horizontalLG,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.dangerGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentDanger.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Iconsax.tick_circle,
              size: 70,
              color: AppColors.textWhite,
            ),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1))
              .then()
              .shake(duration: 300.ms),
          AppSpacing.vGapXL,
          Text(
            'Emergency SOS Sent!',
            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 300.ms),
          AppSpacing.vGapMD,
          Text(
            'Your emergency contacts have been notified with your current location.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
          
          if (_notificationsSent > 0) ...[
            AppSpacing.vGapLG,
            Container(
              padding: AppSpacing.allMD,
              decoration: BoxDecoration(
                color: AppColors.accentSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                border: Border.all(color: AppColors.accentSuccess.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.notification, color: AppColors.accentSuccess, size: 20),
                  AppSpacing.hGapSM,
                  Text(
                    '$_notificationsSent notifications sent',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.accentSuccess,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
          
          AppSpacing.vGapLG,
          GlassCard(
            padding: AppSpacing.allMD,
            borderRadius: AppSpacing.radiusLG,
            child: Row(
              children: [
                Container(
                  padding: AppSpacing.allSM,
                  decoration: BoxDecoration(
                    color: AppColors.accentDanger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  ),
                  child: const Icon(Iconsax.info_circle, color: AppColors.accentDanger, size: 20),
                ),
                AppSpacing.hGapMD,
                Expanded(
                  child: Text(
                    'Emergency services have been notified.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.accentDanger, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms),
          
          AppSpacing.vGapXL,
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              onPressed: () => Navigator.of(context).pop(),
              text: 'Back to Home',
              gradient: AppColors.primaryGradient,
              icon: Icon(Iconsax.home, color: AppColors.textWhite),
            ),
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}
