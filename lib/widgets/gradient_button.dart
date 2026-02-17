import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/spacing.dart';
import 'package:wellguard_ai/theme/typography.dart';

/// A modern gradient button with press animation and optional icon
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final double? width;
  final double height;
  final double borderRadius;
  final Widget? icon;
  final bool isLoading;
  final bool enableHaptics;
  final List<BoxShadow>? shadows;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient = AppColors.primaryGradient,
    this.width,
    this.height = AppSpacing.buttonHeightLG,
    this.borderRadius = AppSpacing.radiusMD,
    this.icon,
    this.isLoading = false,
    this.enableHaptics = true,
    this.shadows,
  });

  /// Primary gradient button (cyan/blue)
  factory GradientButton.primary({
    required String text,
    VoidCallback? onPressed,
    double? width,
    Widget? icon,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      gradient: AppColors.primaryGradient,
      width: width,
      icon: icon,
      isLoading: isLoading,
      shadows: [
        BoxShadow(
          color: AppColors.shadowPrimary,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Secondary gradient button (orange)
  factory GradientButton.secondary({
    required String text,
    VoidCallback? onPressed,
    double? width,
    Widget? icon,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      gradient: AppColors.secondaryGradient,
      width: width,
      icon: icon,
      isLoading: isLoading,
      shadows: [
        BoxShadow(
          color: AppColors.shadowSecondary,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Danger gradient button (red)
  factory GradientButton.danger({
    required String text,
    VoidCallback? onPressed,
    double? width,
    Widget? icon,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      gradient: AppColors.dangerGradient,
      width: width,
      icon: icon,
      isLoading: isLoading,
      shadows: [
        BoxShadow(
          color: AppColors.shadowDanger,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Success gradient button (green)
  factory GradientButton.success({
    required String text,
    VoidCallback? onPressed,
    double? width,
    Widget? icon,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      gradient: AppColors.successGradient,
      width: width,
      icon: icon,
      isLoading: isLoading,
      shadows: [
        BoxShadow(
          color: AppColors.accentSuccess.withOpacity(0.4),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      if (widget.enableHaptics) {
        HapticFeedback.lightImpact();
      }
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isDisabled ? 0.6 : 1.0,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: isDisabled ? null : widget.shadows,
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.textWhite,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          AppSpacing.hGapSM,
                        ],
                        Text(
                          widget.text,
                          style: AppTypography.buttonLarge,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small gradient icon button
class GradientIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final double size;
  final double borderRadius;
  final List<BoxShadow>? shadows;
  final bool enableHaptics;

  const GradientIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.gradient = AppColors.primaryGradient,
    this.size = AppSpacing.iconButtonSize,
    this.borderRadius = AppSpacing.radiusMD,
    this.shadows,
    this.enableHaptics = true,
  });

  factory GradientIconButton.primary({
    required Widget icon,
    VoidCallback? onPressed,
    double size = AppSpacing.iconButtonSize,
  }) {
    return GradientIconButton(
      icon: icon,
      onPressed: onPressed,
      gradient: AppColors.primaryGradient,
      size: size,
      shadows: [
        BoxShadow(
          color: AppColors.shadowPrimary,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  factory GradientIconButton.danger({
    required Widget icon,
    VoidCallback? onPressed,
    double size = AppSpacing.iconButtonSize,
  }) {
    return GradientIconButton(
      icon: icon,
      onPressed: onPressed,
      gradient: AppColors.dangerGradient,
      size: size,
      shadows: [
        BoxShadow(
          color: AppColors.shadowDanger,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  State<GradientIconButton> createState() => _GradientIconButtonState();
}

class _GradientIconButtonState extends State<GradientIconButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
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
      onTapDown: (_) {
        if (widget.onPressed != null) _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
      },
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        if (widget.onPressed != null) {
          if (widget.enableHaptics) {
            HapticFeedback.lightImpact();
          }
          widget.onPressed!();
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.shadows,
              ),
              child: Center(child: widget.icon),
            ),
          );
        },
      ),
    );
  }
}

/// Outlined gradient border button
class OutlinedGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final double? width;
  final double height;
  final double borderRadius;
  final double borderWidth;
  final Widget? icon;

  const OutlinedGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient = AppColors.primaryGradient,
    this.width,
    this.height = AppSpacing.buttonHeightLG,
    this.borderRadius = AppSpacing.radiusMD,
    this.borderWidth = 2.0,
    this.icon,
  });

  @override
  State<OutlinedGradientButton> createState() => _OutlinedGradientButtonState();
}

class _OutlinedGradientButtonState extends State<OutlinedGradientButton>
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
      onTapDown: (_) {
        if (widget.onPressed != null) _controller.forward();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        if (widget.onPressed != null) {
          HapticFeedback.lightImpact();
          widget.onPressed!();
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                gradient: widget.gradient,
              ),
              padding: EdgeInsets.all(widget.borderWidth),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgMain,
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius - widget.borderWidth,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        AppSpacing.hGapSM,
                      ],
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            widget.gradient.createShader(bounds),
                        child: Text(
                          widget.text,
                          style: AppTypography.buttonLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
