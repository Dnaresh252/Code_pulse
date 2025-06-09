import 'package:flutter/material.dart';
import 'package:code_assistant/screens/quiz/question_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String? selectedLanguage;
  String? selectedDifficulty;

  final List<String> languages = ['Python', 'Java', 'C++', 'JavaScript', 'Dart'];
  final List<String> difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    offset: Offset(0, 6),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.tealAccent, size: 50),
                  const SizedBox(height: 16),
                  const Text(
                    'AI Quiz Generator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate quizzes using AI\nbased on your tech stack.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 30),

                  // Language Dropdown
                  _buildDropdown(
                    label: 'Select Language',
                    value: selectedLanguage,
                    items: languages,
                    onChanged: (val) => setState(() => selectedLanguage = val),
                  ),

                  const SizedBox(height: 20),

                  // Difficulty Dropdown
                  _buildDropdown(
                    label: 'Select Difficulty',
                    value: selectedDifficulty,
                    items: difficulties,
                    onChanged: (val) => setState(() => selectedDifficulty = val),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton.icon(
                    onPressed: selectedLanguage != null && selectedDifficulty != null
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuestionScreen(
                            language: selectedLanguage!,
                            difficulty: selectedDifficulty!,
                          ),
                        ),
                      );
                    }
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(50),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey.shade800,
                      disabledForegroundColor: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1E1E1E),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1F1F1F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.tealAccent),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem<String>(
        value: e,
        child: Text(e),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }
}




//
// // File: lib/screens/quiz/quiz_screen.dart
//
// import 'package:code_assistant/screens/quiz/question_screen.dart';
// import 'package:flutter/material.dart';
//
// class QuizScreen extends StatefulWidget {
//   const QuizScreen({Key? key}) : super(key: key);
//
//   @override
//   State<QuizScreen> createState() => _QuizScreenState();
// }
//
// class _QuizScreenState extends State<QuizScreen> {
//   String? selectedLanguage;
//   String? selectedDifficulty;
//
//   final List<String> languages = [
//     'Python',
//     'Java',
//     'C++',
//     'JavaScript',
//     'Dart'
//   ];
//   final List<String> difficulties = ['Easy', 'Medium', 'Hard'];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF4F4249),
//
//       body: Center(
//           child: SingleChildScrollView(
//             child: Card(
//               elevation: 12,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               color: Color(0xFF1E1E1E),
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text(
//                       '🧠 AI Quiz Generator',
//                       style:
//                       TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 24),
//                     DropdownButtonFormField<String>(
//                       value: selectedLanguage,
//                       items: languages
//                           .map((lang) => DropdownMenuItem(
//                         value: lang,
//                         child: Text(lang,
//                             style: const TextStyle(fontSize: 18)),
//                       ))
//                           .toList(),
//                       onChanged: (val) =>
//                           setState(() => selectedLanguage = val),
//                       decoration: const InputDecoration(
//                         labelText: 'Select Language',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: selectedDifficulty,
//                       items: difficulties
//                           .map((level) => DropdownMenuItem(
//                         value: level,
//                         child: Text(level,
//                             style: const TextStyle(fontSize: 18)),
//                       ))
//                           .toList(),
//                       onChanged: (val) =>
//                           setState(() => selectedDifficulty = val),
//                       decoration: const InputDecoration(
//                         labelText: 'Select Difficulty',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 30),
//                     ElevatedButton.icon(
//                       onPressed:
//                       selectedLanguage != null && selectedDifficulty != null
//                           ? () {
//                         Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => QuestionScreen(
//                                 language: selectedLanguage!,
//                                 difficulty: selectedDifficulty!,
//                               ),
//                             ),
//                         );
//
//                       }
//                           : null,
//                       icon: const Icon(Icons.play_arrow),
//                       label: const Text('Start Quiz'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blueAccent,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 32, vertical: 14),
//                         textStyle: const TextStyle(fontSize: 18),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         disabledBackgroundColor: Colors.grey.shade400,
//                         disabledForegroundColor: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//
//     );
//   }
// }