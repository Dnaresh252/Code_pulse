import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';

class AnswersScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final List<String> userAnswers;

  const AnswersScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  State<AnswersScreen> createState() => _AnswersScreenState();
}

class _AnswersScreenState extends State<AnswersScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int correctCount = 0;
  int wrongCount = 0;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Calculate correct and wrong answers
    for (int i = 0; i < widget.questions.length; i++) {
      final userAnswer = widget.userAnswers.length > i ? widget.userAnswers[i] : '';
      if (userAnswer == widget.questions[i].correctAnswer) {
        correctCount++;
      } else {
        wrongCount++;
      }
    }

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Helper method to determine screen size category
  String getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 'mobile';
    if (width < 1200) return 'tablet';
    return 'desktop';
  }

  // Helper method to get responsive font size
  double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenSize = getScreenSize(context);
    final width = MediaQuery.of(context).size.width;

    // Scale based on screen width for smoother transitions
    final scaleFactor = width / 375; // 375 is iPhone 11 width

    switch (screenSize) {
      case 'mobile':
        return baseSize * (scaleFactor > 1.3 ? 1.3 : scaleFactor);
      case 'tablet':
        return baseSize * 1.2;
      case 'desktop':
        return baseSize * 1.4;
      default:
        return baseSize;
    }
  }

  // Helper method to get responsive padding
  EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    final width = MediaQuery.of(context).size.width;

    switch (screenSize) {
      case 'mobile':
        return EdgeInsets.all(width * 0.04);
      case 'tablet':
        return EdgeInsets.all(width * 0.05);
      case 'desktop':
        return EdgeInsets.symmetric(
          horizontal: width * 0.15,
          vertical: 30,
        );
      default:
        return const EdgeInsets.all(20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = getScreenSize(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (screenSize == 'desktop' || (screenSize == 'tablet' && isLandscape)) {
                  // Desktop and landscape tablet layout with side panel
                  return Row(
                    children: [
                      // Fixed side panel
                      Container(
                        width: 350,
                        child: Column(
                          children: [
                            _buildHeader(isCompact: false),
                            _buildSummaryCard(isCompact: false),
                          ],
                        ),
                      ),
                      // Answers list
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            border: Border(
                              left: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: _buildAnswersList(),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mobile and portrait tablet layout
                  return Column(
                    children: [
                      _buildHeader(isCompact: true),
                      _buildSummaryCard(isCompact: true),
                      Expanded(child: _buildAnswersList()),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    final screenSize = getScreenSize(context);
    final padding = isCompact ? getResponsivePadding(context) : EdgeInsets.all(30);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(screenSize == 'mobile' ? 10 : 12),
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
              child: Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF00D4AA),
                size: getResponsiveFontSize(context, 20),
              ),
            ),
          ),
          SizedBox(width: screenSize == 'mobile' ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF00A8CC), Colors.white],
                    stops: [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: Text(
                    'Review Answers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: getResponsiveFontSize(context, 24),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Detailed quiz analysis',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: getResponsiveFontSize(context, 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required bool isCompact}) {
    final screenSize = getScreenSize(context);
    final padding = isCompact
        ? EdgeInsets.symmetric(horizontal: getResponsivePadding(context).horizontal)
        : EdgeInsets.symmetric(horizontal: 30);
    final isVerySmall = MediaQuery.of(context).size.width < 350;

    return Container(
      margin: padding,
      padding: EdgeInsets.all(screenSize == 'mobile' ? 16 : 20),
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
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: isVerySmall
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryIcon(),
          SizedBox(height: 12),
          _buildSummaryContent(isVertical: true),
        ],
      )
          : Row(
        children: [
          _buildSummaryIcon(),
          SizedBox(width: screenSize == 'mobile' ? 12 : 16),
          Expanded(
            child: _buildSummaryContent(isVertical: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryIcon() {
    final screenSize = getScreenSize(context);

    return Container(
      padding: EdgeInsets.all(screenSize == 'mobile' ? 10 : 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.analytics,
        color: Colors.white,
        size: getResponsiveFontSize(context, 24),
      ),
    );
  }

  Widget _buildSummaryContent({required bool isVertical}) {
    final screenSize = getScreenSize(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiz Summary',
          style: TextStyle(
            fontSize: getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        isVertical
            ? Column(
          children: [
            _buildSummaryItem(
              'Correct',
              correctCount.toString(),
              const Color(0xFF00D4AA),
              Icons.check_circle,
              expanded: true,
            ),
            SizedBox(height: 8),
            _buildSummaryItem(
              'Wrong',
              wrongCount.toString(),
              Colors.red,
              Icons.cancel,
              expanded: true,
            ),
            SizedBox(height: 8),
            _buildSummaryItem(
              'Total',
              widget.questions.length.toString(),
              Colors.blue,
              Icons.quiz,
              expanded: true,
            ),
          ],
        )
            : Wrap(
          spacing: screenSize == 'mobile' ? 8 : 16,
          runSpacing: 8,
          children: [
            _buildSummaryItem(
              'Correct',
              correctCount.toString(),
              const Color(0xFF00D4AA),
              Icons.check_circle,
              expanded: false,
            ),
            _buildSummaryItem(
              'Wrong',
              wrongCount.toString(),
              Colors.red,
              Icons.cancel,
              expanded: false,
            ),
            _buildSummaryItem(
              'Total',
              widget.questions.length.toString(),
              Colors.blue,
              Icons.quiz,
              expanded: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon, {required bool expanded}) {
    final screenSize = getScreenSize(context);

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize == 'mobile' ? 10 : 12,
        vertical: screenSize == 'mobile' ? 6 : 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: getResponsiveFontSize(context, 16)),
          SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: getResponsiveFontSize(context, 10),
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return expanded ? Expanded(child: content) : content;
  }

  Widget _buildAnswersList() {
    final screenSize = getScreenSize(context);
    final padding = getResponsivePadding(context);

    return ListView.builder(
      padding: EdgeInsets.all(
        screenSize == 'desktop' ? 30 : padding.horizontal,
      ),
      itemCount: widget.questions.length,
      itemBuilder: (context, index) {
        final question = widget.questions[index];
        final userAnswer = widget.userAnswers.length > index ? widget.userAnswers[index] : '';
        final isCorrect = userAnswer == question.correctAnswer;
        final isEmpty = userAnswer.isEmpty;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenSize == 'desktop' ? 800 : double.infinity,
            ),
            child: Container(
              margin: EdgeInsets.only(bottom: screenSize == 'mobile' ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCorrect
                      ? const Color(0xFF00D4AA).withOpacity(0.3)
                      : isEmpty
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.all(screenSize == 'mobile' ? 16 : 20),
                  childrenPadding: EdgeInsets.fromLTRB(
                    screenSize == 'mobile' ? 16 : 20,
                    0,
                    screenSize == 'mobile' ? 16 : 20,
                    screenSize == 'mobile' ? 16 : 20,
                  ),
                  leading: Container(
                    width: screenSize == 'mobile' ? 36 : 40,
                    height: screenSize == 'mobile' ? 36 : 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCorrect
                            ? [const Color(0xFF00D4AA), const Color(0xFF00A8CC)]
                            : isEmpty
                            ? [Colors.orange, Colors.orange.shade700]
                            : [Colors.red, Colors.red.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isCorrect
                              ? const Color(0xFF00D4AA)
                              : isEmpty
                              ? Colors.orange
                              : Colors.red).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    question.question,
                    style: TextStyle(
                      fontSize: getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle
                              : isEmpty
                              ? Icons.help_outline
                              : Icons.cancel,
                          color: isCorrect
                              ? const Color(0xFF00D4AA)
                              : isEmpty
                              ? Colors.orange
                              : Colors.red,
                          size: getResponsiveFontSize(context, 16),
                        ),
                        SizedBox(width: 8),
                        Text(
                          isCorrect
                              ? 'Correct'
                              : isEmpty
                              ? 'No Answer'
                              : 'Incorrect',
                          style: TextStyle(
                            color: isCorrect
                                ? const Color(0xFF00D4AA)
                                : isEmpty
                                ? Colors.orange
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: getResponsiveFontSize(context, 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  iconColor: Colors.white,
                  collapsedIconColor: Colors.white.withOpacity(0.7),
                  children: [
                    _buildAnswerDetails(question, userAnswer, isCorrect, isEmpty),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerDetails(QuizQuestion question, String userAnswer, bool isCorrect, bool isEmpty) {
    final screenSize = getScreenSize(context);
    final isVerySmall = MediaQuery.of(context).size.width < 350;

    return Container(
      padding: EdgeInsets.all(screenSize == 'mobile' ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Answer Section
          Container(
            padding: EdgeInsets.all(screenSize == 'mobile' ? 10 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isCorrect
                      ? const Color(0xFF00D4AA)
                      : isEmpty
                      ? Colors.orange
                      : Colors.red).withOpacity(0.1),
                  (isCorrect
                      ? const Color(0xFF00D4AA)
                      : isEmpty
                      ? Colors.orange
                      : Colors.red).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isCorrect
                    ? const Color(0xFF00D4AA)
                    : isEmpty
                    ? Colors.orange
                    : Colors.red).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: isVerySmall
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: isCorrect
                          ? const Color(0xFF00D4AA)
                          : isEmpty
                          ? Colors.orange
                          : Colors.red,
                      size: getResponsiveFontSize(context, 16),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Your answer:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  isEmpty ? 'No answer provided' : userAnswer,
                  style: TextStyle(
                    color: isCorrect
                        ? const Color(0xFF00D4AA)
                        : isEmpty
                        ? Colors.orange
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: getResponsiveFontSize(context, 14),
                  ),
                ),
              ],
            )
                : Row(
              children: [
                Icon(
                  Icons.person,
                  color: isCorrect
                      ? const Color(0xFF00D4AA)
                      : isEmpty
                      ? Colors.orange
                      : Colors.red,
                  size: getResponsiveFontSize(context, 16),
                ),
                SizedBox(width: 8),
                Text(
                  'Your answer: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: getResponsiveFontSize(context, 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    isEmpty ? 'No answer provided' : userAnswer,
                    style: TextStyle(
                      color: isCorrect
                          ? const Color(0xFF00D4AA)
                          : isEmpty
                          ? Colors.orange
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: getResponsiveFontSize(context, 14),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Correct Answer Section
          Container(
            padding: EdgeInsets.all(screenSize == 'mobile' ? 10 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D4AA).withOpacity(0.1),
                  const Color(0xFF00D4AA).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00D4AA).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: isVerySmall
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: const Color(0xFF00D4AA),
                      size: getResponsiveFontSize(context, 16),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Correct answer:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  question.correctAnswer,
                  style: TextStyle(
                    color: const Color(0xFF00D4AA),
                    fontWeight: FontWeight.bold,
                    fontSize: getResponsiveFontSize(context, 14),
                  ),
                ),
              ],
            )
                : Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF00D4AA),
                  size: getResponsiveFontSize(context, 16),
                ),
                SizedBox(width: 8),
                Text(
                  'Correct answer: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: getResponsiveFontSize(context, 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    question.correctAnswer,
                    style: TextStyle(
                      color: const Color(0xFF00D4AA),
                      fontWeight: FontWeight.bold,
                      fontSize: getResponsiveFontSize(context, 14),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Explanation Section
          if (question.explanation.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(screenSize == 'mobile' ? 14 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.blue.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Colors.blue,
                        size: getResponsiveFontSize(context, 16),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Explanation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: getResponsiveFontSize(context, 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    question.explanation,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: getResponsiveFontSize(context, 14),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import '../../models/quiz_question.dart';
//
// class AnswersScreen extends StatefulWidget {
//   final List<QuizQuestion> questions;
//   final List<String> userAnswers;
//
//   const AnswersScreen({
//     super.key,
//     required this.questions,
//     required this.userAnswers,
//   });
//
//   @override
//   State<AnswersScreen> createState() => _AnswersScreenState();
// }
//
// class _AnswersScreenState extends State<AnswersScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _fadeController;
//   late Animation<double> _fadeAnimation;
//
//   int correctCount = 0;
//   int wrongCount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _fadeController = AnimationController(
//       duration: Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _fadeAnimation = CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeIn,
//     );
//
//     // Calculate correct and wrong answers
//     for (int i = 0; i < widget.questions.length; i++) {
//       final userAnswer = widget.userAnswers.length > i ? widget.userAnswers[i] : '';
//       if (userAnswer == widget.questions[i].correctAnswer) {
//         correctCount++;
//       } else {
//         wrongCount++;
//       }
//     }
//
//     _fadeController.forward();
//   }
//
//   @override
//   void dispose() {
//     _fadeController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color(0xFF0D1B2A),
//               Color(0xFF1B263B),
//               Color(0xFF415A77),
//             ],
//             stops: [0.0, 0.5, 1.0],
//           ),
//         ),
//         child: SafeArea(
//           child: FadeTransition(
//             opacity: _fadeAnimation,
//             child: Column(
//               children: [
//                 _buildHeader(),
//                 _buildSummaryCard(),
//                 Expanded(child: _buildAnswersList()),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.all(20.0),
//       child: Row(
//         children: [
//           GestureDetector(
//             onTap: () => Navigator.pop(context),
//             child: Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Colors.white.withOpacity(0.1),
//                     Colors.white.withOpacity(0.05),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.2),
//                   width: 1,
//                 ),
//               ),
//               child: Icon(
//                 Icons.arrow_back_ios,
//                 color: Color(0xFF00D4AA),
//                 size: 20,
//               ),
//             ),
//           ),
//           SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ShaderMask(
//                   shaderCallback: (bounds) => const LinearGradient(
//                     colors: [Color(0xFF00D4AA), Color(0xFF00A8CC), Colors.white],
//                     stops: [0.0, 0.5, 1.0],
//                   ).createShader(bounds),
//                   child: Text(
//                     'Review Answers',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   'Detailed quiz analysis',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.7),
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSummaryCard() {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 20),
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.white.withOpacity(0.15),
//             Colors.white.withOpacity(0.08),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.2),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             blurRadius: 15,
//             offset: Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
//               ),
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: const Color(0xFF00D4AA).withOpacity(0.3),
//                   blurRadius: 8,
//                   offset: Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Icon(
//               Icons.analytics,
//               color: Colors.white,
//               size: 24,
//             ),
//           ),
//           SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Quiz Summary',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Row(
//                   children: [
//                     _buildSummaryItem(
//                       'Correct',
//                       correctCount.toString(),
//                       const Color(0xFF00D4AA),
//                       Icons.check_circle,
//                     ),
//                     SizedBox(width: 16),
//                     _buildSummaryItem(
//                       'Wrong',
//                       wrongCount.toString(),
//                       Colors.red,
//                       Icons.cancel,
//                     ),
//                     SizedBox(width: 16),
//                     _buildSummaryItem(
//                       'Total',
//                       widget.questions.length.toString(),
//                       Colors.blue,
//                       Icons.quiz,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             color.withOpacity(0.2),
//             color.withOpacity(0.1),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: color.withOpacity(0.3),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color, size: 16),
//           SizedBox(width: 6),
//           Column(
//             children: [
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 10,
//                   color: Colors.white.withOpacity(0.7),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAnswersList() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(20),
//       itemCount: widget.questions.length,
//       itemBuilder: (context, index) {
//         final question = widget.questions[index];
//         final userAnswer = widget.userAnswers.length > index ? widget.userAnswers[index] : '';
//         final isCorrect = userAnswer == question.correctAnswer;
//         final isEmpty = userAnswer.isEmpty;
//
//         return Container(
//           margin: EdgeInsets.only(bottom: 20),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.white.withOpacity(0.1),
//                 Colors.white.withOpacity(0.05),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: isCorrect
//                   ? const Color(0xFF00D4AA).withOpacity(0.3)
//                   : isEmpty
//                   ? Colors.orange.withOpacity(0.3)
//                   : Colors.red.withOpacity(0.3),
//               width: 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//           child: ExpansionTile(
//             tilePadding: EdgeInsets.all(20),
//             childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
//             leading: Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: isCorrect
//                       ? [const Color(0xFF00D4AA), const Color(0xFF00A8CC)]
//                       : isEmpty
//                       ? [Colors.orange, Colors.orange.shade700]
//                       : [Colors.red, Colors.red.shade700],
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: (isCorrect
//                         ? const Color(0xFF00D4AA)
//                         : isEmpty
//                         ? Colors.orange
//                         : Colors.red).withOpacity(0.3),
//                     blurRadius: 8,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: Text(
//                   '${index + 1}',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//             title: Text(
//               question.question,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//                 height: 1.3,
//               ),
//             ),
//             subtitle: Padding(
//               padding: EdgeInsets.only(top: 8),
//               child: Row(
//                 children: [
//                   Icon(
//                     isCorrect
//                         ? Icons.check_circle
//                         : isEmpty
//                         ? Icons.help_outline
//                         : Icons.cancel,
//                     color: isCorrect
//                         ? const Color(0xFF00D4AA)
//                         : isEmpty
//                         ? Colors.orange
//                         : Colors.red,
//                     size: 16,
//                   ),
//                   SizedBox(width: 8),
//                   Text(
//                     isCorrect
//                         ? 'Correct'
//                         : isEmpty
//                         ? 'No Answer'
//                         : 'Incorrect',
//                     style: TextStyle(
//                       color: isCorrect
//                           ? const Color(0xFF00D4AA)
//                           : isEmpty
//                           ? Colors.orange
//                           : Colors.red,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             iconColor: Colors.white,
//             collapsedIconColor: Colors.white.withOpacity(0.7),
//             children: [
//               _buildAnswerDetails(question, userAnswer, isCorrect, isEmpty),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildAnswerDetails(QuizQuestion question, String userAnswer, bool isCorrect, bool isEmpty) {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.white.withOpacity(0.05),
//             Colors.white.withOpacity(0.02),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.1),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // User Answer Section
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   (isCorrect
//                       ? const Color(0xFF00D4AA)
//                       : isEmpty
//                       ? Colors.orange
//                       : Colors.red).withOpacity(0.1),
//                   (isCorrect
//                       ? const Color(0xFF00D4AA)
//                       : isEmpty
//                       ? Colors.orange
//                       : Colors.red).withOpacity(0.05),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: (isCorrect
//                     ? const Color(0xFF00D4AA)
//                     : isEmpty
//                     ? Colors.orange
//                     : Colors.red).withOpacity(0.3),
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.person,
//                   color: isCorrect
//                       ? const Color(0xFF00D4AA)
//                       : isEmpty
//                       ? Colors.orange
//                       : Colors.red,
//                   size: 16,
//                 ),
//                 SizedBox(width: 8),
//                 Text(
//                   'Your answer: ',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                     fontSize: 14,
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     isEmpty ? 'No answer provided' : userAnswer,
//                     style: TextStyle(
//                       color: isCorrect
//                           ? const Color(0xFF00D4AA)
//                           : isEmpty
//                           ? Colors.orange
//                           : Colors.red,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           SizedBox(height: 12),
//
//           // Correct Answer Section
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   const Color(0xFF00D4AA).withOpacity(0.1),
//                   const Color(0xFF00D4AA).withOpacity(0.05),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: const Color(0xFF00D4AA).withOpacity(0.3),
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.check_circle,
//                   color: const Color(0xFF00D4AA),
//                   size: 16,
//                 ),
//                 SizedBox(width: 8),
//                 Text(
//                   'Correct answer: ',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                     fontSize: 14,
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     question.correctAnswer,
//                     style: TextStyle(
//                       color: const Color(0xFF00D4AA),
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Explanation Section
//           if (question.explanation.isNotEmpty) ...[
//             SizedBox(height: 16),
//             Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Colors.blue.withOpacity(0.1),
//                     Colors.blue.withOpacity(0.05),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: Colors.blue.withOpacity(0.3),
//                   width: 1,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.lightbulb,
//                         color: Colors.blue,
//                         size: 16,
//                       ),
//                       SizedBox(width: 8),
//                       Text(
//                         'Explanation',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     question.explanation,
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.9),
//                       fontSize: 14,
//                       height: 1.4,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import '../../models/quiz_question.dart';
// class AnswersScreen extends StatelessWidget {
//   final List<QuizQuestion> questions;
//   final List<String> userAnswers;
//
//   const AnswersScreen({
//     super.key,
//     required this.questions,
//     required this.userAnswers,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Your Answers'),
//         backgroundColor: Colors.deepPurple,
//       ),
//       body: ListView.separated(
//         padding: const EdgeInsets.all(16),
//         itemCount: questions.length,
//         separatorBuilder: (_, __) => const SizedBox(height: 16),
//         itemBuilder: (context, index) {
//           final question = questions[index];
//           final userAnswer = userAnswers.length > index ? userAnswers[index] : '';
//           final isCorrect = userAnswer == question.correctAnswer;
//
//           return Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.shade300,
//                   blurRadius: 6,
//                   offset: const Offset(0, 3),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Q${index + 1}: ${question.question}",
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 RichText(
//                   text: TextSpan(
//                     text: "Your answer: ",
//                     style: const TextStyle(
//                         fontWeight: FontWeight.w600, color: Colors.black87),
//                     children: [
//                       TextSpan(
//                         text: userAnswer.isEmpty ? "No answer" : userAnswer,
//                         style: TextStyle(
//                           color: isCorrect ? Colors.green : Colors.red,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 RichText(
//                   text: TextSpan(
//                     text: "Correct answer: ",
//                     style: const TextStyle(
//                         fontWeight: FontWeight.w600, color: Colors.black87),
//                     children: [
//                       TextSpan(
//                         text: question.correctAnswer,
//                         style: const TextStyle(
//                           color: Colors.green,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (question.explanation.isNotEmpty) ...[
//                   const SizedBox(height: 12),
//                   Text(
//                     "Explanation:",
//                     style: TextStyle(
//                       fontWeight: FontWeight.w600,
//                       color: Colors.deepPurple.shade700,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     question.explanation,
//                     style: const TextStyle(color: Colors.black87),
//                   ),
//                 ],
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }