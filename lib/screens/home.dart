import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/typography.dart';
import 'package:wellguard_ai/theme/spacing.dart';
import 'package:wellguard_ai/models/user_data.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:wellguard_ai/screens/emergency_contacts.dart';
import 'package:wellguard_ai/widgets/widgets.dart';
import 'package:dio/dio.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<EmergencyContact>? _emergencyContacts;
  String? _userName;
  String? _userEmail;
  bool _isLoadingData = true;
  int? _userId;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserAndContacts();
  }
  
  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
  
  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
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
          _userName = userData.name;
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        ),
        title: Row(
          children: [
            Container(
              padding: AppSpacing.allSM,
              decoration: BoxDecoration(
                color: AppColors.accentDanger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              child: const Icon(Iconsax.logout, color: AppColors.accentDanger, size: 20),
            ),
            AppSpacing.hGapMD,
            Text('Logout', style: AppTypography.titleLarge),
          ],
        ),
        content: Text(
          'Are you sure you want to logout? You\'ll need to sign in again to access your account.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                
                // Clear token from DioClient
                DioClient.clearToken();

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
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            ),
            child: Text('Logout', style: AppTypography.labelLarge.copyWith(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.bgMain,
        extendBodyBehindAppBar: true,
        drawer: _buildModernDrawer(),
        body: Stack(
          children: [
            // Animated gradient background
            const AnimatedGradientBackground(),
            
            // Main content
            SafeArea(
              child: _isLoadingData
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildLoadingState(),
                    )
                  : _buildMainContent(),
            ),
            
            // Floating Chatbot button
            Positioned(
              bottom: AppSpacing.xl,
              right: AppSpacing.lg,
              child: _buildFloatingChatbot(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Padding(
      padding: AppSpacing.allLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.vGapXL,
          const SkeletonBox(width: 200, height: 32),
          AppSpacing.vGapSM,
          const SkeletonBox(width: 150, height: 20),
          AppSpacing.vGapXL,
          const SkeletonCard(height: 180),
          AppSpacing.vGapLG,
          const SkeletonCard(height: 120),
          AppSpacing.vGapLG,
          Row(
            children: [
              const Expanded(child: SkeletonCard(height: 100)),
              AppSpacing.hGapMD,
              const Expanded(child: SkeletonCard(height: 100)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Custom App Bar
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        
        // Content
        SliverPadding(
          padding: AppSpacing.horizontalLG,
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              AppSpacing.vGapMD,
              _buildGrievanceCard()
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideY(begin: 0.2, end: 0),
              AppSpacing.vGapLG,
              _buildJourneyCard()
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 300.ms)
                  .slideY(begin: 0.2, end: 0),
              AppSpacing.vGapXL,
              _buildQuickActionsSection()
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 400.ms)
                  .slideY(begin: 0.2, end: 0),
              AppSpacing.vGapXL,
              _buildSafetyTipsSection()
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 500.ms)
                  .slideY(begin: 0.2, end: 0),
              // Bottom spacing for floating button
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: AppSpacing.allLG,
      child: Row(
        children: [
          // Menu button
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: GlassCard(
              padding: AppSpacing.allSM,
              borderRadius: AppSpacing.radiusMD,
              child: const Icon(Iconsax.menu_1, color: AppColors.textMain, size: 24),
            ),
          ),
          AppSpacing.hGapMD,
          // Greeting & user info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_getGreetingIcon(), style: const TextStyle(fontSize: 18)),
                    AppSpacing.hGapXS,
                    Text(
                      _getGreeting(),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Text(
                  _userName ?? 'User',
                  style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideX(begin: -0.2, end: 0),
          ),
          // User avatar
          GestureDetector(
            onTap: () {
              // Profile action
            },
            child: UserAvatar(
              name: _userName ?? 'U',
              size: 48,
              gradient: AppColors.primaryGradient,
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
        ],
      ),
    );
  }
  
  Widget _buildJourneyCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pushNamed('/location_entry');
      },
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: AppSpacing.radiusXL,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.3),
                AppColors.primary.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
          ),
          padding: AppSpacing.allLG,
          child: Row(
            children: [
              Container(
                padding: AppSpacing.allMD,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                ),
                child: const Icon(
                  Iconsax.routing,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              AppSpacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start New Journey',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    AppSpacing.vGapXS,
                    Text(
                      'Track your trip with real-time safety monitoring',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: AppSpacing.allSM,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: const Icon(
                  Iconsax.arrow_right_3,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildJourneyFeature(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 14),
        AppSpacing.hGapXS,
        Text(
          label,
          style: AppTypography.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
  
  Widget _buildGrievanceCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pushNamed('/greivance');
      },
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Iconsax.message_question,
                size: 150,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            // Content
            Padding(
              padding: AppSpacing.allXL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: AppSpacing.allMD,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                        ),
                        child: const Icon(
                          Iconsax.message_question,
                          color: AppColors.textWhite,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.shield_tick, color: AppColors.textWhite, size: 14),
                              AppSpacing.hGapXS,
                              Flexible(
                                child: Text(
                                  'Report & Resolve',
                                  style: AppTypography.caption.copyWith(color: AppColors.textWhite),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapLG,
                  Text(
                    'Raise Grievance',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.vGapXS,
                  Text(
                    'Report an issue or request assistance',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  AppSpacing.vGapLG,
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _buildJourneyFeature(Iconsax.message_text, 'File Report'),
                      _buildJourneyFeature(Iconsax.timer_1, 'Quick Response'),
                      _buildJourneyFeature(Iconsax.tick_circle, 'Track Status'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Quick Actions',
          icon: Iconsax.flash_1,
        ),
        AppSpacing.vGapMD,
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            _buildQuickActionCard(
              icon: Iconsax.call,
              label: 'Emergency',
              subtitle: 'Quick SOS',
              color: AppColors.accentDanger,
              onTap: () => Navigator.of(context).pushNamed('/emergency_sos'),
            ),
            _buildQuickActionCard(
              icon: Iconsax.activity,
              label: 'News Feed',
              subtitle: 'Latest updates',
              color: AppColors.accentInfo,
              onTap: () => Navigator.of(context).pushNamed('/news_feed'),
            ),
            _buildQuickActionCard(
              icon: Iconsax.people,
              label: 'Contacts',
              subtitle: '${_emergencyContacts?.length ?? 0} saved',
              color: AppColors.secondary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EmergencyContactsScreen(
                    contacts: _emergencyContacts ?? [],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        borderRadius: AppSpacing.radiusLG,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSafetyTipsSection() {
    final tips = [
      {'icon': Iconsax.shield_tick, 'text': 'Share your live location with trusted contacts'},
      {'icon': Iconsax.timer_1, 'text': 'Set journey time limits for extra safety'},
      {'icon': Iconsax.call, 'text': 'Keep emergency contacts updated'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Safety Tips',
          icon: Iconsax.lamp_on,
        ),
        AppSpacing.vGapMD,
        GlassCard(
          padding: AppSpacing.allMD,
          borderRadius: AppSpacing.radiusLG,
          child: Column(
            children: tips.asMap().entries.map((entry) {
              final tip = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: entry.key < tips.length - 1 ? AppSpacing.sm : 0),
                child: Row(
                  children: [
                    Container(
                      padding: AppSpacing.allXS,
                      decoration: BoxDecoration(
                        color: AppColors.accentSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                      child: Icon(
                        tip['icon'] as IconData,
                        color: AppColors.accentSuccess,
                        size: 16,
                      ),
                    ),
                    AppSpacing.hGapMD,
                    Expanded(
                      child: Text(
                        tip['text'] as String,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFloatingChatbot() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pushNamed('/chat');
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.smart_toy_rounded,
              color: AppColors.textWhite,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: AppSpacing.allXL,
                child: Column(
                  children: [
                    UserAvatar(
                      name: _userName ?? 'U',
                      size: 80,
                      gradient: AppColors.primaryGradient,
                    ),
                    AppSpacing.vGapMD,
                    Text(
                      _userName ?? 'User',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    AppSpacing.vGapXS,
                    Text(
                      _userEmail ?? '',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    AppSpacing.vGapMD,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.accentSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(color: AppColors.accentSuccess.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accentSuccess,
                              shape: BoxShape.circle,
                            ),
                          ),
                          AppSpacing.hGapSM,
                          Text(
                            'Protected',
                            style: AppTypography.caption.copyWith(color: AppColors.accentSuccess),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(color: AppColors.borderLight.withValues(alpha: 0.3)),
              
              // Menu items
              Expanded(
                child: ListView(
                  padding: AppSpacing.allMD,
                  children: [
                    _buildDrawerItem(
                      icon: Iconsax.home_2,
                      label: 'Home',
                      isSelected: true,
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      icon: Iconsax.call,
                      label: 'Emergency SOS',
                      color: AppColors.accentDanger,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/emergency_sos');
                      },
                    ),
                    _buildDrawerItem(
                      icon: Iconsax.people,
                      label: 'Emergency Contacts',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EmergencyContactsScreen(
                              contacts: _emergencyContacts ?? [],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    _buildDrawerItem(
                      icon: Iconsax.document_text,
                      label: 'News Feed',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/news_feed');
                      },
                    ),
                    
                  ],
                ),
              ),
              
              // Logout
              Padding(
                padding: AppSpacing.allMD,
                child: _buildDrawerItem(
                  icon: Iconsax.logout,
                  label: 'Logout',
                  color: AppColors.accentDanger,
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                ),
              ),
              
              // Footer
              Padding(
                padding: AppSpacing.allMD,
                child: Column(
                  children: [
                    Text(
                      'GrievX',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
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
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    Color? color,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    final itemColor = color ?? AppColors.textMain;
    return Padding(
      padding: AppSpacing.verticalXS,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          child: Container(
            padding: AppSpacing.allMD,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
            ),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? AppColors.primary : itemColor, size: 22),
                AppSpacing.hGapMD,
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? AppColors.primary : itemColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
