import 'package:json_annotation/json_annotation.dart';

part 'post_model.g.dart';

@JsonSerializable()
class Post {
  @JsonKey(name: '_id')
  final String id;
  final String title;
  final String description;
  final String? image;
  final String locality;
  final bool isActive;
  final String startTime;
  final String endTime;
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  Post({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    required this.locality,
    required this.isActive,
    required this.startTime,
    required this.endTime,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);

  DateTime get startDateTime => DateTime.parse(startTime);
  DateTime get endDateTime => DateTime.parse(endTime);
  DateTime get createdAtDateTime => DateTime.parse(createdAt);

  /// Returns true if the post is currently within its active time window
  bool get isCurrentlyActive {
    final now = DateTime.now().toUtc();
    return now.isAfter(startDateTime) && now.isBefore(endDateTime);
  }

  /// Returns a human-readable relative time string
  String get timeAgo {
    final now = DateTime.now().toUtc();
    final diff = now.difference(createdAtDateTime);

    if (diff.inDays > 7) {
      return '${(diff.inDays / 7).floor()}w ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
