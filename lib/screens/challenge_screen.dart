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

  // Color scheme
  static const Color primaryBg = Color(0xFF0D1117);
  static const Color cardBg = Color(0xFF161B22);
  static const Color accentBg = Color(0xFF21262D);
  static const Color primaryText = Color(0xFFE6EDF3);
  static const Color secondaryText = Color(0xFF7D8590);
  static const Color accentColor = Color(0xFF238636);
  static const Color errorColor = Color(0xFFDA3633);
  static const Color warningColor = Color(0xFFD29922);

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
        SnackBar(
          content: const Text('Please enter your solution'),
          backgroundColor: warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
    bool isLoading = false,
  }) {
    return Card(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: accentBg, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForSection(title),
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing,
                ],
              ],
            ),
            const SizedBox(height: 16),
            isLoading
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: accentColor,
                  strokeWidth: 2,
                ),
              ),
            )
                : child,
          ],
        ),
      ),
    );
  }

  IconData _getIconForSection(String title) {
    switch (title.toLowerCase()) {
      case 'settings':
        return Icons.settings_outlined;
      case 'challenge':
        return Icons.assignment_outlined;
      case 'your solution':
        return Icons.code_outlined;
      case 'feedback':
        return Icons.rate_review_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildCustomDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    String Function(String)? itemBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: accentBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentBg, width: 1),
      ),
      child: DropdownButton<String>(
        value: value,
        dropdownColor: accentBg,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, color: secondaryText),
        style: const TextStyle(color: primaryText, fontSize: 14),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              itemBuilder != null ? itemBuilder(item) : item,
              style: const TextStyle(color: primaryText),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    Color chipColor;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        chipColor = accentColor;
        break;
      case 'medium':
        chipColor = warningColor;
        break;
      case 'hard':
        chipColor = errorColor;
        break;
      default:
        chipColor = secondaryText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.developer_mode, color: accentColor),
            SizedBox(width: 8),
            Text(
              'Coding Challenges',
              style: TextStyle(
                color: primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    // Settings Section
                    _buildSectionCard(
                      title: 'Settings',
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Language',
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildCustomDropdown(
                                  value: _selectedLanguage,
                                  items: ProgrammingLanguages.languages
                                      .map((lang) => lang.name)
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedLanguage = value;
                                      });
                                    }
                                  },
                                  itemBuilder: (name) {
                                    final lang = ProgrammingLanguages.languages
                                        .firstWhere((l) => l.name == name);
                                    return '${lang.icon} ${lang.name}';
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Difficulty',
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildCustomDropdown(
                                  value: _selectedDifficulty,
                                  items: difficultyLevels,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedDifficulty = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Challenge Section
                    if (_challenge.isNotEmpty || _isLoadingChallenge)
                      _buildSectionCard(
                        title: 'Challenge',
                        trailing: _buildDifficultyChip(_selectedDifficulty),
                        isLoading: _isLoadingChallenge,
                        child: _challenge.isNotEmpty
                            ? SelectableText(
                          _challenge,
                          style: const TextStyle(
                            color: primaryText,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        )
                            : const SizedBox.shrink(),
                      ),

                    if (_challengeGenerated) ...[
                      const SizedBox(height: 16),

                      // Solution Editor Section
                      _buildSectionCard(
                        title: 'Your Solution',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accentBg),
                          ),
                          child: CodeEditor(
                            language: _selectedLanguage,
                            onCodeChanged: (code) {
                              setState(() {
                                _solution = code;
                              });
                            },
                            height: 300,
                          ),
                        ),
                      ),
                    ],

                    // Feedback Section
                    if (_feedback.isNotEmpty || _isLoadingFeedback) ...[
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Feedback',
                        isLoading: _isLoadingFeedback,
                        child: _feedback.isNotEmpty
                            ? SelectableText(
                          _feedback,
                          style: const TextStyle(
                            color: primaryText,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        )
                            : const SizedBox.shrink(),
                      ),
                    ],

                    // Empty state
                    if (_challenge.isEmpty && !_isLoadingChallenge) ...[
                      const SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 64,
                              color: secondaryText.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ready to Code?',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generate a coding challenge to test your skills',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: _challengeGenerated
              ? (_isLoadingFeedback ? null : _evaluateSolution)
              : (_isLoadingChallenge ? null : _generateChallenge),
          backgroundColor: _challengeGenerated ? accentColor : warningColor,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: (_isLoadingChallenge || _isLoadingFeedback)
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Icon(
            _challengeGenerated ? Icons.send : Icons.flash_on,
            color: Colors.white,
          ),
          label: Text(
            _challengeGenerated ? 'Submit Solution' : 'Generate Challenge',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}





// import 'package:flutter/material.dart';
// import '../services/gemini_service.dart';
// import '../models/programming_language.dart';
// import '../widgets/code_editor.dart';
//
// class ChallengeScreen extends StatefulWidget {
//   const ChallengeScreen({Key? key}) : super(key: key);
//
//   @override
//   _ChallengeScreenState createState() => _ChallengeScreenState();
// }
//
// class _ChallengeScreenState extends State<ChallengeScreen> {
//   final GeminiService _geminiService = GeminiService();
//   String _selectedLanguage = ProgrammingLanguages.languages.first.name;
//   String _selectedDifficulty = 'Easy';
//   String _challenge = '';
//   String _solution = '';
//   String _feedback = '';
//   bool _isLoadingChallenge = false;
//   bool _isLoadingFeedback = false;
//   bool _challengeGenerated = false;
//
//   List<String> difficultyLevels = ['Easy', 'Medium', 'Hard'];
//
//   Future<void> _generateChallenge() async {
//     setState(() {
//       _isLoadingChallenge = true;
//       _challenge = '';
//       _solution = '';
//       _feedback = '';
//       _challengeGenerated = false;
//     });
//
//     try {
//       final challenge = await _geminiService.getCodingChallenge(
//           _selectedLanguage, _selectedDifficulty);
//
//       setState(() {
//         _challenge = challenge;
//         _isLoadingChallenge = false;
//         _challengeGenerated = true;
//       });
//     } catch (e) {
//       setState(() {
//         _challenge = "Error: ${e.toString()}";
//         _isLoadingChallenge = false;
//       });
//     }
//   }
//
//   Future<void> _evaluateSolution() async {
//     if (_solution.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please enter your solution')),
//       );
//       return;
//     }
//
//     setState(() {
//       _isLoadingFeedback = true;
//       _feedback = '';
//     });
//
//     try {
//       final feedback = await _geminiService.evaluateChallengeSolution(
//           _challenge, _solution, _selectedLanguage);
//
//       setState(() {
//         _feedback = feedback;
//         _isLoadingFeedback = false;
//       });
//     } catch (e) {
//       setState(() {
//         _feedback = "Error: ${e.toString()}";
//         _isLoadingFeedback = false;
//       });
//     }
//   }
//
//   @override
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF1E1E2E),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF2E2E4E),
//         elevation: 0,
//         title: const Text('Coding Challenges'),
//       ),
//       resizeToAvoidBottomInset: true,
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// Language & Difficulty Dropdowns
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text('Select language:',
//                           style: TextStyle(color: Colors.white, fontSize: 14)),
//                       const SizedBox(height: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF2E2E4E),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: DropdownButton<String>(
//                           value: _selectedLanguage,
//                           dropdownColor: const Color(0xFF2E2E4E),
//                           isExpanded: true,
//                           underline: const SizedBox(),
//                           style: const TextStyle(color: Colors.white),
//                           items: ProgrammingLanguages.languages
//                               .map((lang) => DropdownMenuItem<String>(
//                             value: lang.name,
//                             child: Text('${lang.icon} ${lang.name}'),
//                           ))
//                               .toList(),
//                           onChanged: (value) {
//                             if (value != null) {
//                               setState(() {
//                                 _selectedLanguage = value;
//                               });
//                             }
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text('Difficulty level:',
//                           style: TextStyle(color: Colors.white, fontSize: 14)),
//                       const SizedBox(height: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF2E2E4E),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: DropdownButton<String>(
//                           value: _selectedDifficulty,
//                           dropdownColor: const Color(0xFF2E2E4E),
//                           isExpanded: true,
//                           underline: const SizedBox(),
//                           style: const TextStyle(color: Colors.white),
//                           items: difficultyLevels
//                               .map((diff) => DropdownMenuItem<String>(
//                             value: diff,
//                             child: Text(diff),
//                           ))
//                               .toList(),
//                           onChanged: (value) {
//                             if (value != null) {
//                               setState(() {
//                                 _selectedDifficulty = value;
//                               });
//                             }
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 20),
//
//             /// Challenge Display
//             if (_challenge.isEmpty && !_isLoadingChallenge)
//               Center(
//                 child: Text(
//                   'Generate a challenge to get started',
//                   style: TextStyle(color: Colors.grey[400], fontSize: 16),
//                 ),
//               )
//             else ...[
//               const Text(
//                 'Challenge:',
//                 style: TextStyle(color: Colors.white, fontSize: 16),
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF2E2E4E),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: _isLoadingChallenge
//                     ? const Center(child: CircularProgressIndicator())
//                     : Text(
//                   _challenge,
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//
//             const SizedBox(height: 20),
//
//             /// Solution Editor
//             if (_challengeGenerated) ...[
//               const Text('Your Solution:',
//                   style: TextStyle(color: Colors.white, fontSize: 16)),
//               const SizedBox(height: 8),
//               CodeEditor(
//                 language: _selectedLanguage,
//                 onCodeChanged: (code) {
//                   setState(() {
//                     _solution = code;
//                   });
//                 },
//                 height: 300, // Give it space to expand
//               ),
//             ],
//
//             const SizedBox(height: 20),
//
//             /// Feedback Section
//             if (_feedback.isNotEmpty) ...[
//               const Text('Feedback:',
//                   style: TextStyle(color: Colors.white, fontSize: 16)),
//               const SizedBox(height: 8),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF2E2E4E),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: _isLoadingFeedback
//                     ? const Center(child: CircularProgressIndicator())
//                     : Text(
//                   _feedback,
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//
//             const SizedBox(height: 100), // extra space before button
//           ],
//         ),
//       ),
//       bottomNavigationBar: Padding(
//         padding: EdgeInsets.only(
//           left: 16,
//           right: 16,
//           bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 32,
//         ),
//         child: ElevatedButton(
//           onPressed: _challengeGenerated
//               ? (_isLoadingFeedback ? null : _evaluateSolution)
//               : (_isLoadingChallenge ? null : _generateChallenge),
//           style: ElevatedButton.styleFrom(
//             backgroundColor:
//             _challengeGenerated ? Colors.blue : Colors.orange,
//             padding: const EdgeInsets.symmetric(vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             minimumSize: const Size(double.infinity, 50),
//           ),
//           child: (_isLoadingChallenge || _isLoadingFeedback)
//               ? const CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//           )
//               : Text(
//             _challengeGenerated ? 'Submit Solution' : 'Generate Challenge',
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
// }