import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/programming_language.dart';
import 'coding_help_screen.dart';
import 'debug_screen.dart';
import 'explain_code_screen.dart';
import 'improve_code_screen.dart';
import 'challenge_screen.dart';
import 'login_screen.dart';
import 'notes/search_screen.dart';
import 'profile_screen.dart';
import 'quiz/quiz_screen.dart';
import 'dart:convert'; // For base64 decoding

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  String _userName = 'Developer';
  bool _isNavigating = false; // Prevent multiple navigations

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkUserAndInitialize();
  }

  // NEW: Check user authentication and initialize
  Future<void> _checkUserAndInitialize() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // No user found, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
                (route) => false,
          );
        }
      });
      return;
    }

    // User exists, proceed with initialization
    await _loadUserData();
    await _updateUserStatus();
  }

  Future<void> _logout() async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        // Navigate to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  // NEW: Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          final userData = userDoc.data();
          setState(() {
            _userName = userData?['fullName'] ?? user.displayName ?? 'Developer';
          });
        }
      }
    } catch (e) {
      // Handle silently, keep default name
    }
  }

  // NEW: Update user online status
  Future<void> _updateUserStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isOnline': true,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Handle silently
    }
  }

  // UPDATED: Simple and safe navigation method
  Future<void> _navigateToScreen(Widget screen) async {
    if (_isNavigating || !mounted) return;

    setState(() {
      _isNavigating = true;
    });

    // Small delay to ensure we're not in a build cycle
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    } catch (e) {
      // Handle navigation error silently
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation to splash screen
        return false;
      },
      child: Scaffold(
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
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? screenWidth * 0.05 : 0,
                ),
                child: Column(
                  children: [
                    _buildAppBar(),
                    _buildWelcomeSection(isLandscape),
                    _buildMainFeatures(isLandscape),
                    _buildQuickActions(isLandscape),
                    _buildLanguageSection(isLandscape),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Logo with glow effect
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4AA).withOpacity(0.3 * _pulseAnimation.value),
                      blurRadius: 15 * _pulseAnimation.value,
                      spreadRadius: 5 * _pulseAnimation.value,
                    ),
                  ],
                ),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                    ),
                  ),
                  child: const Icon(Icons.code, color: Colors.white, size: 24),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF00A8CC), Colors.white],
                stops: [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: const Text(
                'CodePulse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Updated Profile Avatar with image loading
          FutureBuilder<String?>(
            future: _loadProfileImage(), // Add this method to your class
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildDefaultProfileAvatar();
              }

              if (snapshot.hasData && snapshot.data != null) {
                return GestureDetector(
                  onTap: () async => await _navigateToScreen(const ProfileScreen()),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4AA).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      backgroundImage: MemoryImage(
                        base64Decode(snapshot.data!),
                      ),
                    ),
                  ),
                );
              }

              return _buildDefaultProfileAvatar();
            },
          ),
        ],
      ),
    );
  }

