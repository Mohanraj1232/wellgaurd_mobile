import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:wellguard_ai/providers/journey_provider.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  bool _isLoading = false;
  bool _sosSent = false;
  String? _errorMessage;
  int _notificationsSent = 0;

  @override
  void initState() {
    super.initState();
    _triggerEmergencySOS();
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
        appBar: AppBar(
          backgroundColor: AppColors.accentDanger,
          elevation: 0,
          title: const Text(
            'Emergency SOS',
            style: TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildSuccessState(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentDanger.withOpacity(0.1),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.accentDanger,
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Sending Emergency SOS...',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Please wait while we alert your emergency contacts and services.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentDanger.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.accentDanger,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Emergency SOS Failed',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            _errorMessage ?? 'An error occurred',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 140,
              height: 50,
              child: ElevatedButton(
                onPressed: _triggerEmergencySOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentDanger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentDanger.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.emergency,
            size: 80,
            color: AppColors.accentDanger,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Emergency SOS Triggered',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'An EMERGENCY alert has been sent to all your emergency contacts with your location.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (_notificationsSent > 0) ...[
          const SizedBox(height: 12),
          Text(
            'Notifications sent: $_notificationsSent',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.secondary,
            ),
          ),
        ],
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.accentDanger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentDanger),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_rounded,
                color: AppColors.accentDanger,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Emergency services have been notified.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.accentDanger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: 200,
          height: 60,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
