import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/spacing.dart';

/// A shimmer loading effect wrapper
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor = const Color(0xFF1A2332),
    this.highlightColor = const Color(0xFF243044),
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

/// Skeleton box for loading states
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16.0,
    this.borderRadius = AppSpacing.radiusSM,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton circle for avatars
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({
    super.key,
    this.size = AppSpacing.avatarLG,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton card matching the app's card style
class SkeletonCard extends StatelessWidget {
  final double? height;
  final EdgeInsetsGeometry? margin;

  const SkeletonCard({
    super.key,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height,
        margin: margin,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppSpacing.borderRadiusLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonCircle(size: AppSpacing.avatarMD),
                AppSpacing.hGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(width: 120, height: 16),
                      AppSpacing.vGapXS,
                      SkeletonBox(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMD,
            const SkeletonBox(height: 14),
            AppSpacing.vGapXS,
            const SkeletonBox(width: 200, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for list items
class SkeletonListItem extends StatelessWidget {
  final bool showAvatar;
  final bool showSubtitle;
  final bool showTrailing;

  const SkeletonListItem({
    super.key,
    this.showAvatar = true,
    this.showSubtitle = true,
    this.showTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: AppSpacing.listItemPadding,
        child: Row(
          children: [
            if (showAvatar) ...[
              const SkeletonCircle(size: AppSpacing.avatarMD),
              AppSpacing.hGapMD,
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 140, height: 16),
                  if (showSubtitle) ...[
                    AppSpacing.vGapXS,
                    SkeletonBox(width: 100, height: 12),
                  ],
                ],
              ),
            ),
            if (showTrailing) const SkeletonBox(width: 60, height: 32),
          ],
        ),
      ),
    );
  }
}

/// Skeleton list for multiple items
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final bool showAvatar;
  final bool showSubtitle;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.showAvatar = true,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => AppSpacing.vGapSM,
      itemBuilder: (context, index) {
        return SkeletonListItem(
          showAvatar: showAvatar,
          showSubtitle: showSubtitle,
        );
      },
    );
  }
}

/// Skeleton for the home screen user card
class SkeletonUserCard extends StatelessWidget {
  const SkeletonUserCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppSpacing.borderRadiusLG,
        ),
        child: Row(
          children: [
            const SkeletonCircle(size: AppSpacing.avatarXL),
            AppSpacing.hGapMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 140, height: 18),
                  AppSpacing.vGapXS,
                  const SkeletonBox(width: 100, height: 14),
                  AppSpacing.vGapXS,
                  SkeletonBox(width: 180, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for journey card
class SkeletonJourneyCard extends StatelessWidget {
  const SkeletonJourneyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppSpacing.borderRadiusLG,
        ),
        child: Row(
          children: [
            const SkeletonCircle(size: AppSpacing.avatarLG),
            AppSpacing.hGapMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 160, height: 20),
                  AppSpacing.vGapXS,
                  SkeletonBox(width: 200, height: 14),
                ],
              ),
            ),
            const SkeletonBox(width: 20, height: 20),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for statistics dashboard
class SkeletonStats extends StatelessWidget {
  const SkeletonStats({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: AppSpacing.borderRadiusMD,
              ),
              child: Column(
                children: [
                  const SkeletonBox(width: 40, height: 24),
                  AppSpacing.vGapXS,
                  SkeletonBox(width: 60, height: 12),
                ],
              ),
            ),
          ),
          AppSpacing.hGapMD,
          Expanded(
            child: Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: AppSpacing.borderRadiusMD,
              ),
              child: Column(
                children: [
                  const SkeletonBox(width: 40, height: 24),
                  AppSpacing.vGapXS,
                  SkeletonBox(width: 60, height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
