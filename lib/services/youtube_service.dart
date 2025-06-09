import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

class YoutubeService {
  static const _apiKey = 'AIzaSyC3VBd9eJ9q6HmkiFyhtRIptiLvf3dra6k';

  static Future<List<YoutubeVideo>> fetchVideos(String query) async {
    final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=10&q=${Uri.encodeComponent(query)}&key=$_apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List<dynamic>? ?? [];
      return items.map((item) => YoutubeVideo.fromJson(item)).toList();
    } else {
      throw Exception('YouTube API error: ${response.statusCode}');
    }
  }
}