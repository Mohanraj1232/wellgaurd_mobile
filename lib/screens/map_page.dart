import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/typography.dart';
import 'package:wellguard_ai/theme/spacing.dart';
import 'package:wellguard_ai/providers/journey_provider.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:wellguard_ai/services/location_service.dart';
import 'package:wellguard_ai/widgets/widgets.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  // Map state
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLatLng;
  LatLng? _startLatLng;
  LatLng? _destinationLatLng;

  // Timer for location updates
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;

  // UI state
  bool _isLoading = true;
  bool _isSendingSOS = false;
  bool _showRoadInfo = false;
  bool _followUser = true; // Auto-follow user location
  int? _userId;

  // Pulsing animation for SOS button
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _initialize();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initialize() async {
    await _loadUserId();
    _setupMap();
    _startLocationTracking();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userid');
  }

  void _setupMap() {
    final journeyProvider =
        Provider.of<JourneyProvider>(context, listen: false);
    final routeData = journeyProvider.routeData;

    if (routeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No route data available'),
          backgroundColor: AppColors.accentDanger,
        ),
      );
      Navigator.pop(context);
      return;
    }

    // Set start location
    _startLatLng = LatLng(
      journeyProvider.currentLatitude ?? 0,
      journeyProvider.currentLongitude ?? 0,
    );
    _currentLatLng = _startLatLng;

    // Decode polyline
    _drawRoute(routeData.polyline);

    // Add markers
    _addMarkers();

    setState(() {
      _isLoading = false;
    });
  }

  void _drawRoute(String encodedPolyline) {
    try {
      List<PointLatLng> points =
          PolylinePoints().decodePolyline(encodedPolyline);

      if (points.isEmpty) {
        // If no polyline from API, create a simple line from start to end
        return;
      }

      List<LatLng> polylineCoordinates =
          points.map((point) => LatLng(point.latitude, point.longitude)).toList();

      // Set destination from last point
      _destinationLatLng = polylineCoordinates.last;

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: AppColors.primaryLight,
            width: 5,
            points: polylineCoordinates,
          ),
        );
      });
    } catch (e) {
      print('Error drawing route: $e');
    }
  }

  void _addMarkers() {
    setState(() {
      _markers = {
        // Start marker
        if (_startLatLng != null)
          Marker(
            markerId: const MarkerId('start'),
            position: _startLatLng!,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Start'),
          ),

        // Destination marker
        if (_destinationLatLng != null)
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: Provider.of<JourneyProvider>(context, listen: false)
                      .destination ??
                  'Destination',
            ),
          ),

        // Current location marker
        if (_currentLatLng != null)
          Marker(
            markerId: const MarkerId('current'),
            position: _currentLatLng!,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'You are here'),
          ),
      };
    });
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _updateLocation();
    });
  }

  Future<void> _updateLocation() async {
    try {
      final journeyProvider =
          Provider.of<JourneyProvider>(context, listen: false);
      final routeId = journeyProvider.routeId;

      if (routeId == null || _userId == null || _currentLatLng == null) return;

      // Update location on server using the current stored location
      final apiClient = DioClient.getApiClient();
      final response = await apiClient.updateLocation(
        routeId: routeId,
        latitude: _currentLatLng!.latitude,
        longitude: _currentLatLng!.longitude,
      );

      if (response.success && response.data != null) {
        journeyProvider.updateFromLocationResponse(response.data!);

        if (response.data!.status == 'completed') {
          _stopLocationTracking();
          _showArrivalDialog();
        } else if (response.data!.sosTriggered == true) {
          _stopLocationTracking();
          _showAutoSOSDialog();
        }
      }
    } catch (e) {
      print('Location update error: $e');
    }
  }

  void _updateCurrentMarker() {
    if (_currentLatLng == null) return;

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'current');
      _markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );
    });
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _positionStream?.cancel();
  }

  Future<void> _triggerSOS() async {
    HapticFeedback.heavyImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXL)),
        title: Row(
          children: [
            Container(
              padding: AppSpacing.allSM,
              decoration: BoxDecoration(
                color: AppColors.accentDanger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              child: const Icon(Iconsax.warning_2, color: AppColors.accentDanger, size: 24),
            ),
            AppSpacing.hGapMD,
            Text('Trigger SOS?', style: AppTypography.titleLarge),
          ],
        ),
        content: Text(
          'This will immediately alert your emergency contacts with your current location. Are you sure?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDanger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMD)),
            ),
            child: Text('SEND SOS', style: AppTypography.labelLarge.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSendingSOS = true;
    });

    try {
      final journeyProvider =
          Provider.of<JourneyProvider>(context, listen: false);
      final routeId = journeyProvider.routeId;

      if (routeId == null || _userId == null) {
        throw Exception('Missing route or user information');
      }

      final apiClient = DioClient.getApiClient();
      final response = await apiClient.triggerSOS(
        userId: _userId!,
        routeId: routeId,
        latitude: _currentLatLng?.latitude ?? journeyProvider.currentLatitude ?? 0,
        longitude: _currentLatLng?.longitude ?? journeyProvider.currentLongitude ?? 0,
      );

      if (response.success) {
        _stopLocationTracking();
        journeyProvider.triggerSOS();

        if (mounted) {
          _showSOSSentDialog(response.data?.notificationsSent ?? 0);
        }
      } else {
        throw Exception(response.message ?? 'Failed to send SOS');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SOS Error: ${e.toString()}'),
            backgroundColor: AppColors.accentDanger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingSOS = false;
        });
      }
    }
  }

  void _showSOSSentDialog(int notificationsSent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXL)),
        title: Row(
          children: [
            Container(
              padding: AppSpacing.allSM,
              decoration: BoxDecoration(
                color: AppColors.accentSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              child: const Icon(Iconsax.tick_circle, color: AppColors.accentSuccess, size: 24),
            ),
            AppSpacing.hGapMD,
            Text('SOS Alert Sent!', style: AppTypography.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your emergency contacts have been notified.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.vGapMD,
            Container(
              padding: AppSpacing.allMD,
              decoration: BoxDecoration(
                color: AppColors.accentSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.notification, color: AppColors.accentSuccess, size: 20),
                  AppSpacing.hGapSM,
                  Text(
                    '$notificationsSent notifications sent',
                    style: AppTypography.titleSmall.copyWith(color: AppColors.accentSuccess, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMD)),
            ),
            child: Text('OK', style: AppTypography.labelLarge.copyWith(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  void _showAutoSOSDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
              child: const Icon(Iconsax.timer_pause, color: AppColors.accentWarning, size: 24),
            ),
            AppSpacing.hGapMD,
            Text('Time Exceeded', style: AppTypography.titleLarge),
          ],
        ),
        content: Text(
          'You haven\'t reached your destination within the time limit. Your emergency contacts have been automatically notified.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMD)),
            ),
            child: Text('OK', style: AppTypography.labelLarge.copyWith(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXL)),
        title: Row(
          children: [
            Container(
              padding: AppSpacing.allSM,
              decoration: BoxDecoration(
                gradient: AppColors.successGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              child: const Icon(Iconsax.medal_star, color: AppColors.textWhite, size: 24),
            ),
            AppSpacing.hGapMD,
            Text('Arrived Safely!', style: AppTypography.titleLarge),
          ],
        ),
        content: Text(
          'Journey completed successfully. Stay safe!',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final journeyProvider = Provider.of<JourneyProvider>(context, listen: false);
              journeyProvider.completeJourney();
              journeyProvider.reset();

              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMD)),
            ),
            child: Text('Done', style: AppTypography.labelLarge.copyWith(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelJourney() async {
    final confirmed = await showDialog<bool>(
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
              child: const Icon(Iconsax.close_circle, color: AppColors.accentWarning, size: 24),
            ),
            AppSpacing.hGapMD,
            Text('Cancel Journey?', style: AppTypography.titleLarge),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this journey?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentWarning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMD)),
            ),
            child: Text('Yes, Cancel', style: AppTypography.labelLarge.copyWith(color: AppColors.textWhite)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final journeyProvider =
          Provider.of<JourneyProvider>(context, listen: false);
      final routeId = journeyProvider.routeId;

      if (routeId != null && _userId != null) {
        final apiClient = DioClient.getApiClient();
        await apiClient.cancelRoute(
          routeId: routeId,
          userId: _userId!,
        );
      }

      _stopLocationTracking();
      journeyProvider.cancelJourney();
      journeyProvider.reset();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling journey: ${e.toString()}'),
            backgroundColor: AppColors.accentDanger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stopLocationTracking();
    _mapController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _cancelJourney();
        return false;
      },
      child: Scaffold(
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Loading map...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  // Google Map
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _startLatLng ?? const LatLng(0, 0),
                      zoom: 15,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    onCameraMoveStarted: () {
                      // Disable auto-follow when user interacts with map
                      if (_followUser) {
                        setState(() {
                          _followUser = false;
                        });
                      }
                    },
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // Fit bounds to show entire route
                      if (_startLatLng != null && _destinationLatLng != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngBounds(
                            LatLngBounds(
                              southwest: LatLng(
                                _startLatLng!.latitude < _destinationLatLng!.latitude
                                    ? _startLatLng!.latitude
                                    : _destinationLatLng!.latitude,
                                _startLatLng!.longitude < _destinationLatLng!.longitude
                                    ? _startLatLng!.longitude
                                    : _destinationLatLng!.longitude,
                              ),
                              northeast: LatLng(
                                _startLatLng!.latitude > _destinationLatLng!.latitude
                                    ? _startLatLng!.latitude
                                    : _destinationLatLng!.latitude,
                                _startLatLng!.longitude > _destinationLatLng!.longitude
                                    ? _startLatLng!.longitude
                                    : _destinationLatLng!.longitude,
                              ),
                            ),
                            50,
                          ),
                        );
                      }
                    },
                  ),

                  // Top Info Card + Status Indicator
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 8),
                        if (_showRoadInfo) _buildRoadInfoCard(),
                      ],
                    ),
                  ),

                  // Bottom Controls
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomControls(),
                  ),

                  // My Location Button
                  Positioned(
                    bottom: 180,
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'location',
                      backgroundColor: _followUser 
                          ? AppColors.primary 
                          : AppColors.bgCard,
                      onPressed: () {
                        setState(() {
                          _followUser = true;
                        });
                        if (_currentLatLng != null) {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(_currentLatLng!),
                          );
                        }
                      },
                      child: Icon(
                        Icons.my_location,
                        color: _followUser 
                            ? AppColors.textWhite 
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Consumer<JourneyProvider>(
      builder: (context, journey, child) {
        return GlassCard(
          padding: AppSpacing.allMD,
          borderRadius: AppSpacing.radiusXL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Safety Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: AppSpacing.horizontalMD + AppSpacing.verticalSM,
                        decoration: BoxDecoration(
                          color: journey.safetyColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: journey.safetyColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.shield_tick, color: journey.safetyColor, size: 18),
                            AppSpacing.hGapSM,
                            Text(
                              '${journey.safetyScore}/100',
                              style: AppTypography.titleSmall.copyWith(
                                color: journey.safetyColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.hGapSM,
                      Text(
                        journey.riskText,
                        style: AppTypography.labelMedium.copyWith(
                          color: journey.safetyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _showRoadInfo = !_showRoadInfo;
                      });
                    },
                    child: Container(
                      padding: AppSpacing.allXS,
                      decoration: BoxDecoration(
                        color: AppColors.bgGlass,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                      child: Icon(
                        _showRoadInfo ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: AppSpacing.xl, color: AppColors.borderLight.withValues(alpha: 0.3)),
              // Journey Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(Iconsax.routing, journey.formattedDistance, 'Distance'),
                  Container(width: 1, height: 40, color: AppColors.borderLight.withValues(alpha: 0.3)),
                  _buildInfoItem(Iconsax.timer_1, '${journey.minutesRemaining} min', 'Remaining'),
                  Container(width: 1, height: 40, color: AppColors.borderLight.withValues(alpha: 0.3)),
                  _buildInfoItem(Iconsax.clock, _getExpectedArrival(journey.routeData?.expectedArrivalTime), 'ETA'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: AppSpacing.allXS,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        AppSpacing.vGapXS,
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  String _getExpectedArrival(String? isoTime) {
    if (isoTime == null) return '--:--';
    try {
      final dateTime = DateTime.parse(isoTime);
      return DateFormat.jm().format(dateTime);
    } catch (e) {
      return '--:--';
    }
  }

  Widget _buildStatusIndicator() {
    return Consumer<JourneyProvider>(
      builder: (context, journey, child) {
        Color bgColor;
        Color textColor;
        String statusText;
        IconData icon;

        switch (journey.status) {
          case JourneyStatus.active:
            bgColor = AppColors.secondary;
            textColor = AppColors.textWhite;
            statusText = 'Tracking';
            icon = Iconsax.gps;
            break;
          case JourneyStatus.completed:
            bgColor = AppColors.secondary;
            textColor = AppColors.textWhite;
            statusText = 'Arrived!';
            icon = Iconsax.tick_circle;
            break;
          case JourneyStatus.sosTriggered:
            bgColor = AppColors.accentDanger;
            textColor = AppColors.textWhite;
            statusText = 'SOS ACTIVE';
            icon = Iconsax.warning_2;
            break;
          default:
            bgColor = AppColors.borderLight;
            textColor = AppColors.textSecondary;
            statusText = 'Idle';
            icon = Iconsax.record;
        }

        return Container(
          padding: AppSpacing.horizontalMD + AppSpacing.verticalSM,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 14),
              AppSpacing.hGapXS,
              Text(statusText, style: AppTypography.caption.copyWith(color: textColor, fontWeight: FontWeight.w600)),
            ],
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.3));
      },
    );
  }

  Widget _buildRoadInfoCard() {
    return Consumer<JourneyProvider>(
      builder: (context, journey, child) {
        final roads = journey.routeData?.roadsUsed ?? [];

        if (roads.isEmpty) {
          return GlassCard(
            padding: AppSpacing.allMD,
            borderRadius: AppSpacing.radiusLG,
            child: Text(
              'No road information available',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          );
        }

        return GlassCard(
          padding: AppSpacing.allSM,
          borderRadius: AppSpacing.radiusLG,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: roads.length,
              itemBuilder: (context, index) {
                final road = roads[index];
                return Container(
                  padding: AppSpacing.allSM,
                  margin: EdgeInsets.only(bottom: index < roads.length - 1 ? AppSpacing.xs : 0),
                  decoration: BoxDecoration(
                    color: AppColors.bgGlass,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: AppSpacing.allXS,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                        ),
                        child: const Icon(Iconsax.routing_2, color: AppColors.primary, size: 16),
                      ),
                      AppSpacing.hGapSM,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              road.name,
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w500),
                            ),
                            AppSpacing.vGapXS,
                            Row(
                              children: [
                                if (road.quality != null)
                                  _buildRoadRating('Quality', road.quality!),
                                if (road.lighting != null)
                                  _buildRoadRating('Lights', road.lighting!),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoadRating(String label, double value) {
    final color = value >= 7
        ? AppColors.accentSuccess
        : (value >= 4 ? AppColors.accentWarning : AppColors.accentDanger);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: AppSpacing.horizontalSM + AppSpacing.verticalXS,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          Text(
            '${value.toStringAsFixed(0)}/10',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgMain.withValues(alpha: 0.8),
            AppColors.bgMain,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            width: 40,
            height: 4,
            margin: AppSpacing.bottomSM,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          // SOS Button with pulsing animation
          ScaleTransition(
            scale: _pulseAnimation,
            child: GestureDetector(
              onTap: _isSendingSOS ? null : _triggerSOS,
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.dangerGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentDanger.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: _isSendingSOS
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.textWhite,
                              ),
                            ),
                            AppSpacing.hGapMD,
                            Text(
                              'Sending SOS...',
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
                            const Icon(Iconsax.warning_2, color: AppColors.textWhite, size: 28),
                            AppSpacing.hGapMD,
                            Text(
                              'EMERGENCY SOS',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          AppSpacing.vGapMD,
          // Cancel Button
          TextButton.icon(
            onPressed: _cancelJourney,
            icon: const Icon(Iconsax.close_circle, size: 18),
            label: Text('Cancel Journey', style: AppTypography.labelLarge),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
