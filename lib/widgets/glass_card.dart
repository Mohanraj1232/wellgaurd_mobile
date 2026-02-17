import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/spacing.dart';

/// A glassmorphic card widget with blur effect, gradient overlay, and subtle border glow
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurAmount;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool showGlow;
  final Color? glowColor;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppSpacing.radiusLG,
    this.blurAmount = 10.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.showGlow = true,
    this.glowColor,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = glowColor ?? AppColors.primary.withOpacity(0.1);
    final effectiveBorderColor = borderColor ?? AppColors.borderGlass;
    final effectiveBackgroundColor = backgroundColor ?? AppColors.bgGlass;

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (showGlow)
            BoxShadow(
              color: effectiveGlowColor,
              blurRadius: 20,
              spreadRadius: 0,
            ),
          BoxShadow(
            color: AppColors.shadowDark.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            padding: padding ?? AppSpacing.cardPadding,
            decoration: BoxDecoration(
              gradient: gradient ?? LinearGradient(
                colors: [
                  effectiveBackgroundColor,
                  effectiveBackgroundColor.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: effectiveBorderColor,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// A glass card with primary color accent glow
class PrimaryGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const PrimaryGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppColors.shadowPrimary,
      borderColor: AppColors.primary.withOpacity(0.3),
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

/// A glass card with danger color accent glow for emergency elements
class DangerGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const DangerGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppColors.shadowDanger,
      borderColor: AppColors.accentDanger.withOpacity(0.3),
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

/// A glass card with secondary/orange color accent glow
class SecondaryGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const SecondaryGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppColors.shadowSecondary,
      borderColor: AppColors.secondary.withOpacity(0.3),
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

/// A simple glass container without the card styling
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurAmount;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = AppSpacing.radiusMD,
    this.blurAmount = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.bgGlass,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppColors.borderGlass,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
