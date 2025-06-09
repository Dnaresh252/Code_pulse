import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';
class AnswersScreen extends StatelessWidget {
  final List<QuizQuestion> questions;
  final List<String> userAnswers;

  const AnswersScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Answers'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final question = questions[index];
          final userAnswer = userAnswers.length > index ? userAnswers[index] : '';
          final isCorrect = userAnswer == question.correctAnswer;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Q${index + 1}: ${question.question}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    text: "Your answer: ",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: userAnswer.isEmpty ? "No answer" : userAnswer,
                        style: TextStyle(
                          color: isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    text: "Correct answer: ",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: question.correctAnswer,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (question.explanation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Explanation:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.explanation,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}