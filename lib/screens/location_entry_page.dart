import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/services/location_service.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:wellguard_ai/providers/journey_provider.dart';

class LocationEntryPage extends StatefulWidget {
  const LocationEntryPage({super.key});

  @override
  State<LocationEntryPage> createState() => _LocationEntryPageState();
}

class _LocationEntryPageState extends State<LocationEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _locationService = LocationService();

  // Hardcoded start location
  static const double _hardcodedLatitude = 12.869462392059459;
  static const double _hardcodedLongitude = 80.2165001240523;

  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isSubmitting = false;
  String? _locationError;
  int? _userId;
  int? _emergencyContactsCount;

  @override
  void initState() {
    super.initState();
    _initialize();
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
        title: const Text(
          'Location Permission Required',
          style: TextStyle(color: AppColors.textMain),
        ),
        content: const Text(
          'This app needs location access to track your journey and ensure your safety. Please enable location permission in settings.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: AppColors.textWhite),
            ),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'WellGuard - Start Journey',
          style: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              const Text(
                'Where are you going?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your destination and we\'ll keep you safe',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Destination Input
              TextFormField(
                controller: _destinationController,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  labelText: 'Enter Destination',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: 'e.g., Mandaveli, Chennai',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a destination';
                  }
                  if (value.trim().length < 3) {
                    return 'Destination must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Time Limit Input
              TextFormField(
                controller: _timeLimitController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textMain),
                decoration: InputDecoration(
                  labelText: 'Approx. Time to Reach (minutes)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: 'e.g., 30',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.access_time,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter time limit';
                  }
                  final time = int.tryParse(value.trim());
                  if (time == null || time <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  if (time > 999) {
                    return 'Time limit cannot exceed 999 minutes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Current Location Display
              Card(
                color: AppColors.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _locationError != null
                        ? AppColors.accentDanger
                        : AppColors.borderLight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _locationError != null
                              ? AppColors.accentDanger.withValues(alpha: 0.1)
                              : AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _locationError != null
                              ? Icons.location_off
                              : Icons.my_location,
                          color: _locationError != null
                              ? AppColors.accentDanger
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Starting From',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_isLoadingLocation)
                              Row(
                                children: const [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Fetching location...',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            else if (_locationError != null)
                              Text(
                                _locationError!,
                                style: const TextStyle(
                                  color: AppColors.accentDanger,
                                  fontSize: 14,
                                ),
                              )
                            else if (_currentPosition != null)
                              Text(
                                '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  color: AppColors.textMain,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_locationError != null)
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.primary,
                          ),
                          onPressed: _fetchCurrentLocation,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Start Journey Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isSubmitting ||
                          _isLoadingLocation ||
                          _currentPosition == null)
                      ? null
                      : _startJourney,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.borderDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isSubmitting
                      ? const Row(
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
                            SizedBox(width: 12),
                            Text(
                              'Finding Safe Route...',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.navigation,
                              color: AppColors.textWhite,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Start Journey',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Footer Info
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.contacts,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_emergencyContactsCount ?? 0} emergency contacts added',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 18,
                      ),
                      label: const Text('Back to Home'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
