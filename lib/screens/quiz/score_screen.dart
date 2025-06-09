import 'package:code_assistant/screens/quiz/solution_screen.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:confetti/confetti.dart';
import '../../models/quiz_question.dart';

class ScoreScreen extends StatefulWidget {
  final int correct;
  final int wrong;
  final List<QuizQuestion> questions;
  final List<String> userAnswers;

  const ScoreScreen({
    super.key,
    required this.correct,
    required this.wrong,
    required this.questions,
    required this.userAnswers,
  });

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  late ConfettiController _confettiController;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.correct / (widget.correct + widget.wrong) >= 0.7) {
        setState(() => _showConfetti = true);
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getPerformanceMessage(double percent) {
    if (percent >= 0.9) return 'Outstanding!';
    if (percent >= 0.7) return 'Great Job!';
    if (percent >= 0.5) return 'Good Effort!';
    return 'Keep Practicing!';
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.correct + widget.wrong;
    final double percent = total == 0 ? 0 : widget.correct / total;

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color primaryColor = colorScheme.primary;
    final Color surfaceColor = colorScheme.surface;
    final Color onSurfaceColor = colorScheme.onSurface;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black87,
                  Colors.black,
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getPerformanceMessage(percent),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularPercentIndicator(
                        radius: 120.0,
                        lineWidth: 16.0,
                        animation: true,
                        animationDuration: 1200,
                        percent: percent,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${(percent * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: 36.0,
                                fontWeight: FontWeight.bold,
                                color: onSurfaceColor,
                              ),
                            ),
                            Text(
                              "${widget.correct}/$total",
                              style: TextStyle(
                                fontSize: 16.0,
                                color: onSurfaceColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        progressColor: Colors.lightBlueAccent,
                        backgroundColor: onSurfaceColor.withOpacity(0.1),
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      if (_showConfetti)
                        ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality: BlastDirectionality.explosive,
                          shouldLoop: false,
                          colors: const [
                            Colors.green,
                            Colors.blue,
                            Colors.pink,
                            Colors.orange,
                            Colors.purple,
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: surfaceColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: onSurfaceColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildScoreCard("Correct", widget.correct, Colors.lightGreenAccent),
                        _buildScoreCard("Wrong", widget.wrong, Colors.orangeAccent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.replay_rounded,
                        label: "Try Again",
                        onPressed: () => Navigator.pop(context),
                        isPrimary: true,
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        context,
                        icon: Icons.quiz_rounded,
                        label: "Review Answers",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnswersScreen(
                                questions: widget.questions,
                                userAnswers: widget.userAnswers,
                              ),
                            ),
                          );
                        },
                        isPrimary: false,
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        context,
                        icon: Icons.home_rounded,
                        label: "Return Home",
                        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                        isPrimary: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_showConfetti)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 3.14, // upward
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onPressed,
        required bool isPrimary,
      }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? Colors.lightBlueAccent
              : Theme.of(context).colorScheme.surface.withOpacity(0.2),
          foregroundColor: isPrimary ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: isPrimary ? 4 : 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }
}

