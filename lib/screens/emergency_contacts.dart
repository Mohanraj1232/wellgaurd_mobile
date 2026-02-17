import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/typography.dart';
import 'package:wellguard_ai/theme/spacing.dart';
import 'package:wellguard_ai/models/user_data.dart';
import 'package:wellguard_ai/widgets/widgets.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final List<EmergencyContact> contacts;

  const EmergencyContactsScreen({
    super.key,
    required this.contacts,
  });

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  
  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  Future<void> _sendSMS(String number) async {
    final uri = Uri.parse('sms:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  Future<void> _openWhatsApp(String number) async {
    // Remove any non-digit characters and add country code if needed
    final cleanNumber = number.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background
          const AnimatedGradientBackground(),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Content
                Expanded(
                  child: widget.contacts.isEmpty
                      ? _buildEmptyState()
                      : _buildContactsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: AppSpacing.allLG,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: GlassCard(
              padding: AppSpacing.allSM,
              borderRadius: AppSpacing.radiusMD,
              child: const Icon(Iconsax.arrow_left, color: AppColors.textMain, size: 24),
            ),
          ),
          AppSpacing.hGapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Contacts',
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.contacts.length} contact${widget.contacts.length != 1 ? 's' : ''} saved',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: AppSpacing.allSM,
            decoration: BoxDecoration(
              color: AppColors.accentDanger.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusMD,
            ),
            child: const Icon(Iconsax.people, color: AppColors.accentDanger, size: 24),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.bgGlass,
              borderRadius: AppSpacing.borderRadiusRound,
            ),
            child: const Icon(
              Iconsax.user_remove,
              size: 60,
              color: AppColors.textMuted,
            ),
          ),
          AppSpacing.vGapLG,
          Text(
            'No Emergency Contacts',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          AppSpacing.vGapSM,
          Text(
            'Add contacts to receive alerts\nduring emergencies',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }
  
  Widget _buildContactsList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: AppSpacing.allLG,
        itemCount: widget.contacts.length,
        itemBuilder: (context, index) {
          final contact = widget.contacts[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildContactCard(contact, index),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildContactCard(EmergencyContact contact, int index) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accentDanger,
      AppColors.accentWarning,
    ];
    final color = colors[index % colors.length];
    
    return Padding(
      padding: AppSpacing.bottomMD,
      child: GlassCard(
        padding: AppSpacing.allMD,
        borderRadius: AppSpacing.radiusXL,
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      contact.name[0].toUpperCase(),
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                AppSpacing.hGapMD,
                // Contact info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AppSpacing.vGapXS,
                      Row(
                        children: [
                          Container(
                            padding: AppSpacing.horizontalSM + AppSpacing.verticalXS,
                            decoration: BoxDecoration(
                              color: AppColors.accentSuccess.withValues(alpha: 0.1),
                              borderRadius: AppSpacing.borderRadiusSM,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Iconsax.call, size: 12, color: AppColors.accentSuccess),
                                AppSpacing.hGapXS,
                                Text(
                                  contact.smsNumber ?? 'N/A',
                                  style: AppTypography.caption.copyWith(color: AppColors.accentSuccess),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMD,
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Iconsax.call,
                    label: 'Call',
                    color: AppColors.accentSuccess,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _makeCall(contact.smsNumber ?? '');
                    },
                  ),
                ),
                AppSpacing.hGapSM,
                Expanded(
                  child: _buildActionButton(
                    icon: Iconsax.message,
                    label: 'SMS',
                    color: AppColors.primary,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _sendSMS(contact.smsNumber ?? '');
                    },
                  ),
                ),
                AppSpacing.hGapSM,
                Expanded(
                  child: _buildActionButton(
                    icon: Iconsax.send_2,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _openWhatsApp(contact.whatsappNumber ?? '');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.verticalSM,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppSpacing.borderRadiusMD,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            AppSpacing.vGapXS,
            Text(
              label,
              style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
