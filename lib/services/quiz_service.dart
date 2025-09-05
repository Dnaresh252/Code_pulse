import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_question.dart';

class AIService {
  // ⚠ Replace this with your actual Gemini API key
  static const _apiKey = "Paste your Api key";

  static const _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';

  static Future<List<QuizQuestion>> fetchQuiz(String language, String difficulty) async {
    final prompt = '''
You are a quiz-generating AI assistant.

Generate *exactly 5* multiple-choice quiz questions on *$language* at *$difficulty* level.

Each question must have:
- A "question" string,
- An "options" array with 4 unique strings,
- A "correct_answer" string (must match one of the options),
- An "explanation" string (a short explanation of why the answer is correct).

⚠ Respond ONLY with raw JSON (no markdown, no backticks, no explanations).

Example:
[
  {
    "question": "...",
    "options": ["...", "...", "...", "..."],
    "correct_answer": "...",
    "explanation": "..."
  }
]
''';



    final response = await http.post(
      Uri.parse(_url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('❌ Failed to fetch quiz: ${response.statusCode}');
    }

    final content = json.decode(response.body);
    final candidates = content['candidates'];

    if (candidates == null || candidates.isEmpty) {
      throw Exception('❌ No candidates returned from Gemini.');
    }

    final text = candidates[0]['content']['parts'][0]['text'];


    /// Extract JSON array safely
    String extractJsonArray(String raw) {
      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');

      if (start == -1 || end == -1 || start >= end) {
        throw Exception("❌ Could not find a valid JSON array in AI response.");
      }

      return raw.substring(start, end + 1);
    }

    try {
      final cleanedJson = extractJsonArray(text);

      final parsed = jsonDecode(cleanedJson);
      if (parsed is! List) throw Exception("Invalid format: not a List");

      return parsed.map<QuizQuestion>((e) => QuizQuestion.fromJson(e)).toList();
    } catch (e) {
      throw Exception('❌ Failed to parse AI response: $e\n\nRaw:\n$text');
    }
  }
}
