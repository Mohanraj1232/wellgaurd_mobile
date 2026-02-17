import 'package:flutter/material.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/spacing.dart';

/// A widget that creates a pulsing animation effect, perfect for SOS buttons
class PulsingWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;
  final bool animate;
  final Color? glowColor;
  final double glowRadius;

  const PulsingWidget({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 1.1,
    this.duration = const Duration(milliseconds: 1000),
    this.animate = true,
    this.glowColor,
    this.glowRadius = 20.0,
  });

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.8,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// A circular pulsing ring effect, often used behind SOS buttons
class PulsingRings extends StatefulWidget {
  final double size;
  final Color color;
  final int ringCount;
  final Duration duration;
  final bool animate;
  final Widget? child;

  const PulsingRings({
    super.key,
    this.size = 100.0,
    this.color = AppColors.accentDanger,
    this.ringCount = 3,
    this.duration = const Duration(milliseconds: 2000),
    this.animate = true,
    this.child,
  });

  @override
  State<PulsingRings> createState() => _PulsingRingsState();
}

class _PulsingRingsState extends State<PulsingRings>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(widget.ringCount, (index) {
      return AnimationController(
        duration: widget.duration,
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    if (widget.animate) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (int i = 0; i < widget.ringCount; i++) {
      Future.delayed(Duration(milliseconds: (widget.duration.inMilliseconds ~/ widget.ringCount) * i), () {
        if (mounted && widget.animate) {
          _controllers[i].repeat();
        }
      });
    }
  }

  @override
  void didUpdateWidget(PulsingRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _startAnimations();
      } else {
        for (var controller in _controllers) {
          controller.stop();
          controller.reset();
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(widget.ringCount, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Container(
                  width: widget.size + (widget.size * _animations[index].value),
                  height: widget.size + (widget.size * _animations[index].value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity(1 - _animations[index].value),
                      width: 3,
                    ),
                  ),
                );
              },
            );
          }),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

/// Floating SOS button with pulse animation
class FloatingSosButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;
  final bool showPulse;

  const FloatingSosButton({
    super.key,
    required this.onPressed,
    this.size = 72.0,
    this.showPulse = true,
  });

  @override
  State<FloatingSosButton> createState() => _FloatingSosButtonState();
}

class _FloatingSosButtonState extends State<FloatingSosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    if (widget.showPulse) {
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing background circles
          if (widget.showPulse)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: widget.size * _pulseAnimation.value,
                  height: widget.size * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentDanger.withOpacity(
                      0.3 * (1 - (_pulseAnimation.value - 1) / 0.3),
                    ),
                  ),
                );
              },
            ),
          // Main button
          GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: AppColors.dangerGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDanger,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Breathing animation wrapper for any widget
class BreathingAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scaleAmount;
  final bool animate;

  const BreathingAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.scaleAmount = 0.05,
    this.animate = true,
  });

  @override
  State<BreathingAnimation> createState() => _BreathingAnimationState();
}

class _BreathingAnimationState extends State<BreathingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.0 + widget.scaleAmount,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
