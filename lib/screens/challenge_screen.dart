import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../models/programming_language.dart';
import '../widgets/code_editor.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({Key? key}) : super(key: key);

  @override
  _ChallengeScreenState createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final GeminiService _geminiService = GeminiService();
  String _selectedLanguage = ProgrammingLanguages.languages.first.name;
  String _selectedDifficulty = 'Easy';
  String _challenge = '';
  String _solution = '';
  String _feedback = '';
  bool _isLoadingChallenge = false;
  bool _isLoadingFeedback = false;
  bool _challengeGenerated = false;

  List<String> difficultyLevels = ['Easy', 'Medium', 'Hard'];

  Future<void> _generateChallenge() async {
    setState(() {
      _isLoadingChallenge = true;
      _challenge = '';
      _solution = '';
      _feedback = '';
      _challengeGenerated = false;
    });

    try {
      final challenge = await _geminiService.getCodingChallenge(
          _selectedLanguage, _selectedDifficulty);

      setState(() {
        _challenge = challenge;
        _isLoadingChallenge = false;
        _challengeGenerated = true;
      });
    } catch (e) {
      setState(() {
        _challenge = "Error: ${e.toString()}";
        _isLoadingChallenge = false;
      });
    }
  }

  Future<void> _evaluateSolution() async {
    if (_solution.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your solution')),
      );
      return;
    }

    setState(() {
      _isLoadingFeedback = true;
      _feedback = '';
    });

    try {
      final feedback = await _geminiService.evaluateChallengeSolution(
          _challenge, _solution, _selectedLanguage);

      setState(() {
        _feedback = feedback;
        _isLoadingFeedback = false;
      });
    } catch (e) {
      setState(() {
        _feedback = "Error: ${e.toString()}";
        _isLoadingFeedback = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E2E4E),
        elevation: 0,
        title: const Text('Coding Challenges'),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Language & Difficulty Dropdowns
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select language:',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E2E4E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          dropdownColor: const Color(0xFF2E2E4E),
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white),
                          items: ProgrammingLanguages.languages
                              .map((lang) => DropdownMenuItem<String>(
                            value: lang.name,
                            child: Text('${lang.icon} ${lang.name}'),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedLanguage = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Difficulty level:',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E2E4E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedDifficulty,
                          dropdownColor: const Color(0xFF2E2E4E),
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white),
                          items: difficultyLevels
                              .map((diff) => DropdownMenuItem<String>(
                            value: diff,
                            child: Text(diff),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedDifficulty = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Challenge Display
            if (_challenge.isEmpty && !_isLoadingChallenge)
              Center(
                child: Text(
                  'Generate a challenge to get started',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
              )
            else ...[
              const Text(
                'Challenge:',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E4E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoadingChallenge
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                  _challenge,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],

            const SizedBox(height: 20),

            /// Solution Editor
            if (_challengeGenerated) ...[
              const Text('Your Solution:',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              CodeEditor(
                language: _selectedLanguage,
                onCodeChanged: (code) {
                  setState(() {
                    _solution = code;
                  });
                },
                height: 300, // Give it space to expand
              ),
            ],

            const SizedBox(height: 20),

            /// Feedback Section
            if (_feedback.isNotEmpty) ...[
              const Text('Feedback:',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E4E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoadingFeedback
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                  _feedback,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],

            const SizedBox(height: 100), // extra space before button
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 32,
        ),
        child: ElevatedButton(
          onPressed: _challengeGenerated
              ? (_isLoadingFeedback ? null : _evaluateSolution)
              : (_isLoadingChallenge ? null : _generateChallenge),
          style: ElevatedButton.styleFrom(
            backgroundColor:
            _challengeGenerated ? Colors.blue : Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: (_isLoadingChallenge || _isLoadingFeedback)
              ? const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          )
              : Text(
            _challengeGenerated ? 'Submit Solution' : 'Generate Challenge',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

}
