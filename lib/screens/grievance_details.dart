import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wellguard_ai/theme/colors.dart';
import 'package:wellguard_ai/models/grievance_model.dart';
import 'package:wellguard_ai/constants.dart';

class GrievanceDetailsScreen extends StatefulWidget {
  final Grievance grievance;

  const GrievanceDetailsScreen({super.key, required this.grievance});

  @override
  State<GrievanceDetailsScreen> createState() => _GrievanceDetailsScreenState();
}

class _GrievanceDetailsScreenState extends State<GrievanceDetailsScreen> {
  late final Grievance grievance;
  AudioPlayer? _audioPlayer;
  bool _audioLoading = false;
  String? _audioError;

  @override
  void initState() {
    super.initState();
    grievance = widget.grievance;
    if (grievance.audio != null && grievance.audio!.isNotEmpty) {
      _initAudio();
    }
  }

  String _getAudioUrl(String audioPath) {
    if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
      return audioPath;
    }
    String normalizedPath = audioPath.replaceAll('\\', '/');
    if (normalizedPath.startsWith('/')) {
      normalizedPath = normalizedPath.substring(1);
    }
    return '${AppConstants.fullApiUrl}/$normalizedPath';
  }

  Future<void> _initAudio() async {
    setState(() {
      _audioLoading = true;
      _audioError = null;
    });
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setUrl(_getAudioUrl(grievance.audio!));
    } catch (e) {
      setState(() => _audioError = 'Failed to load audio');
    } finally {
      if (mounted) setState(() => _audioLoading = false);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppColors.accentInfo;
      case 'inprogress':
        return AppColors.accentWarning;
      case 'completed':
        return AppColors.secondary;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.pending_outlined;
      case 'inprogress':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Grievance Submitted';
      case 'inprogress':
        return 'Under Review';
      case 'completed':
        return 'Resolved';
      default:
        return status;
    }
  }

  Widget _buildAudioPlayer() {
    if (grievance.audio == null || grievance.audio!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Audio Recording',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: _audioLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : _audioError != null
                  ? Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.accentDanger, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _audioError!,
                            style: const TextStyle(
                              color: AppColors.accentDanger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _initAudio,
                          child: const Text('Retry',
                              style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    )
                  : StreamBuilder<PlayerState>(
                      stream: _audioPlayer!.playerStateStream,
                      builder: (context, snapshot) {
                        final state = snapshot.data;
                        final isPlaying = state?.playing ?? false;
                        final processingState =
                            state?.processingState ?? ProcessingState.idle;
                        final isCompleted =
                            processingState == ProcessingState.completed;

                        return Row(
                          children: [
                            // Play / Pause button
                            GestureDetector(
                              onTap: () async {
                                if (isCompleted) {
                                  await _audioPlayer!.seek(Duration.zero);
                                  await _audioPlayer!.play();
                                } else if (isPlaying) {
                                  await _audioPlayer!.pause();
                                } else {
                                  await _audioPlayer!.play();
                                }
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                                child: Icon(
                                  isCompleted
                                      ? Icons.replay
                                      : isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                  color: AppColors.textWhite,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Seek bar + time
                            Expanded(
                              child: StreamBuilder<Duration>(
                                stream: _audioPlayer!.positionStream,
                                builder: (context, posSnapshot) {
                                  final position =
                                      posSnapshot.data ?? Duration.zero;
                                  final duration =
                                      _audioPlayer!.duration ?? Duration.zero;
                                  final progress = duration.inMilliseconds > 0
                                      ? (position.inMilliseconds /
                                              duration.inMilliseconds)
                                          .clamp(0.0, 1.0)
                                      : 0.0;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 3,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                  enabledThumbRadius: 7),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                  overlayRadius: 14),
                                          activeTrackColor: AppColors.primary,
                                          inactiveTrackColor:
                                              AppColors.borderLight,
                                          thumbColor: AppColors.primary,
                                          overlayColor: AppColors.primary
                                              .withValues(alpha: 0.2),
                                        ),
                                        child: Slider(
                                          value: progress,
                                          onChanged: (value) {
                                            final seek = Duration(
                                              milliseconds: (value *
                                                      duration.inMilliseconds)
                                                  .round(),
                                            );
                                            _audioPlayer!.seek(seek);
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDuration(position),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            Text(
                                              _formatDuration(duration),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }

  bool _isBase64Image(String? imageData) {
    return imageData != null && imageData.startsWith('data:image');
  }

  Uint8List _decodeBase64Image(String dataUri) {
    final base64Str = dataUri.split(',').last;
    return base64Decode(base64Str);
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    String normalizedPath = imagePath.replaceAll('\\', '/');
    if (normalizedPath.startsWith('/')) {
      normalizedPath = normalizedPath.substring(1);
    }
    return '${AppConstants.fullApiUrl}/$normalizedPath';
  }

  Widget _buildGrievanceImage(String? imageData, {double? height, BoxFit fit = BoxFit.cover}) {
    if (imageData == null || imageData.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isBase64Image(imageData)) {
      try {
        final bytes = _decodeBase64Image(imageData);
        return Image.memory(
          bytes,
          height: height,
          width: double.infinity,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: height,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 8),
                    Text('Failed to load image', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  ],
                ),
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 48, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text('Failed to load image', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              ],
            ),
          ),
        );
      }
    }

    return Image.network(
      _getImageUrl(imageData),
      height: height,
      width: double.infinity,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 48, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text('Failed to load image', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              ],
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(grievance.status);
    final statusIcon = _getStatusIcon(grievance.status);
    final dateFormat = DateFormat('MMM dd, yyyy \'at\' hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Grievance Details',
              style: TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 18, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            grievance.statusDisplay,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    grievance.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Department
                        _buildDetailRow(
                          icon: Icons.business,
                          label: 'Department',
                          value: grievance.departmentName,
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.borderLight),
                        const SizedBox(height: 12),
                        // Date
                        if (grievance.createdAt != null)
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            label: 'Submitted On',
                            value: dateFormat.format(grievance.createdAt!),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description Section
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      grievance.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textMain,
                        height: 1.5,
                      ),
                    ),
                  ),

                  // Audio Section
                  _buildAudioPlayer(),

                  // Image Section (if no sliver image shown)
                  if (grievance.image != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Attachment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showFullImage(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildGrievanceImage(grievance.image, height: 200),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Tap to view full image',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],

                  // Resolution Section (if completed)
                  if (grievance.status == 'completed' &&
                      grievance.resolution != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Resolution',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: AppColors.secondary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Resolved',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            grievance.resolution!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textMain,
                              height: 1.5,
                            ),
                          ),
                          if (grievance.resolvedAt != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Resolved on ${dateFormat.format(grievance.resolvedAt!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Status Timeline
                  const SizedBox(height: 24),
                  const Text(
                    'Status Timeline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusTimeline(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTimeline() {
    final statuses = ['submitted', 'inprogress', 'completed'];
    final currentIndex = statuses.indexOf(grievance.status);

    return Column(
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final isActive = index <= currentIndex;
        final isLast = index == statuses.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? _getStatusColor(status) : AppColors.bgCard,
                    border: Border.all(
                      color: isActive
                          ? _getStatusColor(status)
                          : AppColors.borderLight,
                      width: 2,
                    ),
                  ),
                  child: isActive
                      ? Icon(
                          index < currentIndex
                              ? Icons.check
                              : _getStatusIcon(status),
                          size: 16,
                          color: AppColors.textWhite,
                        )
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 35,
                    color: isActive && index < currentIndex
                        ? _getStatusColor(statuses[index + 1])
                        : AppColors.borderLight,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? AppColors.textMain : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showFullImage(BuildContext context) {
    if (grievance.image == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Attachment',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: InteractiveViewer(
            child: Center(
              child: _buildGrievanceImage(grievance.image, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
