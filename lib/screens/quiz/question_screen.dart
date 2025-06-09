import 'package:code_assistant/screens/quiz/score_screen.dart';
import 'package:code_assistant/services/quiz_service.dart';
import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';

class QuestionScreen extends StatefulWidget {
  final String language;
  final String difficulty;

  const QuestionScreen({
    super.key,
    required this.language,
    required this.difficulty,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> with SingleTickerProviderStateMixin {
  late Future<List<QuizQuestion>> _quizFuture;
  List<QuizQuestion> questions = [];
  int currentIndex = 0;
  int correct = 0;
  int wrong = 0;
  List<String> answered = [];
  List<String> userAnswers = [];
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _quizFuture = AIService.fetchQuiz(widget.language, widget.difficulty);
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color getOptionColor(String option, String correctAnswer, bool isSelected) {
    if (!isSelected) return const Color(0xFF121212); // dark background for unselected
    if (option == correctAnswer) return Colors.green.shade900.withOpacity(0.7);
    return Colors.red.shade900.withOpacity(0.7);
  }

  Icon? getOptionIcon(String option, String correctAnswer, bool isSelected) {
    if (!isSelected) return null;
    if (option == correctAnswer) return const Icon(Icons.check_circle, color: Colors.greenAccent);
    return const Icon(Icons.cancel, color: Colors.redAccent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // dark background
      body: FutureBuilder<List<QuizQuestion>>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No questions found.', style: TextStyle(color: Colors.white)));
          }

          questions = snapshot.data!;
          if (currentIndex >= questions.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ScoreScreen(
                    correct: correct,
                    wrong: wrong,
                    questions: questions,
                    userAnswers: userAnswers,
                  ),
                ),
              );
            });
            return const SizedBox.shrink();
          }