// Add these helper methods to your class
  Widget _buildDefaultProfileAvatar() {
    return GestureDetector(
      onTap: () async => await _navigateToScreen(const ProfileScreen()),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4AA).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white.withOpacity(0.1),
          child: const Icon(Icons.person, color: Color(0xFF00D4AA), size: 24),
        ),
      ),
    );
  }

  Future<String?> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final imageKey = 'profile_image_${user.uid}';
    return prefs.getString(imageKey);
  }

  Widget _buildWelcomeSection(bool isLandscape) {
    // Extract first name for more personal greeting
    final firstName = _userName.split(' ').first;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isLandscape ? 5 : 10
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $firstName! 👋',
            style: TextStyle(
              fontSize: isLandscape ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
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
              'What would you like to learn today? 🚀',
              style: TextStyle(
                color: const Color(0xFF00D4AA),
                fontSize: isLandscape ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFeatures(bool isLandscape) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? 15 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Core Features',
            style: TextStyle(
              fontSize: isLandscape ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isLandscape ? 12 : 16),
          _buildEnhancedFeatureCard(
            title: 'Ask Coding Questions',
            description: 'Get instant answers to your programming questions',
            icon: Icons.question_answer,
            gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            onTap: () async => await _navigateToScreen(const CodingHelpScreen()),
            isLandscape: isLandscape,
          ),
          _buildEnhancedFeatureCard(
            title: 'Debug Your Code',
            description: 'Find and fix issues in your code efficiently',
            icon: Icons.bug_report,
            gradient: const [Color(0xFFEF4444), Color(0xFFF97316)],
            onTap: () async => await _navigateToScreen(const DebugScreen()),
            isLandscape: isLandscape,
          ),
          _buildEnhancedFeatureCard(
            title: 'Explain Code',
            description: 'Get detailed explanations of how code works',
            icon: Icons.school,
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            onTap: () async => await _navigateToScreen(const ExplainCodeScreen()),
            isLandscape: isLandscape,
          ),
          _buildEnhancedFeatureCard(
            title: 'Improve Your Code',
            description: 'Get suggestions to enhance your code quality',
            icon: Icons.auto_fix_high,
            gradient: const [Color(0xFF8B5CF6), Color(0xFFA855F7)],
            onTap: () async => await _navigateToScreen(const ImproveCodeScreen()),
            isLandscape: isLandscape,
          ),
          _buildEnhancedFeatureCard(
            title: 'Coding Challenges',
            description: 'Practice with challenges and get instant feedback',
            icon: Icons.fitness_center,
            gradient: const [Color(0xFFF97316), Color(0xFFEAB308)],
            onTap: () async => await _navigateToScreen(const ChallengeScreen()),
            isLandscape: isLandscape,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isLandscape) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isLandscape ? 15 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: isLandscape ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isLandscape ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Take Quiz',
                  subtitle: 'Test Your Skills',
                  icon: Icons.quiz,
                  gradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                  onTap: () async => await _navigateToScreen(const QuizScreen()),
                  isLandscape: isLandscape,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Watch Videos',
                  subtitle: 'Learn Visually',
                  icon: Icons.video_library,
                  gradient: const [Color(0xFFDC2626), Color(0xFFEA580C)],
                  onTap: () async => await _navigateToScreen(const SearchPage()),
                  isLandscape: isLandscape,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(bool isLandscape) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? 15 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code, color: Color(0xFF00D4AA), size: 24),
              const SizedBox(width: 8),
              Text(
                'Supported Languages',
                style: TextStyle(
                  fontSize: isLandscape ? 20 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: isLandscape ? 12 : 16),
          _buildEnhancedLanguageGrid(isLandscape),
        ],
      ),
    );
  }

  Widget _buildEnhancedFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradient,
    required Future<void> Function() onTap,
    required bool isLandscape,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLandscape ? 12 : 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isNavigating ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedOpacity(
            opacity: _isNavigating ? 0.6 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: EdgeInsets.all(isLandscape ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
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
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isLandscape ? 14 : 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gradient[0].withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: isLandscape ? 24 : 28,
                    ),
                  ),
                  SizedBox(width: isLandscape ? 16 : 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: isLandscape ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isLandscape ? 4 : 6),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: isLandscape ? 12 : 14,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF00D4AA),
                      size: 16,
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

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required Future<void> Function() onTap,
    required bool isLandscape,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isNavigating ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedOpacity(
          opacity: _isNavigating ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: isLandscape ? 120 : 150,
            padding: EdgeInsets.all(isLandscape ? 12 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
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
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(isLandscape ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isLandscape ? 18 : 22,
                  ),
                ),
                SizedBox(height: isLandscape ? 8 : 10),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isLandscape ? 13 : 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: isLandscape ? 2 : 4),
                Flexible(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isLandscape ? 10 : 11,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedLanguageGrid(bool isLandscape) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLandscape ? 6 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: ProgrammingLanguages.languages.length,
      itemBuilder: (context, index) {
        final language = ProgrammingLanguages.languages[index];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                language.icon,
                style: TextStyle(fontSize: isLandscape ? 20 : 24),
              ),
              SizedBox(height: isLandscape ? 4 : 6),
              Text(
                language.name,
                style: TextStyle(
                  fontSize: isLandscape ? 10 : 11,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}


//
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/programming_language.dart';
// import 'coding_help_screen.dart';
// import 'debug_screen.dart';
// import 'explain_code_screen.dart';
// import 'improve_code_screen.dart';
// import 'challenge_screen.dart';
// import 'login_screen.dart';
// import 'notes/search_screen.dart';
// import 'profile_screen.dart';
// import 'quiz/quiz_screen.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
//   late AnimationController _pulseController;
//   late AnimationController _fadeController;
//   late Animation<double> _pulseAnimation;
//   late Animation<double> _fadeAnimation;
//
//   String _userName = 'Developer';
//   bool _isNavigating = false; // Prevent multiple navigations
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _checkUserAndInitialize();
//   }
//
//   // NEW: Check user authentication and initialize
//   Future<void> _checkUserAndInitialize() async {
//     final user = FirebaseAuth.instance.currentUser;
//
//     if (user == null) {
//       // No user found, redirect to login
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
//                 (route) => false,
//           );
//         }
//       });
//       return;
//     }
//
//     // User exists, proceed with initialization
//     await _loadUserData();
//     await _updateUserStatus();
//   }
//
//   Future<void> _logout() async {
//     try {
//       // Sign out from Firebase
//       await FirebaseAuth.instance.signOut();
//
//       // Clear SharedPreferences
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.clear();
//
//       if (mounted) {
//         // Navigate to login screen
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
//               (route) => false,
//         );
//       }
//     } catch (e) {
//       // Handle error silently
//     }
//   }
//
//   void _initializeAnimations() {
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     );
//
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _pulseAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.05,
//     ).animate(CurvedAnimation(
//       parent: _pulseController,
//       curve: Curves.easeInOut,
//     ));
//
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeIn,
//     ));
//
//     _pulseController.repeat(reverse: true);
//     _fadeController.forward();
//   }
//
//   // NEW: Load user data from Firestore
//   Future<void> _loadUserData() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         final userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .get();
//
//         if (userDoc.exists && mounted) {
//           final userData = userDoc.data();
//           setState(() {
//             _userName = userData?['fullName'] ?? user.displayName ?? 'Developer';
//           });
//         }
//       }
//     } catch (e) {
//       // Handle silently, keep default name
//     }
//   }
//
//   // NEW: Update user online status
//   Future<void> _updateUserStatus() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .update({
//           'isOnline': true,
//           'lastActiveAt': FieldValue.serverTimestamp(),
//         });
//       }
//     } catch (e) {
//       // Handle silently
//     }
//   }
//
//   // UPDATED: Simple and safe navigation method
//   Future<void> _navigateToScreen(Widget screen) async {
//     if (_isNavigating || !mounted) return;
//
//     setState(() {
//       _isNavigating = true;
//     });
//
//     // Small delay to ensure we're not in a build cycle
//     await Future.delayed(const Duration(milliseconds: 100));
//
//     if (!mounted) return;
//
//     try {
//       await Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => screen),
//       );
//     } catch (e) {
//       // Handle navigation error silently
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isNavigating = false;
//         });
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _fadeController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
//
//     return WillPopScope(
//       onWillPop: () async {
//         // Prevent back navigation to splash screen
//         return false;
//       },
//       child: Scaffold(
//         body: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Color(0xFF0D1B2A),
//                 Color(0xFF1B263B),
//                 Color(0xFF415A77),
//               ],
//               stops: [0.0, 0.5, 1.0],
//             ),
//           ),
//           child: SafeArea(
//             child: FadeTransition(
//               opacity: _fadeAnimation,
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isLandscape ? screenWidth * 0.05 : 0,
//                 ),
//                 child: Column(
//                   children: [
//                     _buildAppBar(),
//                     _buildWelcomeSection(isLandscape),
//                     _buildMainFeatures(isLandscape),
//                     _buildQuickActions(isLandscape),
//                     _buildLanguageSection(isLandscape),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAppBar() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       child: Row(
//         children: [
//           // Logo with glow effect
//           AnimatedBuilder(
//             animation: _pulseAnimation,
//             builder: (context, child) {
//               return Container(
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color(0xFF00D4AA).withOpacity(0.3 * _pulseAnimation.value),
//                       blurRadius: 15 * _pulseAnimation.value,
//                       spreadRadius: 5 * _pulseAnimation.value,
//                     ),
//                   ],
//                 ),
//                 child: Container(
//                   width: 45,
//                   height: 45,
//                   decoration: const BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
//                     ),
//                   ),
//                   child: const Icon(Icons.code, color: Colors.white, size: 24),
//                 ),
//               );
//             },
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: ShaderMask(
//               shaderCallback: (bounds) => const LinearGradient(
//                 colors: [Color(0xFF00D4AA), Color(0xFF00A8CC), Colors.white],
//                 stops: [0.0, 0.5, 1.0],
//               ).createShader(bounds),
//               child: const Text(
//                 'CodePulse',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 1.0,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           // Profile Avatar with glow - Removed logout button
//           GestureDetector(
//             onTap: () async => await _navigateToScreen(const ProfileScreen()),
//             child: Container(
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xFF00D4AA).withOpacity(0.3),
//                     blurRadius: 10,
//                     spreadRadius: 2,
//                   ),
//                 ],
//               ),
//               child: CircleAvatar(
//                 radius: 22,
//                 backgroundColor: Colors.white.withOpacity(0.1),
//                 child: const Icon(Icons.person, color: Color(0xFF00D4AA), size: 24),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildWelcomeSection(bool isLandscape) {
//     // Extract first name for more personal greeting
//     final firstName = _userName.split(' ').first;
//
//     return Container(
//       padding: EdgeInsets.symmetric(
//           horizontal: 20,
//           vertical: isLandscape ? 5 : 10
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Hello, $firstName! 👋',
//             style: TextStyle(
//               fontSize: isLandscape ? 24 : 28,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   const Color(0xFF00D4AA).withOpacity(0.2),
//                   const Color(0xFF00A8CC).withOpacity(0.2),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: const Color(0xFF00D4AA).withOpacity(0.3),
//                 width: 1,
//               ),
//             ),
//             child: Text(
//               'What would you like to learn today? 🚀',
//               style: TextStyle(
//                 color: const Color(0xFF00D4AA),
//                 fontSize: isLandscape ? 14 : 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMainFeatures(bool isLandscape) {
//     return Container(
//       padding: EdgeInsets.all(isLandscape ? 15 : 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Core Features',
//             style: TextStyle(
//               fontSize: isLandscape ? 20 : 22,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           SizedBox(height: isLandscape ? 12 : 16),
//           _buildEnhancedFeatureCard(
//             title: 'Ask Coding Questions',
//             description: 'Get instant answers to your programming questions',
//             icon: Icons.question_answer,
//             gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
//             onTap: () async => await _navigateToScreen(const CodingHelpScreen()),
//             isLandscape: isLandscape,
//           ),
//           _buildEnhancedFeatureCard(
//             title: 'Debug Your Code',
//             description: 'Find and fix issues in your code efficiently',
//             icon: Icons.bug_report,
//             gradient: const [Color(0xFFEF4444), Color(0xFFF97316)],
//             onTap: () async => await _navigateToScreen(const DebugScreen()),
//             isLandscape: isLandscape,
//           ),
//           _buildEnhancedFeatureCard(
//             title: 'Explain Code',
//             description: 'Get detailed explanations of how code works',
//             icon: Icons.school,
//             gradient: const [Color(0xFF10B981), Color(0xFF059669)],
//             onTap: () async => await _navigateToScreen(const ExplainCodeScreen()),
//             isLandscape: isLandscape,
//           ),
//           _buildEnhancedFeatureCard(
//             title: 'Improve Your Code',
//             description: 'Get suggestions to enhance your code quality',
//             icon: Icons.auto_fix_high,
//             gradient: const [Color(0xFF8B5CF6), Color(0xFFA855F7)],
//             onTap: () async => await _navigateToScreen(const ImproveCodeScreen()),
//             isLandscape: isLandscape,
//           ),
//           _buildEnhancedFeatureCard(
//             title: 'Coding Challenges',
//             description: 'Practice with challenges and get instant feedback',
//             icon: Icons.fitness_center,
//             gradient: const [Color(0xFFF97316), Color(0xFFEAB308)],
//             onTap: () async => await _navigateToScreen(const ChallengeScreen()),
//             isLandscape: isLandscape,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQuickActions(bool isLandscape) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: isLandscape ? 15 : 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Quick Actions',
//             style: TextStyle(
//               fontSize: isLandscape ? 20 : 22,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           SizedBox(height: isLandscape ? 12 : 16),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildQuickActionCard(
//                   title: 'Take Quiz',
//                   subtitle: 'Test Your Skills',
//                   icon: Icons.quiz,
//                   gradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
//                   onTap: () async => await _navigateToScreen(const QuizScreen()),
//                   isLandscape: isLandscape,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: _buildQuickActionCard(
//                   title: 'Watch Videos',
//                   subtitle: 'Learn Visually',
//                   icon: Icons.video_library,
//                   gradient: const [Color(0xFFDC2626), Color(0xFFEA580C)],
//                   onTap: () async => await _navigateToScreen(const SearchPage()),
//                   isLandscape: isLandscape,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLanguageSection(bool isLandscape) {
//     return Container(
//       padding: EdgeInsets.all(isLandscape ? 15 : 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.code, color: Color(0xFF00D4AA), size: 24),
//               const SizedBox(width: 8),
//               Text(
//                 'Supported Languages',
//                 style: TextStyle(
//                   fontSize: isLandscape ? 20 : 22,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: isLandscape ? 12 : 16),
//           _buildEnhancedLanguageGrid(isLandscape),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEnhancedFeatureCard({
//     required String title,
//     required String description,
//     required IconData icon,
//     required List<Color> gradient,
//     required Future<void> Function() onTap,
//     required bool isLandscape,
//   }) {
//     return Container(
//       margin: EdgeInsets.only(bottom: isLandscape ? 12 : 16),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: _isNavigating ? null : onTap,
//           borderRadius: BorderRadius.circular(20),
//           child: AnimatedOpacity(
//             opacity: _isNavigating ? 0.6 : 1.0,
//             duration: const Duration(milliseconds: 200),
//             child: Container(
//               padding: EdgeInsets.all(isLandscape ? 16 : 20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     Colors.white.withOpacity(0.1),
//                     Colors.white.withOpacity(0.05),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.1),
//                   width: 1,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 15,
//                     offset: const Offset(0, 8),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(isLandscape ? 14 : 16),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(colors: gradient),
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: gradient[0].withOpacity(0.3),
//                           blurRadius: 10,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Icon(
//                       icon,
//                       color: Colors.white,
//                       size: isLandscape ? 24 : 28,
//                     ),
//                   ),
//                   SizedBox(width: isLandscape ? 16 : 20),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           title,
//                           style: TextStyle(
//                             fontSize: isLandscape ? 16 : 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         SizedBox(height: isLandscape ? 4 : 6),
//                         Text(
//                           description,
//                           style: TextStyle(
//                             fontSize: isLandscape ? 12 : 14,
//                             color: Colors.white.withOpacity(0.7),
//                             height: 1.3,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Icon(
//                       Icons.arrow_forward_ios,
//                       color: Color(0xFF00D4AA),
//                       size: 16,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickActionCard({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required List<Color> gradient,
//     required Future<void> Function() onTap,
//     required bool isLandscape,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: _isNavigating ? null : onTap,
//         borderRadius: BorderRadius.circular(20),
//         child: AnimatedOpacity(
//           opacity: _isNavigating ? 0.6 : 1.0,
//           duration: const Duration(milliseconds: 200),
//           child: Container(
//             height: isLandscape ? 120 : 150,
//             padding: EdgeInsets.all(isLandscape ? 12 : 16),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   Colors.white.withOpacity(0.1),
//                   Colors.white.withOpacity(0.05),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.1),
//                 width: 1,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   blurRadius: 15,
//                   offset: const Offset(0, 8),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(isLandscape ? 8 : 10),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(colors: gradient),
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                         color: gradient[0].withOpacity(0.3),
//                         blurRadius: 8,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Icon(
//                     icon,
//                     color: Colors.white,
//                     size: isLandscape ? 18 : 22,
//                   ),
//                 ),
//                 SizedBox(height: isLandscape ? 8 : 10),
//                 Flexible(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: isLandscape ? 13 : 15,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                     textAlign: TextAlign.center,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 SizedBox(height: isLandscape ? 2 : 4),
//                 Flexible(
//                   child: Text(
//                     subtitle,
//                     style: TextStyle(
//                       fontSize: isLandscape ? 10 : 11,
//                       color: Colors.white.withOpacity(0.6),
//                     ),
//                     textAlign: TextAlign.center,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEnhancedLanguageGrid(bool isLandscape) {
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: isLandscape ? 6 : 4,
//         crossAxisSpacing: 12,
//         mainAxisSpacing: 12,
//         childAspectRatio: 1,
//       ),
//       itemCount: ProgrammingLanguages.languages.length,
//       itemBuilder: (context, index) {
//         final language = ProgrammingLanguages.languages[index];
//         return Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Colors.white.withOpacity(0.1),
//                 Colors.white.withOpacity(0.05),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.1),
//               width: 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 language.icon,
//                 style: TextStyle(fontSize: isLandscape ? 20 : 24),
//               ),
//               SizedBox(height: isLandscape ? 4 : 6),
//               Text(
//                 language.name,
//                 style: TextStyle(
//                   fontSize: isLandscape ? 10 : 11,
//                   color: Colors.white.withOpacity(0.8),
//                   fontWeight: FontWeight.w500,
//                 ),
//                 textAlign: TextAlign.center,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }