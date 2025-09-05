// services/youtube_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

class YoutubeService {
  static const _apiKey = "Paste your api key"; // Your API key

  // ONLY inappropriate content keywords that students should not access
  static const List<String> _blockedKeywords = [
    // Adult/Sexual content
    'adult', 'porn', 'sex', 'xxx', 'nude', 'naked', 'explicit', 'nsfw',
    'mature', 'erotic', 'intimate', 'seductive', 'sensual', 'sexual',
    'pornography', 'strip', 'lingerie', 'fetish', 'bdsm', 'escort',
    'hot girls', 'sexy', 'provocative', 'adult content', 'not safe for work',
    '18+', 'adults only', 'mature content', 'sexual content',

    // Violence and harmful content
    'violence', 'violent', 'fight', 'blood', 'kill', 'death', 'murder',
    'weapon', 'gun', 'knife', 'shooting', 'terrorism', 'bomb',

    // Drugs and substance abuse
    'drugs', 'cocaine', 'heroin', 'marijuana', 'weed', 'smoking', 'alcohol',
    'drunk', 'drinking', 'beer', 'wine', 'vodka', 'drug dealer',

    // Gambling and inappropriate activities
    'gambling', 'casino', 'poker', 'betting', 'lottery',

    // Hate speech and inappropriate behavior
    'hate speech', 'racist', 'discrimination', 'bullying', 'harassment',

    // Other inappropriate content
    'suicide', 'self harm', 'depression help', 'cutting', 'anorexia',
    'illegal', 'crime', 'steal', 'robbery', 'fraud'
  ];

  // Main method for fetching videos with safety filtering
  static Future<List<YoutubeVideo>> fetchVideos(String query) async {
    // Only sanitize the query (remove inappropriate terms)
    final safeQuery = _sanitizeQuery(query);

    final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?'
            'part=snippet&'
            'type=video&'
            'maxResults=15&'
            'safeSearch=strict&' // YouTube's built-in safe search
            'relevanceLanguage=en&'
            'order=relevance&'
            'q=${Uri.encodeComponent(safeQuery)}&'
            'key=$_apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List<dynamic>? ?? [];

      // Convert to YoutubeVideo objects
      final videos = items.map((item) => YoutubeVideo.fromJson(item)).toList();

      // Apply ONLY safety content filtering (remove inappropriate content)
      final safeVideos = _filterInappropriateContent(videos);

      // Return top 10 safe videos (no educational scoring, just safety)
      return safeVideos.take(10).toList();
    } else {
      throw Exception('YouTube API error: ${response.statusCode}');
    }
  }

  // Sanitize query to remove inappropriate terms only
  static String _sanitizeQuery(String query) {
    String sanitized = query.toLowerCase().trim();

    // Remove ONLY blocked inappropriate keywords
    for (String keyword in _blockedKeywords) {
      sanitized = sanitized.replaceAll(keyword, '');
    }

    // Clean up extra spaces
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();

    // If query becomes empty after sanitization, use original query
    return sanitized.isEmpty ? query : sanitized;
  }

  // Filter videos to remove ONLY inappropriate content
  static List<YoutubeVideo> _filterInappropriateContent(List<YoutubeVideo> videos) {
    return videos.where((video) {
      return _isVideoAppropriate(video);
    }).toList();
  }

  // Check if video is appropriate (NO inappropriate content)
  static bool _isVideoAppropriate(YoutubeVideo video) {
    final title = video.title.toLowerCase();
    final description = video.description.toLowerCase();
    final channelTitle = video.channelTitle.toLowerCase();

    // Check for blocked inappropriate keywords ONLY
    for (String keyword in _blockedKeywords) {
      if (title.contains(keyword) ||
          description.contains(keyword) ||
          channelTitle.contains(keyword)) {
        return false;
      }
    }

    return true;
  }

  // Backwards compatibility methods (no changes to functionality)
  static Future<List<YoutubeVideo>> fetchCodingVideos(String query) async {
    return fetchVideos(query);
  }

  static Future<List<YoutubeVideo>> fetchLanguageSpecificVideos(String language, String topic) async {
    final query = '$language $topic';
    return fetchVideos(query);
  }

  static Future<List<YoutubeVideo>> fetchTrendingCodingVideos() async {
    return fetchVideos('trending');
  }
}
