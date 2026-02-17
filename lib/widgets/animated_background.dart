import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:wellguard_ai/theme/colors.dart';

/// Animated gradient mesh background for login/onboarding screens
class AnimatedGradientBackground extends StatelessWidget {
  final Widget? child;

  const AnimatedGradientBackground({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Container(
          decoration: const BoxDecoration(
            color: AppColors.bgMain,
          ),
        ),
        // Animated blob 1 - Primary color
        Positioned(
          top: -100,
          left: -100,
          child: _AnimatedBlob(
            color: AppColors.primary.withOpacity(0.15),
            size: 400,
            duration: const Duration(seconds: 10),
          ),
        ),
        // Animated blob 2 - Secondary color
        Positioned(
          bottom: -150,
          right: -100,
          child: _AnimatedBlob(
            color: AppColors.secondary.withOpacity(0.1),
            size: 350,
            duration: const Duration(seconds: 12),
            reverse: true,
          ),
        ),
        // Animated blob 3 - Accent
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          left: MediaQuery.of(context).size.width * 0.3,
          child: _AnimatedBlob(
            color: AppColors.primaryDark.withOpacity(0.08),
            size: 250,
            duration: const Duration(seconds: 8),
          ),
        ),
        // Content
        if (child != null) child!,
      ],
    );
  }
}

/// Individual animated blob
class _AnimatedBlob extends StatelessWidget {
  final Color color;
  final double size;
  final Duration duration;
  final bool reverse;

  const _AnimatedBlob({
    required this.color,
    required this.size,
    required this.duration,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return MirrorAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 2 * math.pi),
      duration: duration,
      builder: (context, value, child) {
        final offset = reverse ? -1 : 1;
        return Transform.translate(
          offset: Offset(
            math.sin(value) * 30 * offset,
            math.cos(value) * 20 * offset,
          ),
          child: Transform.scale(
            scale: 1 + math.sin(value) * 0.1,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color,
                    color.withOpacity(0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Simpler gradient background without animations
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: colors ?? [
            AppColors.bgCard.withOpacity(0.5),
            AppColors.bgMain,
          ],
          center: Alignment.topCenter,
          radius: 1.5,
        ),
      ),
      child: child,
    );
  }
}

/// Particle background for special screens
class ParticleBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color particleColor;

  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 30,
    this.particleColor = AppColors.primary,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  void _initParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.001 + 0.0005,
        opacity: _random.nextDouble() * 0.5 + 0.1,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.bgMain),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Update particle positions
            for (var particle in _particles) {
              particle.y -= particle.speed;
              if (particle.y < -0.1) {
                particle.y = 1.1;
                particle.x = _random.nextDouble();
              }
            }

            return CustomPaint(
              painter: ParticlePainter(
                particles: _particles,
                color: widget.particleColor,
              ),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Gradient overlay for images or content
class GradientOverlay extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientOverlay({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors ?? [
                  Colors.transparent,
                  AppColors.bgMain.withOpacity(0.8),
                  AppColors.bgMain,
                ],
                begin: begin,
                end: end,
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
