import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/google_search_result.dart';

class GoogleSearchService {
  static const _apiKey = 'AIzaSyByK2SI5e10K2xfkvDXjLFGCMaiz1DqtJ4';
  static const _cseId = '92c5d6361bac64d85';

  static Future<List<GoogleSearchResult>> fetchGoogleLinks(String query) async {
    final url = Uri.parse(
        'https://www.googleapis.com/customsearch/v1?key=$_apiKey&cx=$_cseId&q=${Uri.encodeComponent(query)}&num=5');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map((item) => GoogleSearchResult.fromJson(item))
          .toList();
    } else {
      throw Exception('Google Search API error: ${response.statusCode}');
    }
  }
}