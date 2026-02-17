import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/theme/typography.dart';
import 'package:wellguard_ai/theme/spacing.dart';
import 'package:wellguard_ai/widgets/widgets.dart';
import 'package:wellguard_ai/services/dio_client.dart';
import 'package:wellguard_ai/models/post_model.dart';
import 'package:wellguard_ai/screens/post_detail.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = DioClient.getApiClient();
      final response = await apiClient.getActivePosts();

      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            _posts = response.data!;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.message ?? 'Failed to load posts';
            _isLoading = false;
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        String msg = 'Could not connect to server';
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          msg = 'Connection timed out';
        } else if (e.response != null) {
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            msg = data['message'];
          }
        }
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _errorMessage != null
                          ? _buildErrorState()
                          : _posts.isEmpty
                              ? _buildEmptyState()
                              : _buildPostsList(),
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
              'News Feed',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _fetchPosts();
            },
            child: GlassCard(
              padding: AppSpacing.allSM,
              borderRadius: AppSpacing.radiusMD,
              child: const Icon(Iconsax.refresh, color: AppColors.textMain, size: 24),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: AppSpacing.horizontalLG,
      child: Column(
        children: List.generate(
          3,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SkeletonCard(height: 180),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: AppSpacing.allXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: AppSpacing.allXL,
              decoration: BoxDecoration(
                color: AppColors.accentDanger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.warning_2, size: 48, color: AppColors.accentDanger),
            ),
            AppSpacing.vGapXL,
            Text(
              'Oops!',
              style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapSM,
            Text(
              _errorMessage ?? 'Something went wrong',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapXL,
            GradientButton.primary(
              text: 'Retry',
              onPressed: _fetchPosts,
              icon: const Icon(Iconsax.refresh, color: AppColors.textWhite, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: AppSpacing.allXL,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.document_text, size: 64, color: AppColors.primary),
          ),
          AppSpacing.vGapXL,
          Text(
            'No News Yet',
            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          AppSpacing.vGapSM,
          Padding(
            padding: AppSpacing.horizontalXL,
            child: Text(
              'Stay tuned! Safety alerts and news updates will appear here.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 200.ms).scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
          ),
    );
  }

  Widget _buildPostsList() {
    return RefreshIndicator(
      onRefresh: _fetchPosts,
      color: AppColors.primary,
      backgroundColor: AppColors.bgCard,
      child: AnimationLimiter(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: AppSpacing.horizontalLG,
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPostCard(_posts[index]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      },
      child: GlassCard(
        padding: AppSpacing.allMD,
        borderRadius: AppSpacing.radiusLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: locality badge + time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.location, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        post.locality,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (post.isCurrentlyActive)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.accentSuccess,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  post.timeAgo,
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),

            AppSpacing.vGapMD,

            // Title
            Text(
              post.title,
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            AppSpacing.vGapSM,

            // Description
            Text(
              post.description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Image thumbnail (if available)
            if (post.image != null && post.image!.isNotEmpty) ...[
              AppSpacing.vGapMD,
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                child: Image.network(
                  post.image!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ],

            AppSpacing.vGapMD,

            // Footer: date range + arrow
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgHover,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.calendar_1, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${dateFormat.format(post.startDateTime.toLocal())}  →  ${dateFormat.format(post.endDateTime.toLocal())}',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.hGapSM,
                const Icon(Iconsax.arrow_right_3, size: 18, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
