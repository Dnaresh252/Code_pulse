// Create this file: lib/models/app_models.dart
// This prevents the Note class conflict

import 'dart:convert';

// Shared Note Model - Use this everywhere
class Note {
  final String id;
  final String topic;
  final String content;
  final NoteType type;
  final DateTime createdAt;

  Note({
    String? id,
    required this.topic,
    required this.content,
    DateTime? createdAt,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type = _determineNoteType(content),
        createdAt = createdAt ?? DateTime.now();

  static NoteType _determineNoteType(String content) {
    if (content.toLowerCase().contains('youtube.com') ||
        content.toLowerCase().contains('youtu.be')) {
      return NoteType.video;
    } else if (content.toLowerCase().contains('http://') ||
        content.toLowerCase().contains('https://')) {
      return NoteType.link;
    }
    return NoteType.text;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      topic: json['topic'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

enum NoteType { text, video, link }

// YouTube Video Model
class YoutubeVideo {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final String description;

  YoutubeVideo({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    this.description = '',
  });

  String get videoUrl => 'https://youtube.com/watch?v=$videoId';

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'channelTitle': channelTitle,
      'description': description,
    };
  }

  factory YoutubeVideo.fromJson(Map<String, dynamic> json) {
    return YoutubeVideo(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      channelTitle: json['channelTitle'] ?? '',
      description: json['description'] ?? '',
    );
  }

  // Convert to Note for saving
  Note toNote() {
    return Note(
      topic: title,
      content: '''$videoUrl

📹 Video from: $channelTitle
📚 Saved for studying

💡 My Notes:
• Key points from the video
• Important concepts
• Things to remember

📝 Description:
${description.isNotEmpty ? description : 'No description available'}''',
    );
  }
}