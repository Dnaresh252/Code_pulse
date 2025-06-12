
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/quiz_question.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'solution_screen.dart';

class ScoreScreen extends StatefulWidget {
  final int correct;
  final int wrong;
  final List<QuizQuestion> questions;
  final List<String> userAnswers;
  final String language;     // ✅ NEW: Add this
  final String difficulty;   // ✅ NEW: Add this

  const ScoreScreen({
    super.key,
    required this.correct,
    required this.wrong,
    required this.questions,
    required this.userAnswers,
    required this.language,     // ✅ NEW: Add this
    required this.difficulty,   // ✅ NEW: Add this
  });

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _pointsController;
  late AnimationController _shimmerController;
  late AnimationController _bounceController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<int> _pointsAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _bounceAnimation;

  bool _showConfetti = false;
  int _currentPoints = 0;
  int _totalPoints = 0;
  int _earnedPoints = 0;
  int _quizzesTaken = 0;
  int _newQuizCount = 0;
  bool _pointsAnimationComplete = false;
  bool _isNewRecord = false;
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _calculatePoints();
    _loadUserStats();
  }

  void _initializeControllers() {
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pointsController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  void _initializeAnimations() {
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _pointsAnimation = IntTween(
      begin: _currentPoints,
      end: _currentPoints + _earnedPoints,
    ).animate(CurvedAnimation(
      parent: _pointsController,
      curve: Curves.easeOutQuart,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
  }

  // ✅ NEW: Enhanced difficulty-based scoring system
  void _calculatePoints() {
    final int total = widget.correct + widget.wrong;
    final double percent = total == 0 ? 0 : widget.correct / total;

    // Base points for correct answers with difficulty multiplier
    int basePoints = widget.correct * _getDifficultyMultiplier();

    // Performance bonuses (scaled by difficulty)
    int performanceBonus = _getPerformanceBonus(percent);

    // Perfect score mega bonus
    if (widget.wrong == 0 && widget.correct > 0) {
      basePoints += _getDifficultyPerfectBonus();
      _isNewRecord = true;
    }

    // Quiz completion bonus
    basePoints += _getDifficultyCompletionBonus();

    _earnedPoints = basePoints + performanceBonus;
  }

  // ✅ NEW: Difficulty-based scoring methods
  int _getDifficultyMultiplier() {
    switch (widget.difficulty.toLowerCase()) {
      case 'easy': return 10;
      case 'medium': return 15;
      case 'hard': return 25;
      default: return 10;
    }
  }

  int _getPerformanceBonus(double percent) {
    int baseBonus = 0;
    if (percent >= 0.95) {
      baseBonus = 100;
      _isNewRecord = true;
    } else if (percent >= 0.9) {
      baseBonus = 75;
    } else if (percent >= 0.8) {
      baseBonus = 50;
    } else if (percent >= 0.7) {
      baseBonus = 30;
    } else if (percent >= 0.6) {
      baseBonus = 15;
    } else if (percent >= 0.5) {
      baseBonus = 5;
    }

    // Scale bonus by difficulty
    switch (widget.difficulty.toLowerCase()) {
      case 'easy': return (baseBonus * 0.8).round();
      case 'medium': return baseBonus;
      case 'hard': return (baseBonus * 1.5).round();
      default: return baseBonus;
    }
  }

  int _getDifficultyPerfectBonus() {
    switch (widget.difficulty.toLowerCase()) {
      case 'easy': return 30;
      case 'medium': return 50;
      case 'hard': return 100;
      default: return 50;
    }
  }

  int _getDifficultyCompletionBonus() {
    switch (widget.difficulty.toLowerCase()) {
      case 'easy': return 10;
      case 'medium': return 20;
      case 'hard': return 35;
      default: return 20;
    }
  }

  // ✅ NEW: User level system
  String _getUserLevel() {
    if (_totalPoints >= 5000) return 'Expert';
    if (_totalPoints >= 3000) return 'Advanced';
    if (_totalPoints >= 1500) return 'Intermediate';
    if (_totalPoints >= 500) return 'Beginner';
    return 'Rookie';
  }

  Color _getLevelColor() {
    final level = _getUserLevel();
    switch (level) {
      case 'Expert': return Colors.purple;
      case 'Advanced': return const Color(0xFF00D4AA);
      case 'Intermediate': return Colors.blue;
      case 'Beginner': return Colors.orange;
      default: return Colors.grey;
    }
  }

  // ✅ NEW: Difficulty color and icon methods
  Color _getDifficultyColor() {
    switch (widget.difficulty.toLowerCase()) {
      case 'easy': return Colors.green;
      case 'medium': return Colors.orange;
      case 'hard': return Colors.red;
      default: return Colors.blue;
    }
  }

  IconData _getDifficultyIcon() {
    switch (widget.difficulty.toLowerCase()) {
      case 'easy': return Icons.sentiment_satisfied;
      case 'medium': return Icons.sentiment_neutral;
      case 'hard': return Icons.sentiment_very_dissatisfied;
      default: return Icons.help_outline;
    }
  }
  // ✅ UPDATED: User-specific data loading
  Future<void> _loadUserStats() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return; // No user logged in

    setState(() {
      _currentPoints = prefs.getInt('${userId}_user_points') ?? 0;
      _quizzesTaken = prefs.getInt('${userId}_quizzes_taken') ?? 0;
      _totalPoints = _currentPoints + _earnedPoints;
      _newQuizCount = _quizzesTaken + 1;
    });

    // Update points animation with current values
    _pointsAnimation = IntTween(
      begin: _currentPoints,
      end: _totalPoints,
    ).animate(CurvedAnimation(
      parent: _pointsController,
      curve: Curves.easeOutQuart,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();

      Future.delayed(const Duration(milliseconds: 300), () {
        _slideController.forward();
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        _pulseController.repeat(reverse: true);
        _shimmerController.repeat();
      });

      // Points animation
      Future.delayed(const Duration(milliseconds: 1000), () {
        _pointsController.forward().then((_) {
          setState(() => _pointsAnimationComplete = true);
          _bounceController.forward();
          _saveUserStats();
        });
      });

      // Confetti for good performance
      final percent = widget.correct / (widget.correct + widget.wrong);
      if (percent >= 0.7) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          setState(() => _showConfetti = true);
          _confettiController.play();
        });
      }
    });
  }

  // ✅ UPDATED: User-specific data saving
  Future<void> _saveUserStats() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return; // No user logged in

    await prefs.setInt('${userId}_user_points', _totalPoints);
    await prefs.setInt('${userId}_quizzes_taken', _newQuizCount);

    // Save best score if this is a new record
    final bestScore = prefs.getInt('${userId}_best_score') ?? 0;
    if (_earnedPoints > bestScore) {
      await prefs.setInt('${userId}_best_score', _earnedPoints);
    }

    // ✅ NEW: Save language-specific stats
    final languageKey = '${userId}_${widget.language.toLowerCase()}_quizzes';
    final languageCount = prefs.getInt(languageKey) ?? 0;
    await prefs.setInt(languageKey, languageCount + 1);

    // ✅ NEW: Save difficulty-specific stats
    final difficultyKey = '${userId}_${widget.difficulty.toLowerCase()}_quizzes';
    final difficultyCount = prefs.getInt(difficultyKey) ?? 0;
    await prefs.setInt(difficultyKey, difficultyCount + 1);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _pointsController.dispose();
    _shimmerController.dispose();
    _bounceController.dispose();
    super.dispose();
  }
  // Responsive helper methods for mobile-first design
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isLandscape = width > height;

    // Scale based on screen width with landscape consideration
    double scaleFactor = (width / 375).clamp(0.8, 1.6);

    if (isLandscape) {
      scaleFactor *= 0.9; // Slightly smaller in landscape
    }

    return baseSize * scaleFactor;
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    if (isLandscape) {
      return EdgeInsets.symmetric(
        horizontal: size.width * 0.08,
        vertical: size.height * 0.05,
      );
    }

    return EdgeInsets.symmetric(
      horizontal: size.width * 0.06,
      vertical: size.height * 0.03,
    );
  }

  double _getResponsiveCircleRadius(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final smallerDimension = size.width < size.height ? size.width : size.height;
    return (smallerDimension * 0.2).clamp(70.0, 130.0);
  }

  String _getPerformanceMessage(double percent) {
    if (percent >= 0.95) return 'Perfect! 🏆';
    if (percent >= 0.9) return 'Outstanding! 🌟';
    if (percent >= 0.8) return 'Excellent! 🎉';
    if (percent >= 0.7) return 'Great Job! 👏';
    if (percent >= 0.6) return 'Good Work! 👍';
    if (percent >= 0.5) return 'Nice Try! 💪';
    return 'Keep Going! 🚀';
  }

  Color _getPerformanceColor(double percent) {
    if (percent >= 0.9) return const Color(0xFF00D4AA);
    if (percent >= 0.8) return const Color(0xFF00A8CC);
    if (percent >= 0.7) return Colors.blue;
    if (percent >= 0.6) return Colors.orange;
    if (percent >= 0.5) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.correct + widget.wrong;
    final double percent = total == 0 ? 0 : widget.correct / total;
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
              Color(0xFF778DA9),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: _getResponsivePadding(context),
                  child: isLandscape
                      ? _buildLandscapeLayout(percent, total)
                      : _buildPortraitLayout(percent, total),
                ),
              ),
              if (_showConfetti) _buildConfetti(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(double percent, int total) {
    return Column(
      children: [
        _buildHeader(),
        SizedBox(height: _getResponsiveFontSize(context, 20)),
        _buildPointsCard(),
        SizedBox(height: _getResponsiveFontSize(context, 25)),
        _buildScoreCard(percent, total),
        SizedBox(height: _getResponsiveFontSize(context, 25)),
        _buildStatsSection(),
        SizedBox(height: _getResponsiveFontSize(context, 30)),
        _buildActionButtons(),
        SizedBox(height: _getResponsiveFontSize(context, 20)),
      ],
    );
  }

  Widget _buildLandscapeLayout(double percent, int total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 15),
              _buildScoreCard(percent, total),
            ],
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildPointsCard(),
              SizedBox(height: 20),
              _buildStatsSection(),
              SizedBox(height: 25),
              _buildActionButtons(),
            ],
          ),
        ),
      ],
    );
  }
  // ✅ UPDATED: Enhanced header with language, difficulty, and level
  Widget _buildHeader() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          // Language and Difficulty Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveFontSize(context, 16),
              vertical: _getResponsiveFontSize(context, 8),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getDifficultyColor().withOpacity(0.3),
                  _getDifficultyColor().withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getDifficultyColor().withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getDifficultyIcon(),
                  color: _getDifficultyColor(),
                  size: _getResponsiveFontSize(context, 16),
                ),
                SizedBox(width: 8),
                Text(
                  '${widget.language} • ${widget.difficulty}',
                  style: TextStyle(
                    color: _getDifficultyColor(),
                    fontSize: _getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: _getResponsiveFontSize(context, 16)),

          // User Level Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveFontSize(context, 20),
              vertical: _getResponsiveFontSize(context, 10),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_getLevelColor(), _getLevelColor().withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: _getLevelColor().withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.military_tech,
                  color: Colors.white,
                  size: _getResponsiveFontSize(context, 20),
                ),
                SizedBox(width: 8),
                Text(
                  _getUserLevel(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: _getResponsiveFontSize(context, 20)),

          // Trophy Icon
          Container(
            padding: EdgeInsets.all(_getResponsiveFontSize(context, 16)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4AA).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: _getResponsiveFontSize(context, 35),
            ),
          ),
          SizedBox(height: _getResponsiveFontSize(context, 15)),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF00A8CC), Colors.white],
              stops: [0.0, 0.5, 1.0],
            ).createShader(bounds),
            child: Text(
              'Quiz Complete!',
              style: TextStyle(
                color: Colors.white,
                fontSize: _getResponsiveFontSize(context, 28),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Enhanced points card with better information
  Widget _buildPointsCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pointsAnimation, _shimmerAnimation, _bounceAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pointsAnimationComplete ? _bounceAnimation.value : 1.0,
          child: Container(
            padding: EdgeInsets.all(_getResponsiveFontSize(context, 20)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D4AA).withOpacity(0.2),
                  const Color(0xFF00A8CC).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00D4AA).withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4AA).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Shimmer effect
                if (!_pointsAnimationComplete)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(_shimmerAnimation.value - 1, 0),
                            end: Alignment(_shimmerAnimation.value, 0),
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: const Color(0xFF00D4AA),
                          size: _getResponsiveFontSize(context, 24),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Points Earned',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _getResponsiveFontSize(context, 10)),

                    // Points with multiplier info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '+${_pointsAnimationComplete ? _earnedPoints : _pointsAnimation.value - _currentPoints}',
                          style: TextStyle(
                            color: const Color(0xFF00D4AA),
                            fontSize: _getResponsiveFontSize(context, 32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_getDifficultyColor(), _getDifficultyColor().withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_getDifficultyMultiplier()}x',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _getResponsiveFontSize(context, 12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        if (_isNewRecord && _pointsAnimationComplete)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.amber, Colors.orange],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'NEW RECORD!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _getResponsiveFontSize(context, 10),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: _getResponsiveFontSize(context, 8)),
                    Text(
                      'Total: ${_pointsAnimationComplete ? _totalPoints : _pointsAnimation.value}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: _getResponsiveFontSize(context, 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: _getResponsiveFontSize(context, 8)),
                    // Level progress hint
                    Text(
                      _getNextLevelHint(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: _getResponsiveFontSize(context, 12),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ NEW: Helper method for next level hint
  String _getNextLevelHint() {
    final currentLevel = _getUserLevel();
    switch (currentLevel) {
      case 'Rookie':
        return 'Reach 500 points to become a Beginner!';
      case 'Beginner':
        return 'Reach 1,500 points to become Intermediate!';
      case 'Intermediate':
        return 'Reach 3,000 points to become Advanced!';
      case 'Advanced':
        return 'Reach 5,000 points to become an Expert!';
      case 'Expert':
        return 'You\'ve reached the highest level! 🏆';
      default:
        return 'Keep learning and earning points!';
    }
  }
  Widget _buildScoreCard(double percent, int total) {
    final circleRadius = _getResponsiveCircleRadius(context);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.all(_getResponsiveFontSize(context, 25)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: _getPerformanceColor(percent).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _getPerformanceMessage(percent),
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 24),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: _getResponsiveFontSize(context, 25)),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect
                    Container(
                      width: circleRadius * 2.3,
                      height: circleRadius * 2.3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _getPerformanceColor(percent).withOpacity(0.3),
                            _getPerformanceColor(percent).withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    CircularPercentIndicator(
                      radius: circleRadius,
                      lineWidth: circleRadius * 0.12,
                      animation: true,
                      animationDuration: 2000,
                      percent: percent,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                _getPerformanceColor(percent),
                                _getPerformanceColor(percent).withOpacity(0.8),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              "${(percent * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 28),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "${widget.correct}/$total",
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 12),
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      progressColor: _getPerformanceColor(percent),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.all(_getResponsiveFontSize(context, 18)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
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
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: const Color(0xFF00D4AA),
                size: _getResponsiveFontSize(context, 22),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your Statistics',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveFontSize(context, 15)),
          // First row of stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Correct",
                  widget.correct.toString(),
                  Icons.check_circle_rounded,
                  const Color(0xFF00D4AA),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Wrong",
                  widget.wrong.toString(),
                  Icons.cancel_rounded,
                  Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Second row of stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Total Questions",
                  (widget.correct + widget.wrong).toString(),
                  Icons.quiz_rounded,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Quizzes Taken",
                  _newQuizCount.toString(),
                  Icons.history_edu_rounded,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(_getResponsiveFontSize(context, 12)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(_getResponsiveFontSize(context, 8)),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: _getResponsiveFontSize(context, 18),
            ),
          ),
          SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 10),
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.replay_rounded,
          label: "Try Again",
          onPressed: () => Navigator.pop(context),
          gradient: [const Color(0xFF00D4AA), const Color(0xFF00A8CC)],
          isPrimary: true,
        ),
        SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.visibility_rounded,
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
          gradient: [Colors.blue, Colors.blue.shade700],
          isPrimary: false,
        ),
        SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.home_rounded,
          label: "Return Home",
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          gradient: [Colors.grey.shade600, Colors.grey.shade700],
          isPrimary: false,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required List<Color> gradient,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      height: _getResponsiveFontSize(context, 50),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(colors: gradient)
            : LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary
              ? Colors.transparent
              : Colors.white.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: isPrimary
            ? [
          BoxShadow(
            color: gradient[0].withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: _getResponsiveFontSize(context, 22),
                ),
                SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return Stack(
      children: [
        // Top confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3.14, // downward
            emissionFrequency: 0.03,
            numberOfParticles: 15,
            gravity: 0.08,
            colors: const [
              Color(0xFF00D4AA),
              Color(0xFF00A8CC),
              Colors.blue,
              Colors.purple,
              Colors.orange,
              Colors.amber,
            ],
          ),
        ),
        // Center explosive confetti
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 25,
            colors: const [
              Color(0xFF00D4AA),
              Color(0xFF00A8CC),
              Colors.blue,
              Colors.purple,
              Colors.orange,
              Colors.amber,
            ],
          ),
        ),
      ],
    );
  }
}