          final q = questions[currentIndex];
          _controller.forward(from: 0);

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar with back, question count, skip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.arrow_back, color: Colors.white),
                      Text(
                        "Question ${currentIndex + 1}/${questions.length}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            currentIndex++;
                            answered.clear();
                          });
                        },
                        child: const Text(
                          "Skip",
                          style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Progress Bar
                  LinearProgressIndicator(
                    value: (currentIndex + 1) / questions.length,
                    backgroundColor: Colors.tealAccent.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${currentIndex + 1}/${questions.length}",
                    style: const TextStyle(color: Colors.tealAccent),
                  ),

                  const SizedBox(height: 30),

                  // Question Text
                  Text(
                    q.question,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Options List
                  Expanded(
                    child: ListView.builder(
                      itemCount: q.options.length,
                      itemBuilder: (context, index) {
                        final opt = q.options[index];
                        final isSelected = answered.contains(opt);
                        final tileColor = getOptionColor(opt, q.correctAnswer, isSelected);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: tileColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade800),
                          ),
                          child: ListTile(
                            leading: getOptionIcon(opt, q.correctAnswer, isSelected),
                            title: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                            onTap: () {
                              if (answered.isNotEmpty) return;
                              setState(() {
                                answered.add(opt);
                                if (userAnswers.length > currentIndex) {
                                  userAnswers[currentIndex] = opt;
                                } else {
                                  userAnswers.add(opt);
                                }
                                if (opt == q.correctAnswer) {
                                  correct++;
                                } else {
                                  wrong++;
                                }
                              });
                              Future.delayed(const Duration(milliseconds: 1500), () {
                                setState(() {
                                  currentIndex++;
                                  answered.clear();
                                  _controller.reset();
                                });
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // See Explanation (optional)
                  if (answered.isNotEmpty && answered.first == q.correctAnswer)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "See explanation →",
                        style: TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}



// import 'package:code_assistant/screens/quiz/score_screen.dart';
// import 'package:code_assistant/services/quiz_service.dart';
// import 'package:flutter/material.dart';
// import '../../models/quiz_question.dart';
//
// class QuestionScreen extends StatefulWidget {
//   final String language;
//   final String difficulty;
//
//   const QuestionScreen({
//     super.key,
//     required this.language,
//     required this.difficulty,
//   });
//
//   @override
//   State<QuestionScreen> createState() => _QuestionScreenState();
// }
//
// class _QuestionScreenState extends State<QuestionScreen> with SingleTickerProviderStateMixin {
//   late Future<List<QuizQuestion>> _quizFuture;
//   List<QuizQuestion> questions = [];
//   int currentIndex = 0;
//   int correct = 0;
//   int wrong = 0;
//   List<String> answered = [];
//   List<String> userAnswers = [];
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _quizFuture = AIService.fetchQuiz(widget.language, widget.difficulty);
//     _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
//     _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   Color getOptionColor(String option, String correctAnswer, bool isSelected) {
//     if (!isSelected) return Colors.white;
//     if (option == correctAnswer) return Colors.green.shade100;
//     return Colors.red.shade100;
//   }
//
//   Icon? getOptionIcon(String option, String correctAnswer, bool isSelected) {
//     if (!isSelected) return null;
//     if (option == correctAnswer) return const Icon(Icons.check_circle, color: Colors.green);
//     return const Icon(Icons.cancel, color: Colors.red);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFDF6F2),
//       body: FutureBuilder<List<QuizQuestion>>(
//         future: _quizFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('No questions found.'));
//           }
//
//           questions = snapshot.data!;
//           if (currentIndex >= questions.length) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ScoreScreen(
//                     correct: correct,
//                     wrong: wrong,
//                     questions: questions,
//                     userAnswers: userAnswers,
//                   ),
//                 ),
//               );
//             });
//             return const SizedBox.shrink();
//           }
//
//           final q = questions[currentIndex];
//           _controller.forward(from: 0);
//
//           return FadeTransition(
//             opacity: _fadeAnimation,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Top bar with back, question count, skip
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Icon(Icons.arrow_back, color: Colors.black),
//                       Text(
//                         "Question ${currentIndex + 1}/${questions.length}",
//                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                       ),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             currentIndex++;
//                             answered.clear();
//                           });
//                         },
//                         child: const Text(
//                           "Skip",
//                           style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Progress Bar
//                   LinearProgressIndicator(
//                     value: (currentIndex + 1) / questions.length,
//                     backgroundColor: Colors.orange.shade100,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
//                   ),
//                   const SizedBox(height: 6),
//                   Text("${currentIndex + 1}/${questions.length}", style: const TextStyle(color: Colors.teal)),
//
//                   const SizedBox(height: 30),
//
//                   // Question Text
//                   Text(
//                     q.question,
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1E2A78),
//                       height: 1.4,
//                     ),
//                   ),
//
//                   const SizedBox(height: 30),
//
//                   // Options List
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: q.options.length,
//                       itemBuilder: (context, index) {
//                         final opt = q.options[index];
//                         final isSelected = answered.contains(opt);
//                         final tileColor = getOptionColor(opt, q.correctAnswer, isSelected);
//
//                         return AnimatedContainer(
//                           duration: const Duration(milliseconds: 300),
//                           margin: const EdgeInsets.only(bottom: 14),
//                           decoration: BoxDecoration(
//                             color: tileColor,
//                             borderRadius: BorderRadius.circular(14),
//                             border: Border.all(color: Colors.grey.shade300),
//                           ),
//                           child: ListTile(
//                             leading: getOptionIcon(opt, q.correctAnswer, isSelected),
//                             title: Text(
//                               opt,
//                               style: TextStyle(
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.w500,
//                                 color: isSelected ? Colors.black87 : const Color(0xFF1E2A78),
//                               ),
//                             ),
//                             onTap: () {
//                               if (answered.isNotEmpty) return;
//                               setState(() {
//                                 answered.add(opt);
//                                 if (userAnswers.length > currentIndex) {
//                                   userAnswers[currentIndex] = opt;
//                                 } else {
//                                   userAnswers.add(opt);
//                                 }
//                                 if (opt == q.correctAnswer) {
//                                   correct++;
//                                 } else {
//                                   wrong++;
//                                 }
//                               });
//                               Future.delayed(const Duration(milliseconds: 1500), () {
//                                 setState(() {
//                                   currentIndex++;
//                                   answered.clear();
//                                   _controller.reset();
//                                 });
//                               });
//                             },
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//
//                   // See Explanation (optional)
//                   if (answered.isNotEmpty && answered.first == q.correctAnswer)
//                     const Padding(
//                       padding: EdgeInsets.only(top: 8),
//                       child: Text(
//                         "See explanation →",
//                         style: TextStyle(
//                           color: Colors.teal,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
