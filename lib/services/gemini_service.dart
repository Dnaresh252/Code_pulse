import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class GeminiService {
  final String _apiKey = ApiConstants.apiKey;
  final String _modelName = ApiConstants.modelName;

  GeminiService();

  bool isValidApiKey() {
    return true; // Always return true to accept any API key
  }

  Future<String> getCodingHelp(String prompt) async {
    // Check if API key is valid
    if (!isValidApiKey()) {
      return '''
⚠️ This app is using a placeholder API key. 
To get complete responses to any coding question, please:

1. Get a Gemini API key from https://ai.google.dev/
2. Replace the API key in lib/utils/constants.dart

For now, I'll try to provide a general response based on your query.
''';
    }

    try {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$_apiKey';

      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null &&
            data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ??
              'No response generated.';
        } else {
          return 'Unable to parse the API response.';
        }
      } else {
        return 'Error: HTTP ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Error connecting to the AI service: ${e.toString()}';
    }
  }

  Future<String> debugCode(String code, String language) async {
    // Check if API key is valid
    if (!isValidApiKey()) {
      return '''
⚠️ This app is using a placeholder API key. 
To get complete responses for code debugging, please:

1. Get a Gemini API key from https://ai.google.dev/
2. Replace the API key in lib/utils/constants.dart
''';
    }

    try {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$_apiKey';

      final prompt = '''
You are an expert ${language} developer. Debug the following code and identify any issues, bugs, or potential problems. 
Provide a detailed analysis with specific line references when possible.
Also suggest fixes for each issue you identify.

```${language.toLowerCase()}
${code}
```

Format your response using markdown with the following sections:
1. Summary of issues found
2. Detailed analysis with line references
3. Fixed code snippets
''';

      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null &&
            data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ??
              'No debug analysis generated.';
        } else {
          return 'Unable to parse the API response.';
        }
      } else {
        return 'Error: HTTP ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Error connecting to the AI service: ${e.toString()}';
    }
  }

  Future<String> explainCode(String code, String language) async {
    // Check if API key is valid
    if (!isValidApiKey()) {
      return '''
⚠️ This app is using a placeholder API key. 
To get complete code explanations, please:

1. Get a Gemini API key from https://ai.google.dev/
2. Replace the API key in lib/utils/constants.dart
''';
    }

    try {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$_apiKey';

      final prompt = '''
You are an expert ${language} developer. Explain the following code in detail.
Break down what it does, how it works, and the techniques used.
Be thorough but also clear and concise. Focus on helping someone understand this code completely.

```${language.toLowerCase()}
${code}
```

Format your response using markdown with the following sections:
1. Overview of what the code does
2. Step-by-step explanation
3. Key concepts and techniques used
4. Time and space complexity analysis (if applicable)
''';

      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null &&
            data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ??
              'No explanation generated.';
        } else {
          return 'Unable to parse the API response.';
        }
      } else {
        return 'Error: HTTP ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Error connecting to the AI service: ${e.toString()}';
    }
  }

  Future<String> suggestImprovements(String code, String language) async {
    // Check if API key is valid
    if (!isValidApiKey()) {
      return '''
⚠️ This app is using a placeholder API key. 
To get complete code improvement suggestions, please:

1. Get a Gemini API key from https://ai.google.dev/
2. Replace the API key in lib/utils/constants.dart
''';
    }

    try {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$_apiKey';

      final prompt = '''
You are an expert ${language} developer. Analyze the following code and suggest improvements for:
1. Code quality and readability
2. Performance optimization
3. Following ${language} best practices
4. Error handling and edge cases

Provide specific, actionable recommendations with example code.

```${language.toLowerCase()}
${code}
```

Format your response using markdown with the following sections:
1. Overall assessment
2. Readability improvements
3. Performance optimizations
4. Best practices
5. Improved code examples
''';

      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null &&
            data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ??
              'No improvement suggestions generated.';
        } else {
          return 'Unable to parse the API response.';
        }
      } else {
        return 'Error: HTTP ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Error connecting to the AI service: ${e.toString()}';
    }
  }

  Future<String> getCodingChallenge(String language, String difficulty) async {
    if (!isValidApiKey()) {
      return '''
⚠️ This app is using a placeholder API key. 
To get AI-generated coding challenges, please:

1. Get a Gemini API key from https://ai.google.dev/
2. Replace the API key in lib/utils/constants.dart

For now, showing a sample challenge.
''';
    }

    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$_apiKey';

      final prompt = '''
Generate a random coding challenge for ${language} programming language with ${difficulty} difficulty level.

Requirements:
- Create a unique, interesting problem that hasn't been overused
- Include clear problem statement and examples
- Provide appropriate constraints
- Add helpful hints without giving away the solution
- Make it appropriate for ${difficulty} level:
  * Easy: Basic syntax, simple algorithms, string/array manipulation
  * Medium: Data structures, moderate algorithms, multiple conditions
  * Hard: Complex algorithms, optimization, advanced data structures

Format your response as markdown with these sections:
# Coding Challenge: [Title] (${difficulty})

## Problem Statement
[Clear description of what to solve]

## Examples
[Input/Output examples with explanations]

## Constraints
[Technical constraints and limits]

## Hints
[Helpful hints without revealing the solution]

Make this challenge engaging and educational for someone learning ${language}.
''';

      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.8,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1536,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null &&
            data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ??
              'No challenge generated.';
        } else {
          return 'Unable to parse the API response.';
        }
      } else {
        return 'Error: HTTP ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Error connecting to the AI service: ${e.toString()}';
    }
  }

  Future<String> evaluateChallengeSolution(
      String challenge, String solution, String language) async {
    if (!isValidApiKey()) {
      return '''
⚠️ This app is using a placeholder API key. 
To get AI-powered solution evaluation, please:

1. Get a Gemini API key from https://ai.google.dev/
2. Replace the API key in lib/utils/constants.dart

For now, showing a sample evaluation.
''';
    }

    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$_apiKey';

      final prompt = '''
You are an expert ${language} developer and coding mentor. Evaluate the following solution to a coding challenge.

## Original Challenge:
${challenge}

## Student's Solution:
```${language.toLowerCase()}
${solution}
```

Please provide a comprehensive evaluation covering:

1. **Correctness**: Does the solution solve the problem correctly?
2. **Code Quality**: Is the code well-written, readable, and maintainable?
3. **Efficiency**: Analyze time and space complexity
4. **Best Practices**: Does it follow ${language} best practices?
5. **Edge Cases**: Does it handle edge cases properly?
6. **Improvements**: Specific suggestions for improvement

Format your response as markdown with these sections:
# Solution Evaluation

## Correctness Analysis
[Analyze if the solution works correctly]

## Code Quality Assessment
[Evaluate readability, structure, naming, etc.]

## Performance Analysis
[Time/space complexity analysis]

## Best Practices Review
[${language}-specific best practices]

## Edge Cases & Error Handling
[How well does it handle edge cases]

## Suggested Improvements
[Specific, actionable improvements with code examples if needed]

## Overall Score: X/10
[Final score with brief justification]

Be constructive, encouraging, and educational in your feedback.
''';

      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null &&
            data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ??
              'No evaluation generated.';
        } else {
          return 'Unable to parse the API response.';
        }
      } else {
        return 'Error: HTTP ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Error connecting to the AI service: ${e.toString()}';
    }
  }
}