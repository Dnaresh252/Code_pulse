import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'email_change_verification_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  String userName = "Loading...";
  String userEmail = "Loading...";
  String profileImageBase64 = "";

  // Real data from SharedPreferences - user-specific
  int userPoints = 0;
  int notesCount = 0;
  int savedVideosCount = 0;
  int savedLinksCount = 0;
  int quizzesTaken = 0;
  int bestQuizScore = 0;
  String userLevel = "Rookie";

  // UI state variables
  bool isEditing = false;
  bool isLoading = true;
  bool isUploadingImage = false;
  File? _profileImage;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Animation controllers for engaging UI
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _counterController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _counterAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _counterController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _counterAnimation = CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutQuart,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _counterController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ✅ Responsive helper methods
  double _getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  double _getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  bool _isMobile(BuildContext context) => _getScreenWidth(context) < 600;
  bool _isTablet(BuildContext context) => _getScreenWidth(context) >= 600 && _getScreenWidth(context) < 900;
  bool _isDesktop(BuildContext context) => _getScreenWidth(context) >= 900;

  // ✅ Better responsive font sizing
  double _getResponsiveFontSize(BuildContext context, double baseMobile) {
    if (_isMobile(context)) {
      return baseMobile * (_getScreenWidth(context) / 375).clamp(0.85, 1.2);
    } else if (_isTablet(context)) {
      return baseMobile * 1.15;
    }
    return baseMobile * 1.3;
  }

  // ✅ Better responsive padding
  EdgeInsets _getResponsivePadding(BuildContext context) {
    if (_isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    } else if (_isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
  }

  // ✅ Better responsive spacing
  double _getResponsiveSpacing(BuildContext context, double baseMobile) {
    if (_isMobile(context)) {
      return baseMobile;
    } else if (_isTablet(context)) {
      return baseMobile * 1.2;
    }
    return baseMobile * 1.5;
  }

  // ✅ Calculate card dimensions to prevent overflow
  double _getCardHeight(BuildContext context) {
    if (_isMobile(context)) {
      return 140;
    } else if (_isTablet(context)) {
      return 160;
    }
    return 180;
  }

  int _getCrossAxisCount(BuildContext context) {
    if (_isMobile(context)) {
      return 2;
    } else if (_isTablet(context)) {
      return 3;
    }
    return 4;
  }
  // ✅ Enhanced user data loading with better error handling
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _redirectToLogin();
        return;
      }

      // Load Firebase user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data()!;
        setState(() {
          userName = userData['fullName'] ?? 'Unknown User';
          userEmail = userData['email'] ?? user.email ?? '';
          _nameController.text = userName;
          _emailController.text = userEmail;
        });

        // Load profile image and stats data
        await Future.wait([
          _loadProfileImage(),
          _loadUserStats(),
        ]);

        // Start animations after data is loaded
        if (mounted) {
          _fadeController.forward();
          _slideController.forward();
          _counterController.forward();
          _pulseController.repeat(reverse: true);
        }

        setState(() {
          isLoading = false;
        });
      } else {
        _redirectToLogin();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Failed to load profile data');
      }
    }
  }

  // ✅ Enhanced stats loading with better calculations
  // ✅ FIXED NOTES COUNTING - Replace the _loadUserStats() method
  Future<void> _loadUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userId = user.uid;

      // Load points and quiz data
      final points = prefs.getInt('${userId}_user_points') ?? 0;
      final quizCount = prefs.getInt('${userId}_quizzes_taken') ?? 0;
      final bestScore = prefs.getInt('${userId}_best_score') ?? 0;

      // ✅ IMPROVED NOTES COUNTING WITH MULTIPLE SOURCES
      int totalNotesCount = 0;
      int linksCount = 0;
      int videosCount = 0;

      // Method 1: Count saved notes
      final savedNotesJson = prefs.getStringList('${userId}_saved_notes') ?? [];
      totalNotesCount += savedNotesJson.length;

      // Count links in saved notes
      for (final noteString in savedNotesJson) {
        try {
          if (noteString.contains('http') || noteString.contains('www.')) {
            linksCount++;
          }
        } catch (e) {
          debugPrint('Error parsing saved note: $e');
        }
      }

      // Method 2: Count coding notes
      final codingNotesJson = prefs.getStringList('${userId}_coding_notes') ?? [];
      totalNotesCount += codingNotesJson.length;

      // Method 3: Count personal notes (if you have this feature)
      final personalNotesJson = prefs.getStringList('${userId}_personal_notes') ?? [];
      totalNotesCount += personalNotesJson.length;

      // Method 4: Count study notes (if you have this feature)
      final studyNotesJson = prefs.getStringList('${userId}_study_notes') ?? [];
      totalNotesCount += studyNotesJson.length;

      // ✅ IMPROVED VIDEO COUNTING
      final savedVideosJson = prefs.getStringList('${userId}_saved_videos') ?? [];
      final bookmarkedVideosJson = prefs.getStringList('${userId}_bookmarked_videos') ?? [];
      videosCount = savedVideosJson.length + bookmarkedVideosJson.length;

      // ✅ IMPROVED LINKS COUNTING FROM MULTIPLE SOURCES
      final savedLinksJson = prefs.getStringList('${userId}_saved_links') ?? [];
      final bookmarkedLinksJson = prefs.getStringList('${userId}_bookmarked_links') ?? [];
      linksCount += savedLinksJson.length + bookmarkedLinksJson.length;

      // Calculate user level based on points
      final level = _calculateUserLevel(points);

      // ✅ DEBUG LOGGING TO CHECK VALUES
      debugPrint('📊 USER STATS DEBUG:');
      debugPrint('   - User ID: $userId');
      debugPrint('   - Points: $points');
      debugPrint('   - Saved Notes: ${savedNotesJson.length}');
      debugPrint('   - Coding Notes: ${codingNotesJson.length}');
      debugPrint('   - Personal Notes: ${personalNotesJson.length}');
      debugPrint('   - Study Notes: ${studyNotesJson.length}');
      debugPrint('   - Total Notes: $totalNotesCount');
      debugPrint('   - Videos: $videosCount');
      debugPrint('   - Links: $linksCount');
      debugPrint('   - Quizzes: $quizCount');
      debugPrint('   - Level: $level');

      if (mounted) {
        setState(() {
          userPoints = points;
          quizzesTaken = quizCount;
          bestQuizScore = bestScore;
          notesCount = totalNotesCount; // ✅ PROPERLY SET TOTAL NOTES
          savedVideosCount = videosCount;
          savedLinksCount = linksCount;
          userLevel = level;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading user stats: $e');
      // Handle gracefully with default values
      if (mounted) {
        setState(() {
          userPoints = 0;
          notesCount = 0;
          savedVideosCount = 0;
          savedLinksCount = 0;
          quizzesTaken = 0;
          bestQuizScore = 0;
          userLevel = 'Rookie';
        });
      }
    }
  }

  // ✅ User level calculation
  String _calculateUserLevel(int points) {
    if (points >= 5000) return 'Expert';
    if (points >= 3000) return 'Advanced';
    if (points >= 1500) return 'Intermediate';
    if (points >= 500) return 'Beginner';
    return 'Rookie';
  }

  // ✅ Enhanced level styling
  Color _getLevelColor() {
    switch (userLevel) {
      case 'Expert':
        return const Color(0xFF8B5CF6); // Purple
      case 'Advanced':
        return const Color(0xFF00D4AA); // Teal
      case 'Intermediate':
        return const Color(0xFF3B82F6); // Blue
      case 'Beginner':
        return const Color(0xFFF59E0B); // Orange
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  IconData _getLevelIcon() {
    switch (userLevel) {
      case 'Expert': return Icons.diamond;
      case 'Advanced': return Icons.military_tech;
      case 'Intermediate': return Icons.star;
      case 'Beginner': return Icons.school;
      default: return Icons.person;
    }
  }

  // ✅ Better next level info with progress
  String _getNextLevelInfo() {
    final nextPoints = _getNextLevelPoints();
    final currentPoints = _getCurrentLevelPoints();

    if (userLevel == 'Expert') {
      return 'Congratulations! You\'ve reached the highest level! 🏆';
    }

    final needed = nextPoints - userPoints;
    final nextLevel = _getNextLevelName();

    return 'Earn $needed more points to reach $nextLevel level!';
  }

  String _getNextLevelName() {
    switch (userLevel) {
      case 'Rookie': return 'Beginner';
      case 'Beginner': return 'Intermediate';
      case 'Intermediate': return 'Advanced';
      case 'Advanced': return 'Expert';
      default: return 'Expert';
    }
  }

  int _getNextLevelPoints() {
    switch (userLevel) {
      case 'Rookie': return 500;
      case 'Beginner': return 1500;
      case 'Intermediate': return 3000;
      case 'Advanced': return 5000;
      default: return 5000; // Expert level
    }
  }

  int _getCurrentLevelPoints() {
    switch (userLevel) {
      case 'Rookie': return 0;
      case 'Beginner': return 500;
      case 'Intermediate': return 1500;
      case 'Advanced': return 3000;
      case 'Expert': return 5000;
      default: return 0;
    }
  }

  double _getLevelProgress() {
    if (userLevel == 'Expert') return 1.0;

    final nextPoints = _getNextLevelPoints();
    final currentPoints = _getCurrentLevelPoints();
    final progress = ((userPoints - currentPoints) / (nextPoints - currentPoints)).clamp(0.0, 1.0);

    return progress;
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final imageKey = 'profile_image_${user.uid}';
        final savedImageBase64 = prefs.getString(imageKey);
        if (savedImageBase64 != null && savedImageBase64.isNotEmpty && mounted) {
          setState(() {
            profileImageBase64 = savedImageBase64;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  // ✅ Refresh user data with loading state
  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      _loadUserStats(),
      _loadProfileImage(),
    ]);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
      _showSuccessSnackBar('Profile data refreshed!');
    }
  }
  // ✅ Enhanced image picking with better UX
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
          isUploadingImage = true;
        });

        await _saveProfileImageLocally(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: Please try again');
    }
  }

  Future<void> _saveProfileImageLocally(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();
      final imageKey = 'profile_image_${user.uid}';
      await prefs.setString(imageKey, base64String);

      if (mounted) {
        setState(() {
          profileImageBase64 = base64String;
          isUploadingImage = false;
        });
        _showSuccessSnackBar('Profile image updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isUploadingImage = false;
          _profileImage = null;
        });
        _showErrorSnackBar('Failed to save image');
      }
    }
  }

  // ✅ Enhanced profile update
  // ✅ REPLACE the existing _updateProfile() method with this:
  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (name.isEmpty) {
      _showErrorSnackBar('Name cannot be empty');
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }

    if (currentUser == null) return;

    try {
      setState(() {
        isLoading = true;
      });

      // ✅ CHECK IF EMAIL CHANGED
      final emailChanged = currentUser.email != email;

      if (emailChanged) {
        // ✅ EMAIL CHANGED - Send verification to new email
        await _handleEmailChange(email, name);
      } else {
        // ✅ ONLY NAME CHANGED - Update directly
        await _updateNameOnly(name);
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Failed to update profile');
      }
    }
  }

// ✅ ADD THESE NEW METHODS to ProfileScreen:

  Future<void> _updateNameOnly(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fullName': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth display name
      await user.updateDisplayName(name);

      if (mounted) {
        setState(() {
          userName = name;
          isEditing = false;
          isLoading = false;
        });
        _showSuccessSnackBar('Name updated successfully!');
      }
    }
  }

  Future<void> _handleEmailChange(String newEmail, String name) async {
    try {
      // ✅ NAVIGATE TO EMAIL CHANGE VERIFICATION SCREEN
      setState(() {
        isLoading = false;
        isEditing = false;
      });

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailChangeVerificationScreen(
            currentEmail: userEmail,
            newEmail: newEmail,
            userName: name,
          ),
        ),
      );

      // ✅ HANDLE RESULT FROM EMAIL CHANGE SCREEN
      if (result == true) {
        // Email successfully changed
        await _loadUserData(); // Refresh profile data
        _showSuccessSnackBar('Email updated successfully!');
      } else {
        // Email change cancelled or failed - revert email field
        _emailController.text = userEmail;
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _emailController.text = userEmail; // Revert on error
      _showErrorSnackBar('Failed to initiate email change');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // ✅ SUPER ATTRACTIVE LOGOUT DIALOG
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return _LogoutDialogContent();
      },
    );
  }


  void _redirectToLogin() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
            (route) => false,
      );
    }
  }

  void _cancelEditing() {
    setState(() {
      _nameController.text = userName;
      _emailController.text = userEmail;
      isEditing = false;
    });
  }

  // ✅ Enhanced snackbar methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00D4AA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
      ),
    );
  }

  // Helper method to convert base64 string to Uint8List
  Uint8List _base64ToImage(String base64String) {
    return base64Decode(base64String);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: isLoading ? _buildLoadingState() : _buildMainContent(),
    );
  }

  // ✅ Beautiful loading state
  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1B2A),
            Color(0xFF1B263B),
            Color(0xFF415A77),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_getResponsiveSpacing(context, 24)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00D4AA).withOpacity(0.2),
                    const Color(0xFF00A8CC).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4AA).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(context, 24)),
            Text(
              'Loading your learning profile...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: _getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(context, 8)),
            Text(
              'Please wait a moment',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: _getResponsiveFontSize(context, 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Main content with proper overflow handling
  Widget _buildMainContent() {
    return Container(
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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ✅ Enhanced App Bar
              _buildEnhancedAppBar(),

              // ✅ Main content with proper spacing
              SliverPadding(
                padding: _getResponsivePadding(context),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile Header
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildProfileHeader(),
                    ),

                    SizedBox(height: _getResponsiveSpacing(context, 24)),

                    // Level Progress
                    _buildLevelProgressCard(),

                    SizedBox(height: _getResponsiveSpacing(context, 20)),

                    // Points Card
                    AnimatedBuilder(
                      animation: _counterAnimation,
                      builder: (context, child) => _buildPointsCard(),
                    ),

                    SizedBox(height: _getResponsiveSpacing(context, 20)),

                    // Stats Grid - Fixed overflow issues
                    _buildStatsGrid(),

                    SizedBox(height: _getResponsiveSpacing(context, 20)),

                    // Account Settings
                    _buildAccountSettings(),

                    SizedBox(height: _getResponsiveSpacing(context, 20)),

                    // Learning Journey
                    _buildLearningJourney(),

                    // ✅ Attractive Logout Section
                    SizedBox(height: _getResponsiveSpacing(context, 20)),
                    _buildLogoutSection(),

                    // Bottom spacing for scroll
                    SizedBox(height: _getResponsiveSpacing(context, 40)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Enhanced app bar with better design
  Widget _buildEnhancedAppBar() {
    return SliverAppBar(
      expandedHeight: _isMobile(context) ? 70 : 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1B263B),
      automaticallyImplyLeading: false, // ✅ Custom leading

      // ✅ Custom back button aligned properly
      leading: Container(
        margin: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: const Color(0xFF00D4AA),
            size: _getResponsiveFontSize(context, 18),
          ),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF00D4AA).withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: const Color(0xFF00D4AA).withOpacity(0.3),
              ),
            ),
            padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
          ),
        ),
      ),

      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        // ✅ Proper alignment with back button and refresh button
        titlePadding: EdgeInsets.only(
          left: _getResponsiveSpacing(context, 64), // ✅ Space after back button
          bottom: _getResponsiveSpacing(context, 16),
          right: _getResponsiveSpacing(context, 100), // ✅ Space before refresh button
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
          ).createShader(bounds),
          child: Text(
            'Profile', // ✅ Changed to shorter headline
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(context, 16), // ✅ Appropriate size for shorter text
            ),
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B263B),
                Color(0xFF0D1B2A),
              ],
            ),
          ),
        ),
      ),

      actions: [
        // ✅ Refresh button aligned with back button
        Container(
          margin: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
          child: TextButton.icon(
            onPressed: _refreshData,
            icon: Icon(
              Icons.refresh_rounded,
              color: const Color(0xFF00D4AA),
              size: _getResponsiveFontSize(context, 16),
            ),
            label: Text(
              'Refresh',
              style: TextStyle(
                color: const Color(0xFF00D4AA),
                fontSize: _getResponsiveFontSize(context, 12),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA).withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: const Color(0xFF00D4AA).withOpacity(0.3),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: _getResponsiveSpacing(context, 10),
                vertical: _getResponsiveSpacing(context, 6),
              ),
            ),
          ),
        ),
      ],
    );
  }

