import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/spacing.dart';
import 'package:wellguard_ai/theme/typography.dart';

/// Modern action card with gradient background and icon
class ActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.gradient = AppColors.primaryGradient,
    this.onTap,
    this.trailing,
  });

  factory ActionCard.primary({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ActionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      gradient: AppColors.primaryGradient,
      onTap: onTap,
    );
  }

  factory ActionCard.secondary({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ActionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      gradient: AppColors.secondaryGradient,
      onTap: onTap,
    );
  }

  factory ActionCard.danger({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ActionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      gradient: AppColors.dangerGradient,
      onTap: onTap,
    );
  }

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: AppSpacing.borderRadiusLG,
                boxShadow: [
                  BoxShadow(
                    color: (widget.gradient.colors.first).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: AppSpacing.cardPaddingLarge,
              child: Row(
                children: [
                  Container(
                    padding: AppSpacing.paddingMD,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: AppSpacing.borderRadiusMD,
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.textWhite,
                      size: AppSpacing.iconXL,
                    ),
                  ),
                  AppSpacing.hGapMD,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textWhite,
                          ),
                        ),
                        AppSpacing.vGapXXS,
                        Text(
                          widget.subtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  widget.trailing ??
                      Container(
                        padding: AppSpacing.paddingXS,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: AppSpacing.borderRadiusSM,
                        ),
                        child: const Icon(
                          Iconsax.arrow_right_3,
                          color: AppColors.textWhite,
                          size: AppSpacing.iconMD,
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Quick action button with neumorphic style
class QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: AppSpacing.borderRadiusMD,
                border: Border.all(
                  color: AppColors.borderLight.withOpacity(0.5),
                ),
                boxShadow: [
                  // Outer shadow (dark - bottom right)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(4, 4),
                  ),
                  // Inner shadow (light - top left)
                  BoxShadow(
                    color: AppColors.bgHover.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(-4, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: AppSpacing.paddingSM,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color.withOpacity(0.2),
                          widget.color.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppSpacing.borderRadiusSM,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: AppSpacing.iconLG,
                    ),
                  ),
                  AppSpacing.vGapSM,
                  Text(
                    widget.label,
                    style: AppTypography.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Stats card for dashboard
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Gradient? gradient;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color = AppColors.primary,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppSpacing.borderRadiusMD,
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: AppSpacing.paddingXS,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppSpacing.borderRadiusSM,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: AppSpacing.iconMD,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) {
                  return (gradient ?? LinearGradient(colors: [color, color]))
                      .createShader(bounds);
                },
                child: Text(
                  value,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapSM,
          Text(
            label,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// User avatar with gradient background
class UserAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;
  final Gradient? gradient;

  const UserAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = AppSpacing.avatarLG,
    this.backgroundColor,
    this.gradient,
  });

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getColorFromName(String name) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accentSuccess,
      AppColors.primaryDark,
      AppColors.secondaryDark,
    ];
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? _getColorFromName(name ?? '');

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(imageUrl!),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient ??
            LinearGradient(
              colors: [bgColor, bgColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textWhite,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}

/// Section header with optional action
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.primary, size: 20),
              AppSpacing.hGapSM,
            ],
            Text(
              title,
              style: AppTypography.titleSmall,
            ),
          ],
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText!,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Status badge
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.icon,
  });

  factory StatusBadge.success(String label) => StatusBadge(
        label: label,
        color: AppColors.accentSuccess,
        icon: Iconsax.tick_circle,
      );

  factory StatusBadge.warning(String label) => StatusBadge(
        label: label,
        color: AppColors.accentWarning,
        icon: Iconsax.warning_2,
      );

  factory StatusBadge.danger(String label) => StatusBadge(
        label: label,
        color: AppColors.accentDanger,
        icon: Iconsax.danger,
      );

  factory StatusBadge.info(String label) => StatusBadge(
        label: label,
        color: AppColors.primary,
        icon: Iconsax.info_circle,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSM,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppSpacing.iconXS,
              color: color,
            ),
            AppSpacing.hGapXXS,
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
