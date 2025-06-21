// models/youtube_video.dart
class YoutubeVideo {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String description;
  final String channelTitle;
  final String channelId;
  final String publishedAt;
  final int? viewCount;
  final String duration;

  YoutubeVideo({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.description,
    required this.channelTitle,
    required this.channelId,
    required this.publishedAt,
    this.viewCount,
    required this.duration,
  });

  factory YoutubeVideo.fromJson(Map<String, dynamic> json) {
    return YoutubeVideo(
      videoId: json['id']['videoId'] ?? '',
      title: json['snippet']['title'] ?? '',
      thumbnailUrl: json['snippet']['thumbnails']['medium']['url'] ??
          json['snippet']['thumbnails']['default']['url'] ?? '',
      description: json['snippet']['description'] ?? '',
      channelTitle: json['snippet']['channelTitle'] ?? '',
      channelId: json['snippet']['channelId'] ?? '',
      publishedAt: json['snippet']['publishedAt'] ?? '',
      viewCount: json['statistics']?['viewCount'] != null
          ? int.tryParse(json['statistics']['viewCount'].toString())
          : null,
      duration: json['contentDetails']?['duration'] ?? '',
    );
  }

  // Helper methods for content analysis
  bool get isShortForm => duration.isNotEmpty &&
      (duration.contains('PT') && !duration.contains('M') &&
          int.tryParse(duration.replaceAll(RegExp(r'[^0-9]'), '')) != null &&
          int.parse(duration.replaceAll(RegExp(r'[^0-9]'), '')) < 60);

  bool get isLongForm => duration.isNotEmpty &&
      (duration.contains('H') ||
          (duration.contains('M') &&
              int.tryParse(duration.split('M')[0].replaceAll(RegExp(r'[^0-9]'), '')) != null &&
              int.parse(duration.split('M')[0].replaceAll(RegExp(r'[^0-9]'), '')) > 20));

  // Get formatted duration
  String get formattedDuration {
    if (duration.isEmpty) return '';

    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(duration);

    if (match == null) return '';

    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

