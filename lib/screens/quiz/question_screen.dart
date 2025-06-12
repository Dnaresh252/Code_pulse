
import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';
import '../../services/quiz_service.dart';
import 'score_screen.dart';

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

class _QuestionScreenState extends State<QuestionScreen>
    with TickerProviderStateMixin {
  late Future<List<QuizQuestion>> _quizFuture;
  List<QuizQuestion> questions = [];
  int currentIndex = 0;
  int correct = 0;
  int wrong = 0;
  List<String> answered = [];
  List<String> userAnswers = [];

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    // Assuming AIService.fetchQuiz is correctly defined elsewhere.
    _quizFuture = AIService.fetchQuiz(widget.language, widget.difficulty);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Color getOptionColor(String option, String correctAnswer, bool isSelected) {
    if (!isSelected) {
      return Colors.white.withOpacity(0.08);
    }
    if (option == correctAnswer) {
      return const Color(0xFF00D4AA).withOpacity(0.2);
    }
    return Colors.red.withOpacity(0.2);
  }

  Border getOptionBorder(String option, String correctAnswer, bool isSelected) {
    if (!isSelected) {
      return Border.all(color: Colors.white.withOpacity(0.2), width: 1);
    }
    if (option == correctAnswer) {
      return Border.all(color: const Color(0xFF00D4AA), width: 2);
    }
    return Border.all(color: Colors.red, width: 2);
  }

  Widget? getOptionIcon(String option, String correctAnswer, bool isSelected) {
    if (!isSelected) return null;
    if (option == correctAnswer) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF00D4AA),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4AA).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.close, color: Colors.white, size: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B263B),
              Color(0xFF415A77),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<QuizQuestion>>(
            future: _quizFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

              if (snapshot.hasError) {
                return _buildErrorScreen(snapshot.error.toString());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildNoQuestionsScreen();
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
                        language: widget.language,     // ✅ ADD this line
                        difficulty: widget.difficulty, // ✅ ADD this line
                      ),
                    ),
                  );
                });
                return const SizedBox.shrink();
              }

              final q = questions[currentIndex];
              _fadeController.forward(from: 0);
              _progressController.animateTo((currentIndex + 1) / questions.length);

              return SingleChildScrollView( // Made the screen scrollable
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 24),
                        _buildProgressSection(),
                        const SizedBox(height: 32),
                        _buildQuestionCard(q),
                        const SizedBox(height: 24),
                        // Removed Expanded around _buildOptionsSection
                        _buildOptionsSection(q),
                        if (answered.isNotEmpty) _buildExplanationHint(),
                        const SizedBox(height: 20), // Added some bottom padding for scroll
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF00D4AA),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Generating Quiz Questions...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while AI creates your ${widget.difficulty} ${widget.language} quiz',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Quiz',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoQuestionsScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.quiz,
              color: Color(0xFF00D4AA),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Questions Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to generate questions for this quiz.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF00D4AA),
              size: 20,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00D4AA).withOpacity(0.2),
                const Color(0xFF00A8CC).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00D4AA).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            "Question ${currentIndex + 1}/${questions.length}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00D4AA),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              currentIndex++;
              answered.clear();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Text(
              "Skip",
              style: TextStyle(
                color: Color(0xFF00D4AA),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.timeline,
              color: Color(0xFF00D4AA),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Progress',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4AA).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                  minHeight: 8,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${currentIndex + 1} of ${questions.length} questions",
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(QuizQuestion q) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.language} • ${widget.difficulty}',
                            style: const TextStyle(
                              color: Color(0xFF00D4AA),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose the correct answer',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  q.question,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionsSection(QuizQuestion q) {
    // Removed Expanded and added ShrinkWrap and physics for proper scrolling within SingleChildScrollView
    return ListView.builder(
      shrinkWrap: true, // Important for ListView.builder inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
      itemCount: q.options.length,
      itemBuilder: (context, index) {
        final opt = q.options[index];
        final isSelected = answered.contains(opt);
        final isCorrect = opt == q.correctAnswer;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getOptionColor(opt, q.correctAnswer, isSelected),
                getOptionColor(opt, q.correctAnswer, isSelected).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: getOptionBorder(opt, q.correctAnswer, isSelected),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: isCorrect
                    ? const Color(0xFF00D4AA).withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
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
                    _fadeController.reset();
                  });
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: getOptionIcon(opt, q.correctAnswer, isSelected) ??
                            Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        opt,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExplanationHint() {
    if (answered.isEmpty) return const SizedBox.shrink();

    final isCorrect = answered.first == questions[currentIndex].correctAnswer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCorrect
              ? [
            const Color(0xFF00D4AA).withOpacity(0.2),
            const Color(0xFF00A8CC).withOpacity(0.1),
          ]
              : [
            Colors.red.withOpacity(0.2),
            Colors.red.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF00D4AA).withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? const Color(0xFF00D4AA) : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isCorrect ? 'Correct! Well done!' : 'Incorrect. Keep learning!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'See explanation →',
            style: TextStyle(
              color: isCorrect ? const Color(0xFF00D4AA) : Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}