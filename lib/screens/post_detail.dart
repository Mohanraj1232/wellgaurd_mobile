import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/typography.dart';
import 'package:wellguard_ai/theme/spacing.dart';
import 'package:wellguard_ai/widgets/widgets.dart';
import 'package:wellguard_ai/models/post_model.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: AppSpacing.horizontalLG,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSpacing.vGapMD,

                        // Status + locality row
                        _buildStatusRow()
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 100.ms)
                            .slideY(begin: 0.1, end: 0),

                        AppSpacing.vGapLG,

                        // Title
                        Text(
                          post.title,
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 200.ms)
                            .slideY(begin: 0.1, end: 0),

                        AppSpacing.vGapSM,

                        // Posted time
                        Row(
                          children: [
                            const Icon(Iconsax.clock, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'Posted ${post.timeAgo}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 250.ms),

                        AppSpacing.vGapXL,

                        // Image
                        if (post.image != null && post.image!.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                            child: Image.network(
                              post.image!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: double.infinity,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    color: AppColors.bgHover,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: AppColors.bgHover,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Iconsax.gallery_slash, color: AppColors.textMuted, size: 40),
                                      SizedBox(height: 8),
                                      Text(
                                        'Image not available',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 300.ms)
                              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                          AppSpacing.vGapXL,
                        ],

                        // Description section
                        GlassCard(
                          padding: AppSpacing.allMD,
                          borderRadius: AppSpacing.radiusLG,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: AppSpacing.allXS,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                                    ),
                                    child: const Icon(Iconsax.document_text, size: 18, color: AppColors.primary),
                                  ),
                                  AppSpacing.hGapSM,
                                  Text(
                                    'Description',
                                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              AppSpacing.vGapMD,
                              Text(
                                post.description,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 400.ms)
                            .slideY(begin: 0.1, end: 0),

                        AppSpacing.vGapLG,

                        // Time details card
                        GlassCard(
                          padding: AppSpacing.allMD,
                          borderRadius: AppSpacing.radiusLG,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: AppSpacing.allXS,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentWarning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                                    ),
                                    child: const Icon(Iconsax.calendar_1, size: 18, color: AppColors.accentWarning),
                                  ),
                                  AppSpacing.hGapSM,
                                  Text(
                                    'Schedule',
                                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              AppSpacing.vGapMD,
                              _buildTimeRow(
                                label: 'Starts',
                                value: dateFormat.format(post.startDateTime.toLocal()),
                                icon: Iconsax.play_circle,
                                color: AppColors.accentSuccess,
                              ),
                              AppSpacing.vGapMD,
                              _buildTimeRow(
                                label: 'Ends',
                                value: dateFormat.format(post.endDateTime.toLocal()),
                                icon: Iconsax.stop_circle,
                                color: AppColors.accentDanger,
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 500.ms)
                            .slideY(begin: 0.1, end: 0),

                        // Bottom padding
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              'Post Detail',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        // Locality badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.location, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                post.locality,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.hGapSM,
        // Active status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: post.isCurrentlyActive
                ? AppColors.accentSuccess.withValues(alpha: 0.15)
                : AppColors.textMuted.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: post.isCurrentlyActive
                  ? AppColors.accentSuccess.withValues(alpha: 0.3)
                  : AppColors.textMuted.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: post.isCurrentlyActive ? AppColors.accentSuccess : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                post.isCurrentlyActive ? 'Active' : 'Inactive',
                style: AppTypography.labelMedium.copyWith(
                  color: post.isCurrentlyActive ? AppColors.accentSuccess : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        AppSpacing.hGapSM,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
