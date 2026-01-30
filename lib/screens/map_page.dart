import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/providers/journey_provider.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:wellguard_ai/services/location_service.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Row(
          children: const [
            Icon(Icons.warning_amber, color: AppColors.accentDanger, size: 28),
            SizedBox(width: 8),
            Text(
              'Trigger SOS?',
              style: TextStyle(color: AppColors.textMain),
            ),
          ],
        ),
        content: const Text(
          'This will immediately alert your emergency contacts with your current location. Are you sure?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDanger,
            ),
            child: const Text(
              'SEND SOS',
              style: TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: AppColors.secondary, size: 28),
            SizedBox(width: 8),
            Text(
              '🚨 SOS Alert Sent!',
              style: TextStyle(color: AppColors.textMain),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your emergency contacts have been notified.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Notifications sent: $notificationsSent',
              style: const TextStyle(
                color: AppColors.textMain,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.textWhite),
            ),
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
        title: Row(
          children: const [
            Icon(Icons.warning, color: AppColors.accentWarning, size: 28),
            SizedBox(width: 8),
            Text(
              '⚠️ Time Limit Exceeded',
              style: TextStyle(color: AppColors.textMain),
            ),
          ],
        ),
        content: const Text(
          'You haven\'t reached your destination within the time limit. Your emergency contacts have been automatically notified.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.textWhite),
            ),
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
        title: Row(
          children: const [
            Icon(Icons.celebration, color: AppColors.secondary, size: 28),
            SizedBox(width: 8),
            Text(
              '🎉 You\'ve Arrived Safely!',
              style: TextStyle(color: AppColors.textMain),
            ),
          ],
        ),
        content: const Text(
          'Journey completed successfully. Stay safe!',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final journeyProvider =
                  Provider.of<JourneyProvider>(context, listen: false);
              journeyProvider.completeJourney();
              journeyProvider.reset();

              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text(
              'Done',
              style: TextStyle(color: AppColors.textWhite),
            ),
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
        title: const Text(
          'Cancel Journey?',
          style: TextStyle(color: AppColors.textMain),
        ),
        content: const Text(
          'Are you sure you want to cancel this journey?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentWarning,
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.textWhite),
            ),
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

                  // Top Info Card
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 16,
                    right: 16,
                    child: _buildInfoCard(),
                  ),

                  // Status Indicator
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    right: 16,
                    child: _buildStatusIndicator(),
                  ),

                  // Road Info Toggle
                  if (_showRoadInfo)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 140,
                      left: 16,
                      right: 16,
                      child: _buildRoadInfoCard(),
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
        return Card(
          color: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: journey.safetyColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shield,
                                color: journey.safetyColor,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${journey.safetyScore}/100',
                                style: TextStyle(
                                  color: journey.safetyColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          journey.riskText,
                          style: TextStyle(
                            color: journey.safetyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _showRoadInfo
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _showRoadInfo = !_showRoadInfo;
                        });
                      },
                    ),
                  ],
                ),
                const Divider(height: 20),
                // Journey Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(
                      Icons.straighten,
                      journey.formattedDistance,
                      'Distance',
                    ),
                    _buildInfoItem(
                      Icons.access_time,
                      '${journey.minutesRemaining} min',
                      'Remaining',
                    ),
                    _buildInfoItem(
                      Icons.schedule,
                      _getExpectedArrival(journey.routeData?.expectedArrivalTime),
                      'ETA',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textMain,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
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
            statusText = 'Tracking...';
            icon = Icons.gps_fixed;
            break;
          case JourneyStatus.completed:
            bgColor = AppColors.secondary;
            textColor = AppColors.textWhite;
            statusText = 'Arrived!';
            icon = Icons.check_circle;
            break;
          case JourneyStatus.sosTriggered:
            bgColor = AppColors.accentDanger;
            textColor = AppColors.textWhite;
            statusText = 'SOS TRIGGERED';
            icon = Icons.warning;
            break;
          default:
            bgColor = AppColors.borderLight;
            textColor = AppColors.textSecondary;
            statusText = 'Idle';
            icon = Icons.circle;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoadInfoCard() {
    return Consumer<JourneyProvider>(
      builder: (context, journey, child) {
        final roads = journey.routeData?.roadsUsed ?? [];

        if (roads.isEmpty) {
          return Card(
            color: AppColors.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'No road information available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return Card(
          color: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: roads.length,
              itemBuilder: (context, index) {
                final road = roads[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.route,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  title: Text(
                    road.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      if (road.quality != null)
                        _buildRoadRating('Quality', road.quality!),
                      if (road.lighting != null)
                        _buildRoadRating('Lights', road.lighting!),
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
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)}/10',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: value >= 7
                  ? AppColors.secondary
                  : (value >= 4 ? AppColors.accentWarning : AppColors.accentDanger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SOS Button
          ScaleTransition(
            scale: _pulseAnimation,
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isSendingSOS ? null : _triggerSOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentDanger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
                child: _isSendingSOS
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
                            'Sending SOS...',
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
                            Icons.warning_amber,
                            color: AppColors.textWhite,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'EMERGENCY SOS',
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
          ),
          const SizedBox(height: 12),
          // Cancel Button
          TextButton(
            onPressed: _cancelJourney,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text(
              'Cancel Journey',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
