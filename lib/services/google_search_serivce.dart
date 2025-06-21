import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/google_search_result.dart';

class GoogleSearchService {
  static const _apiKey = 'AIzaSyByK2SI5e10K2xfkvDXjLFGCMaiz1DqtJ4';
  static const _cseId = '92c5d6361bac64d85'; // Add your Custom Search Engine ID

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

  static Future<List<GoogleSearchResult>> fetchGoogleLinks(String query) async {
    // Check if query contains inappropriate content
    if (_containsInappropriateContent(query)) {
      throw Exception('Inappropriate search content detected');
    }

    // Only sanitize the query (remove inappropriate terms)
    final safeQuery = _sanitizeQuery(query);

    final url = Uri.parse(
        'https://www.googleapis.com/customsearch/v1?'
            'key=$_apiKey&'
            'cx=$_cseId&'
            'q=${Uri.encodeComponent(safeQuery)}&'
            'num=10&'
            'safe=active&' // Enable Google SafeSearch
            'filter=1' // Remove duplicate content
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List<dynamic>? ?? [];

      // Convert to GoogleSearchResult objects
      final results = items
          .map((item) => GoogleSearchResult.fromJson(item))
          .toList();

      // Apply ONLY safety filtering (remove inappropriate content)
      final safeResults = _filterInappropriateContent(results);

      // Return top 5 safe results (no educational scoring, just safety)
      return safeResults.take(5).toList();
    } else {
      throw Exception('Google Search API error: ${response.statusCode}');
    }
  }

  // Check if query contains inappropriate content
  static bool _containsInappropriateContent(String query) {
    final searchQuery = query.toLowerCase().trim();

    for (String keyword in _blockedKeywords) {
      if (searchQuery.contains(keyword)) {
        return true;
      }
    }
    return false;
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

  // Filter search results to remove ONLY inappropriate content
  static List<GoogleSearchResult> _filterInappropriateContent(List<GoogleSearchResult> results) {
    return results.where((result) {
      return _isResultAppropriate(result);
    }).toList();
  }

  // Check if search result is appropriate (NO inappropriate content)

  static bool _isResultAppropriate(GoogleSearchResult result) {
    final title = result.title.toLowerCase();
    final link = result.link.toLowerCase();

    // Check for blocked inappropriate keywords in title and link only
    for (String keyword in _blockedKeywords) {
      if (title.contains(keyword) || link.contains(keyword)) {
        return false;
      }
    }

    return true;
  }
}