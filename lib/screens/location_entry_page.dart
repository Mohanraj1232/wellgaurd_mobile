import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/typography.dart';
import 'package:wellguard_ai/theme/spacing.dart';
import 'package:wellguard_ai/services/location_service.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:wellguard_ai/providers/journey_provider.dart';
import 'package:wellguard_ai/widgets/widgets.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LocationEntryPage extends StatefulWidget {
  const LocationEntryPage({super.key});

  @override
  State<LocationEntryPage> createState() => _LocationEntryPageState();
}

class _LocationEntryPageState extends State<LocationEntryPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _locationService = LocationService();
  final _destinationFocus = FocusNode();
  final _timeFocus = FocusNode();

  // Hardcoded start location
  static const double _hardcodedLatitude = 12.869462392059459;
  static const double _hardcodedLongitude = 80.2165001240523;

  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isSubmitting = false;
  String? _locationError;
  int? _userId;
  int? _emergencyContactsCount;
  double _selectedTimeLimit = 30; // Default 30 minutes
  
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initialize();
    _timeLimitController.text = '30';
  }
  
  void _setupAnimations() {
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initialize() async {
    await _loadUserId();
    _setHardcodedLocation();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userid');
      _emergencyContactsCount = prefs.getInt('emergency_contacts_count') ?? 0;
    });
  }

  void _setHardcodedLocation() {
    setState(() {
      _currentPosition = Position(
        latitude: _hardcodedLatitude,
        longitude: _hardcodedLongitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _isLoadingLocation = false;
      _locationError = null;
    });
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    final permissionResult = await _locationService.requestLocationPermission();

    if (!permissionResult.granted) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = permissionResult.message;
      });

      if (permissionResult.permanentlyDenied && mounted) {
        _showPermissionDialog();
      }
      return;
    }

    final position = await _locationService.getCurrentPosition();

    if (mounted) {
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
        if (position == null) {
          _locationError = 'Unable to get current location. Please try again.';
        }
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXL)),
        title: Row(
          children: [
            Container(
              padding: AppSpacing.allSM,
              decoration: BoxDecoration(
                color: AppColors.accentWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              child: const Icon(Iconsax.location_slash, color: AppColors.accentWarning, size: 20),
            ),
            AppSpacing.hGapMD,
            Text('Location Required', style: AppTypography.titleLarge),
          ],
        ),
        content: Text(
          'This app needs location access to track your journey and ensure your safety. Please enable location permission in settings.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMD)),
            ),
            child: Text('Open Settings', style: AppTypography.labelLarge.copyWith(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  Future<void> _startJourney() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for location to be fetched'),
          backgroundColor: AppColors.accentWarning,
        ),
      );
      return;
    }
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in. Please login again.'),
          backgroundColor: AppColors.accentDanger,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiClient = DioClient.getApiClient();
      final destination = _destinationController.text.trim();
      final timeLimit = int.parse(_timeLimitController.text.trim());

      final response = await apiClient.fetchRoute(
        userId: _userId!,
        destination: destination,
        timeLimit: timeLimit,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      if (response.success && response.data != null) {
        final routeData = response.data!;

        // Update journey provider
        if (mounted) {
          final journeyProvider =
              Provider.of<JourneyProvider>(context, listen: false);
          journeyProvider.setCurrentLocation(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          journeyProvider.setDestinationInfo(destination, timeLimit);
          journeyProvider.initializeRoute(routeData);

          // Show success message with safety score
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Route found! Safety Score: ${routeData.safetyScore}/100 (${routeData.riskLevel})',
              ),
              backgroundColor: routeData.safetyScore >= 60
                  ? AppColors.secondary
                  : (routeData.safetyScore >= 40
                      ? AppColors.accentWarning
                      : AppColors.accentDanger),
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to map page
          Navigator.of(context).pushNamed('/map');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to fetch route'),
              backgroundColor: AppColors.accentDanger,
            ),
          );
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to start journey';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Cannot connect to server. Please try again.';
      } else if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData['message'] != null) {
          errorMessage = responseData['message'];
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.accentDanger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.accentDanger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _timeLimitController.dispose();
    _destinationFocus.dispose();
    _timeFocus.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated background
          const AnimatedGradientBackground(),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: AppSpacing.allLG,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.2, end: 0),
                    AppSpacing.vGapXL,
                    
                    // Route timeline
                    _buildRouteTimeline()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 200.ms)
                        .slideX(begin: -0.2, end: 0),
                    AppSpacing.vGapXL,
                    
                    // Time limit section
                    _buildTimeLimitSection()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 300.ms)
                        .slideY(begin: 0.2, end: 0),
                    AppSpacing.vGapXL,
                    
                    // Safety info card
                    _buildSafetyInfoCard()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 400.ms)
                        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                    AppSpacing.vGapXL,
                    
                    // Start button
                    _buildStartButton()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 500.ms)
                        .slideY(begin: 0.3, end: 0),
                    AppSpacing.vGapLG,
                    
                    // Back link
                    _buildBackLink()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: GlassCard(
            padding: AppSpacing.allSM,
            borderRadius: AppSpacing.radiusMD,
            child: const Icon(Iconsax.arrow_left, color: AppColors.textMain, size: 24),
          ),
        ),
        AppSpacing.vGapLG,
        Row(
          children: [
            Container(
              padding: AppSpacing.allMD,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              child: const Icon(Iconsax.routing_2, color: AppColors.textWhite, size: 28),
            ),
            AppSpacing.hGapMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Journey', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
                  AppSpacing.vGapXS,
                  Text(
                    'Enter your destination for safe tracking',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildRouteTimeline() {
    return GlassCard(
      padding: AppSpacing.allLG,
      borderRadius: AppSpacing.radiusXL,
      child: Column(
        children: [
          // Start location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentSuccess.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(color: AppColors.accentSuccess, width: 2),
                    ),
                    child: const Icon(Iconsax.gps, color: AppColors.accentSuccess, size: 20),
                  ),
                  Container(
                    width: 2,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.accentSuccess,
                          AppColors.primary.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Starting From', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                    AppSpacing.vGapXS,
                    if (_isLoadingLocation)
                      Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          AppSpacing.hGapSM,
                          Text('Fetching location...', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ],
                      )
                    else if (_locationError != null)
                      GestureDetector(
                        onTap: _fetchCurrentLocation,
                        child: Row(
                          children: [
                            const Icon(Iconsax.location_slash, color: AppColors.accentDanger, size: 16),
                            AppSpacing.hGapSM,
                            Expanded(
                              child: Text(
                                _locationError!,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.accentDanger),
                              ),
                            ),
                            const Icon(Iconsax.refresh, color: AppColors.primary, size: 16),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Location',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                          AppSpacing.vGapXS,
                          Container(
                            padding: AppSpacing.horizontalSM + AppSpacing.verticalXS,
                            decoration: BoxDecoration(
                              color: AppColors.accentSuccess.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                            ),
                            child: Text(
                              '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                              style: AppTypography.caption.copyWith(color: AppColors.accentSuccess, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // Destination
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: const Icon(Iconsax.location, color: AppColors.textWhite, size: 20),
              ),
              AppSpacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Destination', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                    AppSpacing.vGapSM,
                    TextFormField(
                      controller: _destinationController,
                      focusNode: _destinationFocus,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'e.g., Mandaveli, Chennai',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.bgGlass,
                        contentPadding: AppSpacing.horizontalMD + AppSpacing.verticalMD,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                          borderSide: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                          borderSide: const BorderSide(color: AppColors.accentDanger),
                        ),
                        prefixIcon: const Icon(Iconsax.search_normal, color: AppColors.textSecondary, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a destination';
                        }
                        if (value.trim().length < 3) {
                          return 'At least 3 characters required';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _timeFocus.requestFocus(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeLimitSection() {
    return GlassCard(
      padding: AppSpacing.allLG,
      borderRadius: AppSpacing.radiusXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: AppSpacing.allSM,
                decoration: BoxDecoration(
                  color: AppColors.accentWarning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                ),
                child: const Icon(Iconsax.timer_1, color: AppColors.accentWarning, size: 20),
              ),
              AppSpacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expected Travel Time', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                    Text('SOS triggered if exceeded', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: AppSpacing.horizontalMD + AppSpacing.verticalSM,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                ),
                child: Text(
                  '${_selectedTimeLimit.toInt()} min',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapLG,
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.borderLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _selectedTimeLimit,
              min: 5,
              max: 180,
              divisions: 35,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedTimeLimit = value;
                  _timeLimitController.text = value.toInt().toString();
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5 min', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              Text('180 min', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            ],
          ),
          AppSpacing.vGapMD,
          // Quick time presets
          Row(
            children: [
              _buildTimePreset(15),
              AppSpacing.hGapSM,
              _buildTimePreset(30),
              AppSpacing.hGapSM,
              _buildTimePreset(60),
              AppSpacing.hGapSM,
              _buildTimePreset(120),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimePreset(int minutes) {
    final isSelected = _selectedTimeLimit == minutes.toDouble();
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedTimeLimit = minutes.toDouble();
            _timeLimitController.text = minutes.toString();
          });
        },
        child: Container(
          padding: AppSpacing.verticalSM,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.bgGlass,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              '$minutes',
              style: AppTypography.labelLarge.copyWith(
                color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSafetyInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.2),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      padding: AppSpacing.allMD,
      child: Row(
        children: [
          Container(
            padding: AppSpacing.allMD,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            ),
            child: const Icon(Iconsax.shield_tick, color: AppColors.secondary, size: 24),
          ),
          AppSpacing.hGapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety Protection Active', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                AppSpacing.vGapXS,
                Text(
                  '${_emergencyContactsCount ?? 0} contacts will be alerted in emergency',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStartButton() {
    final isEnabled = !_isSubmitting && !_isLoadingLocation && _currentPosition != null;
    
    return ScaleTransition(
      scale: _buttonScale,
      child: GestureDetector(
        onTapDown: (_) => _buttonController.forward(),
        onTapUp: (_) => _buttonController.reverse(),
        onTapCancel: () => _buttonController.reverse(),
        onTap: isEnabled ? () {
          HapticFeedback.heavyImpact();
          _startJourney();
        } : null,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: isEnabled ? AppColors.primaryGradient : null,
            color: isEnabled ? null : AppColors.borderDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
            boxShadow: isEnabled ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ] : null,
          ),
          child: Center(
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.textWhite,
                        ),
                      ),
                      AppSpacing.hGapMD,
                      Text(
                        'Finding Safe Route...',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.routing, color: AppColors.textWhite, size: 24),
                      AppSpacing.hGapMD,
                      Text(
                        'Start Safe Journey',
                        style: AppTypography.titleMedium.copyWith(
                          color: isEnabled ? AppColors.textWhite : AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBackLink() {
    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Iconsax.arrow_left_2, size: 18),
        label: Text('Back to Home', style: AppTypography.labelLarge),
        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
      ),
    );
  }
}