// ✅ Helper function for mobile detection



  // ✅ Redesigned profile header with better layout
  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(context, 24)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile image with level badge
          Stack(
            children: [
              // Glowing container for profile image
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _getLevelColor(),
                      _getLevelColor().withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getLevelColor().withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: _isMobile(context) ? 50 : 60,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (profileImageBase64.isNotEmpty
                      ? MemoryImage(_base64ToImage(profileImageBase64))
                      : null) as ImageProvider?,
                  child: _profileImage == null && profileImageBase64.isEmpty
                      ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 36),
                      fontWeight: FontWeight.bold,
                      color: _getLevelColor(),
                    ),
                  )
                      : null,
                ),
              ),

              // Level badge
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSpacing(context, 10),
                    vertical: _getResponsiveSpacing(context, 4),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_getLevelColor(), _getLevelColor().withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _getLevelColor().withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getLevelIcon(),
                        color: Colors.white,
                        size: _getResponsiveFontSize(context, 14),
                      ),
                      SizedBox(width: _getResponsiveSpacing(context, 4)),
                      Text(
                        userLevel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _getResponsiveFontSize(context, 12),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Camera button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: isUploadingImage ? null : _pickImage,
                  child: Container(
                    padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4AA).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isUploadingImage ? Icons.hourglass_empty : Icons.camera_alt,
                      size: _getResponsiveFontSize(context, 20),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: _getResponsiveSpacing(context, 20)),

          // User name with attractive styling
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
            ).createShader(bounds),
            child: Text(
              userName,
              style: TextStyle(
                color: Colors.white,
                fontSize: _getResponsiveFontSize(context, 24),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SizedBox(height: _getResponsiveSpacing(context, 8)),

          // Email with better styling
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveSpacing(context, 12),
              vertical: _getResponsiveSpacing(context, 6),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userEmail,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: _getResponsiveFontSize(context, 14),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  // ✅ Level progress card with better design
  Widget _buildLevelProgressCard() {
    final progress = _getLevelProgress();

    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getLevelColor().withOpacity(0.2),
            _getLevelColor().withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getLevelColor().withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getResponsiveSpacing(context, 10)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_getLevelColor(), _getLevelColor().withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getLevelIcon(),
                  color: Colors.white,
                  size: _getResponsiveFontSize(context, 20),
                ),
              ),
              SizedBox(width: _getResponsiveSpacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level Progress',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: _getResponsiveFontSize(context, 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      userLevel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: _getLevelColor(),
                  fontSize: _getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: _getResponsiveSpacing(context, 16)),

          // Progress bar with animation
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_getLevelColor(), _getLevelColor().withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: _getLevelColor().withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          SizedBox(height: _getResponsiveSpacing(context, 12)),

          Text(
            _getNextLevelInfo(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: _getResponsiveFontSize(context, 12),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ✅ Animated points card with better design
  Widget _buildPointsCard() {
    final animatedPoints = (userPoints * _counterAnimation.value).round();

    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00D4AA),
            Color(0xFF00A8CC),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.stars_rounded,
              color: Colors.white,
              size: _getResponsiveFontSize(context, 28),
            ),
          ),
          SizedBox(width: _getResponsiveSpacing(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Learning Points",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: _getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: _getResponsiveSpacing(context, 4)),
                Text(
                  animatedPoints.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (bestQuizScore > 0) ...[
                  SizedBox(height: _getResponsiveSpacing(context, 4)),
                  Text(
                    "Best Quiz: $bestQuizScore pts",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: _getResponsiveFontSize(context, 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Fixed stats grid with proper sizing
  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate proper dimensions to prevent overflow
        final crossAxisCount = _getCrossAxisCount(context);
        final spacing = _getResponsiveSpacing(context, 12);
        final availableWidth = constraints.maxWidth - ((crossAxisCount - 1) * spacing);
        final itemWidth = availableWidth / crossAxisCount;
        final aspectRatio = itemWidth / _getCardHeight(context);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          children: [
            _buildStatCard(
              icon: Icons.note_alt_rounded,
              title: "Notes",
              value: notesCount.toString(),
              subtitle: "Saved",
              color: const Color(0xFF8B5CF6),
            ),
            _buildStatCard(
              icon: Icons.video_library_rounded,
              title: "Videos",
              value: savedVideosCount.toString(),
              subtitle: "Bookmarked",
              color: const Color(0xFFEF4444),
            ),
            _buildStatCard(
              icon: Icons.link_rounded,
              title: "Links",
              value: savedLinksCount.toString(),
              subtitle: "Resources",
              color: const Color(0xFF3B82F6),
            ),
            _buildStatCard(
              icon: Icons.quiz_rounded,
              title: "Quizzes",
              value: quizzesTaken.toString(),
              subtitle: "Completed",
              color: const Color(0xFF10B981),
            ),
          ],
        );
      },
    );
  }

  // ✅ Improved stat card with better text handling
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _counterAnimation,
      builder: (context, child) {
        final animatedValue = (int.tryParse(value) ?? 0) * _counterAnimation.value;

        return Container(
          padding: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: _getResponsiveFontSize(context, 20),
                ),
              ),
              SizedBox(height: _getResponsiveSpacing(context, 8)),
              Text(
                animatedValue.round().toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _getResponsiveFontSize(context, 24),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: _getResponsiveSpacing(context, 2)),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: _getResponsiveFontSize(context, 12),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: _getResponsiveFontSize(context, 10),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Account settings with better layout
  Widget _buildAccountSettings() {
    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getResponsiveSpacing(context, 10)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: _getResponsiveFontSize(context, 20),
                ),
              ),
              SizedBox(width: _getResponsiveSpacing(context, 12)),
              Expanded(
                child: Text(
                  "Account Settings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isEditing)
                IconButton(
                  icon: Icon(
                    Icons.edit_rounded,
                    color: const Color(0xFF00D4AA),
                    size: _getResponsiveFontSize(context, 20),
                  ),
                  onPressed: () => setState(() => isEditing = true),
                ),
            ],
          ),
          SizedBox(height: _getResponsiveSpacing(context, 16)),
          _buildEditableField(
            label: "Full Name",
            value: userName,
            controller: _nameController,
            icon: Icons.person_rounded,
          ),
          SizedBox(height: _getResponsiveSpacing(context, 12)),
          _buildEditableField(
            label: "Email",
            value: userEmail,
            controller: _emailController,
            icon: Icons.email_rounded,
          ),
          if (isEditing) ...[
            SizedBox(height: _getResponsiveSpacing(context, 16)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelEditing,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: EdgeInsets.symmetric(
                        vertical: _getResponsiveSpacing(context, 12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: _getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: _getResponsiveSpacing(context, 12)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      padding: EdgeInsets.symmetric(
                        vertical: _getResponsiveSpacing(context, 12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Save",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: _getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditing
              ? const Color(0xFF00D4AA).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF00D4AA),
            size: _getResponsiveFontSize(context, 20),
          ),
          SizedBox(width: _getResponsiveSpacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: _getResponsiveFontSize(context, 12),
                  ),
                ),
                SizedBox(height: _getResponsiveSpacing(context, 4)),
                isEditing
                    ? TextField(
                  controller: controller,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 16),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  maxLines: 1,

                )
                    : Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 16),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ✅ Learning journey with achievements
  Widget _buildLearningJourney() {
    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getResponsiveSpacing(context, 10)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.deepPurple],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  color: Colors.white,
                  size: _getResponsiveFontSize(context, 20),
                ),
              ),
              SizedBox(width: _getResponsiveSpacing(context, 12)),
              Expanded(
                child: Text(
                  "Learning Journey",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSpacing(context, 16)),

          // Dynamic achievements based on real data
          ...(_buildAchievements()),
        ],
      ),
    );
  }

  List<Widget> _buildAchievements() {
    List<Widget> achievements = [];

    if (userPoints > 0) {
      achievements.add(_buildAchievementItem(
        icon: Icons.emoji_events_rounded,
        title: "Points Earned",
        subtitle: "$userPoints learning points collected!",
        time: _getPointsMessage(),
        color: Colors.amber,
      ));
    }

    if (quizzesTaken > 0) {
      achievements.add(_buildAchievementItem(
        icon: Icons.quiz_rounded,
        title: "Quiz Master",
        subtitle: "Completed $quizzesTaken ${quizzesTaken == 1 ? 'quiz' : 'quizzes'}",
        time: bestQuizScore > 0 ? "Best: $bestQuizScore pts" : "Keep going!",
        color: Colors.green,
      ));
    }

    if (notesCount > 0) {
      achievements.add(_buildAchievementItem(
        icon: Icons.note_add_rounded,
        title: "Note Keeper",
        subtitle: "Saved $notesCount ${notesCount == 1 ? 'note' : 'notes'}",
        time: "Great organization!",
        color: Colors.blue,
      ));
    }

    if (savedVideosCount > 0) {
      achievements.add(_buildAchievementItem(
        icon: Icons.video_library_rounded,
        title: "Video Learner",
        subtitle: "Bookmarked $savedVideosCount ${savedVideosCount == 1 ? 'video' : 'videos'}",
        time: "Visual learning!",
        color: Colors.red,
      ));
    }

    // If no achievements yet
    if (achievements.isEmpty) {
      achievements.add(_buildAchievementItem(
        icon: Icons.rocket_launch_rounded,
        title: "Start Your Journey",
        subtitle: "Take your first quiz or save your first note!",
        time: "You've got this! 🚀",
        color: const Color(0xFF00D4AA),
      ));
    }

    return achievements;
  }

  String _getPointsMessage() {
    if (userPoints >= 5000) return "Amazing! 🏆";
    if (userPoints >= 3000) return "Excellent! 🌟";
    if (userPoints >= 1500) return "Great job! 🎉";
    if (userPoints >= 500) return "Keep going! 💪";
    return "Good start! 👍";
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSpacing(context, 12)),
      padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: _getResponsiveFontSize(context, 16),
            ),
          ),
          SizedBox(width: _getResponsiveSpacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: _getResponsiveFontSize(context, 14),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: _getResponsiveSpacing(context, 2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: _getResponsiveFontSize(context, 12),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (time.isNotEmpty)
            Text(
              time,
              style: TextStyle(
                color: color,
                fontSize: _getResponsiveFontSize(context, 10),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  // ✅ SUPER ATTRACTIVE LOGOUT SECTION - The main attraction!
  Widget _buildLogoutSection() {
    return Container(
      margin: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
      padding: EdgeInsets.all(_getResponsiveSpacing(context, 24)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.red.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
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
        children: [
          // Logout icon
          Container(
            padding: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Color(0xFFE53E3E)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: _getResponsiveFontSize(context, 24),
            ),
          ),

          SizedBox(height: _getResponsiveSpacing(context, 16)),

          // Title
          Text(
            'Ready to Sign Out?',
            style: TextStyle(
              color: Colors.white,
              fontSize: _getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: _getResponsiveSpacing(context, 8)),

          // Description
          Text(
            'Your progress is automatically saved.\nYou can continue anytime!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: _getResponsiveFontSize(context, 14),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: _getResponsiveSpacing(context, 20)),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showLogoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: _getResponsiveSpacing(context, 14),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, size: 20),
                  SizedBox(width: _getResponsiveSpacing(context, 8)),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: _getResponsiveSpacing(context, 12)),

          // Security note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_outlined,
                color: const Color(0xFF00D4AA),
                size: _getResponsiveFontSize(context, 16),
              ),
              SizedBox(width: _getResponsiveSpacing(context, 6)),
              Text(
                'Your data is safely stored',
                style: TextStyle(
                  color: const Color(0xFF00D4AA),
                  fontSize: _getResponsiveFontSize(context, 12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



// Improved logout dialog


}
// ✅ FIXED LOGOUT DIALOG - Replace the entire _LogoutDialogContent class
class _LogoutDialogContent extends StatefulWidget {
  @override
  _LogoutDialogContentState createState() => _LogoutDialogContentState();
}

class _LogoutDialogContentState extends State<_LogoutDialogContent> {
  bool _isLoggingOut = false;

  double _getResponsiveSpacing(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (baseSize * screenWidth) / 375;
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (baseSize * screenWidth) / 375;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        margin: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B263B),
              Color(0xFF0D1B2A),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(_getResponsiveSpacing(context, 24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logout icon
              Container(
                padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoggingOut
                        ? [Colors.grey, Colors.grey.shade600]
                        : [Colors.red, const Color(0xFFDC2626)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isLoggingOut ? Colors.grey : Colors.red).withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: _isLoggingOut
                    ? SizedBox(
                  width: _getResponsiveFontSize(context, 32),
                  height: _getResponsiveFontSize(context, 32),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: _getResponsiveFontSize(context, 32),
                ),
              ),

              SizedBox(height: _getResponsiveSpacing(context, 20)),

              // Title
              Text(
                _isLoggingOut ? 'Signing Out...' : 'Ready to Sign Out?',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: _getResponsiveFontSize(context, 24),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: _getResponsiveSpacing(context, 16)),

              // Security message
              Container(
                padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3441),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: const Color(0xFF00D4AA),
                      size: _getResponsiveFontSize(context, 20),
                    ),
                    SizedBox(height: _getResponsiveSpacing(context, 8)),
                    Text(
                      _isLoggingOut
                          ? 'Saving your progress and signing out safely...'
                          : 'Your learning progress is safely saved!\nYou can continue where you left off when you return.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: _getResponsiveFontSize(context, 14),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: _getResponsiveSpacing(context, 24)),

              // Action buttons
              Row(
                children: [
                  // Stay button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isLoggingOut ? null : () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: _getResponsiveSpacing(context, 16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  color: Colors.white.withOpacity(_isLoggingOut ? 0.4 : 0.8),
                                  size: _getResponsiveFontSize(context, 18),
                                ),
                                SizedBox(width: _getResponsiveSpacing(context, 8)),
                                Text(
                                  'Stay Here',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(_isLoggingOut ? 0.4 : 0.8),
                                    fontSize: _getResponsiveFontSize(context, 14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: _getResponsiveSpacing(context, 16)),

                  // Sign Out button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isLoggingOut
                              ? [Colors.grey, Colors.grey.shade600]
                              : [Colors.red, const Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (_isLoggingOut ? Colors.grey : Colors.red).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isLoggingOut ? null : _handleLogout,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: _getResponsiveSpacing(context, 16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isLoggingOut) ...[
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ] else ...[
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                    size: _getResponsiveFontSize(context, 18),
                                  ),
                                ],
                                SizedBox(width: _getResponsiveSpacing(context, 8)),
                                Text(
                                  _isLoggingOut ? 'Signing Out...' : 'Sign Out',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _getResponsiveFontSize(context, 14),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ SIMPLIFIED LOGOUT HANDLING - No nested dialogs
  Future<void> _handleLogout() async {
    if (!mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      // ✅ DIRECT LOGOUT WITHOUT ADDITIONAL DIALOGS
      await _performLogout();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // ✅ CLEAN LOGOUT PROCESS
  Future<void> _performLogout() async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('last_login');

      // ✅ CLEAN NAVIGATION - Remove all overlapping dialogs and navigate
      if (mounted) {
        // Close this dialog first
        Navigator.of(context).pop();

        // Then navigate to login, removing all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog on error
      }
      throw e; // Re-throw to be caught by _handleLogout
    }
  }
}