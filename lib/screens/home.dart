import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/models/user_data.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:dio/dio.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<EmergencyContact>? _emergencyContacts;
  String? _userEmail;
  bool _isLoadingData = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserAndContacts();
  }

  Future<void> _loadUserAndContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userid');

      if (userId == null) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
        return;
      }

      setState(() {
        _userId = userId;
      });

      // Fetch user data from API
      await _fetchUserData(userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user: $e')),
        );
      }
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _fetchUserData(int userId) async {
    try {
      final apiClient = DioClient.getApiClient();
      final response = await apiClient.getUserInfo(userId);

      if (response.success && response.data != null) {
        final userData = response.data!;

        setState(() {
          _emergencyContacts = userData.emergencyContact;
          _userEmail = userData.email;
          _isLoadingData = false;
        });
      } else {
        setState(() {
          _isLoadingData = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Error fetching user data')),
          );
        }
      }
    } on DioException catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        String errorMessage = 'Error fetching user data';
        
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timeout. Please check if the backend server is running.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Cannot connect to server. Please ensure backend is running.';
        } else if (e.response != null) {
          final responseData = e.response?.data;
          if (responseData is Map && responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          'Confirm Logout',
          style: TextStyle(color: AppColors.primary),
        ),
        content: Text(
          'Are you sure you want to logout? All data will be deleted.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDanger,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.textWhite),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button from navigating away
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.bgMain,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'WellGaurd AI',
            style: TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textWhite),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: Drawer(
          backgroundColor: AppColors.bgCard,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.secondary,
                      child: const Text(
                        'WG',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'WellGaurd AI',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.warning),
                title: const Text('SOS'),
                iconColor: AppColors.accentWarning,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/sos');
                },
              ),
              ListTile(
                leading: const Icon(Icons.emergency),
                title: const Text('Emergency SOS'),
                iconColor: AppColors.accentDanger,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/emergency_sos');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                iconColor: AppColors.accentDanger,
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Section
                      if (_userEmail != null)
                        Card(
                          color: AppColors.bgCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  radius: 30,
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.textWhite,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your Account',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _userEmail!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Emergency Contact Section
                      Text(
                        'Emergency Contact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _emergencyContacts == null || _emergencyContacts!.isEmpty
                          ? Card(
                              color: AppColors.bgCard,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.contacts_outlined,
                                        size: 48,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No emergency contact set',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: _emergencyContacts!.map((contact) => Card(
                              color: AppColors.bgCard,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors.accentDanger,
                                          radius: 25,
                                          child: Text(
                                            contact.name[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: AppColors.textWhite,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                contact.name,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textMain,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.phone,
                                                    size: 16,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'SMS: ${contact.smsNumber}',
                                                    style: TextStyle(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.chat,
                                                    size: 16,
                                                    color: AppColors.secondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'WhatsApp: ${contact.whatsappNumber}',
                                                    style: TextStyle(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )).toList(),
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
