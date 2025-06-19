import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'email_change_verification_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  // Data variables
  String userName = "Loading...";
  String userEmail = "Loading...";
  String profileImageBase64 = "";
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

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _counterController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _counterAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _counterController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _counterAnimation = CurvedAnimation(parent: _counterController, curve: Curves.easeOutQuart);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _counterController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ✅ ENHANCED RESPONSIVE SYSTEM
  double _getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  double _getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  bool _isSmallMobile(BuildContext context) => _getScreenWidth(context) < 360;
  bool _isMobile(BuildContext context) => _getScreenWidth(context) < 600;
  bool _isTablet(BuildContext context) => _getScreenWidth(context) >= 600 && _getScreenWidth(context) < 1024;
  bool _isDesktop(BuildContext context) => _getScreenWidth(context) >= 1024;

  // ✅ ENHANCED TYPOGRAPHY SYSTEM
  double _getHeadingSize(BuildContext context) {
    if (_isSmallMobile(context)) return 18;
    if (_isMobile(context)) return 22;
    if (_isTablet(context)) return 26;
    return 30;
  }

  double _getSubheadingSize(BuildContext context) {
    if (_isSmallMobile(context)) return 14;
    if (_isMobile(context)) return 16;
    if (_isTablet(context)) return 18;
    return 20;
  }

  double _getBodySize(BuildContext context) {
    if (_isSmallMobile(context)) return 11;
    if (_isMobile(context)) return 13;
    if (_isTablet(context)) return 14;
    return 15;
  }

  double _getCaptionSize(BuildContext context) {
    if (_isSmallMobile(context)) return 9;
    if (_isMobile(context)) return 10;
    if (_isTablet(context)) return 11;
    return 12;
  }

  // ✅ ENHANCED SPACING SYSTEM
  double _getSpaceXS(BuildContext context) => _isSmallMobile(context) ? 3 : (_isMobile(context) ? 4 : 6);
  double _getSpaceS(BuildContext context) => _isSmallMobile(context) ? 6 : (_isMobile(context) ? 8 : 12);
  double _getSpaceM(BuildContext context) => _isSmallMobile(context) ? 12 : (_isMobile(context) ? 16 : 20);
  double _getSpaceL(BuildContext context) => _isSmallMobile(context) ? 18 : (_isMobile(context) ? 24 : 32);
  double _getSpaceXL(BuildContext context) => _isSmallMobile(context) ? 24 : (_isMobile(context) ? 32 : 48);

  // ✅ MODERN PADDING SYSTEM
  EdgeInsets _getPaddingS(BuildContext context) => EdgeInsets.all(_getSpaceS(context));
  EdgeInsets _getPaddingM(BuildContext context) => EdgeInsets.all(_getSpaceM(context));
  EdgeInsets _getPaddingL(BuildContext context) => EdgeInsets.all(_getSpaceL(context));

  EdgeInsets _getPaddingHorizontal(BuildContext context, double multiplier) =>
      EdgeInsets.symmetric(horizontal: _getSpaceM(context) * multiplier);

  EdgeInsets _getPaddingVertical(BuildContext context, double multiplier) =>
      EdgeInsets.symmetric(vertical: _getSpaceM(context) * multiplier);

  // ✅ MODERN BORDER RADIUS SYSTEM
  double _getRadiusS() => 8;
  double _getRadiusM() => 16;
  double _getRadiusL() => 24;
  double _getRadiusXL() => 32;

  // ✅ GRID SYSTEM FOR NEW LAYOUT
  int _getStatsColumns(BuildContext context) {
    if (_isSmallMobile(context)) return 2;
    if (_isMobile(context)) return 2;
    if (_isTablet(context)) return 4;
    return 4;
  }

  double _getStatsAspectRatio(BuildContext context) {
    if (_isSmallMobile(context)) return 1.4;
    if (_isMobile(context)) return 1.2;
    return 1.0;
  }

  // ✅ MODERN COLOR PALETTE
  Color get primaryColor => const Color(0xFF6366F1); // Indigo
  Color get primaryLight => const Color(0xFF818CF8);
  Color get primaryDark => const Color(0xFF4F46E5);

  Color get accentColor => const Color(0xFF06B6D4); // Cyan
  Color get accentLight => const Color(0xFF22D3EE);
  Color get accentDark => const Color(0xFF0891B2);

  Color get successColor => const Color(0xFF10B981);
  Color get warningColor => const Color(0xFFF59E0B);
  Color get errorColor => const Color(0xFFEF4444);

  Color get surfaceColor => const Color(0xFF1E293B);
  Color get surfaceLight => const Color(0xFF334155);
  Color get surfaceDark => const Color(0xFF0F172A);

  Color get textPrimary => Colors.white;
  Color get textSecondary => Colors.white.withOpacity(0.8);
  Color get textTertiary => Colors.white.withOpacity(0.6);

  // Level styling methods (updated for new design)
  Color _getLevelColor() {
    switch (userLevel) {
      case 'Expert': return const Color(0xFF8B5CF6); // Purple
      case 'Advanced': return const Color(0xFF06B6D4); // Cyan
      case 'Intermediate': return const Color(0xFF3B82F6); // Blue
      case 'Beginner': return const Color(0xFFF59E0B); // Amber
      default: return const Color(0xFF6B7280); // Gray
    }
  }

  IconData _getLevelIcon() {
    switch (userLevel) {
      case 'Expert': return Icons.emoji_events; // Trophy
      case 'Advanced': return Icons.military_tech; // Medal
      case 'Intermediate': return Icons.star; // Star
      case 'Beginner': return Icons.trending_up; // Arrow up
      default: return Icons.circle; // Dot
    }
  }

  String _calculateUserLevel(int points) {
    if (points >= 5000) return 'Expert';
    if (points >= 3000) return 'Advanced';
    if (points >= 1500) return 'Intermediate';
    if (points >= 500) return 'Beginner';
    return 'Rookie';
  }

  // Helper methods
  Uint8List _base64ToImage(String base64String) {
    return base64Decode(base64String);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // ✅ MODERN SNACKBAR SYSTEM
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getSpaceXS(context)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.white, size: 20),
              ),
              SizedBox(width: _getSpaceS(context)),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: _getBodySize(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getRadiusM())),
        margin: EdgeInsets.all(_getSpaceM(context)),
        elevation: 8,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getSpaceXS(context)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error, color: Colors.white, size: 20),
              ),
              SizedBox(width: _getSpaceS(context)),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: _getBodySize(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getRadiusM())),
        margin: EdgeInsets.all(_getSpaceM(context)),
        elevation: 8,
      ),
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

  // ✅ DATA LOADING METHODS (Same functionality, updated animations)
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _redirectToLogin();
        return;
      }

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

        await Future.wait([
          _loadProfileImage(),
          _loadUserStats(),
        ]);

        if (mounted) {
          // Start new animation sequence
          _fadeController.forward();
          await Future.delayed(const Duration(milliseconds: 200));
          _slideController.forward();
          await Future.delayed(const Duration(milliseconds: 300));
          _scaleController.forward();
          await Future.delayed(const Duration(milliseconds: 200));
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

  Future<void> _loadUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userId = user.uid;
      final points = prefs.getInt('${userId}_user_points') ?? 0;
      final quizCount = prefs.getInt('${userId}_quizzes_taken') ?? 0;
      final bestScore = prefs.getInt('${userId}_best_score') ?? 0;

      // Count notes from multiple sources
      int totalNotesCount = 0;
      int linksCount = 0;
      int videosCount = 0;

      final savedNotesJson = prefs.getStringList('${userId}_saved_notes') ?? [];
      totalNotesCount += savedNotesJson.length;

      for (final noteString in savedNotesJson) {
        try {
          if (noteString.contains('http') || noteString.contains('www.')) {
            linksCount++;
          }
        } catch (e) {
          debugPrint('Error parsing saved note: $e');
        }
      }

      final codingNotesJson = prefs.getStringList('${userId}_coding_notes') ?? [];
      totalNotesCount += codingNotesJson.length;

      final personalNotesJson = prefs.getStringList('${userId}_personal_notes') ?? [];
      totalNotesCount += personalNotesJson.length;

      final studyNotesJson = prefs.getStringList('${userId}_study_notes') ?? [];
      totalNotesCount += studyNotesJson.length;

      final savedVideosJson = prefs.getStringList('${userId}_saved_videos') ?? [];
      final bookmarkedVideosJson = prefs.getStringList('${userId}_bookmarked_videos') ?? [];
      videosCount = savedVideosJson.length + bookmarkedVideosJson.length;

      final savedLinksJson = prefs.getStringList('${userId}_saved_links') ?? [];
      final bookmarkedLinksJson = prefs.getStringList('${userId}_bookmarked_links') ?? [];
      linksCount += savedLinksJson.length + bookmarkedLinksJson.length;

      final level = _calculateUserLevel(points);

      if (mounted) {
        setState(() {
          userPoints = points;
          quizzesTaken = quizCount;
          bestQuizScore = bestScore;
          notesCount = totalNotesCount;
          savedVideosCount = videosCount;
          savedLinksCount = linksCount;
          userLevel = level;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading user stats: $e');
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

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });

    // Reset animations
    _counterController.reset();
    _scaleController.reset();

    await Future.wait([
      _loadUserStats(),
      _loadProfileImage(),
    ]);

    if (mounted) {
      setState(() {
        isLoading = false;
      });

      // Restart animations
      _counterController.forward();
      _scaleController.forward();

      _showSuccessSnackBar('Profile data refreshed!');
    }
  }

  // ✅ IMAGE HANDLING METHODS
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
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

  // ✅ PROFILE UPDATE METHODS
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

      final emailChanged = currentUser.email != email;

      if (emailChanged) {
        await _handleEmailChange(email, name);
      } else {
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

  Future<void> _updateNameOnly(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fullName': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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

      if (result == true) {
        await _loadUserData();
        _showSuccessSnackBar('Email updated successfully!');
      } else {
        _emailController.text = userEmail;
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _emailController.text = userEmail;
      _showErrorSnackBar('Failed to initiate email change');
    }
  }

  void _cancelEditing() {
    setState(() {
      _nameController.text = userName;
      _emailController.text = userEmail;
      isEditing = false;
    });
  }

  // ✅ LEVEL PROGRESS CALCULATIONS
  String _getNextLevelInfo() {
    final nextPoints = _getNextLevelPoints();

    if (userLevel == 'Expert') {
      return 'Congratulations! You\'ve reached the highest level! 🏆';
    }

    final needed = nextPoints - userPoints;
    final nextLevel = _getNextLevelName();

    return '$needed points to $nextLevel';
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
      default: return 5000;
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

  // ✅ LOGOUT DIALOG
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return _ModernLogoutDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceDark,
      body: SafeArea(
        child: isLoading ? _buildModernLoadingState() : _buildModernMainContent(),
      ),
    );
  }

  // ✅ MODERN LOADING STATE - Glassmorphism Design
  Widget _buildModernLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surfaceDark,
            surfaceColor,
            surfaceLight.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(_getSpaceXL(context)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_getRadiusXL()),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern loading spinner
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: _getSpaceL(context)),
              // Loading text
              Text(
                'Loading your profile...',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: _getSubheadingSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: _getSpaceS(context)),
              Text(
                'Please wait a moment',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: _getBodySize(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ MODERN MAIN CONTENT - Fixed Layout Structure
  Widget _buildModernMainContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surfaceDark,
            surfaceColor,
            surfaceLight.withOpacity(0.5),
          ],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            _buildModernAppBar(),
            SliverSafeArea(
              sliver: SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: _getSpaceM(context)),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: _getSpaceM(context)),
                    _buildNewHeroSection(),
                    SizedBox(height: _getSpaceL(context)),
                    _buildModernStatsGrid(),
                    SizedBox(height: _getSpaceL(context)),
                    _buildQuickActionsCard(),
                    SizedBox(height: _getSpaceL(context)),
                    _buildModernLearningJourney(),
                    SizedBox(height: _getSpaceL(context)),
                    _buildModernAccountSettings(),
                    SizedBox(height: _getSpaceXL(context) * 2),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW HERO SECTION - Completely Redesigned
  Widget _buildNewHeroSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          // Profile Image and Basic Info Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_getSpaceL(context)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(_getRadiusL()),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Profile Image Section
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated level ring
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  _getLevelColor(),
                                  _getLevelColor().withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Profile Image
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _profileImage != null
                            ? Image.file(_profileImage!, fit: BoxFit.cover)
                            : (profileImageBase64.isNotEmpty
                            ? Image.memory(_base64ToImage(profileImageBase64), fit: BoxFit.cover)
                            : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, accentColor],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontSize: _getHeadingSize(context),
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        )),
                      ),
                    ),

                    // Camera Button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: isUploadingImage ? null : _pickImage,
                        child: Container(
                          padding: EdgeInsets.all(_getSpaceS(context)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, accentColor],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isUploadingImage ? Icons.hourglass_empty : Icons.camera_alt,
                            size: 12,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(width: _getSpaceL(context)),

                // User Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: _getSubheadingSize(context),
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: _getSpaceXS(context)),

                      // Email
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _getSpaceM(context),
                          vertical: _getSpaceS(context),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(_getRadiusS()),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: _getCaptionSize(context),
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: _getSpaceM(context)),

                      // Level Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _getSpaceM(context),
                          vertical: _getSpaceS(context),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_getLevelColor(), _getLevelColor().withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(_getRadiusM()),
                          boxShadow: [
                            BoxShadow(
                              color: _getLevelColor().withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getLevelIcon(),
                              color: textPrimary,
                              size: 16,
                            ),
                            SizedBox(width: _getSpaceS(context)),
                            Text(
                              userLevel,
                              style: TextStyle(
                                fontSize: _getBodySize(context),
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: _getSpaceL(context)),

          // Learning Points and Progress Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_getSpaceL(context)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.8),
                  accentColor.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(_getRadiusL()),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Points Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(_getSpaceM(context)),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(_getRadiusM()),
                      ),
                      child: Icon(
                        Icons.stars_rounded,
                        color: textPrimary,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: _getSpaceM(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learning Points',
                            style: TextStyle(
                              fontSize: _getBodySize(context),
                              color: textPrimary.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: _getSpaceXS(context)),
                          AnimatedBuilder(
                            animation: _counterAnimation,
                            builder: (context, child) {
                              final animatedPoints = (userPoints * _counterAnimation.value).round();
                              return Text(
                                animatedPoints.toString(),
                                style: TextStyle(
                                  fontSize: _getHeadingSize(context) * 1.5,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _getSpaceL(context)),

                // Progress Section
                Row(
                  children: [
                    // Progress Ring - Fixed circle and dot positioning
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: CircularProgressIndicator(
                              value: 1.0, // Full background circle
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.2)),
                            ),
                          ),
                          // Progress circle
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: CircularProgressIndicator(
                              value: _getLevelProgress(),
                              strokeWidth: 8,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeCap: StrokeCap.round, // Rounded ends to prevent merging
                            ),
                          ),
                          // Center content
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getLevelIcon(),
                                  color: textPrimary,
                                  size: 18,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${(_getLevelProgress() * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: _getSpaceL(context)),

                    // Progress Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userLevel,
                            style: TextStyle(
                              fontSize: _getSubheadingSize(context),
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: _getSpaceS(context)),
                          Text(
                            _getNextLevelInfo(),
                            style: TextStyle(
                              fontSize: _getBodySize(context),
                              color: textPrimary.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (bestQuizScore > 0) ...[
                            SizedBox(height: _getSpaceS(context)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: _getSpaceM(context),
                                vertical: _getSpaceS(context),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(_getRadiusS()),
                              ),
                              child: Text(
                                'Best Quiz: $bestQuizScore pts',
                                style: TextStyle(
                                  fontSize: _getCaptionSize(context),
                                  color: textPrimary.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MODERN APP BAR - Fixed Height Issues
  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: _isMobile(context) ? 80 : 100,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              surfaceColor.withOpacity(0.9),
              surfaceLight.withOpacity(0.7),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _getSpaceM(context)),
            child: Row(
              children: [
                // Back Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(_getRadiusM()),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: _getSpaceM(context)),

                // Title
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: _getHeadingSize(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Manage your learning profile',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: _getCaptionSize(context),
                        ),
                      ),
                    ],
                  ),
                ),

                // Refresh Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, accentColor],
                    ),
                    borderRadius: BorderRadius.circular(_getRadiusM()),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _refreshData,
                    icon: Icon(
                      Icons.refresh,
                      color: textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ MODERN STATS GRID - Completely Fixed Overflow Issues
  Widget _buildModernStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getStatsColumns(context);
        final spacing = _getSpaceM(context);

        // Calculate safe dimensions
        final availableWidth = constraints.maxWidth;
        final itemWidth = (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
        final itemHeight = _isSmallMobile(context) ? itemWidth * 1.1 : itemWidth * 0.95;

        return Column(
          children: [
            // First Row
            Row(
              children: [
                Expanded(
                  child: _buildModernStatCard(
                    icon: Icons.article_outlined,
                    title: "Notes",
                    value: notesCount.toString(),
                    subtitle: "Saved",
                    color: const Color(0xFF8B5CF6),
                    gradient: [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
                    height: itemHeight,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildModernStatCard(
                    icon: Icons.play_circle_outline,
                    title: "Videos",
                    value: savedVideosCount.toString(),
                    subtitle: "Bookmarked",
                    color: const Color(0xFFEF4444),
                    gradient: [const Color(0xFFEF4444), const Color(0xFFF87171)],
                    height: itemHeight,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            // Second Row
            Row(
              children: [
                Expanded(
                  child: _buildModernStatCard(
                    icon: Icons.link_outlined,
                    title: "Links",
                    value: savedLinksCount.toString(),
                    subtitle: "Resources",
                    color: const Color(0xFF3B82F6),
                    gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
                    height: itemHeight,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildModernStatCard(
                    icon: Icons.quiz_outlined,
                    title: "Quizzes",
                    value: quizzesTaken.toString(),
                    subtitle: "Completed",
                    color: const Color(0xFF10B981),
                    gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
                    height: itemHeight,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ✅ MODERN STAT CARD - Enhanced Visibility & Responsive
  Widget _buildModernStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required List<Color> gradient,
    double? width,
    required double height,
  }) {
    return AnimatedBuilder(
      animation: _counterAnimation,
      builder: (context, child) {
        final animatedValue = (int.tryParse(value) ?? 0) * _counterAnimation.value;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(_getRadiusL()),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(_getSpaceM(context)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon with gradient background
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(_getSpaceS(context)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(_getRadiusM()),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: _isSmallMobile(context) ? 20 : 24,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: _getSpaceS(context)),

                // Animated Value
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      animatedValue.round().toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _isSmallMobile(context) ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Title
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _isSmallMobile(context) ? 12 : _getBodySize(context),
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Subtitle
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: _isSmallMobile(context) ? 10 : _getCaptionSize(context),
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ QUICK ACTIONS CARD - Fixed Button Layout
  Widget _buildQuickActionsCard() {
    return Container(
      width: double.infinity,
      padding: _getPaddingL(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(_getRadiusL()),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getSpaceM(context)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [warningColor, warningColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(_getRadiusM()),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: textPrimary,
                  size: 20,
                ),
              ),
              SizedBox(width: _getSpaceM(context)),
              Expanded(
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: _getSubheadingSize(context),
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _getSpaceL(context)),

          // Action Buttons Grid - Fixed Layout
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // First Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.edit,
                          label: 'Edit Profile',
                          onTap: () => setState(() => isEditing = true),
                          gradient: [primaryColor, primaryLight],
                        ),
                      ),
                      SizedBox(width: _getSpaceM(context)),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.refresh,
                          label: 'Refresh Data',
                          onTap: _refreshData,
                          gradient: [accentColor, accentLight],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _getSpaceM(context)),
                  // Second Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.camera_alt,
                          label: 'Change Photo',
                          onTap: _pickImage,
                          gradient: [successColor, const Color(0xFF34D399)],
                        ),
                      ),
                      SizedBox(width: _getSpaceM(context)),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.logout,
                          label: 'Sign Out',
                          onTap: _showLogoutDialog,
                          gradient: [errorColor, const Color(0xFFF87171)],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ ACTION BUTTON - Enhanced Visibility & Responsive
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required List<Color> gradient,
  }) {
    return Container(
      height: _isSmallMobile(context) ? 45 : 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(_getRadiusM()),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_getRadiusM()),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getSpaceS(context),
              vertical: _getSpaceS(context),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: _isSmallMobile(context) ? 14 : 16,
                  ),
                ),
                SizedBox(width: _getSpaceS(context)),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: _isSmallMobile(context) ? 11 : _getBodySize(context),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.4),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ MODERN LEARNING JOURNEY - Same as before
  Widget _buildModernLearningJourney() {
    return Container(
      width: double.infinity,
      padding: _getPaddingL(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(_getRadiusL()),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getSpaceM(context)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(_getRadiusM()),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: textPrimary,
                  size: 20,
                ),
              ),
              SizedBox(width: _getSpaceM(context)),
              Expanded(
                child: Text(
                  'Learning Journey',
                  style: TextStyle(
                    fontSize: _getSubheadingSize(context),
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _getSpaceL(context)),

          // Achievements Timeline
          ..._buildModernAchievements(),
        ],
      ),
    );
  }

  List<Widget> _buildModernAchievements() {
    List<Widget> achievements = [];

    if (userPoints > 0) {
      achievements.add(_buildTimelineItem(
        icon: Icons.emoji_events,
        title: "Points Earned",
        subtitle: "$userPoints learning points collected!",
        time: _getPointsMessage(),
        color: warningColor,
        isFirst: true,
      ));
    }

    if (quizzesTaken > 0) {
      achievements.add(_buildTimelineItem(
        icon: Icons.quiz,
        title: "Quiz Master",
        subtitle: "Completed $quizzesTaken ${quizzesTaken == 1 ? 'quiz' : 'quizzes'}",
        time: bestQuizScore > 0 ? "Best: $bestQuizScore pts" : "Keep going!",
        color: successColor,
      ));
    }

    if (notesCount > 0) {
      achievements.add(_buildTimelineItem(
        icon: Icons.note_add,
        title: "Note Keeper",
        subtitle: "Saved $notesCount ${notesCount == 1 ? 'note' : 'notes'}",
        time: "Great organization!",
        color: primaryColor,
      ));
    }

    if (savedVideosCount > 0) {
      achievements.add(_buildTimelineItem(
        icon: Icons.video_library,
        title: "Video Learner",
        subtitle: "Bookmarked $savedVideosCount ${savedVideosCount == 1 ? 'video' : 'videos'}",
        time: "Visual learning!",
        color: errorColor,
        isLast: true,
      ));
    }

    // If no achievements yet
    if (achievements.isEmpty) {
      achievements.add(_buildTimelineItem(
        icon: Icons.rocket_launch,
        title: "Start Your Journey",
        subtitle: "Take your first quiz or save your first note!",
        time: "You've got this! 🚀",
        color: accentColor,
        isFirst: true,
        isLast: true,
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

  // ✅ TIMELINE ITEM - Modern Achievement Card
  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : _getSpaceM(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: textPrimary,
                  size: 20,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  margin: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withOpacity(0.5),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: _getSpaceM(context)),

          // Content
          Expanded(
            child: Container(
              padding: _getPaddingM(context),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(_getRadiusM()),
                border: Border.all(
                  color: color.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: _getBodySize(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: TextStyle(
                            color: color,
                            fontSize: _getCaptionSize(context),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  SizedBox(height: _getSpaceXS(context)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: _getCaptionSize(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MODERN ACCOUNT SETTINGS - Same as before
  Widget _buildModernAccountSettings() {
    return Container(
      width: double.infinity,
      padding: _getPaddingL(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(_getRadiusL()),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getSpaceM(context)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor],
                  ),
                  borderRadius: BorderRadius.circular(_getRadiusM()),
                ),
                child: Icon(
                  Icons.settings,
                  color: textPrimary,
                  size: 20,
                ),
              ),
              SizedBox(width: _getSpaceM(context)),
              Expanded(
                child: Text(
                  'Account Settings',
                  style: TextStyle(
                    fontSize: _getSubheadingSize(context),
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              if (!isEditing)
                GestureDetector(
                  onTap: () => setState(() => isEditing = true),
                  child: Container(
                    padding: EdgeInsets.all(_getSpaceS(context)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(_getRadiusS()),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: primaryColor,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: _getSpaceL(context)),

          // Form Fields
          _buildModernTextField(
            label: "Full Name",
            value: userName,
            controller: _nameController,
            icon: Icons.person_outline,
          ),
          SizedBox(height: _getSpaceM(context)),

          _buildModernTextField(
            label: "Email Address",
            value: userEmail,
            controller: _emailController,
            icon: Icons.email_outlined,
          ),

          // Action Buttons
          if (isEditing) ...[
            SizedBox(height: _getSpaceL(context)),
            Row(
              children: [
                Expanded(
                  child: _buildModernButton(
                    label: "Cancel",
                    onPressed: _cancelEditing,
                    isPrimary: false,
                  ),
                ),
                SizedBox(width: _getSpaceM(context)),
                Expanded(
                  child: _buildModernButton(
                    label: "Save Changes",
                    onPressed: _updateProfile,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ✅ MODERN TEXT FIELD - Same as before
  Widget _buildModernTextField({
    required String label,
    required String value,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Container(
      padding: _getPaddingM(context),
      decoration: BoxDecoration(
        color: isEditing
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(_getRadiusM()),
        border: Border.all(
          color: isEditing
              ? primaryColor.withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_getSpaceS(context)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.2), accentColor.withOpacity(0.2)],
              ),
              borderRadius: BorderRadius.circular(_getRadiusS()),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: _getSpaceM(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textTertiary,
                    fontSize: _getCaptionSize(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: _getSpaceXS(context)),
                isEditing
                    ? TextField(
                  controller: controller,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: _getBodySize(context),
                    fontWeight: FontWeight.w500,
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
                    color: textPrimary,
                    fontSize: _getBodySize(context),
                    fontWeight: FontWeight.w500,
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

  // ✅ MODERN BUTTON - Same as before
  Widget _buildModernButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(colors: [primaryColor, accentColor])
            : null,
        color: isPrimary ? null : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_getRadiusM()),
        border: isPrimary
            ? null
            : Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_getRadiusM()),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textPrimary,
                fontSize: _getBodySize(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ MODERN LOGOUT DIALOG - Fixed Overflow & Responsive
class _ModernLogoutDialog extends StatefulWidget {
  @override
  _ModernLogoutDialogState createState() => _ModernLogoutDialogState();
}

class _ModernLogoutDialogState extends State<_ModernLogoutDialog>
    with SingleTickerProviderStateMixin {
  bool _isLoggingOut = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Responsive helper methods
  bool _isSmallScreen(BuildContext context) => MediaQuery.of(context).size.width < 360;
  double _getDialogPadding(BuildContext context) => _isSmallScreen(context) ? 16.0 : 24.0;
  double _getTitleSize(BuildContext context) => _isSmallScreen(context) ? 20.0 : 24.0;
  double _getBodySize(BuildContext context) => _isSmallScreen(context) ? 12.0 : 14.0;
  double _getButtonTextSize(BuildContext context) => _isSmallScreen(context) ? 13.0 : 16.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: screenWidth * 0.9,
            maxHeight: screenHeight * 0.7,
            minWidth: 280,
          ),
          margin: EdgeInsets.all(_getDialogPadding(context)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFEF4444).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(_getDialogPadding(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logout icon with animation
                Container(
                  width: _isSmallScreen(context) ? 60 : 80,
                  height: _isSmallScreen(context) ? 60 : 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoggingOut
                          ? [Colors.grey, Colors.grey.shade600]
                          : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isLoggingOut ? Colors.grey : const Color(0xFFEF4444))
                            .withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: _isLoggingOut
                      ? const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: _isSmallScreen(context) ? 28 : 36,
                  ),
                ),

                SizedBox(height: _getDialogPadding(context)),

                // Title
                Text(
                  _isLoggingOut ? 'Signing Out...' : 'Ready to Sign Out?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getTitleSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: _getDialogPadding(context) * 0.75),

                // Security message
                Container(
                  padding: EdgeInsets.all(_getDialogPadding(context) * 0.75),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: const Color(0xFF06B6D4),
                        size: _isSmallScreen(context) ? 20 : 24,
                      ),
                      SizedBox(height: _getDialogPadding(context) * 0.5),
                      Text(
                        _isLoggingOut
                            ? 'Saving your progress and signing out safely...'
                            : 'Your learning progress is safely saved!\nYou can continue where you left off.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: _getBodySize(context),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: _getDialogPadding(context) * 1.5),

                // Action buttons
                Row(
                  children: [
                    // Stay button
                    Expanded(
                      child: Container(
                        height: _isSmallScreen(context) ? 45 : 50,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _isLoggingOut ? null : () => Navigator.of(context).pop(),
                            child: Center(
                              child: Text(
                                'Stay Here',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: _getButtonTextSize(context),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: _getDialogPadding(context) * 0.75),

                    // Sign Out button
                    Expanded(
                      child: Container(
                        height: _isSmallScreen(context) ? 45 : 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isLoggingOut
                                ? [Colors.grey, Colors.grey.shade600]
                                : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (_isLoggingOut ? Colors.grey : const Color(0xFFEF4444))
                                  .withOpacity(0.3),
                              blurRadius: 10,
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
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isLoggingOut) ...[
                                    SizedBox(
                                      width: _isSmallScreen(context) ? 14 : 16,
                                      height: _isSmallScreen(context) ? 14 : 16,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ] else ...[
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Colors.white,
                                      size: _isSmallScreen(context) ? 16 : 18,
                                    ),
                                  ],
                                  SizedBox(width: _isSmallScreen(context) ? 6 : 8),
                                  Flexible(
                                    child: Text(
                                      _isLoggingOut ? '....' : 'Sign Out',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: _getButtonTextSize(context),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _performLogout();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _performLogout() async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('last_login');

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      throw e;
    }
  }
}



// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:ui';
//
// import 'email_change_verification_screen.dart';
// import 'login_screen.dart';
//
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
//   // Data variables
//   String userName = "Loading...";
//   String userEmail = "Loading...";
//   String profileImageBase64 = "";
//   int userPoints = 0;
//   int notesCount = 0;
//   int savedVideosCount = 0;
//   int savedLinksCount = 0;
//   int quizzesTaken = 0;
//   int bestQuizScore = 0;
//   String userLevel = "Rookie";
//
//   // UI state variables
//   bool isEditing = false;
//   bool isLoading = true;
//   bool isUploadingImage = false;
//   File? _profileImage;
//
//   // Controllers
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _nameController = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
//
//   // Animation controllers
//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late AnimationController _counterController;
//   late AnimationController _pulseController;
//   late AnimationController _scaleController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _counterAnimation;
//   late Animation<double> _pulseAnimation;
//   late Animation<double> _scaleAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _loadUserData();
//   }
//
//   void _initializeAnimations() {
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
//     _counterController = AnimationController(
//       duration: const Duration(milliseconds: 2500),
//       vsync: this,
//     );
//     _pulseController = AnimationController(
//       duration: const Duration(milliseconds: 2000),
//       vsync: this,
//     );
//     _scaleController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
//     _counterAnimation = CurvedAnimation(parent: _counterController, curve: Curves.easeOutQuart);
//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08)
//         .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
//     _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
//   }
//
//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _slideController.dispose();
//     _counterController.dispose();
//     _pulseController.dispose();
//     _scaleController.dispose();
//     _nameController.dispose();
//     _emailController.dispose();
//     super.dispose();
//   }
//
//   // ✅ ENHANCED RESPONSIVE SYSTEM
//   double _getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;
//   double _getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;
//
//   bool _isSmallMobile(BuildContext context) => _getScreenWidth(context) < 360;
//   bool _isMobile(BuildContext context) => _getScreenWidth(context) < 600;
//   bool _isTablet(BuildContext context) => _getScreenWidth(context) >= 600 && _getScreenWidth(context) < 1024;
//   bool _isDesktop(BuildContext context) => _getScreenWidth(context) >= 1024;
//
//   // ✅ ENHANCED TYPOGRAPHY SYSTEM
//   double _getHeadingSize(BuildContext context) {
//     if (_isSmallMobile(context)) return 18;
//     if (_isMobile(context)) return 22;
//     if (_isTablet(context)) return 26;
//     return 30;
//   }
//
//   double _getSubheadingSize(BuildContext context) {
//     if (_isSmallMobile(context)) return 14;
//     if (_isMobile(context)) return 16;
//     if (_isTablet(context)) return 18;
//     return 20;
//   }
//
//   double _getBodySize(BuildContext context) {
//     if (_isSmallMobile(context)) return 11;
//     if (_isMobile(context)) return 13;
//     if (_isTablet(context)) return 14;
//     return 15;
//   }
//
//   double _getCaptionSize(BuildContext context) {
//     if (_isSmallMobile(context)) return 9;
//     if (_isMobile(context)) return 10;
//     if (_isTablet(context)) return 11;
//     return 12;
//   }
//
//   // ✅ ENHANCED SPACING SYSTEM
//   double _getSpaceXS(BuildContext context) => _isSmallMobile(context) ? 3 : (_isMobile(context) ? 4 : 6);
//   double _getSpaceS(BuildContext context) => _isSmallMobile(context) ? 6 : (_isMobile(context) ? 8 : 12);
//   double _getSpaceM(BuildContext context) => _isSmallMobile(context) ? 12 : (_isMobile(context) ? 16 : 20);
//   double _getSpaceL(BuildContext context) => _isSmallMobile(context) ? 18 : (_isMobile(context) ? 24 : 32);
//   double _getSpaceXL(BuildContext context) => _isSmallMobile(context) ? 24 : (_isMobile(context) ? 32 : 48);
//
//   // ✅ MODERN PADDING SYSTEM
//   EdgeInsets _getPaddingS(BuildContext context) => EdgeInsets.all(_getSpaceS(context));
//   EdgeInsets _getPaddingM(BuildContext context) => EdgeInsets.all(_getSpaceM(context));
//   EdgeInsets _getPaddingL(BuildContext context) => EdgeInsets.all(_getSpaceL(context));
//
//   EdgeInsets _getPaddingHorizontal(BuildContext context, double multiplier) =>
//       EdgeInsets.symmetric(horizontal: _getSpaceM(context) * multiplier);
//
//   EdgeInsets _getPaddingVertical(BuildContext context, double multiplier) =>
//       EdgeInsets.symmetric(vertical: _getSpaceM(context) * multiplier);
//
//   // ✅ MODERN BORDER RADIUS SYSTEM
//   double _getRadiusS() => 8;
//   double _getRadiusM() => 16;
//   double _getRadiusL() => 24;
//   double _getRadiusXL() => 32;
//
//   // ✅ GRID SYSTEM FOR NEW LAYOUT
//   int _getStatsColumns(BuildContext context) {
//     if (_isSmallMobile(context)) return 2;
//     if (_isMobile(context)) return 2;
//     if (_isTablet(context)) return 4;
//     return 4;
//   }
//
//   double _getStatsAspectRatio(BuildContext context) {
//     if (_isSmallMobile(context)) return 1.4;
//     if (_isMobile(context)) return 1.2;
//     return 1.0;
//   }
//
//   // ✅ MODERN COLOR PALETTE
//   Color get primaryColor => const Color(0xFF6366F1); // Indigo
//   Color get primaryLight => const Color(0xFF818CF8);
//   Color get primaryDark => const Color(0xFF4F46E5);
//
//   Color get accentColor => const Color(0xFF06B6D4); // Cyan
//   Color get accentLight => const Color(0xFF22D3EE);
//   Color get accentDark => const Color(0xFF0891B2);
//
//   Color get successColor => const Color(0xFF10B981);
//   Color get warningColor => const Color(0xFFF59E0B);
//   Color get errorColor => const Color(0xFFEF4444);
//
//   Color get surfaceColor => const Color(0xFF1E293B);
//   Color get surfaceLight => const Color(0xFF334155);
//   Color get surfaceDark => const Color(0xFF0F172A);
//
//   Color get textPrimary => Colors.white;
//   Color get textSecondary => Colors.white.withOpacity(0.8);
//   Color get textTertiary => Colors.white.withOpacity(0.6);
//
//   // Level styling methods (updated for new design)
//   Color _getLevelColor() {
//     switch (userLevel) {
//       case 'Expert': return const Color(0xFF8B5CF6); // Purple
//       case 'Advanced': return const Color(0xFF06B6D4); // Cyan
//       case 'Intermediate': return const Color(0xFF3B82F6); // Blue
//       case 'Beginner': return const Color(0xFFF59E0B); // Amber
//       default: return const Color(0xFF6B7280); // Gray
//     }
//   }
//
//   IconData _getLevelIcon() {
//     switch (userLevel) {
//       case 'Expert': return Icons.emoji_events; // Trophy
//       case 'Advanced': return Icons.military_tech; // Medal
//       case 'Intermediate': return Icons.star; // Star
//       case 'Beginner': return Icons.trending_up; // Arrow up
//       default: return Icons.circle; // Dot
//     }
//   }
//
//   String _calculateUserLevel(int points) {
//     if (points >= 5000) return 'Expert';
//     if (points >= 3000) return 'Advanced';
//     if (points >= 1500) return 'Intermediate';
//     if (points >= 500) return 'Beginner';
//     return 'Rookie';
//   }
//
//   // Helper methods
//   Uint8List _base64ToImage(String base64String) {
//     return base64Decode(base64String);
//   }
//
//   bool _isValidEmail(String email) {
//     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
//   }
//
//   // ✅ MODERN SNACKBAR SYSTEM
//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Container(
//           padding: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
//           child: Row(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(_getSpaceXS(context)),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(Icons.check_circle, color: Colors.white, size: 20),
//               ),
//               SizedBox(width: _getSpaceS(context)),
//               Expanded(
//                 child: Text(
//                   message,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: _getBodySize(context),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         backgroundColor: successColor,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getRadiusM())),
//         margin: EdgeInsets.all(_getSpaceM(context)),
//         elevation: 8,
//       ),
//     );
//   }
//
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Container(
//           padding: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
//           child: Row(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(_getSpaceXS(context)),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(Icons.error, color: Colors.white, size: 20),
//               ),
//               SizedBox(width: _getSpaceS(context)),
//               Expanded(
//                 child: Text(
//                   message,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: _getBodySize(context),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         backgroundColor: errorColor,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getRadiusM())),
//         margin: EdgeInsets.all(_getSpaceM(context)),
//         elevation: 8,
//       ),
//     );
//   }
//
//   void _redirectToLogin() {
//     if (mounted) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
//             (route) => false,
//       );
//     }
//   }
//
//   // ✅ DATA LOADING METHODS (Same functionality, updated animations)
//   Future<void> _loadUserData() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         _redirectToLogin();
//         return;
//       }
//
//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
//
//       if (userDoc.exists && mounted) {
//         final userData = userDoc.data()!;
//         setState(() {
//           userName = userData['fullName'] ?? 'Unknown User';
//           userEmail = userData['email'] ?? user.email ?? '';
//           _nameController.text = userName;
//           _emailController.text = userEmail;
//         });
//
//         await Future.wait([
//           _loadProfileImage(),
//           _loadUserStats(),
//         ]);
//
//         if (mounted) {
//           // Start new animation sequence
//           _fadeController.forward();
//           await Future.delayed(const Duration(milliseconds: 200));
//           _slideController.forward();
//           await Future.delayed(const Duration(milliseconds: 300));
//           _scaleController.forward();
//           await Future.delayed(const Duration(milliseconds: 200));
//           _counterController.forward();
//           _pulseController.repeat(reverse: true);
//         }
//
//         setState(() {
//           isLoading = false;
//         });
//       } else {
//         _redirectToLogin();
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//         _showErrorSnackBar('Failed to load profile data');
//       }
//     }
//   }
//
//   Future<void> _loadUserStats() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) return;
//
//       final userId = user.uid;
//       final points = prefs.getInt('${userId}_user_points') ?? 0;
//       final quizCount = prefs.getInt('${userId}_quizzes_taken') ?? 0;
//       final bestScore = prefs.getInt('${userId}_best_score') ?? 0;
//
//       // Count notes from multiple sources
//       int totalNotesCount = 0;
//       int linksCount = 0;
//       int videosCount = 0;
//
//       final savedNotesJson = prefs.getStringList('${userId}_saved_notes') ?? [];
//       totalNotesCount += savedNotesJson.length;
//
//       for (final noteString in savedNotesJson) {
//         try {
//           if (noteString.contains('http') || noteString.contains('www.')) {
//             linksCount++;
//           }
//         } catch (e) {
//           debugPrint('Error parsing saved note: $e');
//         }
//       }
//
//       final codingNotesJson = prefs.getStringList('${userId}_coding_notes') ?? [];
//       totalNotesCount += codingNotesJson.length;
//
//       final personalNotesJson = prefs.getStringList('${userId}_personal_notes') ?? [];
//       totalNotesCount += personalNotesJson.length;
//
//       final studyNotesJson = prefs.getStringList('${userId}_study_notes') ?? [];
//       totalNotesCount += studyNotesJson.length;
//
//       final savedVideosJson = prefs.getStringList('${userId}_saved_videos') ?? [];
//       final bookmarkedVideosJson = prefs.getStringList('${userId}_bookmarked_videos') ?? [];
//       videosCount = savedVideosJson.length + bookmarkedVideosJson.length;
//
//       final savedLinksJson = prefs.getStringList('${userId}_saved_links') ?? [];
//       final bookmarkedLinksJson = prefs.getStringList('${userId}_bookmarked_links') ?? [];
//       linksCount += savedLinksJson.length + bookmarkedLinksJson.length;
//
//       final level = _calculateUserLevel(points);
//
//       if (mounted) {
//         setState(() {
//           userPoints = points;
//           quizzesTaken = quizCount;
//           bestQuizScore = bestScore;
//           notesCount = totalNotesCount;
//           savedVideosCount = videosCount;
//           savedLinksCount = linksCount;
//           userLevel = level;
//         });
//       }
//     } catch (e) {
//       debugPrint('❌ Error loading user stats: $e');
//       if (mounted) {
//         setState(() {
//           userPoints = 0;
//           notesCount = 0;
//           savedVideosCount = 0;
//           savedLinksCount = 0;
//           quizzesTaken = 0;
//           bestQuizScore = 0;
//           userLevel = 'Rookie';
//         });
//       }
//     }
//   }
//
//   Future<void> _loadProfileImage() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         final imageKey = 'profile_image_${user.uid}';
//         final savedImageBase64 = prefs.getString(imageKey);
//         if (savedImageBase64 != null && savedImageBase64.isNotEmpty && mounted) {
//           setState(() {
//             profileImageBase64 = savedImageBase64;
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint('Error loading profile image: $e');
//     }
//   }
//
//   Future<void> _refreshData() async {
//     setState(() {
//       isLoading = true;
//     });
//
//     // Reset animations
//     _counterController.reset();
//     _scaleController.reset();
//
//     await Future.wait([
//       _loadUserStats(),
//       _loadProfileImage(),
//     ]);
//
//     if (mounted) {
//       setState(() {
//         isLoading = false;
//       });
//
//       // Restart animations
//       _counterController.forward();
//       _scaleController.forward();
//
//       _showSuccessSnackBar('Profile data refreshed!');
//     }
//   }
//
//   // ✅ IMAGE HANDLING METHODS
//   Future<void> _pickImage() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 512,
//         maxHeight: 512,
//         imageQuality: 85,
//       );
//
//       if (image != null) {
//         setState(() {
//           _profileImage = File(image.path);
//           isUploadingImage = true;
//         });
//
//         await _saveProfileImageLocally(File(image.path));
//       }
//     } catch (e) {
//       _showErrorSnackBar('Failed to pick image: Please try again');
//     }
//   }
//
//   Future<void> _saveProfileImageLocally(File imageFile) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) return;
//
//       final bytes = await imageFile.readAsBytes();
//       final base64String = base64Encode(bytes);
//
//       final prefs = await SharedPreferences.getInstance();
//       final imageKey = 'profile_image_${user.uid}';
//       await prefs.setString(imageKey, base64String);
//
//       if (mounted) {
//         setState(() {
//           profileImageBase64 = base64String;
//           isUploadingImage = false;
//         });
//         _showSuccessSnackBar('Profile image updated successfully!');
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           isUploadingImage = false;
//           _profileImage = null;
//         });
//         _showErrorSnackBar('Failed to save image');
//       }
//     }
//   }
//
//   // ✅ PROFILE UPDATE METHODS
//   Future<void> _updateProfile() async {
//     final name = _nameController.text.trim();
//     final email = _emailController.text.trim();
//     final currentUser = FirebaseAuth.instance.currentUser;
//
//     if (name.isEmpty) {
//       _showErrorSnackBar('Name cannot be empty');
//       return;
//     }
//
//     if (!_isValidEmail(email)) {
//       _showErrorSnackBar('Please enter a valid email address');
//       return;
//     }
//
//     if (currentUser == null) return;
//
//     try {
//       setState(() {
//         isLoading = true;
//       });
//
//       final emailChanged = currentUser.email != email;
//
//       if (emailChanged) {
//         await _handleEmailChange(email, name);
//       } else {
//         await _updateNameOnly(name);
//       }
//
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//         _showErrorSnackBar('Failed to update profile');
//       }
//     }
//   }
//
//   Future<void> _updateNameOnly(String name) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .update({
//         'fullName': name,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//
//       await user.updateDisplayName(name);
//
//       if (mounted) {
//         setState(() {
//           userName = name;
//           isEditing = false;
//           isLoading = false;
//         });
//         _showSuccessSnackBar('Name updated successfully!');
//       }
//     }
//   }
//
//   Future<void> _handleEmailChange(String newEmail, String name) async {
//     try {
//       setState(() {
//         isLoading = false;
//         isEditing = false;
//       });
//
//       final result = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => EmailChangeVerificationScreen(
//             currentEmail: userEmail,
//             newEmail: newEmail,
//             userName: name,
//           ),
//         ),
//       );
//
//       if (result == true) {
//         await _loadUserData();
//         _showSuccessSnackBar('Email updated successfully!');
//       } else {
//         _emailController.text = userEmail;
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       _emailController.text = userEmail;
//       _showErrorSnackBar('Failed to initiate email change');
//     }
//   }
//
//   void _cancelEditing() {
//     setState(() {
//       _nameController.text = userName;
//       _emailController.text = userEmail;
//       isEditing = false;
//     });
//   }
//
//   // ✅ LEVEL PROGRESS CALCULATIONS
//   String _getNextLevelInfo() {
//     final nextPoints = _getNextLevelPoints();
//
//     if (userLevel == 'Expert') {
//       return 'Congratulations! You\'ve reached the highest level! 🏆';
//     }
//
//     final needed = nextPoints - userPoints;
//     final nextLevel = _getNextLevelName();
//
//     return '$needed points to $nextLevel';
//   }
//
//   String _getNextLevelName() {
//     switch (userLevel) {
//       case 'Rookie': return 'Beginner';
//       case 'Beginner': return 'Intermediate';
//       case 'Intermediate': return 'Advanced';
//       case 'Advanced': return 'Expert';
//       default: return 'Expert';
//     }
//   }
//
//   int _getNextLevelPoints() {
//     switch (userLevel) {
//       case 'Rookie': return 500;
//       case 'Beginner': return 1500;
//       case 'Intermediate': return 3000;
//       case 'Advanced': return 5000;
//       default: return 5000;
//     }
//   }
//
//   int _getCurrentLevelPoints() {
//     switch (userLevel) {
//       case 'Rookie': return 0;
//       case 'Beginner': return 500;
//       case 'Intermediate': return 1500;
//       case 'Advanced': return 3000;
//       case 'Expert': return 5000;
//       default: return 0;
//     }
//   }
//
//   double _getLevelProgress() {
//     if (userLevel == 'Expert') return 1.0;
//
//     final nextPoints = _getNextLevelPoints();
//     final currentPoints = _getCurrentLevelPoints();
//     final progress = ((userPoints - currentPoints) / (nextPoints - currentPoints)).clamp(0.0, 1.0);
//
//     return progress;
//   }
//
//   // ✅ LOGOUT DIALOG
//   Future<void> _showLogoutDialog() async {
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: true,
//       barrierColor: Colors.black.withOpacity(0.8),
//       builder: (BuildContext context) {
//         return _ModernLogoutDialog();
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: surfaceDark,
//       body: SafeArea(
//         child: isLoading ? _buildModernLoadingState() : _buildModernMainContent(),
//       ),
//     );
//   }
//
//   // ✅ MODERN LOADING STATE - Glassmorphism Design
//   Widget _buildModernLoadingState() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             surfaceDark,
//             surfaceColor,
//             surfaceLight.withOpacity(0.8),
//           ],
//         ),
//       ),
//       child: Center(
//         child: Container(
//           padding: EdgeInsets.all(_getSpaceXL(context)),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(_getRadiusXL()),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.2),
//               width: 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.3),
//                 blurRadius: 30,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Modern loading spinner
//               Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [primaryColor, accentColor],
//                   ),
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: primaryColor.withOpacity(0.4),
//                       blurRadius: 20,
//                       spreadRadius: 5,
//                     ),
//                   ],
//                 ),
//                 child: const CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   strokeWidth: 3,
//                 ),
//               ),
//               SizedBox(height: _getSpaceL(context)),
//               // Loading text
//               Text(
//                 'Loading your profile...',
//                 style: TextStyle(
//                   color: textPrimary,
//                   fontSize: _getSubheadingSize(context),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: _getSpaceS(context)),
//               Text(
//                 'Please wait a moment',
//                 style: TextStyle(
//                   color: textSecondary,
//                   fontSize: _getBodySize(context),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ✅ MODERN MAIN CONTENT - Fixed Layout Structure
//   Widget _buildModernMainContent() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             surfaceDark,
//             surfaceColor,
//             surfaceLight.withOpacity(0.5),
//           ],
//         ),
//       ),
//       child: FadeTransition(
//         opacity: _fadeAnimation,
//         child: CustomScrollView(
//           physics: const ClampingScrollPhysics(),
//           slivers: [
//             _buildModernAppBar(),
//             SliverSafeArea(
//               sliver: SliverPadding(
//                 padding: EdgeInsets.symmetric(horizontal: _getSpaceM(context)),
//                 sliver: SliverList(
//                   delegate: SliverChildListDelegate([
//                     SizedBox(height: _getSpaceM(context)),
//                     _buildNewHeroSection(),
//                     SizedBox(height: _getSpaceL(context)),
//                     _buildModernStatsGrid(),
//                     SizedBox(height: _getSpaceL(context)),
//                     _buildQuickActionsCard(),
//                     SizedBox(height: _getSpaceL(context)),
//                     _buildModernLearningJourney(),
//                     SizedBox(height: _getSpaceL(context)),
//                     _buildModernAccountSettings(),
//                     SizedBox(height: _getSpaceXL(context) * 2),
//                   ]),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ✅ NEW HERO SECTION - Completely Redesigned
//   Widget _buildNewHeroSection() {
//     return SlideTransition(
//       position: _slideAnimation,
//       child: Column(
//         children: [
//           // Profile Image and Basic Info Card
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.all(_getSpaceL(context)),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   Colors.white.withOpacity(0.15),
//                   Colors.white.withOpacity(0.05),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(_getRadiusL()),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.2),
//                 width: 1,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   blurRadius: 20,
//                   offset: const Offset(0, 10),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 // Profile Image Section
//                 Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     // Animated level ring
//                     AnimatedBuilder(
//                       animation: _pulseAnimation,
//                       builder: (context, child) {
//                         return Transform.scale(
//                           scale: _pulseAnimation.value,
//                           child: Container(
//                             width: 90,
//                             height: 90,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               gradient: LinearGradient(
//                                 colors: [
//                                   _getLevelColor(),
//                                   _getLevelColor().withOpacity(0.6),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//
//                     // Profile Image
//                     Container(
//                       width: 75,
//                       height: 75,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.white,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.2),
//                             blurRadius: 15,
//                             offset: const Offset(0, 5),
//                           ),
//                         ],
//                       ),
//                       child: ClipOval(
//                         child: _profileImage != null
//                             ? Image.file(_profileImage!, fit: BoxFit.cover)
//                             : (profileImageBase64.isNotEmpty
//                             ? Image.memory(_base64ToImage(profileImageBase64), fit: BoxFit.cover)
//                             : Container(
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [primaryColor, accentColor],
//                             ),
//                           ),
//                           child: Center(
//                             child: Text(
//                               userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
//                               style: TextStyle(
//                                 fontSize: _getHeadingSize(context),
//                                 fontWeight: FontWeight.bold,
//                                 color: textPrimary,
//                               ),
//                             ),
//                           ),
//                         )),
//                       ),
//                     ),
//
//                     // Camera Button
//                     Positioned(
//                       bottom: 0,
//                       right: 0,
//                       child: GestureDetector(
//                         onTap: isUploadingImage ? null : _pickImage,
//                         child: Container(
//                           padding: EdgeInsets.all(_getSpaceS(context)),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [primaryColor, accentColor],
//                             ),
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Colors.white, width: 2),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: primaryColor.withOpacity(0.4),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Icon(
//                             isUploadingImage ? Icons.hourglass_empty : Icons.camera_alt,
//                             size: 12,
//                             color: textPrimary,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 SizedBox(width: _getSpaceL(context)),
//
//                 // User Info Section
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Name
//                       Text(
//                         userName,
//                         style: TextStyle(
//                           fontSize: _getSubheadingSize(context),
//                           fontWeight: FontWeight.bold,
//                           color: textPrimary,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       SizedBox(height: _getSpaceXS(context)),
//
//                       // Email
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: _getSpaceM(context),
//                           vertical: _getSpaceS(context),
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(_getRadiusS()),
//                           border: Border.all(
//                             color: Colors.white.withOpacity(0.2),
//                           ),
//                         ),
//                         child: Text(
//                           userEmail,
//                           style: TextStyle(
//                             fontSize: _getCaptionSize(context),
//                             color: textSecondary,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       SizedBox(height: _getSpaceM(context)),
//
//                       // Level Badge
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: _getSpaceM(context),
//                           vertical: _getSpaceS(context),
//                         ),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [_getLevelColor(), _getLevelColor().withOpacity(0.7)],
//                           ),
//                           borderRadius: BorderRadius.circular(_getRadiusM()),
//                           boxShadow: [
//                             BoxShadow(
//                               color: _getLevelColor().withOpacity(0.4),
//                               blurRadius: 10,
//                               offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               _getLevelIcon(),
//                               color: textPrimary,
//                               size: 16,
//                             ),
//                             SizedBox(width: _getSpaceS(context)),
//                             Text(
//                               userLevel,
//                               style: TextStyle(
//                                 fontSize: _getBodySize(context),
//                                 fontWeight: FontWeight.bold,
//                                 color: textPrimary,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           SizedBox(height: _getSpaceL(context)),
//
//           // Learning Points and Progress Card
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.all(_getSpaceL(context)),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   primaryColor.withOpacity(0.8),
//                   accentColor.withOpacity(0.6),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(_getRadiusL()),
//               boxShadow: [
//                 BoxShadow(
//                   color: primaryColor.withOpacity(0.3),
//                   blurRadius: 20,
//                   offset: const Offset(0, 10),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // Points Header
//                 Row(
//                   children: [
//                     Container(
//                       padding: EdgeInsets.all(_getSpaceM(context)),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(_getRadiusM()),
//                       ),
//                       child: Icon(
//                         Icons.stars_rounded,
//                         color: textPrimary,
//                         size: 28,
//                       ),
//                     ),
//                     SizedBox(width: _getSpaceM(context)),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Learning Points',
//                             style: TextStyle(
//                               fontSize: _getBodySize(context),
//                               color: textPrimary.withOpacity(0.9),
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           SizedBox(height: _getSpaceXS(context)),
//                           AnimatedBuilder(
//                             animation: _counterAnimation,
//                             builder: (context, child) {
//                               final animatedPoints = (userPoints * _counterAnimation.value).round();
//                               return Text(
//                                 animatedPoints.toString(),
//                                 style: TextStyle(
//                                   fontSize: _getHeadingSize(context) * 1.5,
//                                   fontWeight: FontWeight.bold,
//                                   color: textPrimary,
//                                 ),
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: _getSpaceL(context)),
//
//                 // Progress Section
//                 Row(
//                   children: [
//                     // Progress Ring - Fixed circle and dot positioning
//                     SizedBox(
//                       width: 90,
//                       height: 90,
//                       child: Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           // Background circle
//                           SizedBox(
//                             width: 90,
//                             height: 90,
//                             child: CircularProgressIndicator(
//                               value: 1.0, // Full background circle
//                               strokeWidth: 8,
//                               backgroundColor: Colors.white.withOpacity(0.2),
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.2)),
//                             ),
//                           ),
//                           // Progress circle
//                           SizedBox(
//                             width: 90,
//                             height: 90,
//                             child: CircularProgressIndicator(
//                               value: _getLevelProgress(),
//                               strokeWidth: 8,
//                               backgroundColor: Colors.transparent,
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                               strokeCap: StrokeCap.round, // Rounded ends to prevent merging
//                             ),
//                           ),
//                           // Center content
//                           Container(
//                             width: 60,
//                             height: 60,
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.1),
//                               shape: BoxShape.circle,
//                             ),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   _getLevelIcon(),
//                                   color: textPrimary,
//                                   size: 18,
//                                 ),
//                                 SizedBox(height: 2),
//                                 Text(
//                                   '${(_getLevelProgress() * 100).toInt()}%',
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.bold,
//                                     color: textPrimary,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     SizedBox(width: _getSpaceL(context)),
//
//                     // Progress Info
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             userLevel,
//                             style: TextStyle(
//                               fontSize: _getSubheadingSize(context),
//                               fontWeight: FontWeight.bold,
//                               color: textPrimary,
//                             ),
//                           ),
//                           SizedBox(height: _getSpaceS(context)),
//                           Text(
//                             _getNextLevelInfo(),
//                             style: TextStyle(
//                               fontSize: _getBodySize(context),
//                               color: textPrimary.withOpacity(0.8),
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           if (bestQuizScore > 0) ...[
//                             SizedBox(height: _getSpaceS(context)),
//                             Container(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: _getSpaceM(context),
//                                 vertical: _getSpaceS(context),
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.2),
//                                 borderRadius: BorderRadius.circular(_getRadiusS()),
//                               ),
//                               child: Text(
//                                 'Best Quiz: $bestQuizScore pts',
//                                 style: TextStyle(
//                                   fontSize: _getCaptionSize(context),
//                                   color: textPrimary.withOpacity(0.8),
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
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
//   // ✅ MODERN APP BAR - Fixed Height Issues
//   Widget _buildModernAppBar() {
//     return SliverAppBar(
//       expandedHeight: _isMobile(context) ? 80 : 100,
//       floating: true,
//       pinned: true,
//       elevation: 0,
//       backgroundColor: Colors.transparent,
//       automaticallyImplyLeading: false,
//       flexibleSpace: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               surfaceColor.withOpacity(0.9),
//               surfaceLight.withOpacity(0.7),
//             ],
//           ),
//           border: Border(
//             bottom: BorderSide(
//               color: Colors.white.withOpacity(0.1),
//               width: 1,
//             ),
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: _getSpaceM(context)),
//             child: Row(
//               children: [
//                 // Back Button
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(_getRadiusM()),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.2),
//                     ),
//                   ),
//                   child: IconButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     icon: Icon(
//                       Icons.arrow_back_ios_new,
//                       color: textPrimary,
//                       size: 20,
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: _getSpaceM(context)),
//
//                 // Title
//                 Expanded(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Profile',
//                         style: TextStyle(
//                           color: textPrimary,
//                           fontSize: _getHeadingSize(context),
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         'Manage your learning profile',
//                         style: TextStyle(
//                           color: textSecondary,
//                           fontSize: _getCaptionSize(context),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Refresh Button
//                 Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [primaryColor, accentColor],
//                     ),
//                     borderRadius: BorderRadius.circular(_getRadiusM()),
//                     boxShadow: [
//                       BoxShadow(
//                         color: primaryColor.withOpacity(0.3),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: IconButton(
//                     onPressed: _refreshData,
//                     icon: Icon(
//                       Icons.refresh,
//                       color: textPrimary,
//                       size: 20,
//                     ),
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
//   // ✅ MODERN STATS GRID - Completely Fixed Overflow Issues
//   Widget _buildModernStatsGrid() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final crossAxisCount = _getStatsColumns(context);
//         final spacing = _getSpaceM(context);
//
//         // Calculate safe dimensions
//         final availableWidth = constraints.maxWidth;
//         final itemWidth = (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
//         final itemHeight = _isSmallMobile(context) ? itemWidth * 1.1 : itemWidth * 0.95;
//
//         return Column(
//           children: [
//             // First Row
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildModernStatCard(
//                     icon: Icons.article_outlined,
//                     title: "Notes",
//                     value: notesCount.toString(),
//                     subtitle: "Saved",
//                     color: const Color(0xFF8B5CF6),
//                     gradient: [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
//                     height: itemHeight,
//                   ),
//                 ),
//                 SizedBox(width: spacing),
//                 Expanded(
//                   child: _buildModernStatCard(
//                     icon: Icons.play_circle_outline,
//                     title: "Videos",
//                     value: savedVideosCount.toString(),
//                     subtitle: "Bookmarked",
//                     color: const Color(0xFFEF4444),
//                     gradient: [const Color(0xFFEF4444), const Color(0xFFF87171)],
//                     height: itemHeight,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: spacing),
//             // Second Row
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildModernStatCard(
//                     icon: Icons.link_outlined,
//                     title: "Links",
//                     value: savedLinksCount.toString(),
//                     subtitle: "Resources",
//                     color: const Color(0xFF3B82F6),
//                     gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
//                     height: itemHeight,
//                   ),
//                 ),
//                 SizedBox(width: spacing),
//                 Expanded(
//                   child: _buildModernStatCard(
//                     icon: Icons.quiz_outlined,
//                     title: "Quizzes",
//                     value: quizzesTaken.toString(),
//                     subtitle: "Completed",
//                     color: const Color(0xFF10B981),
//                     gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
//                     height: itemHeight,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   // ✅ MODERN STAT CARD - Enhanced Visibility & Responsive
//   Widget _buildModernStatCard({
//     required IconData icon,
//     required String title,
//     required String value,
//     required String subtitle,
//     required Color color,
//     required List<Color> gradient,
//     double? width,
//     required double height,
//   }) {
//     return AnimatedBuilder(
//       animation: _counterAnimation,
//       builder: (context, child) {
//         final animatedValue = (int.tryParse(value) ?? 0) * _counterAnimation.value;
//
//         return Container(
//           width: width,
//           height: height,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Colors.white.withOpacity(0.2),
//                 Colors.white.withOpacity(0.1),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(_getRadiusL()),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.3),
//               width: 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.15),
//                 blurRadius: 20,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           child: Padding(
//             padding: EdgeInsets.all(_getSpaceM(context)),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 // Icon with gradient background
//                 Expanded(
//                   flex: 2,
//                   child: Container(
//                     padding: EdgeInsets.all(_getSpaceS(context)),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(colors: gradient),
//                       borderRadius: BorderRadius.circular(_getRadiusM()),
//                       boxShadow: [
//                         BoxShadow(
//                           color: color.withOpacity(0.4),
//                           blurRadius: 12,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Center(
//                       child: Icon(
//                         icon,
//                         color: Colors.white,
//                         size: _isSmallMobile(context) ? 20 : 24,
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: _getSpaceS(context)),
//
//                 // Animated Value
//                 Expanded(
//                   flex: 2,
//                   child: Center(
//                     child: Text(
//                       animatedValue.round().toString(),
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: _isSmallMobile(context) ? 24 : 28,
//                         fontWeight: FontWeight.bold,
//                         shadows: [
//                           Shadow(
//                             color: Colors.black.withOpacity(0.3),
//                             offset: const Offset(0, 2),
//                             blurRadius: 4,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 // Title
//                 Expanded(
//                   flex: 1,
//                   child: Center(
//                     child: Text(
//                       title,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: _isSmallMobile(context) ? 12 : _getBodySize(context),
//                         fontWeight: FontWeight.w700,
//                         shadows: [
//                           Shadow(
//                             color: Colors.black.withOpacity(0.4),
//                             offset: const Offset(0, 1),
//                             blurRadius: 2,
//                           ),
//                         ],
//                       ),
//                       textAlign: TextAlign.center,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ),
//
//                 // Subtitle
//                 Expanded(
//                   flex: 1,
//                   child: Center(
//                     child: Text(
//                       subtitle,
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.9),
//                         fontSize: _isSmallMobile(context) ? 10 : _getCaptionSize(context),
//                         fontWeight: FontWeight.w500,
//                         shadows: [
//                           Shadow(
//                             color: Colors.black.withOpacity(0.3),
//                             offset: const Offset(0, 1),
//                             blurRadius: 2,
//                           ),
//                         ],
//                       ),
//                       textAlign: TextAlign.center,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // ✅ QUICK ACTIONS CARD - Fixed Button Layout
//   Widget _buildQuickActionsCard() {
//     return Container(
//       width: double.infinity,
//       padding: _getPaddingL(context),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Colors.white.withOpacity(0.15),
//             Colors.white.withOpacity(0.05),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(_getRadiusL()),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.2),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Row(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(_getSpaceM(context)),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [warningColor, warningColor.withOpacity(0.7)],
//                   ),
//                   borderRadius: BorderRadius.circular(_getRadiusM()),
//                 ),
//                 child: Icon(
//                   Icons.flash_on,
//                   color: textPrimary,
//                   size: 20,
//                 ),
//               ),
//               SizedBox(width: _getSpaceM(context)),
//               Expanded(
//                 child: Text(
//                   'Quick Actions',
//                   style: TextStyle(
//                     fontSize: _getSubheadingSize(context),
//                     fontWeight: FontWeight.bold,
//                     color: textPrimary,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: _getSpaceL(context)),
//
//           // Action Buttons Grid - Fixed Layout
//           LayoutBuilder(
//             builder: (context, constraints) {
//               return Column(
//                 children: [
//                   // First Row
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildActionButton(
//                           icon: Icons.edit,
//                           label: 'Edit Profile',
//                           onTap: () => setState(() => isEditing = true),
//                           gradient: [primaryColor, primaryLight],
//                         ),
//                       ),
//                       SizedBox(width: _getSpaceM(context)),
//                       Expanded(
//                         child: _buildActionButton(
//                           icon: Icons.refresh,
//                           label: 'Refresh Data',
//                           onTap: _refreshData,
//                           gradient: [accentColor, accentLight],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: _getSpaceM(context)),
//                   // Second Row
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildActionButton(
//                           icon: Icons.camera_alt,
//                           label: 'Change Photo',
//                           onTap: _pickImage,
//                           gradient: [successColor, const Color(0xFF34D399)],
//                         ),
//                       ),
//                       SizedBox(width: _getSpaceM(context)),
//                       Expanded(
//                         child: _buildActionButton(
//                           icon: Icons.logout,
//                           label: 'Sign Out',
//                           onTap: _showLogoutDialog,
//                           gradient: [errorColor, const Color(0xFFF87171)],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ✅ ACTION BUTTON - Enhanced Visibility & Responsive
//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//     required List<Color> gradient,
//   }) {
//     return Container(
//       height: _isSmallMobile(context) ? 45 : 50,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(colors: gradient),
//         borderRadius: BorderRadius.circular(_getRadiusM()),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.2),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: gradient[0].withOpacity(0.4),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(_getRadiusM()),
//           onTap: onTap,
//           child: Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: _getSpaceS(context),
//               vertical: _getSpaceS(context),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Icon(
//                     icon,
//                     color: Colors.white,
//                     size: _isSmallMobile(context) ? 14 : 16,
//                   ),
//                 ),
//                 SizedBox(width: _getSpaceS(context)),
//                 Flexible(
//                   child: Text(
//                     label,
//                     style: TextStyle(
//                       fontSize: _isSmallMobile(context) ? 11 : _getBodySize(context),
//                       fontWeight: FontWeight.w700,
//                       color: Colors.white,
//                       shadows: [
//                         Shadow(
//                           color: Colors.black.withOpacity(0.4),
//                           offset: const Offset(0, 1),
//                           blurRadius: 2,
//                         ),
//                       ],
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     textAlign: TextAlign.center,
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
//   // ✅ MODERN LEARNING JOURNEY - Same as before
//   Widget _buildModernLearningJourney() {
//     return Container(
//       width: double.infinity,
//       padding: _getPaddingL(context),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Colors.white.withOpacity(0.15),
//             Colors.white.withOpacity(0.05),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(_getRadiusL()),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.2),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Row(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(_getSpaceM(context)),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
//                   ),
//                   borderRadius: BorderRadius.circular(_getRadiusM()),
//                 ),
//                 child: Icon(
//                   Icons.trending_up,
//                   color: textPrimary,
//                   size: 20,
//                 ),
//               ),
//               SizedBox(width: _getSpaceM(context)),
//               Expanded(
//                 child: Text(
//                   'Learning Journey',
//                   style: TextStyle(
//                     fontSize: _getSubheadingSize(context),
//                     fontWeight: FontWeight.bold,
//                     color: textPrimary,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: _getSpaceL(context)),
//
//           // Achievements Timeline
//           ..._buildModernAchievements(),
//         ],
//       ),
//     );
//   }
//
//   List<Widget> _buildModernAchievements() {
//     List<Widget> achievements = [];
//
//     if (userPoints > 0) {
//       achievements.add(_buildTimelineItem(
//         icon: Icons.emoji_events,
//         title: "Points Earned",
//         subtitle: "$userPoints learning points collected!",
//         time: _getPointsMessage(),
//         color: warningColor,
//         isFirst: true,
//       ));
//     }
//
//     if (quizzesTaken > 0) {
//       achievements.add(_buildTimelineItem(
//         icon: Icons.quiz,
//         title: "Quiz Master",
//         subtitle: "Completed $quizzesTaken ${quizzesTaken == 1 ? 'quiz' : 'quizzes'}",
//         time: bestQuizScore > 0 ? "Best: $bestQuizScore pts" : "Keep going!",
//         color: successColor,
//       ));
//     }
//
//     if (notesCount > 0) {
//       achievements.add(_buildTimelineItem(
//         icon: Icons.note_add,
//         title: "Note Keeper",
//         subtitle: "Saved $notesCount ${notesCount == 1 ? 'note' : 'notes'}",
//         time: "Great organization!",
//         color: primaryColor,
//       ));
//     }
//
//     if (savedVideosCount > 0) {
//       achievements.add(_buildTimelineItem(
//         icon: Icons.video_library,
//         title: "Video Learner",
//         subtitle: "Bookmarked $savedVideosCount ${savedVideosCount == 1 ? 'video' : 'videos'}",
//         time: "Visual learning!",
//         color: errorColor,
//         isLast: true,
//       ));
//     }
//
//     // If no achievements yet
//     if (achievements.isEmpty) {
//       achievements.add(_buildTimelineItem(
//         icon: Icons.rocket_launch,
//         title: "Start Your Journey",
//         subtitle: "Take your first quiz or save your first note!",
//         time: "You've got this! 🚀",
//         color: accentColor,
//         isFirst: true,
//         isLast: true,
//       ));
//     }
//
//     return achievements;
//   }
//
//   String _getPointsMessage() {
//     if (userPoints >= 5000) return "Amazing! 🏆";
//     if (userPoints >= 3000) return "Excellent! 🌟";
//     if (userPoints >= 1500) return "Great job! 🎉";
//     if (userPoints >= 500) return "Keep going! 💪";
//     return "Good start! 👍";
//   }
//
//   // ✅ TIMELINE ITEM - Modern Achievement Card
//   Widget _buildTimelineItem({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required String time,
//     required Color color,
//     bool isFirst = false,
//     bool isLast = false,
//   }) {
//     return Container(
//       margin: EdgeInsets.only(bottom: isLast ? 0 : _getSpaceM(context)),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Timeline indicator
//           Column(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [color, color.withOpacity(0.7)],
//                   ),
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: color.withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   icon,
//                   color: textPrimary,
//                   size: 20,
//                 ),
//               ),
//               if (!isLast)
//                 Container(
//                   width: 2,
//                   height: 40,
//                   margin: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         color.withOpacity(0.5),
//                         Colors.white.withOpacity(0.1),
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           SizedBox(width: _getSpaceM(context)),
//
//           // Content
//           Expanded(
//             child: Container(
//               padding: _getPaddingM(context),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.05),
//                 borderRadius: BorderRadius.circular(_getRadiusM()),
//                 border: Border.all(
//                   color: color.withOpacity(0.2),
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           title,
//                           style: TextStyle(
//                             color: textPrimary,
//                             fontWeight: FontWeight.w600,
//                             fontSize: _getBodySize(context),
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       if (time.isNotEmpty)
//                         Text(
//                           time,
//                           style: TextStyle(
//                             color: color,
//                             fontSize: _getCaptionSize(context),
//                             fontWeight: FontWeight.w500,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                     ],
//                   ),
//                   SizedBox(height: _getSpaceXS(context)),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       color: textSecondary,
//                       fontSize: _getCaptionSize(context),
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ✅ MODERN ACCOUNT SETTINGS - Same as before
//   Widget _buildModernAccountSettings() {
//     return Container(
//       width: double.infinity,
//       padding: _getPaddingL(context),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Colors.white.withOpacity(0.15),
//             Colors.white.withOpacity(0.05),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(_getRadiusL()),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.2),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Row(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(_getSpaceM(context)),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [primaryColor, accentColor],
//                   ),
//                   borderRadius: BorderRadius.circular(_getRadiusM()),
//                 ),
//                 child: Icon(
//                   Icons.settings,
//                   color: textPrimary,
//                   size: 20,
//                 ),
//               ),
//               SizedBox(width: _getSpaceM(context)),
//               Expanded(
//                 child: Text(
//                   'Account Settings',
//                   style: TextStyle(
//                     fontSize: _getSubheadingSize(context),
//                     fontWeight: FontWeight.bold,
//                     color: textPrimary,
//                   ),
//                 ),
//               ),
//               if (!isEditing)
//                 GestureDetector(
//                   onTap: () => setState(() => isEditing = true),
//                   child: Container(
//                     padding: EdgeInsets.all(_getSpaceS(context)),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(_getRadiusS()),
//                       border: Border.all(
//                         color: primaryColor.withOpacity(0.3),
//                       ),
//                     ),
//                     child: Icon(
//                       Icons.edit,
//                       color: primaryColor,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           SizedBox(height: _getSpaceL(context)),
//
//           // Form Fields
//           _buildModernTextField(
//             label: "Full Name",
//             value: userName,
//             controller: _nameController,
//             icon: Icons.person_outline,
//           ),
//           SizedBox(height: _getSpaceM(context)),
//
//           _buildModernTextField(
//             label: "Email Address",
//             value: userEmail,
//             controller: _emailController,
//             icon: Icons.email_outlined,
//           ),
//
//           // Action Buttons
//           if (isEditing) ...[
//             SizedBox(height: _getSpaceL(context)),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildModernButton(
//                     label: "Cancel",
//                     onPressed: _cancelEditing,
//                     isPrimary: false,
//                   ),
//                 ),
//                 SizedBox(width: _getSpaceM(context)),
//                 Expanded(
//                   child: _buildModernButton(
//                     label: "Save Changes",
//                     onPressed: _updateProfile,
//                     isPrimary: true,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   // ✅ MODERN TEXT FIELD - Same as before
//   Widget _buildModernTextField({
//     required String label,
//     required String value,
//     required TextEditingController controller,
//     required IconData icon,
//   }) {
//     return Container(
//       padding: _getPaddingM(context),
//       decoration: BoxDecoration(
//         color: isEditing
//             ? Colors.white.withOpacity(0.1)
//             : Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(_getRadiusM()),
//         border: Border.all(
//           color: isEditing
//               ? primaryColor.withOpacity(0.4)
//               : Colors.white.withOpacity(0.1),
//           width: 1.5,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(_getSpaceS(context)),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [primaryColor.withOpacity(0.2), accentColor.withOpacity(0.2)],
//               ),
//               borderRadius: BorderRadius.circular(_getRadiusS()),
//             ),
//             child: Icon(
//               icon,
//               color: primaryColor,
//               size: 20,
//             ),
//           ),
//           SizedBox(width: _getSpaceM(context)),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     color: textTertiary,
//                     fontSize: _getCaptionSize(context),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 SizedBox(height: _getSpaceXS(context)),
//                 isEditing
//                     ? TextField(
//                   controller: controller,
//                   style: TextStyle(
//                     color: textPrimary,
//                     fontSize: _getBodySize(context),
//                     fontWeight: FontWeight.w500,
//                   ),
//                   decoration: const InputDecoration(
//                     isDense: true,
//                     contentPadding: EdgeInsets.zero,
//                     border: InputBorder.none,
//                   ),
//                   maxLines: 1,
//                 )
//                     : Text(
//                   value,
//                   style: TextStyle(
//                     color: textPrimary,
//                     fontSize: _getBodySize(context),
//                     fontWeight: FontWeight.w500,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ✅ MODERN BUTTON - Same as before
//   Widget _buildModernButton({
//     required String label,
//     required VoidCallback onPressed,
//     required bool isPrimary,
//   }) {
//     return Container(
//       height: 50,
//       decoration: BoxDecoration(
//         gradient: isPrimary
//             ? LinearGradient(colors: [primaryColor, accentColor])
//             : null,
//         color: isPrimary ? null : Colors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(_getRadiusM()),
//         border: isPrimary
//             ? null
//             : Border.all(color: Colors.white.withOpacity(0.3)),
//         boxShadow: isPrimary ? [
//           BoxShadow(
//             color: primaryColor.withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ] : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(_getRadiusM()),
//           onTap: onPressed,
//           child: Center(
//             child: Text(
//               label,
//               style: TextStyle(
//                 color: textPrimary,
//                 fontSize: _getBodySize(context),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ✅ MODERN LOGOUT DIALOG - Same as before
// class _ModernLogoutDialog extends StatefulWidget {
//   @override
//   _ModernLogoutDialogState createState() => _ModernLogoutDialogState();
// }
//
// class _ModernLogoutDialogState extends State<_ModernLogoutDialog>
//     with SingleTickerProviderStateMixin {
//   bool _isLoggingOut = false;
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _scaleAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.elasticOut,
//     );
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       child: ScaleTransition(
//         scale: _scaleAnimation,
//         child: Container(
//           width: double.infinity,
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.9,
//             maxHeight: MediaQuery.of(context).size.height * 0.6,
//           ),
//           margin: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Color(0xFF1E293B),
//                 Color(0xFF0F172A),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(
//               color: const Color(0xFFEF4444).withOpacity(0.3),
//               width: 2,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.5),
//                 blurRadius: 30,
//                 offset: const Offset(0, 15),
//               ),
//             ],
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(32),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Logout icon with animation
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: _isLoggingOut
//                           ? [Colors.grey, Colors.grey.shade600]
//                           : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
//                     ),
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: (_isLoggingOut ? Colors.grey : const Color(0xFFEF4444))
//                             .withOpacity(0.4),
//                         blurRadius: 20,
//                         spreadRadius: 5,
//                       ),
//                     ],
//                   ),
//                   child: _isLoggingOut
//                       ? const CircularProgressIndicator(
//                     strokeWidth: 3,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   )
//                       : const Icon(
//                     Icons.logout_rounded,
//                     color: Colors.white,
//                     size: 36,
//                   ),
//                 ),
//
//                 const SizedBox(height: 24),
//
//                 // Title
//                 Text(
//                   _isLoggingOut ? 'Signing Out...' : 'Ready to Sign Out?',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//
//                 const SizedBox(height: 16),
//
//                 // Security message
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF334155),
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.1),
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       const Icon(
//                         Icons.verified_user,
//                         color: Color(0xFF06B6D4),
//                         size: 24,
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         _isLoggingOut
//                             ? 'Saving your progress and signing out safely...'
//                             : 'Your learning progress is safely saved!\nYou can continue where you left off.',
//                         style: const TextStyle(
//                           color: Colors.white70,
//                           fontSize: 14,
//                           height: 1.4,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 32),
//
//                 // Action buttons
//                 Row(
//                   children: [
//                     // Stay button
//                     Expanded(
//                       child: Container(
//                         height: 50,
//                         decoration: BoxDecoration(
//                           color: Colors.transparent,
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(
//                             color: Colors.white.withOpacity(0.3),
//                           ),
//                         ),
//                         child: Material(
//                           color: Colors.transparent,
//                           child: InkWell(
//                             borderRadius: BorderRadius.circular(16),
//                             onTap: _isLoggingOut ? null : () => Navigator.of(context).pop(),
//                             child: const Center(
//                               child: Text(
//                                 'Stay Here',
//                                 style: TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(width: 16),
//
//                     // Sign Out button
//                     Expanded(
//                       child: Container(
//                         height: 50,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: _isLoggingOut
//                                 ? [Colors.grey, Colors.grey.shade600]
//                                 : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
//                           ),
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: (_isLoggingOut ? Colors.grey : const Color(0xFFEF4444))
//                                   .withOpacity(0.3),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Material(
//                           color: Colors.transparent,
//                           child: InkWell(
//                             borderRadius: BorderRadius.circular(16),
//                             onTap: _isLoggingOut ? null : _handleLogout,
//                             child: Center(
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   if (_isLoggingOut) ...[
//                                     const SizedBox(
//                                       width: 16,
//                                       height: 16,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                       ),
//                                     ),
//                                   ] else ...[
//                                     const Icon(
//                                       Icons.logout_rounded,
//                                       color: Colors.white,
//                                       size: 18,
//                                     ),
//                                   ],
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     _isLoggingOut ? 'Signing Out...' : 'Sign Out',
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _handleLogout() async {
//     if (!mounted) return;
//
//     setState(() {
//       _isLoggingOut = true;
//     });
//
//     try {
//       await _performLogout();
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoggingOut = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Logout failed: ${e.toString()}'),
//             backgroundColor: const Color(0xFFEF4444),
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         );
//       }
//     }
//   }
//
//   Future<void> _performLogout() async {
//     try {
//       // Sign out from Firebase
//       await FirebaseAuth.instance.signOut();
//
//       // Clear SharedPreferences
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool('is_logged_in', false);
//       await prefs.remove('last_login');
//
//       if (mounted) {
//         Navigator.of(context).pop();
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
//               (route) => false,
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.of(context).pop();
//       }
//       throw e;
//     }
//   }
// }
//
//
//
//
//
//
//
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'dart:io';
// // import 'dart:convert';
// // import 'dart:typed_data';
// // import 'dart:ui';
// //
// // import 'email_change_verification_screen.dart';
// // import 'login_screen.dart';
// //
// // class ProfileScreen extends StatefulWidget {
// //   const ProfileScreen({super.key});
// //
// //   @override
// //   State<ProfileScreen> createState() => _ProfileScreenState();
// // }
// //
// // class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
// //   // Data variables
// //   String userName = "Loading...";
// //   String userEmail = "Loading...";
// //   String profileImageBase64 = "";
// //   int userPoints = 0;
// //   int notesCount = 0;
// //   int savedVideosCount = 0;
// //   int savedLinksCount = 0;
// //   int quizzesTaken = 0;
// //   int bestQuizScore = 0;
// //   String userLevel = "Rookie";
// //
// //   // UI state variables
// //   bool isEditing = false;
// //   bool isLoading = true;
// //   bool isUploadingImage = false;
// //   File? _profileImage;
// //
// //   // Controllers
// //   final TextEditingController _emailController = TextEditingController();
// //   final TextEditingController _nameController = TextEditingController();
// //   final ImagePicker _picker = ImagePicker();
// //
// //   // Animation controllers
// //   late AnimationController _fadeController;
// //   late AnimationController _slideController;
// //   late AnimationController _counterController;
// //   late AnimationController _pulseController;
// //   late AnimationController _scaleController;
// //   late Animation<double> _fadeAnimation;
// //   late Animation<Offset> _slideAnimation;
// //   late Animation<double> _counterAnimation;
// //   late Animation<double> _pulseAnimation;
// //   late Animation<double> _scaleAnimation;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _initializeAnimations();
// //     _loadUserData();
// //   }
// //
// //   void _initializeAnimations() {
// //     _fadeController = AnimationController(
// //       duration: const Duration(milliseconds: 1200),
// //       vsync: this,
// //     );
// //     _slideController = AnimationController(
// //       duration: const Duration(milliseconds: 1000),
// //       vsync: this,
// //     );
// //     _counterController = AnimationController(
// //       duration: const Duration(milliseconds: 2500),
// //       vsync: this,
// //     );
// //     _pulseController = AnimationController(
// //       duration: const Duration(milliseconds: 2000),
// //       vsync: this,
// //     );
// //     _scaleController = AnimationController(
// //       duration: const Duration(milliseconds: 800),
// //       vsync: this,
// //     );
// //
// //     _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
// //     _slideAnimation = Tween<Offset>(
// //       begin: const Offset(0, 0.3),
// //       end: Offset.zero,
// //     ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
// //     _counterAnimation = CurvedAnimation(parent: _counterController, curve: Curves.easeOutQuart);
// //     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08)
// //         .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
// //     _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
// //   }
// //
// //   @override
// //   void dispose() {
// //     _fadeController.dispose();
// //     _slideController.dispose();
// //     _counterController.dispose();
// //     _pulseController.dispose();
// //     _scaleController.dispose();
// //     _nameController.dispose();
// //     _emailController.dispose();
// //     super.dispose();
// //   }
// //
// //   // ✅ MODERN RESPONSIVE SYSTEM
// //   double _getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;
// //   double _getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;
// //
// //   bool _isSmallMobile(BuildContext context) => _getScreenWidth(context) < 360;
// //   bool _isMobile(BuildContext context) => _getScreenWidth(context) < 600;
// //   bool _isTablet(BuildContext context) => _getScreenWidth(context) >= 600 && _getScreenWidth(context) < 1024;
// //   bool _isDesktop(BuildContext context) => _getScreenWidth(context) >= 1024;
// //
// //   // ✅ MODERN TYPOGRAPHY SYSTEM
// //   double _getHeadingSize(BuildContext context) {
// //     if (_isSmallMobile(context)) return 20;
// //     if (_isMobile(context)) return 24;
// //     if (_isTablet(context)) return 28;
// //     return 32;
// //   }
// //
// //   double _getSubheadingSize(BuildContext context) {
// //     if (_isSmallMobile(context)) return 16;
// //     if (_isMobile(context)) return 18;
// //     if (_isTablet(context)) return 20;
// //     return 22;
// //   }
// //
// //   double _getBodySize(BuildContext context) {
// //     if (_isSmallMobile(context)) return 12;
// //     if (_isMobile(context)) return 14;
// //     if (_isTablet(context)) return 15;
// //     return 16;
// //   }
// //
// //   double _getCaptionSize(BuildContext context) {
// //     if (_isSmallMobile(context)) return 10;
// //     if (_isMobile(context)) return 11;
// //     if (_isTablet(context)) return 12;
// //     return 13;
// //   }
// //
// //   // ✅ MODERN SPACING SYSTEM
// //   double _getSpaceXS(BuildContext context) => _isMobile(context) ? 4 : 6;
// //   double _getSpaceS(BuildContext context) => _isMobile(context) ? 8 : 12;
// //   double _getSpaceM(BuildContext context) => _isMobile(context) ? 16 : 20;
// //   double _getSpaceL(BuildContext context) => _isMobile(context) ? 24 : 32;
// //   double _getSpaceXL(BuildContext context) => _isMobile(context) ? 32 : 48;
// //
// //   // ✅ MODERN PADDING SYSTEM
// //   EdgeInsets _getPaddingS(BuildContext context) => EdgeInsets.all(_getSpaceS(context));
// //   EdgeInsets _getPaddingM(BuildContext context) => EdgeInsets.all(_getSpaceM(context));
// //   EdgeInsets _getPaddingL(BuildContext context) => EdgeInsets.all(_getSpaceL(context));
// //
// //   EdgeInsets _getPaddingHorizontal(BuildContext context, double multiplier) =>
// //       EdgeInsets.symmetric(horizontal: _getSpaceM(context) * multiplier);
// //
// //   EdgeInsets _getPaddingVertical(BuildContext context, double multiplier) =>
// //       EdgeInsets.symmetric(vertical: _getSpaceM(context) * multiplier);
// //
// //   // ✅ MODERN BORDER RADIUS SYSTEM
// //   double _getRadiusS() => 8;
// //   double _getRadiusM() => 16;
// //   double _getRadiusL() => 24;
// //   double _getRadiusXL() => 32;
// //
// //   // ✅ GRID SYSTEM FOR NEW LAYOUT
// //   int _getStatsColumns(BuildContext context) {
// //     if (_isSmallMobile(context)) return 2;
// //     if (_isMobile(context)) return 2;
// //     if (_isTablet(context)) return 4;
// //     return 4;
// //   }
// //
// //   double _getStatsAspectRatio(BuildContext context) {
// //     if (_isSmallMobile(context)) return 1.4;
// //     if (_isMobile(context)) return 1.2;
// //     return 1.0;
// //   }
// //
// //   // ✅ MODERN COLOR PALETTE
// //   Color get primaryColor => const Color(0xFF6366F1); // Indigo
// //   Color get primaryLight => const Color(0xFF818CF8);
// //   Color get primaryDark => const Color(0xFF4F46E5);
// //
// //   Color get accentColor => const Color(0xFF06B6D4); // Cyan
// //   Color get accentLight => const Color(0xFF22D3EE);
// //   Color get accentDark => const Color(0xFF0891B2);
// //
// //   Color get successColor => const Color(0xFF10B981);
// //   Color get warningColor => const Color(0xFFF59E0B);
// //   Color get errorColor => const Color(0xFFEF4444);
// //
// //   Color get surfaceColor => const Color(0xFF1E293B);
// //   Color get surfaceLight => const Color(0xFF334155);
// //   Color get surfaceDark => const Color(0xFF0F172A);
// //
// //   Color get textPrimary => Colors.white;
// //   Color get textSecondary => Colors.white.withOpacity(0.8);
// //   Color get textTertiary => Colors.white.withOpacity(0.6);
// //
// //   // Level styling methods (updated for new design)
// //   Color _getLevelColor() {
// //     switch (userLevel) {
// //       case 'Expert': return const Color(0xFF8B5CF6); // Purple
// //       case 'Advanced': return const Color(0xFF06B6D4); // Cyan
// //       case 'Intermediate': return const Color(0xFF3B82F6); // Blue
// //       case 'Beginner': return const Color(0xFFF59E0B); // Amber
// //       default: return const Color(0xFF6B7280); // Gray
// //     }
// //   }
// //
// //   IconData _getLevelIcon() {
// //     switch (userLevel) {
// //       case 'Expert': return Icons.emoji_events; // Trophy
// //       case 'Advanced': return Icons.military_tech; // Medal
// //       case 'Intermediate': return Icons.star; // Star
// //       case 'Beginner': return Icons.trending_up; // Arrow up
// //       default: return Icons.circle; // Dot
// //     }
// //   }
// //
// //   String _calculateUserLevel(int points) {
// //     if (points >= 5000) return 'Expert';
// //     if (points >= 3000) return 'Advanced';
// //     if (points >= 1500) return 'Intermediate';
// //     if (points >= 500) return 'Beginner';
// //     return 'Rookie';
// //   }
// //
// //   // Helper methods
// //   Uint8List _base64ToImage(String base64String) {
// //     return base64Decode(base64String);
// //   }
// //
// //   bool _isValidEmail(String email) {
// //     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
// //   }
// //
// //   // ✅ MODERN SNACKBAR SYSTEM
// //   void _showSuccessSnackBar(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Container(
// //           padding: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
// //           child: Row(
// //             children: [
// //               Container(
// //                 padding: EdgeInsets.all(_getSpaceXS(context)),
// //                 decoration: BoxDecoration(
// //                   color: Colors.white.withOpacity(0.2),
// //                   shape: BoxShape.circle,
// //                 ),
// //                 child: Icon(Icons.check_circle, color: Colors.white, size: 20),
// //               ),
// //               SizedBox(width: _getSpaceS(context)),
// //               Expanded(
// //                 child: Text(
// //                   message,
// //                   style: TextStyle(
// //                     fontWeight: FontWeight.w600,
// //                     fontSize: _getBodySize(context),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //         backgroundColor: successColor,
// //         behavior: SnackBarBehavior.floating,
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getRadiusM())),
// //         margin: EdgeInsets.all(_getSpaceM(context)),
// //         elevation: 8,
// //       ),
// //     );
// //   }
// //
// //   void _showErrorSnackBar(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Container(
// //           padding: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
// //           child: Row(
// //             children: [
// //               Container(
// //                 padding: EdgeInsets.all(_getSpaceXS(context)),
// //                 decoration: BoxDecoration(
// //                   color: Colors.white.withOpacity(0.2),
// //                   shape: BoxShape.circle,
// //                 ),
// //                 child: Icon(Icons.error, color: Colors.white, size: 20),
// //               ),
// //               SizedBox(width: _getSpaceS(context)),
// //               Expanded(
// //                 child: Text(
// //                   message,
// //                   style: TextStyle(
// //                     fontWeight: FontWeight.w600,
// //                     fontSize: _getBodySize(context),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //         backgroundColor: errorColor,
// //         behavior: SnackBarBehavior.floating,
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getRadiusM())),
// //         margin: EdgeInsets.all(_getSpaceM(context)),
// //         elevation: 8,
// //       ),
// //     );
// //   }
// //
// //   void _redirectToLogin() {
// //     if (mounted) {
// //       Navigator.pushAndRemoveUntil(
// //         context,
// //         MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
// //             (route) => false,
// //       );
// //     }
// //   }
// //
// //   // ✅ DATA LOADING METHODS (Same functionality, updated animations)
// //   Future<void> _loadUserData() async {
// //     try {
// //       final user = FirebaseAuth.instance.currentUser;
// //       if (user == null) {
// //         _redirectToLogin();
// //         return;
// //       }
// //
// //       final userDoc = await FirebaseFirestore.instance
// //           .collection('users')
// //           .doc(user.uid)
// //           .get();
// //
// //       if (userDoc.exists && mounted) {
// //         final userData = userDoc.data()!;
// //         setState(() {
// //           userName = userData['fullName'] ?? 'Unknown User';
// //           userEmail = userData['email'] ?? user.email ?? '';
// //           _nameController.text = userName;
// //           _emailController.text = userEmail;
// //         });
// //
// //         await Future.wait([
// //           _loadProfileImage(),
// //           _loadUserStats(),
// //         ]);
// //
// //         if (mounted) {
// //           // Start new animation sequence
// //           _fadeController.forward();
// //           await Future.delayed(const Duration(milliseconds: 200));
// //           _slideController.forward();
// //           await Future.delayed(const Duration(milliseconds: 300));
// //           _scaleController.forward();
// //           await Future.delayed(const Duration(milliseconds: 200));
// //           _counterController.forward();
// //           _pulseController.repeat(reverse: true);
// //         }
// //
// //         setState(() {
// //           isLoading = false;
// //         });
// //       } else {
// //         _redirectToLogin();
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         setState(() {
// //           isLoading = false;
// //         });
// //         _showErrorSnackBar('Failed to load profile data');
// //       }
// //     }
// //   }
// //
// //   Future<void> _loadUserStats() async {
// //     try {
// //       final prefs = await SharedPreferences.getInstance();
// //       final user = FirebaseAuth.instance.currentUser;
// //       if (user == null) return;
// //
// //       final userId = user.uid;
// //       final points = prefs.getInt('${userId}_user_points') ?? 0;
// //       final quizCount = prefs.getInt('${userId}_quizzes_taken') ?? 0;
// //       final bestScore = prefs.getInt('${userId}_best_score') ?? 0;
// //
// //       // Count notes from multiple sources
// //       int totalNotesCount = 0;
// //       int linksCount = 0;
// //       int videosCount = 0;
// //
// //       final savedNotesJson = prefs.getStringList('${userId}_saved_notes') ?? [];
// //       totalNotesCount += savedNotesJson.length;
// //
// //       for (final noteString in savedNotesJson) {
// //         try {
// //           if (noteString.contains('http') || noteString.contains('www.')) {
// //             linksCount++;
// //           }
// //         } catch (e) {
// //           debugPrint('Error parsing saved note: $e');
// //         }
// //       }
// //
// //       final codingNotesJson = prefs.getStringList('${userId}_coding_notes') ?? [];
// //       totalNotesCount += codingNotesJson.length;
// //
// //       final personalNotesJson = prefs.getStringList('${userId}_personal_notes') ?? [];
// //       totalNotesCount += personalNotesJson.length;
// //
// //       final studyNotesJson = prefs.getStringList('${userId}_study_notes') ?? [];
// //       totalNotesCount += studyNotesJson.length;
// //
// //       final savedVideosJson = prefs.getStringList('${userId}_saved_videos') ?? [];
// //       final bookmarkedVideosJson = prefs.getStringList('${userId}_bookmarked_videos') ?? [];
// //       videosCount = savedVideosJson.length + bookmarkedVideosJson.length;
// //
// //       final savedLinksJson = prefs.getStringList('${userId}_saved_links') ?? [];
// //       final bookmarkedLinksJson = prefs.getStringList('${userId}_bookmarked_links') ?? [];
// //       linksCount += savedLinksJson.length + bookmarkedLinksJson.length;
// //
// //       final level = _calculateUserLevel(points);
// //
// //       if (mounted) {
// //         setState(() {
// //           userPoints = points;
// //           quizzesTaken = quizCount;
// //           bestQuizScore = bestScore;
// //           notesCount = totalNotesCount;
// //           savedVideosCount = videosCount;
// //           savedLinksCount = linksCount;
// //           userLevel = level;
// //         });
// //       }
// //     } catch (e) {
// //       debugPrint('❌ Error loading user stats: $e');
// //       if (mounted) {
// //         setState(() {
// //           userPoints = 0;
// //           notesCount = 0;
// //           savedVideosCount = 0;
// //           savedLinksCount = 0;
// //           quizzesTaken = 0;
// //           bestQuizScore = 0;
// //           userLevel = 'Rookie';
// //         });
// //       }
// //     }
// //   }
// //
// //   Future<void> _loadProfileImage() async {
// //     try {
// //       final prefs = await SharedPreferences.getInstance();
// //       final user = FirebaseAuth.instance.currentUser;
// //       if (user != null) {
// //         final imageKey = 'profile_image_${user.uid}';
// //         final savedImageBase64 = prefs.getString(imageKey);
// //         if (savedImageBase64 != null && savedImageBase64.isNotEmpty && mounted) {
// //           setState(() {
// //             profileImageBase64 = savedImageBase64;
// //           });
// //         }
// //       }
// //     } catch (e) {
// //       debugPrint('Error loading profile image: $e');
// //     }
// //   }
// //
// //   Future<void> _refreshData() async {
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     // Reset animations
// //     _counterController.reset();
// //     _scaleController.reset();
// //
// //     await Future.wait([
// //       _loadUserStats(),
// //       _loadProfileImage(),
// //     ]);
// //
// //     if (mounted) {
// //       setState(() {
// //         isLoading = false;
// //       });
// //
// //       // Restart animations
// //       _counterController.forward();
// //       _scaleController.forward();
// //
// //       _showSuccessSnackBar('Profile data refreshed!');
// //     }
// //   }
// //
// //   // ✅ IMAGE HANDLING METHODS
// //   Future<void> _pickImage() async {
// //     try {
// //       final XFile? image = await _picker.pickImage(
// //         source: ImageSource.gallery,
// //         maxWidth: 512,
// //         maxHeight: 512,
// //         imageQuality: 85,
// //       );
// //
// //       if (image != null) {
// //         setState(() {
// //           _profileImage = File(image.path);
// //           isUploadingImage = true;
// //         });
// //
// //         await _saveProfileImageLocally(File(image.path));
// //       }
// //     } catch (e) {
// //       _showErrorSnackBar('Failed to pick image: Please try again');
// //     }
// //   }
// //
// //   Future<void> _saveProfileImageLocally(File imageFile) async {
// //     try {
// //       final user = FirebaseAuth.instance.currentUser;
// //       if (user == null) return;
// //
// //       final bytes = await imageFile.readAsBytes();
// //       final base64String = base64Encode(bytes);
// //
// //       final prefs = await SharedPreferences.getInstance();
// //       final imageKey = 'profile_image_${user.uid}';
// //       await prefs.setString(imageKey, base64String);
// //
// //       if (mounted) {
// //         setState(() {
// //           profileImageBase64 = base64String;
// //           isUploadingImage = false;
// //         });
// //         _showSuccessSnackBar('Profile image updated successfully!');
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         setState(() {
// //           isUploadingImage = false;
// //           _profileImage = null;
// //         });
// //         _showErrorSnackBar('Failed to save image');
// //       }
// //     }
// //   }
// //
// //   // ✅ PROFILE UPDATE METHODS
// //   Future<void> _updateProfile() async {
// //     final name = _nameController.text.trim();
// //     final email = _emailController.text.trim();
// //     final currentUser = FirebaseAuth.instance.currentUser;
// //
// //     if (name.isEmpty) {
// //       _showErrorSnackBar('Name cannot be empty');
// //       return;
// //     }
// //
// //     if (!_isValidEmail(email)) {
// //       _showErrorSnackBar('Please enter a valid email address');
// //       return;
// //     }
// //
// //     if (currentUser == null) return;
// //
// //     try {
// //       setState(() {
// //         isLoading = true;
// //       });
// //
// //       final emailChanged = currentUser.email != email;
// //
// //       if (emailChanged) {
// //         await _handleEmailChange(email, name);
// //       } else {
// //         await _updateNameOnly(name);
// //       }
// //
// //     } catch (e) {
// //       if (mounted) {
// //         setState(() {
// //           isLoading = false;
// //         });
// //         _showErrorSnackBar('Failed to update profile');
// //       }
// //     }
// //   }
// //
// //   Future<void> _updateNameOnly(String name) async {
// //     final user = FirebaseAuth.instance.currentUser;
// //     if (user != null) {
// //       await FirebaseFirestore.instance
// //           .collection('users')
// //           .doc(user.uid)
// //           .update({
// //         'fullName': name,
// //         'updatedAt': FieldValue.serverTimestamp(),
// //       });
// //
// //       await user.updateDisplayName(name);
// //
// //       if (mounted) {
// //         setState(() {
// //           userName = name;
// //           isEditing = false;
// //           isLoading = false;
// //         });
// //         _showSuccessSnackBar('Name updated successfully!');
// //       }
// //     }
// //   }
// //
// //   Future<void> _handleEmailChange(String newEmail, String name) async {
// //     try {
// //       setState(() {
// //         isLoading = false;
// //         isEditing = false;
// //       });
// //
// //       final result = await Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //           builder: (context) => EmailChangeVerificationScreen(
// //             currentEmail: userEmail,
// //             newEmail: newEmail,
// //             userName: name,
// //           ),
// //         ),
// //       );
// //
// //       if (result == true) {
// //         await _loadUserData();
// //         _showSuccessSnackBar('Email updated successfully!');
// //       } else {
// //         _emailController.text = userEmail;
// //       }
// //     } catch (e) {
// //       setState(() {
// //         isLoading = false;
// //       });
// //       _emailController.text = userEmail;
// //       _showErrorSnackBar('Failed to initiate email change');
// //     }
// //   }
// //
// //   void _cancelEditing() {
// //     setState(() {
// //       _nameController.text = userName;
// //       _emailController.text = userEmail;
// //       isEditing = false;
// //     });
// //   }
// //
// //   // ✅ LEVEL PROGRESS CALCULATIONS
// //   String _getNextLevelInfo() {
// //     final nextPoints = _getNextLevelPoints();
// //
// //     if (userLevel == 'Expert') {
// //       return 'Congratulations! You\'ve reached the highest level! 🏆';
// //     }
// //
// //     final needed = nextPoints - userPoints;
// //     final nextLevel = _getNextLevelName();
// //
// //     return '$needed points to $nextLevel';
// //   }
// //
// //   String _getNextLevelName() {
// //     switch (userLevel) {
// //       case 'Rookie': return 'Beginner';
// //       case 'Beginner': return 'Intermediate';
// //       case 'Intermediate': return 'Advanced';
// //       case 'Advanced': return 'Expert';
// //       default: return 'Expert';
// //     }
// //   }
// //
// //   int _getNextLevelPoints() {
// //     switch (userLevel) {
// //       case 'Rookie': return 500;
// //       case 'Beginner': return 1500;
// //       case 'Intermediate': return 3000;
// //       case 'Advanced': return 5000;
// //       default: return 5000;
// //     }
// //   }
// //
// //   int _getCurrentLevelPoints() {
// //     switch (userLevel) {
// //       case 'Rookie': return 0;
// //       case 'Beginner': return 500;
// //       case 'Intermediate': return 1500;
// //       case 'Advanced': return 3000;
// //       case 'Expert': return 5000;
// //       default: return 0;
// //     }
// //   }
// //
// //   double _getLevelProgress() {
// //     if (userLevel == 'Expert') return 1.0;
// //
// //     final nextPoints = _getNextLevelPoints();
// //     final currentPoints = _getCurrentLevelPoints();
// //     final progress = ((userPoints - currentPoints) / (nextPoints - currentPoints)).clamp(0.0, 1.0);
// //
// //     return progress;
// //   }
// //
// //   // ✅ LOGOUT DIALOG
// //   Future<void> _showLogoutDialog() async {
// //     return showDialog<void>(
// //       context: context,
// //       barrierDismissible: true,
// //       barrierColor: Colors.black.withOpacity(0.8),
// //       builder: (BuildContext context) {
// //         return _ModernLogoutDialog();
// //       },
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: surfaceDark,
// //       body: SafeArea(
// //         child: isLoading ? _buildModernLoadingState() : _buildModernMainContent(),
// //       ),
// //     );
// //   }
// //
// //   // ✅ MODERN LOADING STATE - Glassmorphism Design
// //   Widget _buildModernLoadingState() {
// //     return Container(
// //       decoration: BoxDecoration(
// //         gradient: LinearGradient(
// //           begin: Alignment.topLeft,
// //           end: Alignment.bottomRight,
// //           colors: [
// //             surfaceDark,
// //             surfaceColor,
// //             surfaceLight.withOpacity(0.8),
// //           ],
// //         ),
// //       ),
// //       child: Center(
// //         child: Container(
// //           padding: EdgeInsets.all(_getSpaceXL(context)),
// //           decoration: BoxDecoration(
// //             color: Colors.white.withOpacity(0.1),
// //             borderRadius: BorderRadius.circular(_getRadiusXL()),
// //             border: Border.all(
// //               color: Colors.white.withOpacity(0.2),
// //               width: 1,
// //             ),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.black.withOpacity(0.3),
// //                 blurRadius: 30,
// //                 offset: const Offset(0, 10),
// //               ),
// //             ],
// //           ),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               // Modern loading spinner
// //               Container(
// //                 width: 80,
// //                 height: 80,
// //                 decoration: BoxDecoration(
// //                   gradient: LinearGradient(
// //                     colors: [primaryColor, accentColor],
// //                   ),
// //                   shape: BoxShape.circle,
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: primaryColor.withOpacity(0.4),
// //                       blurRadius: 20,
// //                       spreadRadius: 5,
// //                     ),
// //                   ],
// //                 ),
// //                 child: const CircularProgressIndicator(
// //                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// //                   strokeWidth: 3,
// //                 ),
// //               ),
// //               SizedBox(height: _getSpaceL(context)),
// //               // Loading text
// //               Text(
// //                 'Loading your profile...',
// //                 style: TextStyle(
// //                   color: textPrimary,
// //                   fontSize: _getSubheadingSize(context),
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //               SizedBox(height: _getSpaceS(context)),
// //               Text(
// //                 'Please wait a moment',
// //                 style: TextStyle(
// //                   color: textSecondary,
// //                   fontSize: _getBodySize(context),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ✅ MODERN MAIN CONTENT - Fixed Layout Structure
// //   Widget _buildModernMainContent() {
// //     return Container(
// //       decoration: BoxDecoration(
// //         gradient: LinearGradient(
// //           begin: Alignment.topLeft,
// //           end: Alignment.bottomRight,
// //           colors: [
// //             surfaceDark,
// //             surfaceColor,
// //             surfaceLight.withOpacity(0.5),
// //           ],
// //         ),
// //       ),
// //       child: FadeTransition(
// //         opacity: _fadeAnimation,
// //         child: CustomScrollView(
// //           physics: const BouncingScrollPhysics(),
// //           slivers: [
// //             _buildModernAppBar(),
// //             SliverToBoxAdapter(
// //               child: Padding(
// //                 padding: EdgeInsets.symmetric(horizontal: _getSpaceM(context)),
// //                 child: Column(
// //                   children: [
// //                     SizedBox(height: _getSpaceM(context)),
// //                     _buildNewHeroSection(),
// //                     SizedBox(height: _getSpaceL(context)),
// //                     _buildModernStatsGrid(),
// //                     SizedBox(height: _getSpaceL(context)),
// //                     _buildQuickActionsCard(),
// //                     SizedBox(height: _getSpaceL(context)),
// //                     _buildModernLearningJourney(),
// //                     SizedBox(height: _getSpaceL(context)),
// //                     _buildModernAccountSettings(),
// //                     SizedBox(height: MediaQuery.of(context).padding.bottom + _getSpaceXL(context)),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ✅ NEW HERO SECTION - Completely Redesigned
// //   Widget _buildNewHeroSection() {
// //     return SlideTransition(
// //       position: _slideAnimation,
// //       child: Column(
// //         children: [
// //           // Profile Image and Basic Info Card
// //           Container(
// //             width: double.infinity,
// //             padding: EdgeInsets.all(_getSpaceL(context)),
// //             decoration: BoxDecoration(
// //               gradient: LinearGradient(
// //                 begin: Alignment.topLeft,
// //                 end: Alignment.bottomRight,
// //                 colors: [
// //                   Colors.white.withOpacity(0.15),
// //                   Colors.white.withOpacity(0.05),
// //                 ],
// //               ),
// //               borderRadius: BorderRadius.circular(_getRadiusL()),
// //               border: Border.all(
// //                 color: Colors.white.withOpacity(0.2),
// //                 width: 1,
// //               ),
// //               boxShadow: [
// //                 BoxShadow(
// //                   color: Colors.black.withOpacity(0.2),
// //                   blurRadius: 20,
// //                   offset: const Offset(0, 10),
// //                 ),
// //               ],
// //             ),
// //             child: Row(
// //               children: [
// //                 // Profile Image Section
// //                 Stack(
// //                   alignment: Alignment.center,
// //                   children: [
// //                     // Animated level ring
// //                     AnimatedBuilder(
// //                       animation: _pulseAnimation,
// //                       builder: (context, child) {
// //                         return Transform.scale(
// //                           scale: _pulseAnimation.value,
// //                           child: Container(
// //                             width: 90,
// //                             height: 90,
// //                             decoration: BoxDecoration(
// //                               shape: BoxShape.circle,
// //                               gradient: LinearGradient(
// //                                 colors: [
// //                                   _getLevelColor(),
// //                                   _getLevelColor().withOpacity(0.6),
// //                                 ],
// //                               ),
// //                             ),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //
// //                     // Profile Image
// //                     Container(
// //                       width: 75,
// //                       height: 75,
// //                       decoration: BoxDecoration(
// //                         shape: BoxShape.circle,
// //                         color: Colors.white,
// //                         boxShadow: [
// //                           BoxShadow(
// //                             color: Colors.black.withOpacity(0.2),
// //                             blurRadius: 15,
// //                             offset: const Offset(0, 5),
// //                           ),
// //                         ],
// //                       ),
// //                       child: ClipOval(
// //                         child: _profileImage != null
// //                             ? Image.file(_profileImage!, fit: BoxFit.cover)
// //                             : (profileImageBase64.isNotEmpty
// //                             ? Image.memory(_base64ToImage(profileImageBase64), fit: BoxFit.cover)
// //                             : Container(
// //                           decoration: BoxDecoration(
// //                             gradient: LinearGradient(
// //                               colors: [primaryColor, accentColor],
// //                             ),
// //                           ),
// //                           child: Center(
// //                             child: Text(
// //                               userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
// //                               style: TextStyle(
// //                                 fontSize: _getHeadingSize(context),
// //                                 fontWeight: FontWeight.bold,
// //                                 color: textPrimary,
// //                               ),
// //                             ),
// //                           ),
// //                         )),
// //                       ),
// //                     ),
// //
// //                     // Camera Button
// //                     Positioned(
// //                       bottom: 0,
// //                       right: 0,
// //                       child: GestureDetector(
// //                         onTap: isUploadingImage ? null : _pickImage,
// //                         child: Container(
// //                           padding: EdgeInsets.all(_getSpaceS(context)),
// //                           decoration: BoxDecoration(
// //                             gradient: LinearGradient(
// //                               colors: [primaryColor, accentColor],
// //                             ),
// //                             shape: BoxShape.circle,
// //                             border: Border.all(color: Colors.white, width: 2),
// //                             boxShadow: [
// //                               BoxShadow(
// //                                 color: primaryColor.withOpacity(0.4),
// //                                 blurRadius: 8,
// //                                 offset: const Offset(0, 2),
// //                               ),
// //                             ],
// //                           ),
// //                           child: Icon(
// //                             isUploadingImage ? Icons.hourglass_empty : Icons.camera_alt,
// //                             size: 12,
// //                             color: textPrimary,
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //
// //                 SizedBox(width: _getSpaceL(context)),
// //
// //                 // User Info Section
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       // Name
// //                       Text(
// //                         userName,
// //                         style: TextStyle(
// //                           fontSize: _getSubheadingSize(context),
// //                           fontWeight: FontWeight.bold,
// //                           color: textPrimary,
// //                         ),
// //                         maxLines: 1,
// //                         overflow: TextOverflow.ellipsis,
// //                       ),
// //                       SizedBox(height: _getSpaceXS(context)),
// //
// //                       // Email
// //                       Container(
// //                         padding: EdgeInsets.symmetric(
// //                           horizontal: _getSpaceM(context),
// //                           vertical: _getSpaceS(context),
// //                         ),
// //                         decoration: BoxDecoration(
// //                           color: Colors.white.withOpacity(0.1),
// //                           borderRadius: BorderRadius.circular(_getRadiusS()),
// //                           border: Border.all(
// //                             color: Colors.white.withOpacity(0.2),
// //                           ),
// //                         ),
// //                         child: Text(
// //                           userEmail,
// //                           style: TextStyle(
// //                             fontSize: _getCaptionSize(context),
// //                             color: textSecondary,
// //                           ),
// //                           maxLines: 1,
// //                           overflow: TextOverflow.ellipsis,
// //                         ),
// //                       ),
// //                       SizedBox(height: _getSpaceM(context)),
// //
// //                       // Level Badge
// //                       Container(
// //                         padding: EdgeInsets.symmetric(
// //                           horizontal: _getSpaceM(context),
// //                           vertical: _getSpaceS(context),
// //                         ),
// //                         decoration: BoxDecoration(
// //                           gradient: LinearGradient(
// //                             colors: [_getLevelColor(), _getLevelColor().withOpacity(0.7)],
// //                           ),
// //                           borderRadius: BorderRadius.circular(_getRadiusM()),
// //                           boxShadow: [
// //                             BoxShadow(
// //                               color: _getLevelColor().withOpacity(0.4),
// //                               blurRadius: 10,
// //                               offset: const Offset(0, 3),
// //                             ),
// //                           ],
// //                         ),
// //                         child: Row(
// //                           mainAxisSize: MainAxisSize.min,
// //                           children: [
// //                             Icon(
// //                               _getLevelIcon(),
// //                               color: textPrimary,
// //                               size: 16,
// //                             ),
// //                             SizedBox(width: _getSpaceS(context)),
// //                             Text(
// //                               userLevel,
// //                               style: TextStyle(
// //                                 fontSize: _getBodySize(context),
// //                                 fontWeight: FontWeight.bold,
// //                                 color: textPrimary,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //
// //           SizedBox(height: _getSpaceL(context)),
// //
// //           // Learning Points and Progress Card
// //           Container(
// //             width: double.infinity,
// //             padding: EdgeInsets.all(_getSpaceL(context)),
// //             decoration: BoxDecoration(
// //               gradient: LinearGradient(
// //                 begin: Alignment.topLeft,
// //                 end: Alignment.bottomRight,
// //                 colors: [
// //                   primaryColor.withOpacity(0.8),
// //                   accentColor.withOpacity(0.6),
// //                 ],
// //               ),
// //               borderRadius: BorderRadius.circular(_getRadiusL()),
// //               boxShadow: [
// //                 BoxShadow(
// //                   color: primaryColor.withOpacity(0.3),
// //                   blurRadius: 20,
// //                   offset: const Offset(0, 10),
// //                 ),
// //               ],
// //             ),
// //             child: Column(
// //               children: [
// //                 // Points Header
// //                 Row(
// //                   children: [
// //                     Container(
// //                       padding: EdgeInsets.all(_getSpaceM(context)),
// //                       decoration: BoxDecoration(
// //                         color: Colors.white.withOpacity(0.2),
// //                         borderRadius: BorderRadius.circular(_getRadiusM()),
// //                       ),
// //                       child: Icon(
// //                         Icons.stars_rounded,
// //                         color: textPrimary,
// //                         size: 28,
// //                       ),
// //                     ),
// //                     SizedBox(width: _getSpaceM(context)),
// //                     Expanded(
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Text(
// //                             'Learning Points',
// //                             style: TextStyle(
// //                               fontSize: _getBodySize(context),
// //                               color: textPrimary.withOpacity(0.9),
// //                               fontWeight: FontWeight.w600,
// //                             ),
// //                           ),
// //                           SizedBox(height: _getSpaceXS(context)),
// //                           AnimatedBuilder(
// //                             animation: _counterAnimation,
// //                             builder: (context, child) {
// //                               final animatedPoints = (userPoints * _counterAnimation.value).round();
// //                               return Text(
// //                                 animatedPoints.toString(),
// //                                 style: TextStyle(
// //                                   fontSize: _getHeadingSize(context) * 1.5,
// //                                   fontWeight: FontWeight.bold,
// //                                   color: textPrimary,
// //                                 ),
// //                               );
// //                             },
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 SizedBox(height: _getSpaceL(context)),
// //
// //                 // Progress Section
// //                 Row(
// //                   children: [
// //                     // Progress Ring - Fixed circle and dot positioning
// //                     SizedBox(
// //                       width: 90,
// //                       height: 90,
// //                       child: Stack(
// //                         alignment: Alignment.center,
// //                         children: [
// //                           // Background circle
// //                           SizedBox(
// //                             width: 90,
// //                             height: 90,
// //                             child: CircularProgressIndicator(
// //                               value: 1.0, // Full background circle
// //                               strokeWidth: 8,
// //                               backgroundColor: Colors.white.withOpacity(0.2),
// //                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.2)),
// //                             ),
// //                           ),
// //                           // Progress circle
// //                           SizedBox(
// //                             width: 90,
// //                             height: 90,
// //                             child: CircularProgressIndicator(
// //                               value: _getLevelProgress(),
// //                               strokeWidth: 8,
// //                               backgroundColor: Colors.transparent,
// //                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// //                               strokeCap: StrokeCap.round, // Rounded ends to prevent merging
// //                             ),
// //                           ),
// //                           // Center content
// //                           Container(
// //                             width: 60,
// //                             height: 60,
// //                             decoration: BoxDecoration(
// //                               color: Colors.white.withOpacity(0.1),
// //                               shape: BoxShape.circle,
// //                             ),
// //                             child: Column(
// //                               mainAxisAlignment: MainAxisAlignment.center,
// //                               children: [
// //                                 Icon(
// //                                   _getLevelIcon(),
// //                                   color: textPrimary,
// //                                   size: 18,
// //                                 ),
// //                                 SizedBox(height: 2),
// //                                 Text(
// //                                   '${(_getLevelProgress() * 100).toInt()}%',
// //                                   style: TextStyle(
// //                                     fontSize: 10,
// //                                     fontWeight: FontWeight.bold,
// //                                     color: textPrimary,
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //
// //                     SizedBox(width: _getSpaceL(context)),
// //
// //                     // Progress Info
// //                     Expanded(
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Text(
// //                             userLevel,
// //                             style: TextStyle(
// //                               fontSize: _getSubheadingSize(context),
// //                               fontWeight: FontWeight.bold,
// //                               color: textPrimary,
// //                             ),
// //                           ),
// //                           SizedBox(height: _getSpaceS(context)),
// //                           Text(
// //                             _getNextLevelInfo(),
// //                             style: TextStyle(
// //                               fontSize: _getBodySize(context),
// //                               color: textPrimary.withOpacity(0.8),
// //                             ),
// //                             maxLines: 2,
// //                             overflow: TextOverflow.ellipsis,
// //                           ),
// //                           if (bestQuizScore > 0) ...[
// //                             SizedBox(height: _getSpaceS(context)),
// //                             Container(
// //                               padding: EdgeInsets.symmetric(
// //                                 horizontal: _getSpaceM(context),
// //                                 vertical: _getSpaceS(context),
// //                               ),
// //                               decoration: BoxDecoration(
// //                                 color: Colors.white.withOpacity(0.2),
// //                                 borderRadius: BorderRadius.circular(_getRadiusS()),
// //                               ),
// //                               child: Text(
// //                                 'Best Quiz: $bestQuizScore pts',
// //                                 style: TextStyle(
// //                                   fontSize: _getCaptionSize(context),
// //                                   color: textPrimary.withOpacity(0.8),
// //                                   fontWeight: FontWeight.w500,
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         ],
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ✅ MODERN APP BAR - Fixed Height Issues
// //   Widget _buildModernAppBar() {
// //     return SliverAppBar(
// //       expandedHeight: _isMobile(context) ? 80 : 100,
// //       floating: true,
// //       pinned: true,
// //       elevation: 0,
// //       backgroundColor: Colors.transparent,
// //       automaticallyImplyLeading: false,
// //       flexibleSpace: Container(
// //         decoration: BoxDecoration(
// //           gradient: LinearGradient(
// //             begin: Alignment.topLeft,
// //             end: Alignment.bottomRight,
// //             colors: [
// //               surfaceColor.withOpacity(0.9),
// //               surfaceLight.withOpacity(0.7),
// //             ],
// //           ),
// //           border: Border(
// //             bottom: BorderSide(
// //               color: Colors.white.withOpacity(0.1),
// //               width: 1,
// //             ),
// //           ),
// //         ),
// //         child: SafeArea(
// //           child: Padding(
// //             padding: EdgeInsets.symmetric(horizontal: _getSpaceM(context)),
// //             child: Row(
// //               children: [
// //                 // Back Button
// //                 Container(
// //                   decoration: BoxDecoration(
// //                     color: Colors.white.withOpacity(0.1),
// //                     borderRadius: BorderRadius.circular(_getRadiusM()),
// //                     border: Border.all(
// //                       color: Colors.white.withOpacity(0.2),
// //                     ),
// //                   ),
// //                   child: IconButton(
// //                     onPressed: () => Navigator.of(context).pop(),
// //                     icon: Icon(
// //                       Icons.arrow_back_ios_new,
// //                       color: textPrimary,
// //                       size: 20,
// //                     ),
// //                   ),
// //                 ),
// //                 SizedBox(width: _getSpaceM(context)),
// //
// //                 // Title
// //                 Expanded(
// //                   child: Column(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         'Profile',
// //                         style: TextStyle(
// //                           color: textPrimary,
// //                           fontSize: _getHeadingSize(context),
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                       Text(
// //                         'Manage your learning profile',
// //                         style: TextStyle(
// //                           color: textSecondary,
// //                           fontSize: _getCaptionSize(context),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //
// //                 // Refresh Button
// //                 Container(
// //                   decoration: BoxDecoration(
// //                     gradient: LinearGradient(
// //                       colors: [primaryColor, accentColor],
// //                     ),
// //                     borderRadius: BorderRadius.circular(_getRadiusM()),
// //                     boxShadow: [
// //                       BoxShadow(
// //                         color: primaryColor.withOpacity(0.3),
// //                         blurRadius: 8,
// //                         offset: const Offset(0, 2),
// //                       ),
// //                     ],
// //                   ),
// //                   child: IconButton(
// //                     onPressed: _refreshData,
// //                     icon: Icon(
// //                       Icons.refresh,
// //                       color: textPrimary,
// //                       size: 20,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ✅ MODERN STATS GRID - Fixed Overflow Issues
// //   Widget _buildModernStatsGrid() {
// //     return LayoutBuilder(
// //       builder: (context, constraints) {
// //         final crossAxisCount = _getStatsColumns(context);
// //         final spacing = _getSpaceM(context);
// //
// //         // Calculate proper height to prevent overflow
// //         final itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
// //         final itemHeight = itemWidth * 0.9; // Better aspect ratio
// //
// //         return Wrap(
// //           spacing: spacing,
// //           runSpacing: spacing,
// //           children: [
// //             _buildModernStatCard(
// //               icon: Icons.article_outlined,
// //               title: "Notes",
// //               value: notesCount.toString(),
// //               subtitle: "Saved",
// //               color: const Color(0xFF8B5CF6),
// //               gradient: [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
// //               width: itemWidth,
// //               height: itemHeight,
// //             ),
// //             _buildModernStatCard(
// //               icon: Icons.play_circle_outline,
// //               title: "Videos",
// //               value: savedVideosCount.toString(),
// //               subtitle: "Bookmarked",
// //               color: const Color(0xFFEF4444),
// //               gradient: [const Color(0xFFEF4444), const Color(0xFFF87171)],
// //               width: itemWidth,
// //               height: itemHeight,
// //             ),
// //             _buildModernStatCard(
// //               icon: Icons.link_outlined,
// //               title: "Links",
// //               value: savedLinksCount.toString(),
// //               subtitle: "Resources",
// //               color: const Color(0xFF3B82F6),
// //               gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
// //               width: itemWidth,
// //               height: itemHeight,
// //             ),
// //             _buildModernStatCard(
// //               icon: Icons.quiz_outlined,
// //               title: "Quizzes",
// //               value: quizzesTaken.toString(),
// //               subtitle: "Completed",
// //               color: const Color(0xFF10B981),
// //               gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
// //               width: itemWidth,
// //               height: itemHeight,
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   // ✅ MODERN STAT CARD - Fixed Layout Issues
// //   Widget _buildModernStatCard({
// //     required IconData icon,
// //     required String title,
// //     required String value,
// //     required String subtitle,
// //     required Color color,
// //     required List<Color> gradient,
// //     required double width,
// //     required double height,
// //   }) {
// //     return AnimatedBuilder(
// //       animation: _counterAnimation,
// //       builder: (context, child) {
// //         final animatedValue = (int.tryParse(value) ?? 0) * _counterAnimation.value;
// //
// //         return Container(
// //           width: width,
// //           height: height,
// //           decoration: BoxDecoration(
// //             gradient: LinearGradient(
// //               begin: Alignment.topLeft,
// //               end: Alignment.bottomRight,
// //               colors: [
// //                 Colors.white.withOpacity(0.15),
// //                 Colors.white.withOpacity(0.05),
// //               ],
// //             ),
// //             borderRadius: BorderRadius.circular(_getRadiusL()),
// //             border: Border.all(
// //               color: Colors.white.withOpacity(0.2),
// //               width: 1,
// //             ),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.black.withOpacity(0.1),
// //                 blurRadius: 15,
// //                 offset: const Offset(0, 5),
// //               ),
// //             ],
// //           ),
// //           child: Padding(
// //             padding: EdgeInsets.all(_getSpaceM(context)),
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               crossAxisAlignment: CrossAxisAlignment.center,
// //               children: [
// //                 // Icon with gradient background
// //                 Flexible(
// //                   flex: 3,
// //                   child: Container(
// //                     padding: EdgeInsets.all(_getSpaceS(context)),
// //                     decoration: BoxDecoration(
// //                       gradient: LinearGradient(colors: gradient),
// //                       borderRadius: BorderRadius.circular(_getRadiusM()),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: color.withOpacity(0.3),
// //                           blurRadius: 8,
// //                           offset: const Offset(0, 2),
// //                         ),
// //                       ],
// //                     ),
// //                     child: FittedBox(
// //                       child: Icon(
// //                         icon,
// //                         color: textPrimary,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //
// //                 SizedBox(height: _getSpaceS(context)),
// //
// //                 // Animated Value
// //                 Flexible(
// //                   flex: 2,
// //                   child: FittedBox(
// //                     fit: BoxFit.scaleDown,
// //                     child: Text(
// //                       animatedValue.round().toString(),
// //                       style: TextStyle(
// //                         color: textPrimary,
// //                         fontSize: 28,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //
// //                 SizedBox(height: _getSpaceXS(context)),
// //
// //                 // Title
// //                 Flexible(
// //                   flex: 1,
// //                   child: FittedBox(
// //                     fit: BoxFit.scaleDown,
// //                     child: Text(
// //                       title,
// //                       style: TextStyle(
// //                         color: textSecondary,
// //                         fontSize: _getBodySize(context),
// //                         fontWeight: FontWeight.w600,
// //                       ),
// //                       textAlign: TextAlign.center,
// //                       maxLines: 1,
// //                     ),
// //                   ),
// //                 ),
// //
// //                 // Subtitle
// //                 Flexible(
// //                   flex: 1,
// //                   child: FittedBox(
// //                     fit: BoxFit.scaleDown,
// //                     child: Text(
// //                       subtitle,
// //                       style: TextStyle(
// //                         color: textTertiary,
// //                         fontSize: _getCaptionSize(context),
// //                       ),
// //                       textAlign: TextAlign.center,
// //                       maxLines: 1,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   // ✅ QUICK ACTIONS CARD - Fixed Button Layout
// //   Widget _buildQuickActionsCard() {
// //     return Container(
// //       width: double.infinity,
// //       padding: _getPaddingL(context),
// //       decoration: BoxDecoration(
// //         gradient: LinearGradient(
// //           begin: Alignment.topLeft,
// //           end: Alignment.bottomRight,
// //           colors: [
// //             Colors.white.withOpacity(0.15),
// //             Colors.white.withOpacity(0.05),
// //           ],
// //         ),
// //         borderRadius: BorderRadius.circular(_getRadiusL()),
// //         border: Border.all(
// //           color: Colors.white.withOpacity(0.2),
// //           width: 1,
// //         ),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.1),
// //             blurRadius: 15,
// //             offset: const Offset(0, 5),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Header
// //           Row(
// //             children: [
// //               Container(
// //                 padding: EdgeInsets.all(_getSpaceM(context)),
// //                 decoration: BoxDecoration(
// //                   gradient: LinearGradient(
// //                     colors: [warningColor, warningColor.withOpacity(0.7)],
// //                   ),
// //                   borderRadius: BorderRadius.circular(_getRadiusM()),
// //                 ),
// //                 child: Icon(
// //                   Icons.flash_on,
// //                   color: textPrimary,
// //                   size: 20,
// //                 ),
// //               ),
// //               SizedBox(width: _getSpaceM(context)),
// //               Expanded(
// //                 child: Text(
// //                   'Quick Actions',
// //                   style: TextStyle(
// //                     fontSize: _getSubheadingSize(context),
// //                     fontWeight: FontWeight.bold,
// //                     color: textPrimary,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: _getSpaceL(context)),
// //
// //           // Action Buttons Grid
// //           GridView.count(
// //             shrinkWrap: true,
// //             physics: const NeverScrollableScrollPhysics(),
// //             crossAxisCount: 2,
// //             childAspectRatio: 2.8,
// //             crossAxisSpacing: _getSpaceM(context),
// //             mainAxisSpacing: _getSpaceM(context),
// //             children: [
// //               _buildActionButton(
// //                 icon: Icons.edit,
// //                 label: 'Edit Profile',
// //                 onTap: () => setState(() => isEditing = true),
// //                 gradient: [primaryColor, primaryLight],
// //               ),
// //               _buildActionButton(
// //                 icon: Icons.refresh,
// //                 label: 'Refresh Data',
// //                 onTap: _refreshData,
// //                 gradient: [accentColor, accentLight],
// //               ),
// //               _buildActionButton(
// //                 icon: Icons.camera_alt,
// //                 label: 'Change Photo',
// //                 onTap: _pickImage,
// //                 gradient: [successColor, const Color(0xFF34D399)],
// //               ),
// //               _buildActionButton(
// //                 icon: Icons.logout,
// //                 label: 'Sign Out',
// //                 onTap: _showLogoutDialog,
// //                 gradient: [errorColor, const Color(0xFFF87171)],
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ✅ ACTION BUTTON - Fixed Responsive Design
// //   Widget _buildActionButton({
// //     required IconData icon,
// //     required String label,
// //     required VoidCallback onTap,
// //     required List<Color> gradient,
// //   }) {
// //     return Container(
// //       decoration: BoxDecoration(
// //         gradient: LinearGradient(colors: gradient),
// //         borderRadius: BorderRadius.circular(_getRadiusM()),
// //         boxShadow: [
// //           BoxShadow(
// //             color: gradient[0].withOpacity(0.3),
// //             blurRadius: 8,
// //             offset: const Offset(0, 3),
// //           ),
// //         ],
// //       ),
// //       child: Material(
// //         color: Colors.transparent,
// //         child: InkWell(
// //           borderRadius: BorderRadius.circular(_getRadiusM()),
// //           onTap: onTap,
// //           child: Padding(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: _getSpaceM(context),
// //               vertical: _getSpaceM(context),
// //             ),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 Icon(
// //                   icon,
// //                   color: textPrimary,
// //                   size: 16,
// //                 ),
// //                 SizedBox(width: _getSpaceS(context)),
// //                 Flexible(
// //                   child: Text(
// //                     label,
// //                     style: TextStyle(
// //                       fontSize: _getBodySize(context),
// //                       fontWeight: FontWeight.w600,
// //                       color: textPrimary,
// //                     ),
// //                     maxLines: 1,
// //                     overflow: TextOverflow.ellipsis,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ✅ MODERN LEARNING JOURNEY - Same as before
// //   Widget _buildModernLearningJourney() {
// //     return Container(
// //       width: double.infinity,
// //       padding: _getPaddingL(context),
// //       decoration: BoxDecoration(
// //         gradient: LinearGradient(
// //           begin: Alignment.topLeft,
// //           end: Alignment.bottomRight,
// //           colors: [
// //             Colors.white.withOpacity(0.15),
// //             Colors.white.withOpacity(0.05),
// //           ],
// //         ),
// //         borderRadius: BorderRadius.circular(_getRadiusL()),
// //         border: Border.all(
// //           color: Colors.white.withOpacity(0.2),
// //           width: 1,
// //         ),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.1),
// //             blurRadius: 15,
// //             offset: const Offset(0, 5),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Header
// //           Row(
// //             children: [
// //               Container(
// //                 padding: EdgeInsets.all(_getSpaceM(context)),
// //                 decoration: BoxDecoration(
// //                   gradient: LinearGradient(
// //                     colors: [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
// //                   ),
// //                   borderRadius: BorderRadius.circular(_getRadiusM()),
// //                 ),
// //                 child: Icon(
// //                   Icons.trending_up,
// //                   color: textPrimary,
// //                   size: 20,
// //                 ),
// //               ),
// //               SizedBox(width: _getSpaceM(context)),
// //               Expanded(
// //                 child: Text(
// //                   'Learning Journey',
// //                   style: TextStyle(
// //                     fontSize: _getSubheadingSize(context),
// //                     fontWeight: FontWeight.bold,
// //                     color: textPrimary,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: _getSpaceL(context)),
// //
// //           // Achievements Timeline
// //           ..._buildModernAchievements(),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   List<Widget> _buildModernAchievements() {
// //     List<Widget> achievements = [];
// //
// //     if (userPoints > 0) {
// //       achievements.add(_buildTimelineItem(
// //         icon: Icons.emoji_events,
// //         title: "Points Earned",
// //         subtitle: "$userPoints learning points collected!",
// //         time: _getPointsMessage(),
// //         color: warningColor,
// //         isFirst: true,
// //       ));
// //     }
// //
// //     if (quizzesTaken > 0) {
// //       achievements.add(_buildTimelineItem(
// //         icon: Icons.quiz,
// //         title: "Quiz Master",
// //         subtitle: "Completed $quizzesTaken ${quizzesTaken == 1 ? 'quiz' : 'quizzes'}",
// //         time: bestQuizScore > 0 ? "Best: $bestQuizScore pts" : "Keep going!",
// //         color: successColor,
// //       ));
// //     }
// //
// //     if (notesCount > 0) {
// //       achievements.add(_buildTimelineItem(
// //         icon: Icons.note_add,
// //         title: "Note Keeper",
// //         subtitle: "Saved $notesCount ${notesCount == 1 ? 'note' : 'notes'}",
// //         time: "Great organization!",
// //         color: primaryColor,
// //       ));
// //     }
// //
// //     if (savedVideosCount > 0) {
// //       achievements.add(_buildTimelineItem(
// //         icon: Icons.video_library,
// //         title: "Video Learner",
// //         subtitle: "Bookmarked $savedVideosCount ${savedVideosCount == 1 ? 'video' : 'videos'}",
// //         time: "Visual learning!",
// //         color: errorColor,
// //         isLast: true,
// //       ));
// //     }
// //
// //     // If no achievements yet
// //     if (achievements.isEmpty) {
// //       achievements.add(_buildTimelineItem(
// //         icon: Icons.rocket_launch,
// //         title: "Start Your Journey",
// //         subtitle: "Take your first quiz or save your first note!",
// //         time: "You've got this! 🚀",
// //         color: accentColor,
// //         isFirst: true,
// //         isLast: true,
// //       ));
// //     }
// //
// //     return achievements;
// //   }
// //
// //   String _getPointsMessage() {
// //     if (userPoints >= 5000) return "Amazing! 🏆";
// //     if (userPoints >= 3000) return "Excellent! 🌟";
// //     if (userPoints >= 1500) return "Great job! 🎉";
// //     if (userPoints >= 500) return "Keep going! 💪";
// //     return "Good start! 👍";
// //   }
// //
// //   // ✅ TIMELINE ITEM - Modern Achievement Card
// //   Widget _buildTimelineItem({
// //     required IconData icon,
// //     required String title,
// //     required String subtitle,
// //     required String time,
// //     required Color color,
// //     bool isFirst = false,
// //     bool isLast = false,
// //   }) {
// //     return Container(
// //       margin: EdgeInsets.only(bottom: isLast ? 0 : _getSpaceM(context)),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Timeline indicator
// //           Column(
// //             children: [
// //               Container(
// //                 width: 40,
// //                 height: 40,
// //                 decoration: BoxDecoration(
// //                   gradient: LinearGradient(
// //                     colors: [color, color.withOpacity(0.7)],
// //                   ),
// //                   shape: BoxShape.circle,
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: color.withOpacity(0.3),
// //                       blurRadius: 8,
// //                       offset: const Offset(0, 2),
// //                     ),
// //                   ],
// //                 ),
// //                 child: Icon(
// //                   icon,
// //                   color: textPrimary,
// //                   size: 20,
// //                 ),
// //               ),
// //               if (!isLast)
// //                 Container(
// //                   width: 2,
// //                   height: 40,
// //                   margin: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
// //                   decoration: BoxDecoration(
// //                     gradient: LinearGradient(
// //                       begin: Alignment.topCenter,
// //                       end: Alignment.bottomCenter,
// //                       colors: [
// //                         color.withOpacity(0.5),
// //                         Colors.white.withOpacity(0.1),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //             ],
// //           ),
// //           SizedBox(width: _getSpaceM(context)),
// //
// //           // Content
// //           Expanded(
// //             child: Container(
// //               padding: _getPaddingM(context),
// //               decoration: BoxDecoration(
// //                 color: Colors.white.withOpacity(0.05),
// //                 borderRadius: BorderRadius.circular(_getRadiusM()),
// //                 border: Border.all(
// //                   color: color.withOpacity(0.2),
// //                 ),
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       Expanded(
// //                         child: Text(
// //                           title,
// //                           style: TextStyle(
// //                             color: textPrimary,
// //                             fontWeight: FontWeight.w600,
// //                             fontSize: _getBodySize(context),
// //                           ),
// //                           maxLines: 1,
// //                           overflow: TextOverflow.ellipsis,
// //                         ),
// //                       ),
// //                       if (time.isNotEmpty)
// //                         Text(
// //                           time,
// //                           style: TextStyle(
// //                             color: color,
// //                             fontSize: _getCaptionSize(context),
// //                             fontWeight: FontWeight.w500,
// //                           ),
// //                           maxLines: 1,
// //                           overflow: TextOverflow.ellipsis,
// //                         ),
// //                     ],
// //                   ),
// //                   SizedBox(height: _getSpaceXS(context)),
// //                   Text(
// //                     subtitle,
// //                     style: TextStyle(
// //                       color: textSecondary,
// //                       fontSize: _getCaptionSize(context),
// //                     ),
// //                     maxLines: 2,
// //                     overflow: TextOverflow.ellipsis,
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ✅ MODERN ACCOUNT SETTINGS - Same as before
// //   Widget _buildModernAccountSettings() {
// //     return Container(
// //       width: double.infinity,
// //       padding: _getPaddingL(context),
// //       decoration: BoxDecoration(
// //         gradient: LinearGradient(
// //           begin: Alignment.topLeft,
// //           end: Alignment.bottomRight,
// //           colors: [
// //             Colors.white.withOpacity(0.15),
// //             Colors.white.withOpacity(0.05),
// //           ],
// //         ),
// //         borderRadius: BorderRadius.circular(_getRadiusL()),
// //         border: Border.all(
// //           color: Colors.white.withOpacity(0.2),
// //           width: 1,
// //         ),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.1),
// //             blurRadius: 15,
// //             offset: const Offset(0, 5),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Header
// //           Row(
// //             children: [
// //               Container(
// //                 padding: EdgeInsets.all(_getSpaceM(context)),
// //                 decoration: BoxDecoration(
// //                   gradient: LinearGradient(
// //                     colors: [primaryColor, accentColor],
// //                   ),
// //                   borderRadius: BorderRadius.circular(_getRadiusM()),
// //                 ),
// //                 child: Icon(
// //                   Icons.settings,
// //                   color: textPrimary,
// //                   size: 20,
// //                 ),
// //               ),
// //               SizedBox(width: _getSpaceM(context)),
// //               Expanded(
// //                 child: Text(
// //                   'Account Settings',
// //                   style: TextStyle(
// //                     fontSize: _getSubheadingSize(context),
// //                     fontWeight: FontWeight.bold,
// //                     color: textPrimary,
// //                   ),
// //                 ),
// //               ),
// //               if (!isEditing)
// //                 GestureDetector(
// //                   onTap: () => setState(() => isEditing = true),
// //                   child: Container(
// //                     padding: EdgeInsets.all(_getSpaceS(context)),
// //                     decoration: BoxDecoration(
// //                       color: Colors.white.withOpacity(0.1),
// //                       borderRadius: BorderRadius.circular(_getRadiusS()),
// //                       border: Border.all(
// //                         color: primaryColor.withOpacity(0.3),
// //                       ),
// //                     ),
// //                     child: Icon(
// //                       Icons.edit,
// //                       color: primaryColor,
// //                       size: 18,
// //                     ),
// //                   ),
// //                 ),
// //             ],
// //           ),
// //           SizedBox(height: _getSpaceL(context)),
// //
// //           // Form Fields
// //           _buildModernTextField(
// //             label: "Full Name",
// //             value: userName,
// //             controller: _nameController,
// //             icon: Icons.person_outline,
// //           ),
// //           SizedBox(height: _getSpaceM(context)),
// //
// //           _buildModernTextField(
// //             label: "Email Address",
// //             value: userEmail,
// //             controller: _emailController,
// //             icon: Icons.email_outlined,
// //           ),
// //
// //           // Action Buttons
// //           if (isEditing) ...[
// //             SizedBox(height: _getSpaceL(context)),
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: _buildModernButton(
// //                     label: "Cancel",
// //                     onPressed: _cancelEditing,
// //                     isPrimary: false,
// //                   ),
// //                 ),
// //                 SizedBox(width: _getSpaceM(context)),
// //                 Expanded(
// //                   child: _buildModernButton(
// //                     label: "Save Changes",
// //                     onPressed: _updateProfile,
// //                     isPrimary: true,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ✅ MODERN TEXT FIELD - Same as before
// //   Widget _buildModernTextField({
// //     required String label,
// //     required String value,
// //     required TextEditingController controller,
// //     required IconData icon,
// //   }) {
// //     return Container(
// //       padding: _getPaddingM(context),
// //       decoration: BoxDecoration(
// //         color: isEditing
// //             ? Colors.white.withOpacity(0.1)
// //             : Colors.white.withOpacity(0.05),
// //         borderRadius: BorderRadius.circular(_getRadiusM()),
// //         border: Border.all(
// //           color: isEditing
// //               ? primaryColor.withOpacity(0.4)
// //               : Colors.white.withOpacity(0.1),
// //           width: 1.5,
// //         ),
// //       ),
// //       child: Row(
// //         children: [
// //           Container(
// //             padding: EdgeInsets.all(_getSpaceS(context)),
// //             decoration: BoxDecoration(
// //               gradient: LinearGradient(
// //                 colors: [primaryColor.withOpacity(0.2), accentColor.withOpacity(0.2)],
// //               ),
// //               borderRadius: BorderRadius.circular(_getRadiusS()),
// //             ),
// //             child: Icon(
// //               icon,
// //               color: primaryColor,
// //               size: 20,
// //             ),
// //           ),
// //           SizedBox(width: _getSpaceM(context)),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   label,
// //                   style: TextStyle(
// //                     color: textTertiary,
// //                     fontSize: _getCaptionSize(context),
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                 ),
// //                 SizedBox(height: _getSpaceXS(context)),
// //                 isEditing
// //                     ? TextField(
// //                   controller: controller,
// //                   style: TextStyle(
// //                     color: textPrimary,
// //                     fontSize: _getBodySize(context),
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                   decoration: const InputDecoration(
// //                     isDense: true,
// //                     contentPadding: EdgeInsets.zero,
// //                     border: InputBorder.none,
// //                   ),
// //                   maxLines: 1,
// //                 )
// //                     : Text(
// //                   value,
// //                   style: TextStyle(
// //                     color: textPrimary,
// //                     fontSize: _getBodySize(context),
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                   maxLines: 1,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ✅ MODERN BUTTON - Same as before
// //   Widget _buildModernButton({
// //     required String label,
// //     required VoidCallback onPressed,
// //     required bool isPrimary,
// //   }) {
// //     return Container(
// //       height: 50,
// //       decoration: BoxDecoration(
// //         gradient: isPrimary
// //             ? LinearGradient(colors: [primaryColor, accentColor])
// //             : null,
// //         color: isPrimary ? null : Colors.white.withOpacity(0.1),
// //         borderRadius: BorderRadius.circular(_getRadiusM()),
// //         border: isPrimary
// //             ? null
// //             : Border.all(color: Colors.white.withOpacity(0.3)),
// //         boxShadow: isPrimary ? [
// //           BoxShadow(
// //             color: primaryColor.withOpacity(0.3),
// //             blurRadius: 10,
// //             offset: const Offset(0, 4),
// //           ),
// //         ] : null,
// //       ),
// //       child: Material(
// //         color: Colors.transparent,
// //         child: InkWell(
// //           borderRadius: BorderRadius.circular(_getRadiusM()),
// //           onTap: onPressed,
// //           child: Center(
// //             child: Text(
// //               label,
// //               style: TextStyle(
// //                 color: textPrimary,
// //                 fontSize: _getBodySize(context),
// //                 fontWeight: FontWeight.w600,
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // ✅ MODERN LOGOUT DIALOG - Same as before
// // class _ModernLogoutDialog extends StatefulWidget {
// //   @override
// //   _ModernLogoutDialogState createState() => _ModernLogoutDialogState();
// // }
// //
// // class _ModernLogoutDialogState extends State<_ModernLogoutDialog>
// //     with SingleTickerProviderStateMixin {
// //   bool _isLoggingOut = false;
// //   late AnimationController _animationController;
// //   late Animation<double> _scaleAnimation;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _animationController = AnimationController(
// //       duration: const Duration(milliseconds: 300),
// //       vsync: this,
// //     );
// //     _scaleAnimation = CurvedAnimation(
// //       parent: _animationController,
// //       curve: Curves.elasticOut,
// //     );
// //     _animationController.forward();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _animationController.dispose();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Dialog(
// //       backgroundColor: Colors.transparent,
// //       elevation: 0,
// //       child: ScaleTransition(
// //         scale: _scaleAnimation,
// //         child: Container(
// //           width: double.infinity,
// //           constraints: BoxConstraints(
// //             maxWidth: MediaQuery.of(context).size.width * 0.9,
// //             maxHeight: MediaQuery.of(context).size.height * 0.6,
// //           ),
// //           margin: const EdgeInsets.all(20),
// //           decoration: BoxDecoration(
// //             gradient: const LinearGradient(
// //               begin: Alignment.topLeft,
// //               end: Alignment.bottomRight,
// //               colors: [
// //                 Color(0xFF1E293B),
// //                 Color(0xFF0F172A),
// //               ],
// //             ),
// //             borderRadius: BorderRadius.circular(24),
// //             border: Border.all(
// //               color: const Color(0xFFEF4444).withOpacity(0.3),
// //               width: 2,
// //             ),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.black.withOpacity(0.5),
// //                 blurRadius: 30,
// //                 offset: const Offset(0, 15),
// //               ),
// //             ],
// //           ),
// //           child: Padding(
// //             padding: const EdgeInsets.all(32),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 // Logout icon with animation
// //                 Container(
// //                   width: 80,
// //                   height: 80,
// //                   decoration: BoxDecoration(
// //                     gradient: LinearGradient(
// //                       colors: _isLoggingOut
// //                           ? [Colors.grey, Colors.grey.shade600]
// //                           : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
// //                     ),
// //                     shape: BoxShape.circle,
// //                     boxShadow: [
// //                       BoxShadow(
// //                         color: (_isLoggingOut ? Colors.grey : const Color(0xFFEF4444))
// //                             .withOpacity(0.4),
// //                         blurRadius: 20,
// //                         spreadRadius: 5,
// //                       ),
// //                     ],
// //                   ),
// //                   child: _isLoggingOut
// //                       ? const CircularProgressIndicator(
// //                     strokeWidth: 3,
// //                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// //                   )
// //                       : const Icon(
// //                     Icons.logout_rounded,
// //                     color: Colors.white,
// //                     size: 36,
// //                   ),
// //                 ),
// //
// //                 const SizedBox(height: 24),
// //
// //                 // Title
// //                 Text(
// //                   _isLoggingOut ? 'Signing Out...' : 'Ready to Sign Out?',
// //                   style: const TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 24,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                   textAlign: TextAlign.center,
// //                 ),
// //
// //                 const SizedBox(height: 16),
// //
// //                 // Security message
// //                 Container(
// //                   padding: const EdgeInsets.all(20),
// //                   decoration: BoxDecoration(
// //                     color: const Color(0xFF334155),
// //                     borderRadius: BorderRadius.circular(16),
// //                     border: Border.all(
// //                       color: Colors.white.withOpacity(0.1),
// //                     ),
// //                   ),
// //                   child: Column(
// //                     children: [
// //                       const Icon(
// //                         Icons.verified_user,
// //                         color: Color(0xFF06B6D4),
// //                         size: 24,
// //                       ),
// //                       const SizedBox(height: 12),
// //                       Text(
// //                         _isLoggingOut
// //                             ? 'Saving your progress and signing out safely...'
// //                             : 'Your learning progress is safely saved!\nYou can continue where you left off.',
// //                         style: const TextStyle(
// //                           color: Colors.white70,
// //                           fontSize: 14,
// //                           height: 1.4,
// //                         ),
// //                         textAlign: TextAlign.center,
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //
// //                 const SizedBox(height: 32),
// //
// //                 // Action buttons
// //                 Row(
// //                   children: [
// //                     // Stay button
// //                     Expanded(
// //                       child: Container(
// //                         height: 50,
// //                         decoration: BoxDecoration(
// //                           color: Colors.transparent,
// //                           borderRadius: BorderRadius.circular(16),
// //                           border: Border.all(
// //                             color: Colors.white.withOpacity(0.3),
// //                           ),
// //                         ),
// //                         child: Material(
// //                           color: Colors.transparent,
// //                           child: InkWell(
// //                             borderRadius: BorderRadius.circular(16),
// //                             onTap: _isLoggingOut ? null : () => Navigator.of(context).pop(),
// //                             child: const Center(
// //                               child: Text(
// //                                 'Stay Here',
// //                                 style: TextStyle(
// //                                   color: Colors.white70,
// //                                   fontSize: 16,
// //                                   fontWeight: FontWeight.w600,
// //                                 ),
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //
// //                     const SizedBox(width: 16),
// //
// //                     // Sign Out button
// //                     Expanded(
// //                       child: Container(
// //                         height: 50,
// //                         decoration: BoxDecoration(
// //                           gradient: LinearGradient(
// //                             colors: _isLoggingOut
// //                                 ? [Colors.grey, Colors.grey.shade600]
// //                                 : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
// //                           ),
// //                           borderRadius: BorderRadius.circular(16),
// //                           boxShadow: [
// //                             BoxShadow(
// //                               color: (_isLoggingOut ? Colors.grey : const Color(0xFFEF4444))
// //                                   .withOpacity(0.3),
// //                               blurRadius: 10,
// //                               offset: const Offset(0, 4),
// //                             ),
// //                           ],
// //                         ),
// //                         child: Material(
// //                           color: Colors.transparent,
// //                           child: InkWell(
// //                             borderRadius: BorderRadius.circular(16),
// //                             onTap: _isLoggingOut ? null : _handleLogout,
// //                             child: Center(
// //                               child: Row(
// //                                 mainAxisAlignment: MainAxisAlignment.center,
// //                                 children: [
// //                                   if (_isLoggingOut) ...[
// //                                     const SizedBox(
// //                                       width: 16,
// //                                       height: 16,
// //                                       child: CircularProgressIndicator(
// //                                         strokeWidth: 2,
// //                                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// //                                       ),
// //                                     ),
// //                                   ] else ...[
// //                                     const Icon(
// //                                       Icons.logout_rounded,
// //                                       color: Colors.white,
// //                                       size: 18,
// //                                     ),
// //                                   ],
// //                                   const SizedBox(width: 8),
// //                                   Text(
// //                                     _isLoggingOut ? 'Signing Out...' : 'Sign Out',
// //                                     style: const TextStyle(
// //                                       color: Colors.white,
// //                                       fontSize: 16,
// //                                       fontWeight: FontWeight.bold,
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Future<void> _handleLogout() async {
// //     if (!mounted) return;
// //
// //     setState(() {
// //       _isLoggingOut = true;
// //     });
// //
// //     try {
// //       await _performLogout();
// //     } catch (e) {
// //       if (mounted) {
// //         setState(() {
// //           _isLoggingOut = false;
// //         });
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Logout failed: ${e.toString()}'),
// //             backgroundColor: const Color(0xFFEF4444),
// //             behavior: SnackBarBehavior.floating,
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(12),
// //             ),
// //           ),
// //         );
// //       }
// //     }
// //   }
// //
// //   Future<void> _performLogout() async {
// //     try {
// //       // Sign out from Firebase
// //       await FirebaseAuth.instance.signOut();
// //
// //       // Clear SharedPreferences
// //       final prefs = await SharedPreferences.getInstance();
// //       await prefs.setBool('is_logged_in', false);
// //       await prefs.remove('last_login');
// //
// //       if (mounted) {
// //         Navigator.of(context).pop();
// //         Navigator.of(context).pushAndRemoveUntil(
// //           MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
// //               (route) => false,
// //         );
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         Navigator.of(context).pop();
// //       }
// //       throw e;
// //     }
// //   }
// // }
// //
// //
// //
// //
// // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // import 'package:firebase_auth/firebase_auth.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:shared_preferences/shared_preferences.dart';
// // // import 'package:image_picker/image_picker.dart';
// // // import 'dart:io';
// // // import 'dart:convert';
// // // import 'dart:typed_data';
// // // import 'dart:ui';
// // //
// // // import 'email_change_verification_screen.dart';
// // // import 'login_screen.dart';
// // //
// // // class ProfileScreen extends StatefulWidget {
// // //   const ProfileScreen({super.key});
// // //
// // //   @override
// // //   State<ProfileScreen> createState() => _ProfileScreenState();
// // // }
// // //
// // // class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
// // //   // Data variables
// // //   String userName = "Loading...";
// // //   String userEmail = "Loading...";
// // //   String profileImageBase64 = "";
// // //   int userPoints = 0;
// // //   int notesCount = 0;
// // //   int savedVideosCount = 0;
// // //   int savedLinksCount = 0;
// // //   int quizzesTaken = 0;
// // //   int bestQuizScore = 0;
// // //   String userLevel = "Rookie";
// // //
// // //   // UI state variables
// // //   bool isEditing = false;
// // //   bool isLoading = true;
// // //   bool isUploadingImage = false;
// // //   File? _profileImage;
// // //
// // //   // Controllers
// // //   final TextEditingController _emailController = TextEditingController();
// // //   final TextEditingController _nameController = TextEditingController();
// // //   final ImagePicker _picker = ImagePicker();
// // //
// // //   // Animation controllers
// // //   late AnimationController _fadeController;
// // //   late AnimationController _slideController;
// // //   late AnimationController _counterController;
// // //   late AnimationController _pulseController;
// // //   late AnimationController _scaleController;
// // //   late Animation<double> _fadeAnimation;
// // //   late Animation<Offset> _slideAnimation;
// // //   late Animation<double> _counterAnimation;
// // //   late Animation<double> _pulseAnimation;
// // //   late Animation<double> _scaleAnimation;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _initializeAnimations();
// // //     _loadUserData();
// // //   }
// // //
// // //   void _initializeAnimations() {
// // //     _fadeController = AnimationController(
// // //       duration: const Duration(milliseconds: 1200),
// // //       vsync: this,
// // //     );
// // //     _slideController = AnimationController(
// // //       duration: const Duration(milliseconds: 1000),
// // //       vsync: this,
// // //     );
// // //     _counterController = AnimationController(
// // //       duration: const Duration(milliseconds: 2500),
// // //       vsync: this,
// // //     );
// // //     _pulseController = AnimationController(
// // //       duration: const Duration(milliseconds: 2000),
// // //       vsync: this,
// // //     );
// // //     _scaleController = AnimationController(
// // //       duration: const Duration(milliseconds: 800),
// // //       vsync: this,
// // //     );
// // //
// // //     _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
// // //     _slideAnimation = Tween<Offset>(
// // //       begin: const Offset(0, 0.3),
// // //       end: Offset.zero,
// // //     ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
// // //     _counterAnimation = CurvedAnimation(parent: _counterController, curve: Curves.easeOutQuart);
// // //     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08)
// // //         .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
// // //     _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _fadeController.dispose();
// // //     _slideController.dispose();
// // //     _counterController.dispose();
// // //     _pulseController.dispose();
// // //     _scaleController.dispose();
// // //     _nameController.dispose();
// // //     _emailController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   // ✅ MODERN RESPONSIVE SYSTEM
// // //   double _getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;
// // //   double _getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;
// // //
// // //   bool _isSmallMobile(BuildContext context) => _getScreenWidth(context) < 360;
// // //   bool _isMobile(BuildContext context) => _getScreenWidth(context) < 600;
// // //   bool _isTablet(BuildContext context) => _getScreenWidth(context) >= 600 && _getScreenWidth(context) < 1024;
// // //   bool _isDesktop(BuildContext context) => _getScreenWidth(context) >= 1024;
// // //
// // //   // ✅ MODERN TYPOGRAPHY SYSTEM
// // //   double _getHeadingSize(BuildContext context) {
// // //     if (_isSmallMobile(context)) return 20;
// // //     if (_isMobile(context)) return 24;
// // //     if (_isTablet(context)) return 28;
// // //     return 32;
// // //   }
// // //
// // //   double _getSubheadingSize(BuildContext context) {
// // //     if (_isSmallMobile(context)) return 16;
// // //     if (_isMobile(context)) return 18;
// // //     if (_isTablet(context)) return 20;
// // //     return 22;
// // //   }
// // //
// // //   double _getBodySize(BuildContext context) {
// // //     if (_isSmallMobile(context)) return 12;
// // //     if (_isMobile(context)) return 14;
// // //     if (_isTablet(context)) return 15;
// // //     return 16;
// // //   }
// // //
// // //   double _getCaptionSize(BuildContext context) {
// // //     if (_isSmallMobile(context)) return 10;
// // //     if (_isMobile(context)) return 11;
// // //     if (_isTablet(context)) return 12;
// // //     return 13;
// // //   }
// // //
// // //   // ✅ MODERN SPACING SYSTEM
// // //   double _getSpaceXS(BuildContext context) => _isMobile(context) ? 4 : 6;
// // //   double _getSpaceS(BuildContext context) => _isMobile(context) ? 8 : 12;
// // //   double _getSpaceM(BuildContext context) => _isMobile(context) ? 16 : 20;
// // //   double _getSpaceL(BuildContext context) => _isMobile(context) ? 24 : 32;
// // //   double _getSpaceXL(BuildContext context) => _isMobile(context) ? 32 : 48;
// // //
// // //   // ✅ MODERN PADDING SYSTEM
// // //   EdgeInsets _getPaddingS(BuildContext context) => EdgeInsets.all(_getSpaceS(context));
// // //   EdgeInsets _getPaddingM(BuildContext context) => EdgeInsets.all(_getSpaceM(context));
// // //   EdgeInsets _getPaddingL(BuildContext context) => EdgeInsets.all(_getSpaceL(context));
// // //
// // //   EdgeInsets _getPaddingHorizontal(BuildContext context, double multiplier) =>
// // //       EdgeInsets.symmetric(horizontal: _getSpaceM(context) * multiplier);
// // //
// // //   EdgeInsets _getPaddingVertical(BuildContext context, double multiplier) =>
// // //       EdgeInsets.symmetric(vertical: _getSpaceM(context) * multiplier);
// // //
// // //   // ✅ MODERN BORDER RADIUS SYSTEM
// // //   double _getRadiusS() => 8;
// // //   double _getRadiusM() => 16;
// // //   double _getRadiusL() => 24;
// // //   double _getRadiusXL() => 32;
// // //
// // //   // ✅ GRID SYSTEM FOR NEW LAYOUT
// // //   int _getStatsColumns(BuildContext context) {
// // //     if (_isSmallMobile(context)) return 2;
// // //     if (_isMobile(context)) return 2;
// // //     if (_isTablet(context)) return 4;
// // //     return 4;
// // //   }
// // //
// // //   double _getStatsAspectRatio(BuildContext context) {
// // //     if (_isSmallMobile(context)) return 1.4;
// // //     if (_isMobile(context)) return 1.2;
// // //     return 1.0;
// // //   }
// // //
// // //   // ✅ MODERN COLOR PALETTE
// // //   Color get primaryColor => const Color(0xFF6366F1); // Indigo
// // //   Color get primaryLight => const Color(0xFF818CF8);
// // //   Color get primaryDark => const Color(0xFF4F46E5);
// // //
// // //   Color get accentColor => const Color(0xFF06B6D4); // Cyan
// // //   Color get accentLight => const Color(0xFF22D3EE);
// // //   Color get accentDark => const Color(0xFF0891B2);
// // //
// // //   Color get successColor => const Color(0xFF10B981);
// // //   Color get warningColor => const Color(0xFFF59E0B);
// // //   Color get errorColor => const Color(0xFFEF4444);
// // //
// // //   Color get surfaceColor => const Color(0xFF1E293B);
// // //   Color get surfaceLight => const Color(0xFF334155);
// // //   Color get surfaceDark => const Color(0xFF0F172A);
// // //
// // //   Color get textPrimary => Colors.white;
// // //   Color get textSecondary => Colors.white.withOpacity(0.8);
// // //   Color get textTertiary => Colors.white.withOpacity(0.6);
// // //
// // //   // Level styling methods (updated for new design)
// // //   Color _getLevelColor() {
// // //     switch (userLevel) {
// // //       case 'Expert': return const Color(0xFF8B5CF6); // Purple
// // //       case 'Advanced': return const Color(0xFF06B6D4); // Cyan
// // //       case 'Intermediate': return const Color(0xFF3B82F6); // Blue
// // //       case 'Beginner': return const Color(0xFFF59E0B); // Amber
// // //       default: return const Color(0xFF6B7280); // Gray
// // //     }
// // //   }
// // //
// // //   IconData _getLevelIcon() {
// // //     switch (userLevel) {
// // //       case 'Expert': return Icons.emoji_events; // Trophy
// // //       case 'Advanced': return Icons.military_tech; // Medal
// // //       case 'Intermediate': return Icons.star; // Star
// // //       case 'Beginner': return Icons.trending_up; // Arrow up
// // //       default: return Icons.circle; // Dot
// // //     }
// // //   }
// // //
// // //   String _calculateUserLevel(int points) {
// // //     if (points >= 5000) return 'Expert';
// // //     if (points >= 3000) return 'Advanced';
// // //     if (points >= 1500) return 'Intermediate';
// // //     if (points >= 500) return 'Beginner';
// // //     return 'Rookie';
// // //   }
// // //
// // //   // Helper methods
// // //   Uint8List _base64ToImage(String base64String) {
// // //     return base64Decode(base64String);
// // //   }
// // //
// // //   bool _isValidEmail(String email) {
// // //     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
// // //   }
// // //
// // //   // ✅ MODERN SNACKBAR SYSTEM
// // //   void _showSuccessSnackBar(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Container(
// // //           padding: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
// // //           child: Row(
// // //             children: [
// // //               Container(
// // //                 padding: EdgeInsets.all(_getSpaceXS(context)),
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.white.withOpacity(0.2),
// // //                   shape: BoxShape.circle,
// // //                 ),
// // //                 child: Icon(Icons.check_circle, color: Colors.white, size: 20),
// // //               ),
// // //               SizedBox(width: _getSpaceS(context)),
// // //               Expanded(
// // //                 child: Text(
// // //                   message,
// // //                   style: TextStyle(
// // //                     fontWeight: FontWeight.w600,
// // //                     fontSize: _getBodySize(context),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //         backgroundColor: successColor,
// // //         behavior: SnackBarBehavior.floating,
// // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getRadiusM())),
// // //         margin: EdgeInsets.all(_getSpaceM(context)),
// // //         elevation: 8,
// // //       ),
// // //     );
// // //   }
// // //
// // //   void _showErrorSnackBar(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Container(
// // //           padding: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
// // //           child: Row(
// // //             children: [
// // //               Container(
// // //                 padding: EdgeInsets.all(_getSpaceXS(context)),
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.white.withOpacity(0.2),
// // //                   shape: BoxShape.circle,
// // //                 ),
// // //                 child: Icon(Icons.error, color: Colors.white, size: 20),
// // //               ),
// // //               SizedBox(width: _getSpaceS(context)),
// // //               Expanded(
// // //                 child: Text(
// // //                   message,
// // //                   style: TextStyle(
// // //                     fontWeight: FontWeight.w600,
// // //                     fontSize: _getBodySize(context),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //         backgroundColor: errorColor,
// // //         behavior: SnackBarBehavior.floating,
// // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getRadiusM())),
// // //         margin: EdgeInsets.all(_getSpaceM(context)),
// // //         elevation: 8,
// // //       ),
// // //     );
// // //   }
// // //
// // //   void _redirectToLogin() {
// // //     if (mounted) {
// // //       Navigator.pushAndRemoveUntil(
// // //         context,
// // //         MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
// // //             (route) => false,
// // //       );
// // //     }
// // //   }
// // //   // ✅ DATA LOADING METHODS (Same functionality, updated animations)
// // //
// // //   Future<void> _loadUserData() async {
// // //     try {
// // //       final user = FirebaseAuth.instance.currentUser;
// // //       if (user == null) {
// // //         _redirectToLogin();
// // //         return;
// // //       }
// // //
// // //       final userDoc = await FirebaseFirestore.instance
// // //           .collection('users')
// // //           .doc(user.uid)
// // //           .get();
// // //
// // //       if (userDoc.exists && mounted) {
// // //         final userData = userDoc.data()!;
// // //         setState(() {
// // //           userName = userData['fullName'] ?? 'Unknown User';
// // //           userEmail = userData['email'] ?? user.email ?? '';
// // //           _nameController.text = userName;
// // //           _emailController.text = userEmail;
// // //         });
// // //
// // //         await Future.wait([
// // //           _loadProfileImage(),
// // //           _loadUserStats(),
// // //         ]);
// // //
// // //         if (mounted) {
// // //           // Start new animation sequence
// // //           _fadeController.forward();
// // //           await Future.delayed(const Duration(milliseconds: 200));
// // //           _slideController.forward();
// // //           await Future.delayed(const Duration(milliseconds: 300));
// // //           _scaleController.forward();
// // //           await Future.delayed(const Duration(milliseconds: 200));
// // //           _counterController.forward();
// // //           _pulseController.repeat(reverse: true);
// // //         }
// // //
// // //         setState(() {
// // //           isLoading = false;
// // //         });
// // //       } else {
// // //         _redirectToLogin();
// // //       }
// // //     } catch (e) {
// // //       if (mounted) {
// // //         setState(() {
// // //           isLoading = false;
// // //         });
// // //         _showErrorSnackBar('Failed to load profile data');
// // //       }
// // //     }
// // //   }
// // //
// // //   Future<void> _loadUserStats() async {
// // //     try {
// // //       final prefs = await SharedPreferences.getInstance();
// // //       final user = FirebaseAuth.instance.currentUser;
// // //       if (user == null) return;
// // //
// // //       final userId = user.uid;
// // //       final points = prefs.getInt('${userId}_user_points') ?? 0;
// // //       final quizCount = prefs.getInt('${userId}_quizzes_taken') ?? 0;
// // //       final bestScore = prefs.getInt('${userId}_best_score') ?? 0;
// // //
// // //       // Count notes from multiple sources
// // //       int totalNotesCount = 0;
// // //       int linksCount = 0;
// // //       int videosCount = 0;
// // //
// // //       final savedNotesJson = prefs.getStringList('${userId}_saved_notes') ?? [];
// // //       totalNotesCount += savedNotesJson.length;
// // //
// // //       for (final noteString in savedNotesJson) {
// // //         try {
// // //           if (noteString.contains('http') || noteString.contains('www.')) {
// // //             linksCount++;
// // //           }
// // //         } catch (e) {
// // //           debugPrint('Error parsing saved note: $e');
// // //         }
// // //       }
// // //
// // //       final codingNotesJson = prefs.getStringList('${userId}_coding_notes') ?? [];
// // //       totalNotesCount += codingNotesJson.length;
// // //
// // //       final personalNotesJson = prefs.getStringList('${userId}_personal_notes') ?? [];
// // //       totalNotesCount += personalNotesJson.length;
// // //
// // //       final studyNotesJson = prefs.getStringList('${userId}_study_notes') ?? [];
// // //       totalNotesCount += studyNotesJson.length;
// // //
// // //       final savedVideosJson = prefs.getStringList('${userId}_saved_videos') ?? [];
// // //       final bookmarkedVideosJson = prefs.getStringList('${userId}_bookmarked_videos') ?? [];
// // //       videosCount = savedVideosJson.length + bookmarkedVideosJson.length;
// // //
// // //       final savedLinksJson = prefs.getStringList('${userId}_saved_links') ?? [];
// // //       final bookmarkedLinksJson = prefs.getStringList('${userId}_bookmarked_links') ?? [];
// // //       linksCount += savedLinksJson.length + bookmarkedLinksJson.length;
// // //
// // //       final level = _calculateUserLevel(points);
// // //
// // //       if (mounted) {
// // //         setState(() {
// // //           userPoints = points;
// // //           quizzesTaken = quizCount;
// // //           bestQuizScore = bestScore;
// // //           notesCount = totalNotesCount;
// // //           savedVideosCount = videosCount;
// // //           savedLinksCount = linksCount;
// // //           userLevel = level;
// // //         });
// // //       }
// // //     } catch (e) {
// // //       debugPrint('❌ Error loading user stats: $e');
// // //       if (mounted) {
// // //         setState(() {
// // //           userPoints = 0;
// // //           notesCount = 0;
// // //           savedVideosCount = 0;
// // //           savedLinksCount = 0;
// // //           quizzesTaken = 0;
// // //           bestQuizScore = 0;
// // //           userLevel = 'Rookie';
// // //         });
// // //       }
// // //     }
// // //   }
// // //
// // //   Future<void> _loadProfileImage() async {
// // //     try {
// // //       final prefs = await SharedPreferences.getInstance();
// // //       final user = FirebaseAuth.instance.currentUser;
// // //       if (user != null) {
// // //         final imageKey = 'profile_image_${user.uid}';
// // //         final savedImageBase64 = prefs.getString(imageKey);
// // //         if (savedImageBase64 != null && savedImageBase64.isNotEmpty && mounted) {
// // //           setState(() {
// // //             profileImageBase64 = savedImageBase64;
// // //           });
// // //         }
// // //       }
// // //     } catch (e) {
// // //       debugPrint('Error loading profile image: $e');
// // //     }
// // //   }
// // //
// // //   Future<void> _refreshData() async {
// // //     setState(() {
// // //       isLoading = true;
// // //     });
// // //
// // //     // Reset animations
// // //     _counterController.reset();
// // //     _scaleController.reset();
// // //
// // //     await Future.wait([
// // //       _loadUserStats(),
// // //       _loadProfileImage(),
// // //     ]);
// // //
// // //     if (mounted) {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //
// // //       // Restart animations
// // //       _counterController.forward();
// // //       _scaleController.forward();
// // //
// // //       _showSuccessSnackBar('Profile data refreshed!');
// // //     }
// // //   }
// // //
// // //   // ✅ IMAGE HANDLING METHODS
// // //
// // //   Future<void> _pickImage() async {
// // //     try {
// // //       final XFile? image = await _picker.pickImage(
// // //         source: ImageSource.gallery,
// // //         maxWidth: 512,
// // //         maxHeight: 512,
// // //         imageQuality: 85,
// // //       );
// // //
// // //       if (image != null) {
// // //         setState(() {
// // //           _profileImage = File(image.path);
// // //           isUploadingImage = true;
// // //         });
// // //
// // //         await _saveProfileImageLocally(File(image.path));
// // //       }
// // //     } catch (e) {
// // //       _showErrorSnackBar('Failed to pick image: Please try again');
// // //     }
// // //   }
// // //
// // //   Future<void> _saveProfileImageLocally(File imageFile) async {
// // //     try {
// // //       final user = FirebaseAuth.instance.currentUser;
// // //       if (user == null) return;
// // //
// // //       final bytes = await imageFile.readAsBytes();
// // //       final base64String = base64Encode(bytes);
// // //
// // //       final prefs = await SharedPreferences.getInstance();
// // //       final imageKey = 'profile_image_${user.uid}';
// // //       await prefs.setString(imageKey, base64String);
// // //
// // //       if (mounted) {
// // //         setState(() {
// // //           profileImageBase64 = base64String;
// // //           isUploadingImage = false;
// // //         });
// // //         _showSuccessSnackBar('Profile image updated successfully!');
// // //       }
// // //     } catch (e) {
// // //       if (mounted) {
// // //         setState(() {
// // //           isUploadingImage = false;
// // //           _profileImage = null;
// // //         });
// // //         _showErrorSnackBar('Failed to save image');
// // //       }
// // //     }
// // //   }
// // //
// // //   // ✅ PROFILE UPDATE METHODS
// // //
// // //   Future<void> _updateProfile() async {
// // //     final name = _nameController.text.trim();
// // //     final email = _emailController.text.trim();
// // //     final currentUser = FirebaseAuth.instance.currentUser;
// // //
// // //     if (name.isEmpty) {
// // //       _showErrorSnackBar('Name cannot be empty');
// // //       return;
// // //     }
// // //
// // //     if (!_isValidEmail(email)) {
// // //       _showErrorSnackBar('Please enter a valid email address');
// // //       return;
// // //     }
// // //
// // //     if (currentUser == null) return;
// // //
// // //     try {
// // //       setState(() {
// // //         isLoading = true;
// // //       });
// // //
// // //       final emailChanged = currentUser.email != email;
// // //
// // //       if (emailChanged) {
// // //         await _handleEmailChange(email, name);
// // //       } else {
// // //         await _updateNameOnly(name);
// // //       }
// // //
// // //     } catch (e) {
// // //       if (mounted) {
// // //         setState(() {
// // //           isLoading = false;
// // //         });
// // //         _showErrorSnackBar('Failed to update profile');
// // //       }
// // //     }
// // //   }
// // //
// // //   Future<void> _updateNameOnly(String name) async {
// // //     final user = FirebaseAuth.instance.currentUser;
// // //     if (user != null) {
// // //       await FirebaseFirestore.instance
// // //           .collection('users')
// // //           .doc(user.uid)
// // //           .update({
// // //         'fullName': name,
// // //         'updatedAt': FieldValue.serverTimestamp(),
// // //       });
// // //
// // //       await user.updateDisplayName(name);
// // //
// // //       if (mounted) {
// // //         setState(() {
// // //           userName = name;
// // //           isEditing = false;
// // //           isLoading = false;
// // //         });
// // //         _showSuccessSnackBar('Name updated successfully!');
// // //       }
// // //     }
// // //   }
// // //
// // //   Future<void> _handleEmailChange(String newEmail, String name) async {
// // //     try {
// // //       setState(() {
// // //         isLoading = false;
// // //         isEditing = false;
// // //       });
// // //
// // //       final result = await Navigator.push(
// // //         context,
// // //         MaterialPageRoute(
// // //           builder: (context) => EmailChangeVerificationScreen(
// // //             currentEmail: userEmail,
// // //             newEmail: newEmail,
// // //             userName: name,
// // //           ),
// // //         ),
// // //       );
// // //
// // //       if (result == true) {
// // //         await _loadUserData();
// // //         _showSuccessSnackBar('Email updated successfully!');
// // //       } else {
// // //         _emailController.text = userEmail;
// // //       }
// // //     } catch (e) {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //       _emailController.text = userEmail;
// // //       _showErrorSnackBar('Failed to initiate email change');
// // //     }
// // //   }
// // //
// // //   void _cancelEditing() {
// // //     setState(() {
// // //       _nameController.text = userName;
// // //       _emailController.text = userEmail;
// // //       isEditing = false;
// // //     });
// // //   }
// // //
// // //   // ✅ LEVEL PROGRESS CALCULATIONS
// // //
// // //   String _getNextLevelInfo() {
// // //     final nextPoints = _getNextLevelPoints();
// // //
// // //     if (userLevel == 'Expert') {
// // //       return 'Congratulations! You\'ve reached the highest level! 🏆';
// // //     }
// // //
// // //     final needed = nextPoints - userPoints;
// // //     final nextLevel = _getNextLevelName();
// // //
// // //     return '$needed points to $nextLevel';
// // //   }
// // //
// // //   String _getNextLevelName() {
// // //     switch (userLevel) {
// // //       case 'Rookie': return 'Beginner';
// // //       case 'Beginner': return 'Intermediate';
// // //       case 'Intermediate': return 'Advanced';
// // //       case 'Advanced': return 'Expert';
// // //       default: return 'Expert';
// // //     }
// // //   }
// // //
// // //   int _getNextLevelPoints() {
// // //     switch (userLevel) {
// // //       case 'Rookie': return 500;
// // //       case 'Beginner': return 1500;
// // //       case 'Intermediate': return 3000;
// // //       case 'Advanced': return 5000;
// // //       default: return 5000;
// // //     }
// // //   }
// // //
// // //   int _getCurrentLevelPoints() {
// // //     switch (userLevel) {
// // //       case 'Rookie': return 0;
// // //       case 'Beginner': return 500;
// // //       case 'Intermediate': return 1500;
// // //       case 'Advanced': return 3000;
// // //       case 'Expert': return 5000;
// // //       default: return 0;
// // //     }
// // //   }
// // //
// // //   double _getLevelProgress() {
// // //     if (userLevel == 'Expert') return 1.0;
// // //
// // //     final nextPoints = _getNextLevelPoints();
// // //     final currentPoints = _getCurrentLevelPoints();
// // //     final progress = ((userPoints - currentPoints) / (nextPoints - currentPoints)).clamp(0.0, 1.0);
// // //
// // //     return progress;
// // //   }
// // //
// // //   // ✅ LOGOUT DIALOG
// // //
// // //   Future<void> _showLogoutDialog() async {
// // //     return showDialog<void>(
// // //       context: context,
// // //       barrierDismissible: true,
// // //       barrierColor: Colors.black.withOpacity(0.8),
// // //       builder: (BuildContext context) {
// // //         return _ModernLogoutDialog();
// // //       },
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: surfaceDark,
// // //       body: SafeArea(
// // //         child: isLoading ? _buildModernLoadingState() : _buildModernMainContent(),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ MODERN LOADING STATE - Glassmorphism Design
// // //   Widget _buildModernLoadingState() {
// // //     return Container(
// // //       decoration: BoxDecoration(
// // //         gradient: LinearGradient(
// // //           begin: Alignment.topLeft,
// // //           end: Alignment.bottomRight,
// // //           colors: [
// // //             surfaceDark,
// // //             surfaceColor,
// // //             surfaceLight.withOpacity(0.8),
// // //           ],
// // //         ),
// // //       ),
// // //       child: Center(
// // //         child: Container(
// // //           padding: EdgeInsets.all(_getSpaceXL(context)),
// // //           decoration: BoxDecoration(
// // //             color: Colors.white.withOpacity(0.1),
// // //             borderRadius: BorderRadius.circular(_getRadiusXL()),
// // //             border: Border.all(
// // //               color: Colors.white.withOpacity(0.2),
// // //               width: 1,
// // //             ),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.black.withOpacity(0.3),
// // //                 blurRadius: 30,
// // //                 offset: const Offset(0, 10),
// // //               ),
// // //             ],
// // //           ),
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               // Modern loading spinner
// // //               Container(
// // //                 width: 80,
// // //                 height: 80,
// // //                 decoration: BoxDecoration(
// // //                   gradient: LinearGradient(
// // //                     colors: [primaryColor, accentColor],
// // //                   ),
// // //                   shape: BoxShape.circle,
// // //                   boxShadow: [
// // //                     BoxShadow(
// // //                       color: primaryColor.withOpacity(0.4),
// // //                       blurRadius: 20,
// // //                       spreadRadius: 5,
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 child: const CircularProgressIndicator(
// // //                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// // //                   strokeWidth: 3,
// // //                 ),
// // //               ),
// // //               SizedBox(height: _getSpaceL(context)),
// // //               // Loading text
// // //               Text(
// // //                 'Loading your profile...',
// // //                 style: TextStyle(
// // //                   color: textPrimary,
// // //                   fontSize: _getSubheadingSize(context),
// // //                   fontWeight: FontWeight.w600,
// // //                 ),
// // //               ),
// // //               SizedBox(height: _getSpaceS(context)),
// // //               Text(
// // //                 'Please wait a moment',
// // //                 style: TextStyle(
// // //                   color: textSecondary,
// // //                   fontSize: _getBodySize(context),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ MODERN MAIN CONTENT - New Layout Structure
// // //   Widget _buildModernMainContent() {
// // //     return Container(
// // //       decoration: BoxDecoration(
// // //         gradient: LinearGradient(
// // //           begin: Alignment.topLeft,
// // //           end: Alignment.bottomRight,
// // //           colors: [
// // //             surfaceDark,
// // //             surfaceColor,
// // //             surfaceLight.withOpacity(0.5),
// // //           ],
// // //         ),
// // //       ),
// // //       child: FadeTransition(
// // //         opacity: _fadeAnimation,
// // //         child: CustomScrollView(
// // //           physics: const ClampingScrollPhysics(),
// // //           slivers: [
// // //             _buildModernAppBar(),
// // //             SliverPadding(
// // //               padding: EdgeInsets.only(
// // //                 left: _getSpaceM(context),
// // //                 right: _getSpaceM(context),
// // //                 bottom: MediaQuery.of(context).padding.bottom + _getSpaceXL(context),
// // //               ),
// // //               sliver: SliverList(
// // //                 delegate: SliverChildListDelegate([
// // //                   SizedBox(height: _getSpaceM(context)),
// // //                   _buildHeroProfileCard(),
// // //                   SizedBox(height: _getSpaceL(context)),
// // //                   _buildPointsAndLevelRow(),
// // //                   SizedBox(height: _getSpaceL(context)),
// // //                   _buildModernStatsGrid(),
// // //                   SizedBox(height: _getSpaceL(context)),
// // //                   _buildQuickActionsCard(),
// // //                   SizedBox(height: _getSpaceL(context)),
// // //                   _buildModernLearningJourney(),
// // //                   SizedBox(height: _getSpaceL(context)),
// // //                   _buildModernAccountSettings(),
// // //                   SizedBox(height: _getSpaceXL(context)),
// // //                 ]),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildPointsAndLevelRow() {
// // //     final screenWidth = MediaQuery.of(context).size.width;
// // //     final useColumnLayout = screenWidth < 500;
// // //
// // //     if (useColumnLayout) {
// // //       return Column(
// // //         children: [
// // //           _buildPointsCard(),
// // //           SizedBox(height: _getSpaceM(context)),
// // //           _buildLevelCard(),
// // //         ],
// // //       );
// // //     }
// // //
// // //     return Row(
// // //       children: [
// // //         Expanded(child: _buildPointsCard()),
// // //         SizedBox(width: _getSpaceM(context)),
// // //         Expanded(child: _buildLevelCard()),
// // //       ],
// // //     );
// // //   }
// // //
// // //   // ✅ MODERN APP BAR - Glassmorphism Style
// // //   Widget _buildModernAppBar() {
// // //     return SliverAppBar(
// // //       expandedHeight: _isMobile(context) ? 100 : 120,
// // //       floating: true,
// // //       pinned: true,
// // //       elevation: 0,
// // //       backgroundColor: Colors.transparent,
// // //       automaticallyImplyLeading: false,
// // //       flexibleSpace: Container(
// // //         decoration: BoxDecoration(
// // //           gradient: LinearGradient(
// // //             begin: Alignment.topLeft,
// // //             end: Alignment.bottomRight,
// // //             colors: [
// // //               surfaceColor.withOpacity(0.9),
// // //               surfaceLight.withOpacity(0.7),
// // //             ],
// // //           ),
// // //           border: Border(
// // //             bottom: BorderSide(
// // //               color: Colors.white.withOpacity(0.1),
// // //               width: 1,
// // //             ),
// // //           ),
// // //         ),
// // //         child: BackdropFilter(
// // //           filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
// // //           child: Container(
// // //             padding: _getPaddingHorizontal(context, 1),
// // //             child: SafeArea(
// // //               child: Row(
// // //                 children: [
// // //                   // Back Button
// // //                   Container(
// // //                     decoration: BoxDecoration(
// // //                       color: Colors.white.withOpacity(0.1),
// // //                       borderRadius: BorderRadius.circular(_getRadiusM()),
// // //                       border: Border.all(
// // //                         color: Colors.white.withOpacity(0.2),
// // //                       ),
// // //                     ),
// // //                     child: IconButton(
// // //                       onPressed: () => Navigator.of(context).pop(),
// // //                       icon: Icon(
// // //                         Icons.arrow_back_ios_new,
// // //                         color: textPrimary,
// // //                         size: 20,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   SizedBox(width: _getSpaceM(context)),
// // //
// // //                   // Title
// // //                   Expanded(
// // //                     child: Column(
// // //                       mainAxisAlignment: MainAxisAlignment.center,
// // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // //                       children: [
// // //                         Text(
// // //                           'Profile',
// // //                           style: TextStyle(
// // //                             color: textPrimary,
// // //                             fontSize: _getHeadingSize(context),
// // //                             fontWeight: FontWeight.bold,
// // //                           ),
// // //                         ),
// // //                         Text(
// // //                           'Manage your learning profile',
// // //                           style: TextStyle(
// // //                             color: textSecondary,
// // //                             fontSize: _getCaptionSize(context),
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //
// // //                   // Refresh Button
// // //                   Container(
// // //                     decoration: BoxDecoration(
// // //                       gradient: LinearGradient(
// // //                         colors: [primaryColor, accentColor],
// // //                       ),
// // //                       borderRadius: BorderRadius.circular(_getRadiusM()),
// // //                       boxShadow: [
// // //                         BoxShadow(
// // //                           color: primaryColor.withOpacity(0.3),
// // //                           blurRadius: 8,
// // //                           offset: const Offset(0, 2),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                     child: IconButton(
// // //                       onPressed: _refreshData,
// // //                       icon: Icon(
// // //                         Icons.refresh,
// // //                         color: textPrimary,
// // //                         size: 20,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ HERO PROFILE CARD - Completely New Design
// // //   Widget _buildHeroProfileCard() {
// // //     return Container(
// // //       width: double.infinity,
// // //       padding: _getPaddingL(context),
// // //       decoration: BoxDecoration(
// // //         gradient: LinearGradient(
// // //           begin: Alignment.topLeft,
// // //           end: Alignment.bottomRight,
// // //           colors: [
// // //             Colors.white.withOpacity(0.15),
// // //             Colors.white.withOpacity(0.05),
// // //           ],
// // //         ),
// // //         borderRadius: BorderRadius.circular(_getRadiusL()),
// // //         border: Border.all(
// // //           color: Colors.white.withOpacity(0.2),
// // //           width: 1,
// // //         ),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withOpacity(0.2),
// // //             blurRadius: 20,
// // //             offset: const Offset(0, 10),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         children: [
// // //           // Profile Image with Level Ring
// // //           Stack(
// // //             alignment: Alignment.center,
// // //             children: [
// // //               // Animated level ring
// // //               Container(
// // //                 width: 120,
// // //                 height: 120,
// // //                 decoration: BoxDecoration(
// // //                   shape: BoxShape.circle,
// // //                   gradient: LinearGradient(
// // //                     colors: [
// // //                       _getLevelColor(),
// // //                       _getLevelColor().withOpacity(0.6),
// // //                     ],
// // //                   ),
// // //                 ),
// // //                 child: AnimatedBuilder(
// // //                   animation: _pulseAnimation,
// // //                   builder: (context, child) {
// // //                     return Transform.scale(
// // //                       scale: _pulseAnimation.value,
// // //                       child: Container(
// // //                         decoration: BoxDecoration(
// // //                           shape: BoxShape.circle,
// // //                           border: Border.all(
// // //                             color: _getLevelColor().withOpacity(0.3),
// // //                             width: 2,
// // //                           ),
// // //                         ),
// // //                       ),
// // //                     );
// // //                   },
// // //                 ),
// // //               ),
// // //
// // //               // Profile Image
// // //               Container(
// // //                 width: 100,
// // //                 height: 100,
// // //                 decoration: BoxDecoration(
// // //                   shape: BoxShape.circle,
// // //                   color: Colors.white,
// // //                   boxShadow: [
// // //                     BoxShadow(
// // //                       color: Colors.black.withOpacity(0.2),
// // //                       blurRadius: 15,
// // //                       offset: const Offset(0, 5),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 child: ClipOval(
// // //                   child: _profileImage != null
// // //                       ? Image.file(_profileImage!, fit: BoxFit.cover)
// // //                       : (profileImageBase64.isNotEmpty
// // //                       ? Image.memory(_base64ToImage(profileImageBase64), fit: BoxFit.cover)
// // //                       : Container(
// // //                     decoration: BoxDecoration(
// // //                       gradient: LinearGradient(
// // //                         colors: [primaryColor, accentColor],
// // //                       ),
// // //                     ),
// // //                     child: Center(
// // //                       child: Text(
// // //                         userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
// // //                         style: TextStyle(
// // //                           fontSize: _getHeadingSize(context),
// // //                           fontWeight: FontWeight.bold,
// // //                           color: textPrimary,
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   )),
// // //                 ),
// // //               ),
// // //
// // //               // Camera Button
// // //               Positioned(
// // //                 bottom: 0,
// // //                 right: 5,
// // //                 child: GestureDetector(
// // //                   onTap: isUploadingImage ? null : _pickImage,
// // //                   child: Container(
// // //                     padding: EdgeInsets.all(_getSpaceS(context)),
// // //                     decoration: BoxDecoration(
// // //                       gradient: LinearGradient(
// // //                         colors: [primaryColor, accentColor],
// // //                       ),
// // //                       shape: BoxShape.circle,
// // //                       border: Border.all(color: Colors.white, width: 3),
// // //                       boxShadow: [
// // //                         BoxShadow(
// // //                           color: primaryColor.withOpacity(0.4),
// // //                           blurRadius: 10,
// // //                           offset: const Offset(0, 3),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                     child: Icon(
// // //                       isUploadingImage ? Icons.hourglass_empty : Icons.camera_alt,
// // //                       size: 16,
// // //                       color: textPrimary,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //
// // //           SizedBox(height: _getSpaceL(context)),
// // //
// // //           // User Info
// // //           Column(
// // //             children: [
// // //               // Name
// // //               Text(
// // //                 userName,
// // //                 style: TextStyle(
// // //                   fontSize: _getHeadingSize(context),
// // //                   fontWeight: FontWeight.bold,
// // //                   color: textPrimary,
// // //                 ),
// // //                 textAlign: TextAlign.center,
// // //                 maxLines: 2,
// // //                 overflow: TextOverflow.ellipsis,
// // //               ),
// // //               SizedBox(height: _getSpaceS(context)),
// // //
// // //               // Email
// // //               Container(
// // //                 padding: EdgeInsets.symmetric(
// // //                   horizontal: _getSpaceM(context),
// // //                   vertical: _getSpaceS(context),
// // //                 ),
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.white.withOpacity(0.1),
// // //                   borderRadius: BorderRadius.circular(_getRadiusL()),
// // //                   border: Border.all(
// // //                     color: Colors.white.withOpacity(0.2),
// // //                   ),
// // //                 ),
// // //                 child: Text(
// // //                   userEmail,
// // //                   style: TextStyle(
// // //                     fontSize: _getBodySize(context),
// // //                     color: textSecondary,
// // //                   ),
// // //                   textAlign: TextAlign.center,
// // //                   maxLines: 1,
// // //                   overflow: TextOverflow.ellipsis,
// // //                 ),
// // //               ),
// // //               SizedBox(height: _getSpaceL(context)),
// // //
// // //               // Level Badge
// // //               Container(
// // //                 padding: EdgeInsets.symmetric(
// // //                   horizontal: _getSpaceL(context),
// // //                   vertical: _getSpaceM(context),
// // //                 ),
// // //                 decoration: BoxDecoration(
// // //                   gradient: LinearGradient(
// // //                     colors: [_getLevelColor(), _getLevelColor().withOpacity(0.7)],
// // //                   ),
// // //                   borderRadius: BorderRadius.circular(_getRadiusL()),
// // //                   boxShadow: [
// // //                     BoxShadow(
// // //                       color: _getLevelColor().withOpacity(0.4),
// // //                       blurRadius: 15,
// // //                       offset: const Offset(0, 5),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 child: Row(
// // //                   mainAxisSize: MainAxisSize.min,
// // //                   children: [
// // //                     Icon(
// // //                       _getLevelIcon(),
// // //                       color: textPrimary,
// // //                       size: 20,
// // //                     ),
// // //                     SizedBox(width: _getSpaceS(context)),
// // //                     Text(
// // //                       userLevel,
// // //                       style: TextStyle(
// // //                         fontSize: _getSubheadingSize(context),
// // //                         fontWeight: FontWeight.bold,
// // //                         color: textPrimary,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ MODERN POINTS CARD - New Glassmorphism Design
// // //   Widget _buildPointsCard() {
// // //     return AnimatedBuilder(
// // //       animation: _counterAnimation,
// // //       builder: (context, child) {
// // //         final animatedPoints = (userPoints * _counterAnimation.value).round();
// // //
// // //         return Container(
// // //           width: double.infinity,
// // //           padding: _getPaddingL(context),
// // //           decoration: BoxDecoration(
// // //             gradient: LinearGradient(
// // //               begin: Alignment.topLeft,
// // //               end: Alignment.bottomRight,
// // //               colors: [
// // //                 primaryColor.withOpacity(0.8),
// // //                 accentColor.withOpacity(0.6),
// // //               ],
// // //             ),
// // //             borderRadius: BorderRadius.circular(_getRadiusL()),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: primaryColor.withOpacity(0.3),
// // //                 blurRadius: 20,
// // //                 offset: const Offset(0, 10),
// // //               ),
// // //             ],
// // //           ),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               // Icon and Label
// // //               Row(
// // //                 children: [
// // //                   Container(
// // //                     padding: EdgeInsets.all(_getSpaceM(context)),
// // //                     decoration: BoxDecoration(
// // //                       color: Colors.white.withOpacity(0.2),
// // //                       borderRadius: BorderRadius.circular(_getRadiusM()),
// // //                     ),
// // //                     child: Icon(
// // //                       Icons.stars_rounded,
// // //                       color: textPrimary,
// // //                       size: 24,
// // //                     ),
// // //                   ),
// // //                   SizedBox(width: _getSpaceM(context)),
// // //                   Expanded(
// // //                     child: Text(
// // //                       'Learning Points',
// // //                       style: TextStyle(
// // //                         fontSize: _getBodySize(context),
// // //                         color: textPrimary.withOpacity(0.9),
// // //                         fontWeight: FontWeight.w600,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //               SizedBox(height: _getSpaceL(context)),
// // //
// // //               // Points Value
// // //               Text(
// // //                 animatedPoints.toString(),
// // //                 style: TextStyle(
// // //                   fontSize: _getHeadingSize(context) * 1.5,
// // //                   fontWeight: FontWeight.bold,
// // //                   color: textPrimary,
// // //                 ),
// // //               ),
// // //               SizedBox(height: _getSpaceS(context)),
// // //
// // //               // Best Score
// // //               if (bestQuizScore > 0)
// // //                 Container(
// // //                   padding: EdgeInsets.symmetric(
// // //                     horizontal: _getSpaceM(context),
// // //                     vertical: _getSpaceS(context),
// // //                   ),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.white.withOpacity(0.2),
// // //                     borderRadius: BorderRadius.circular(_getRadiusS()),
// // //                   ),
// // //                   child: Text(
// // //                     'Best Quiz: $bestQuizScore pts',
// // //                     style: TextStyle(
// // //                       fontSize: _getCaptionSize(context),
// // //                       color: textPrimary.withOpacity(0.8),
// // //                       fontWeight: FontWeight.w500,
// // //                     ),
// // //                   ),
// // //                 ),
// // //             ],
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   // ✅ MODERN LEVEL CARD - Progress Ring Design
// // //   Widget _buildLevelCard() {
// // //     final progress = _getLevelProgress();
// // //
// // //     return Container(
// // //       width: double.infinity,
// // //       padding: _getPaddingL(context),
// // //       decoration: BoxDecoration(
// // //         gradient: LinearGradient(
// // //           begin: Alignment.topLeft,
// // //           end: Alignment.bottomRight,
// // //           colors: [
// // //             _getLevelColor().withOpacity(0.8),
// // //             _getLevelColor().withOpacity(0.4),
// // //           ],
// // //         ),
// // //         borderRadius: BorderRadius.circular(_getRadiusL()),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: _getLevelColor().withOpacity(0.3),
// // //             blurRadius: 20,
// // //             offset: const Offset(0, 10),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         children: [
// // //           // Progress Ring
// // //           Stack(
// // //             alignment: Alignment.center,
// // //             children: [
// // //               SizedBox(
// // //                 width: 80,
// // //                 height: 80,
// // //                 child: CircularProgressIndicator(
// // //                   value: progress,
// // //                   strokeWidth: 6,
// // //                   backgroundColor: Colors.white.withOpacity(0.2),
// // //                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// // //                 ),
// // //               ),
// // //               Column(
// // //                 children: [
// // //                   Icon(
// // //                     _getLevelIcon(),
// // //                     color: textPrimary,
// // //                     size: 24,
// // //                   ),
// // //                   Text(
// // //                     '${(progress * 100).toInt()}%',
// // //                     style: TextStyle(
// // //                       fontSize: _getBodySize(context),
// // //                       fontWeight: FontWeight.bold,
// // //                       color: textPrimary,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ],
// // //           ),
// // //           SizedBox(height: _getSpaceL(context)),
// // //
// // //           // Level Info
// // //           Text(
// // //             userLevel,
// // //             style: TextStyle(
// // //               fontSize: _getSubheadingSize(context),
// // //               fontWeight: FontWeight.bold,
// // //               color: textPrimary,
// // //             ),
// // //           ),
// // //           SizedBox(height: _getSpaceS(context)),
// // //
// // //           Text(
// // //             _getNextLevelInfo(),
// // //             style: TextStyle(
// // //               fontSize: _getCaptionSize(context),
// // //               color: textPrimary.withOpacity(0.8),
// // //             ),
// // //             textAlign: TextAlign.center,
// // //             maxLines: 2,
// // //             overflow: TextOverflow.ellipsis,
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ MODERN STATS GRID - Completely New Design
// // //   Widget _buildModernStatsGrid() {
// // //     return LayoutBuilder(
// // //       builder: (context, constraints) {
// // //         final crossAxisCount = _getStatsColumns(context);
// // //         final aspectRatio = _getStatsAspectRatio(context);
// // //         final spacing = _getSpaceM(context);
// // //
// // //         return GridView.count(
// // //           shrinkWrap: true,
// // //           physics: const NeverScrollableScrollPhysics(),
// // //           crossAxisCount: crossAxisCount,
// // //           childAspectRatio: aspectRatio,
// // //           crossAxisSpacing: spacing,
// // //           mainAxisSpacing: spacing,
// // //           children: [
// // //             _buildModernStatCard(
// // //               icon: Icons.article_outlined,
// // //               title: "Notes",
// // //               value: notesCount.toString(),
// // //               subtitle: "Saved",
// // //               color: const Color(0xFF8B5CF6),
// // //               gradient: [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
// // //             ),
// // //             _buildModernStatCard(
// // //               icon: Icons.play_circle_outline,
// // //               title: "Videos",
// // //               value: savedVideosCount.toString(),
// // //               subtitle: "Bookmarked",
// // //               color: const Color(0xFFEF4444),
// // //               gradient: [const Color(0xFFEF4444), const Color(0xFFF87171)],
// // //             ),
// // //             _buildModernStatCard(
// // //               icon: Icons.link_outlined,
// // //               title: "Links",
// // //               value: savedLinksCount.toString(),
// // //               subtitle: "Resources",
// // //               color: const Color(0xFF3B82F6),
// // //               gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
// // //             ),
// // //             _buildModernStatCard(
// // //               icon: Icons.quiz_outlined,
// // //               title: "Quizzes",
// // //               value: quizzesTaken.toString(),
// // //               subtitle: "Completed",
// // //               color: const Color(0xFF10B981),
// // //               gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
// // //             ),
// // //           ],
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   // ✅ MODERN STAT CARD - Glassmorphism with Animated Numbers
// // //   Widget _buildModernStatCard({
// // //     required IconData icon,
// // //     required String title,
// // //     required String value,
// // //     required String subtitle,
// // //     required Color color,
// // //     required List<Color> gradient,
// // //   }) {
// // //     return AnimatedBuilder(
// // //       animation: _counterAnimation,
// // //       builder: (context, child) {
// // //         final animatedValue = (int.tryParse(value) ?? 0) * _counterAnimation.value;
// // //
// // //         return Container(
// // //           decoration: BoxDecoration(
// // //             gradient: LinearGradient(
// // //               begin: Alignment.topLeft,
// // //               end: Alignment.bottomRight,
// // //               colors: [
// // //                 Colors.white.withOpacity(0.15),
// // //                 Colors.white.withOpacity(0.05),
// // //               ],
// // //             ),
// // //             borderRadius: BorderRadius.circular(_getRadiusL()),
// // //             border: Border.all(
// // //               color: Colors.white.withOpacity(0.2),
// // //               width: 1,
// // //             ),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.black.withOpacity(0.1),
// // //                 blurRadius: 15,
// // //                 offset: const Offset(0, 5),
// // //               ),
// // //             ],
// // //           ),
// // //           child: LayoutBuilder(
// // //             builder: (context, constraints) {
// // //               return Padding(
// // //                 padding: EdgeInsets.all(constraints.maxWidth * 0.08),
// // //                 child: Column(
// // //                   mainAxisAlignment: MainAxisAlignment.center,
// // //                   children: [
// // //                     // Icon with gradient background
// // //                     Container(
// // //                       padding: EdgeInsets.all(constraints.maxWidth * 0.08),
// // //                       decoration: BoxDecoration(
// // //                         gradient: LinearGradient(colors: gradient),
// // //                         borderRadius: BorderRadius.circular(_getRadiusM()),
// // //                         boxShadow: [
// // //                           BoxShadow(
// // //                             color: color.withOpacity(0.3),
// // //                             blurRadius: 10,
// // //                             offset: const Offset(0, 3),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                       child: Icon(
// // //                         icon,
// // //                         color: textPrimary,
// // //                         size: (constraints.maxWidth * 0.15).clamp(16.0, 28.0),
// // //                       ),
// // //                     ),
// // //
// // //                     SizedBox(height: constraints.maxHeight * 0.08),
// // //
// // //                     // Animated Value
// // //                     Flexible(
// // //                       child: FittedBox(
// // //                         fit: BoxFit.scaleDown,
// // //                         child: Text(
// // //                           animatedValue.round().toString(),
// // //                           style: TextStyle(
// // //                             color: textPrimary,
// // //                             fontSize: (constraints.maxWidth * 0.2).clamp(18.0, 32.0),
// // //                             fontWeight: FontWeight.bold,
// // //                           ),
// // //                         ),
// // //                       ),
// // //                     ),
// // //
// // //                     SizedBox(height: constraints.maxHeight * 0.02),
// // //
// // //                     // Title
// // //                     Flexible(
// // //                       child: Text(
// // //                         title,
// // //                         style: TextStyle(
// // //                           color: textSecondary,
// // //                           fontSize: (constraints.maxWidth * 0.08).clamp(10.0, 14.0),
// // //                           fontWeight: FontWeight.w600,
// // //                         ),
// // //                         textAlign: TextAlign.center,
// // //                         maxLines: 1,
// // //                         overflow: TextOverflow.ellipsis,
// // //                       ),
// // //                     ),
// // //
// // //                     // Subtitle
// // //                     Flexible(
// // //                       child: Text(
// // //                         subtitle,
// // //                         style: TextStyle(
// // //                           color: textTertiary,
// // //                           fontSize: (constraints.maxWidth * 0.06).clamp(8.0, 12.0),
// // //                         ),
// // //                         textAlign: TextAlign.center,
// // //                         maxLines: 1,
// // //                         overflow: TextOverflow.ellipsis,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               );
// // //             },
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // //
// // //   // ✅ QUICK ACTIONS CARD - New Modern Design
// // //   Widget _buildQuickActionsCard() {
// // //     return Container(
// // //       width: double.infinity,
// // //       padding: _getPaddingL(context),
// // //       decoration: BoxDecoration(
// // //         gradient: LinearGradient(
// // //           begin: Alignment.topLeft,
// // //           end: Alignment.bottomRight,
// // //           colors: [
// // //             Colors.white.withOpacity(0.15),
// // //             Colors.white.withOpacity(0.05),
// // //           ],
// // //         ),
// // //         borderRadius: BorderRadius.circular(_getRadiusL()),
// // //         border: Border.all(
// // //           color: Colors.white.withOpacity(0.2),
// // //           width: 1,
// // //         ),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withOpacity(0.1),
// // //             blurRadius: 15,
// // //             offset: const Offset(0, 5),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           // Header
// // //           Row(
// // //             children: [
// // //               Container(
// // //                 padding: EdgeInsets.all(_getSpaceM(context)),
// // //                 decoration: BoxDecoration(
// // //                   gradient: LinearGradient(
// // //                     colors: [warningColor, warningColor.withOpacity(0.7)],
// // //                   ),
// // //                   borderRadius: BorderRadius.circular(_getRadiusM()),
// // //                 ),
// // //                 child: Icon(
// // //                   Icons.flash_on,
// // //                   color: textPrimary,
// // //                   size: 20,
// // //                 ),
// // //               ),
// // //               SizedBox(width: _getSpaceM(context)),
// // //               Expanded(
// // //                 child: Text(
// // //                   'Quick Actions',
// // //                   style: TextStyle(
// // //                     fontSize: _getSubheadingSize(context),
// // //                     fontWeight: FontWeight.bold,
// // //                     color: textPrimary,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //           SizedBox(height: _getSpaceL(context)),
// // //
// // //           // Action Buttons Grid - Modified this part
// // //           LayoutBuilder(
// // //             builder: (context, constraints) {
// // //               return GridView.count(
// // //                 shrinkWrap: true,
// // //                 physics: const NeverScrollableScrollPhysics(),
// // //                 crossAxisCount: 2,
// // //                 childAspectRatio: constraints.maxWidth > 400 ? 3 : 2.5, // Responsive aspect ratio
// // //                 crossAxisSpacing: _getSpaceM(context),
// // //                 mainAxisSpacing: _getSpaceM(context),
// // //                 children: [
// // //                   _buildActionButton(
// // //                     icon: Icons.edit,
// // //                     label: 'Edit Profile',
// // //                     onTap: () => setState(() => isEditing = true),
// // //                     gradient: [primaryColor, primaryLight],
// // //                   ),
// // //                   _buildActionButton(
// // //                     icon: Icons.refresh,
// // //                     label: 'Refresh Data',
// // //                     onTap: _refreshData,
// // //                     gradient: [accentColor, accentLight],
// // //                   ),
// // //                   _buildActionButton(
// // //                     icon: Icons.camera_alt,
// // //                     label: 'Change Photo',
// // //                     onTap: _pickImage,
// // //                     gradient: [successColor, const Color(0xFF34D399)],
// // //                   ),
// // //                   _buildActionButton(
// // //                     icon: Icons.logout,
// // //                     label: 'Sign Out',
// // //                     onTap: _showLogoutDialog,
// // //                     gradient: [errorColor, const Color(0xFFF87171)],
// // //                   ),
// // //                 ],
// // //               );
// // //             },
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ ACTION BUTTON - Micro-interaction Design
// // //   Widget _buildActionButton({
// // //     required IconData icon,
// // //     required String label,
// // //     required VoidCallback onTap,
// // //     required List<Color> gradient,
// // //   }) {
// // //     return GestureDetector(
// // //       onTap: onTap,
// // //       child: Container(
// // //         height: 50, // Add fixed height
// // //         decoration: BoxDecoration(
// // //           gradient: LinearGradient(colors: gradient),
// // //           borderRadius: BorderRadius.circular(_getRadiusM()),
// // //           boxShadow: [
// // //             BoxShadow(
// // //               color: gradient[0].withOpacity(0.3),
// // //               blurRadius: 8,
// // //               offset: const Offset(0, 3),
// // //             ),
// // //           ],
// // //         ),
// // //         child: Material(
// // //           color: Colors.transparent,
// // //           child: InkWell(
// // //             borderRadius: BorderRadius.circular(_getRadiusM()),
// // //             onTap: onTap,
// // //             child: Padding(
// // //               padding: EdgeInsets.symmetric( // Change to symmetric padding
// // //                 horizontal: _getSpaceM(context),
// // //                 vertical: _getSpaceS(context),
// // //               ),
// // //               child: Row(
// // //                 mainAxisAlignment: MainAxisAlignment.center,
// // //                 children: [
// // //                   Icon(
// // //                     icon,
// // //                     color: textPrimary,
// // //                     size: 16,
// // //                   ),
// // //                   SizedBox(width: _getSpaceS(context)),
// // //                   Flexible(
// // //                     child: Text(
// // //                       label,
// // //                       style: TextStyle(
// // //                         fontSize: _getBodySize(context), // Increase font size
// // //                         fontWeight: FontWeight.w600,
// // //                         color: textPrimary,
// // //                       ),
// // //                       maxLines: 1,
// // //                       overflow: TextOverflow.ellipsis,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ MODERN LEARNING JOURNEY - Timeline Design
// // //   Widget _buildModernLearningJourney() {
// // //     return Container(
// // //       width: double.infinity,
// // //       padding: _getPaddingL(context),
// // //       decoration: BoxDecoration(
// // //         gradient: LinearGradient(
// // //           begin: Alignment.topLeft,
// // //           end: Alignment.bottomRight,
// // //           colors: [
// // //             Colors.white.withOpacity(0.15),
// // //             Colors.white.withOpacity(0.05),
// // //           ],
// // //         ),
// // //         borderRadius: BorderRadius.circular(_getRadiusL()),
// // //         border: Border.all(
// // //           color: Colors.white.withOpacity(0.2),
// // //           width: 1,
// // //         ),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withOpacity(0.1),
// // //             blurRadius: 15,
// // //             offset: const Offset(0, 5),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           // Header
// // //           Row(
// // //             children: [
// // //               Container(
// // //                 padding: EdgeInsets.all(_getSpaceM(context)),
// // //                 decoration: BoxDecoration(
// // //                   gradient: LinearGradient(
// // //                     colors: [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
// // //                   ),
// // //                   borderRadius: BorderRadius.circular(_getRadiusM()),
// // //                 ),
// // //                 child: Icon(
// // //                   Icons.trending_up,
// // //                   color: textPrimary,
// // //                   size: 20,
// // //                 ),
// // //               ),
// // //               SizedBox(width: _getSpaceM(context)),
// // //               Expanded(
// // //                 child: Text(
// // //                   'Learning Journey',
// // //                   style: TextStyle(
// // //                     fontSize: _getSubheadingSize(context),
// // //                     fontWeight: FontWeight.bold,
// // //                     color: textPrimary,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //           SizedBox(height: _getSpaceL(context)),
// // //
// // //           // Achievements Timeline
// // //           ..._buildModernAchievements(),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   List<Widget> _buildModernAchievements() {
// // //     List<Widget> achievements = [];
// // //
// // //     if (userPoints > 0) {
// // //       achievements.add(_buildTimelineItem(
// // //         icon: Icons.emoji_events,
// // //         title: "Points Earned",
// // //         subtitle: "$userPoints learning points collected!",
// // //         time: _getPointsMessage(),
// // //         color: warningColor,
// // //         isFirst: true,
// // //       ));
// // //     }
// // //
// // //     if (quizzesTaken > 0) {
// // //       achievements.add(_buildTimelineItem(
// // //         icon: Icons.quiz,
// // //         title: "Quiz Master",
// // //         subtitle: "Completed $quizzesTaken ${quizzesTaken == 1 ? 'quiz' : 'quizzes'}",
// // //         time: bestQuizScore > 0 ? "Best: $bestQuizScore pts" : "Keep going!",
// // //         color: successColor,
// // //       ));
// // //     }
// // //
// // //     if (notesCount > 0) {
// // //       achievements.add(_buildTimelineItem(
// // //         icon: Icons.note_add,
// // //         title: "Note Keeper",
// // //         subtitle: "Saved $notesCount ${notesCount == 1 ? 'note' : 'notes'}",
// // //         time: "Great organization!",
// // //         color: primaryColor,
// // //       ));
// // //     }
// // //
// // //     if (savedVideosCount > 0) {
// // //       achievements.add(_buildTimelineItem(
// // //         icon: Icons.video_library,
// // //         title: "Video Learner",
// // //         subtitle: "Bookmarked $savedVideosCount ${savedVideosCount == 1 ? 'video' : 'videos'}",
// // //         time: "Visual learning!",
// // //         color: errorColor,
// // //         isLast: true,
// // //       ));
// // //     }
// // //
// // //     // If no achievements yet
// // //     if (achievements.isEmpty) {
// // //       achievements.add(_buildTimelineItem(
// // //         icon: Icons.rocket_launch,
// // //         title: "Start Your Journey",
// // //         subtitle: "Take your first quiz or save your first note!",
// // //         time: "You've got this! 🚀",
// // //         color: accentColor,
// // //         isFirst: true,
// // //         isLast: true,
// // //       ));
// // //     }
// // //
// // //     return achievements;
// // //   }
// // //
// // //   String _getPointsMessage() {
// // //     if (userPoints >= 5000) return "Amazing! 🏆";
// // //     if (userPoints >= 3000) return "Excellent! 🌟";
// // //     if (userPoints >= 1500) return "Great job! 🎉";
// // //     if (userPoints >= 500) return "Keep going! 💪";
// // //     return "Good start! 👍";
// // //   }
// // //
// // //   // ✅ TIMELINE ITEM - Modern Achievement Card
// // //   Widget _buildTimelineItem({
// // //     required IconData icon,
// // //     required String title,
// // //     required String subtitle,
// // //     required String time,
// // //     required Color color,
// // //     bool isFirst = false,
// // //     bool isLast = false,
// // //   }) {
// // //     return Container(
// // //       margin: EdgeInsets.only(bottom: isLast ? 0 : _getSpaceM(context)),
// // //       child: Row(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           // Timeline indicator
// // //           Column(
// // //             children: [
// // //               Container(
// // //                 width: 40,
// // //                 height: 40,
// // //                 decoration: BoxDecoration(
// // //                   gradient: LinearGradient(
// // //                     colors: [color, color.withOpacity(0.7)],
// // //                   ),
// // //                   shape: BoxShape.circle,
// // //                   boxShadow: [
// // //                     BoxShadow(
// // //                       color: color.withOpacity(0.3),
// // //                       blurRadius: 8,
// // //                       offset: const Offset(0, 2),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 child: Icon(
// // //                   icon,
// // //                   color: textPrimary,
// // //                   size: 20,
// // //                 ),
// // //               ),
// // //               if (!isLast)
// // //                 Container(
// // //                   width: 2,
// // //                   height: 40,
// // //                   margin: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
// // //                   decoration: BoxDecoration(
// // //                     gradient: LinearGradient(
// // //                       begin: Alignment.topCenter,
// // //                       end: Alignment.bottomCenter,
// // //                       colors: [
// // //                         color.withOpacity(0.5),
// // //                         Colors.white.withOpacity(0.1),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ),
// // //             ],
// // //           ),
// // //           SizedBox(width: _getSpaceM(context)),
// // //
// // //           // Content
// // //           Expanded(
// // //             child: Container(
// // //               padding: _getPaddingM(context),
// // //               decoration: BoxDecoration(
// // //                 color: Colors.white.withOpacity(0.05),
// // //                 borderRadius: BorderRadius.circular(_getRadiusM()),
// // //                 border: Border.all(
// // //                   color: color.withOpacity(0.2),
// // //                 ),
// // //               ),
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Row(
// // //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                     children: [
// // //                       Expanded(
// // //                         child: Text(
// // //                           title,
// // //                           style: TextStyle(
// // //                             color: textPrimary,
// // //                             fontWeight: FontWeight.w600,
// // //                             fontSize: _getBodySize(context),
// // //                           ),
// // //                           maxLines: 1,
// // //                           overflow: TextOverflow.ellipsis,
// // //                         ),
// // //                       ),
// // //                       if (time.isNotEmpty)
// // //                         Text(
// // //                           time,
// // //                           style: TextStyle(
// // //                             color: color,
// // //                             fontSize: _getCaptionSize(context),
// // //                             fontWeight: FontWeight.w500,
// // //                           ),
// // //                           maxLines: 1,
// // //                           overflow: TextOverflow.ellipsis,
// // //                         ),
// // //                     ],
// // //                   ),
// // //                   SizedBox(height: _getSpaceXS(context)),
// // //                   Text(
// // //                     subtitle,
// // //                     style: TextStyle(
// // //                       color: textSecondary,
// // //                       fontSize: _getCaptionSize(context),
// // //                     ),
// // //                     maxLines: 2,
// // //                     overflow: TextOverflow.ellipsis,
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ MODERN ACCOUNT SETTINGS - New Card Design
// // //   Widget _buildModernAccountSettings() {
// // //     return Container(
// // //       width: double.infinity,
// // //       padding: _getPaddingL(context),
// // //       decoration: BoxDecoration(
// // //         gradient: LinearGradient(
// // //           begin: Alignment.topLeft,
// // //           end: Alignment.bottomRight,
// // //           colors: [
// // //             Colors.white.withOpacity(0.15),
// // //             Colors.white.withOpacity(0.05),
// // //           ],
// // //         ),
// // //         borderRadius: BorderRadius.circular(_getRadiusL()),
// // //         border: Border.all(
// // //           color: Colors.white.withOpacity(0.2),
// // //           width: 1,
// // //         ),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withOpacity(0.1),
// // //             blurRadius: 15,
// // //             offset: const Offset(0, 5),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           // Header
// // //           Row(
// // //             children: [
// // //               Container(
// // //                 padding: EdgeInsets.all(_getSpaceM(context)),
// // //                 decoration: BoxDecoration(
// // //                   gradient: LinearGradient(
// // //                     colors: [primaryColor, accentColor],
// // //                   ),
// // //                   borderRadius: BorderRadius.circular(_getRadiusM()),
// // //                 ),
// // //                 child: Icon(
// // //                   Icons.settings,
// // //                   color: textPrimary,
// // //                   size: 20,
// // //                 ),
// // //               ),
// // //               SizedBox(width: _getSpaceM(context)),
// // //               Expanded(
// // //                 child: Text(
// // //                   'Account Settings',
// // //                   style: TextStyle(
// // //                     fontSize: _getSubheadingSize(context),
// // //                     fontWeight: FontWeight.bold,
// // //                     color: textPrimary,
// // //                   ),
// // //                 ),
// // //               ),
// // //               if (!isEditing)
// // //                 GestureDetector(
// // //                   onTap: () => setState(() => isEditing = true),
// // //                   child: Container(
// // //                     padding: EdgeInsets.all(_getSpaceS(context)),
// // //                     decoration: BoxDecoration(
// // //                       color: Colors.white.withOpacity(0.1),
// // //                       borderRadius: BorderRadius.circular(_getRadiusS()),
// // //                       border: Border.all(
// // //                         color: primaryColor.withOpacity(0.3),
// // //                       ),
// // //                     ),
// // //                     child: Icon(
// // //                       Icons.edit,
// // //                       color: primaryColor,
// // //                       size: 18,
// // //                     ),
// // //                   ),
// // //                 ),
// // //             ],
// // //           ),
// // //           SizedBox(height: _getSpaceL(context)),
// // //
// // //           // Form Fields
// // //           _buildModernTextField(
// // //             label: "Full Name",
// // //             value: userName,
// // //             controller: _nameController,
// // //             icon: Icons.person_outline,
// // //           ),
// // //           SizedBox(height: _getSpaceM(context)),
// // //
// // //           _buildModernTextField(
// // //             label: "Email Address",
// // //             value: userEmail,
// // //             controller: _emailController,
// // //             icon: Icons.email_outlined,
// // //           ),
// // //
// // //           // Action Buttons
// // //           if (isEditing) ...[
// // //             SizedBox(height: _getSpaceL(context)),
// // //             Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: _buildModernButton(
// // //                     label: "Cancel",
// // //                     onPressed: _cancelEditing,
// // //                     isPrimary: false,
// // //                   ),
// // //                 ),
// // //                 SizedBox(width: _getSpaceM(context)),
// // //                 Expanded(
// // //                   child: _buildModernButton(
// // //                     label: "Save Changes",
// // //                     onPressed: _updateProfile,
// // //                     isPrimary: true,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ],
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ MODERN TEXT FIELD - Glassmorphism Input Design
// // //   Widget _buildModernTextField({
// // //     required String label,
// // //     required String value,
// // //     required TextEditingController controller,
// // //     required IconData icon,
// // //   }) {
// // //     return Container(
// // //       padding: _getPaddingM(context),
// // //       decoration: BoxDecoration(
// // //         color: isEditing
// // //             ? Colors.white.withOpacity(0.1)
// // //             : Colors.white.withOpacity(0.05),
// // //         borderRadius: BorderRadius.circular(_getRadiusM()),
// // //         border: Border.all(
// // //           color: isEditing
// // //               ? primaryColor.withOpacity(0.4)
// // //               : Colors.white.withOpacity(0.1),
// // //           width: 1.5,
// // //         ),
// // //       ),
// // //       child: Row(
// // //         children: [
// // //           Container(
// // //             padding: EdgeInsets.all(_getSpaceS(context)),
// // //             decoration: BoxDecoration(
// // //               gradient: LinearGradient(
// // //                 colors: [primaryColor.withOpacity(0.2), accentColor.withOpacity(0.2)],
// // //               ),
// // //               borderRadius: BorderRadius.circular(_getRadiusS()),
// // //             ),
// // //             child: Icon(
// // //               icon,
// // //               color: primaryColor,
// // //               size: 20,
// // //             ),
// // //           ),
// // //           SizedBox(width: _getSpaceM(context)),
// // //           Expanded(
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 Text(
// // //                   label,
// // //                   style: TextStyle(
// // //                     color: textTertiary,
// // //                     fontSize: _getCaptionSize(context),
// // //                     fontWeight: FontWeight.w500,
// // //                   ),
// // //                 ),
// // //                 SizedBox(height: _getSpaceXS(context)),
// // //                 isEditing
// // //                     ? TextField(
// // //                   controller: controller,
// // //                   style: TextStyle(
// // //                     color: textPrimary,
// // //                     fontSize: _getBodySize(context),
// // //                     fontWeight: FontWeight.w500,
// // //                   ),
// // //                   decoration: const InputDecoration(
// // //                     isDense: true,
// // //                     contentPadding: EdgeInsets.zero,
// // //                     border: InputBorder.none,
// // //                   ),
// // //                   maxLines: 1,
// // //                 )
// // //                     : Text(
// // //                   value,
// // //                   style: TextStyle(
// // //                     color: textPrimary,
// // //                     fontSize: _getBodySize(context),
// // //                     fontWeight: FontWeight.w500,
// // //                   ),
// // //                   maxLines: 1,
// // //                   overflow: TextOverflow.ellipsis,
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ✅ MODERN BUTTON - Gradient Design
// // //   Widget _buildModernButton({
// // //     required String label,
// // //     required VoidCallback onPressed,
// // //     required bool isPrimary,
// // //   }) {
// // //     return Container(
// // //       height: 50,
// // //       decoration: BoxDecoration(
// // //         gradient: isPrimary
// // //             ? LinearGradient(colors: [primaryColor, accentColor])
// // //             : null,
// // //         color: isPrimary ? null : Colors.white.withOpacity(0.1),
// // //         borderRadius: BorderRadius.circular(_getRadiusM()),
// // //         border: isPrimary
// // //             ? null
// // //             : Border.all(color: Colors.white.withOpacity(0.3)),
// // //         boxShadow: isPrimary ? [
// // //           BoxShadow(
// // //             color: primaryColor.withOpacity(0.3),
// // //             blurRadius: 10,
// // //             offset: const Offset(0, 4),
// // //           ),
// // //         ] : null,
// // //       ),
// // //       child: Material(
// // //         color: Colors.transparent,
// // //         child: InkWell(
// // //           borderRadius: BorderRadius.circular(_getRadiusM()),
// // //           onTap: onPressed,
// // //           child: Center(
// // //             child: Text(
// // //               label,
// // //               style: TextStyle(
// // //                 color: textPrimary,
// // //                 fontSize: _getBodySize(context),
// // //                 fontWeight: FontWeight.w600,
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // // ✅ MODERN LOGOUT DIALOG - Completely New Design
// // // class _ModernLogoutDialog extends StatefulWidget {
// // //   @override
// // //   _ModernLogoutDialogState createState() => _ModernLogoutDialogState();
// // // }
// // //
// // // class _ModernLogoutDialogState extends State<_ModernLogoutDialog>
// // //     with SingleTickerProviderStateMixin {
// // //   bool _isLoggingOut = false;
// // //   late AnimationController _animationController;
// // //   late Animation<double> _scaleAnimation;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _animationController = AnimationController(
// // //       duration: const Duration(milliseconds: 300),
// // //       vsync: this,
// // //     );
// // //     _scaleAnimation = CurvedAnimation(
// // //       parent: _animationController,
// // //       curve: Curves.elasticOut,
// // //     );
// // //     _animationController.forward();
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _animationController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Dialog(
// // //       backgroundColor: Colors.transparent,
// // //       elevation: 0,
// // //       child: ScaleTransition(
// // //         scale: _scaleAnimation,
// // //         child: Container(
// // //           width: double.infinity,
// // //           constraints: BoxConstraints(
// // //             maxWidth: MediaQuery.of(context).size.width * 0.9,
// // //             maxHeight: MediaQuery.of(context).size.height * 0.6,
// // //           ),
// // //           margin: const EdgeInsets.all(20),
// // //           decoration: BoxDecoration(
// // //             gradient: const LinearGradient(
// // //               begin: Alignment.topLeft,
// // //               end: Alignment.bottomRight,
// // //               colors: [
// // //                 Color(0xFF1E293B),
// // //                 Color(0xFF0F172A),
// // //               ],
// // //             ),
// // //             borderRadius: BorderRadius.circular(24),
// // //             border: Border.all(
// // //               color: const Color(0xFFEF4444).withOpacity(0.3),
// // //               width: 2,
// // //             ),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.black.withOpacity(0.5),
// // //                 blurRadius: 30,
// // //                 offset: const Offset(0, 15),
// // //               ),
// // //             ],
// // //           ),
// // //           child: Padding(
// // //             padding: const EdgeInsets.all(32),
// // //             child: Column(
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 // Logout icon with animation
// // //                 Container(
// // //                   width: 80,
// // //                   height: 80,
// // //                   decoration: BoxDecoration(
// // //                     gradient: LinearGradient(
// // //                       colors: _isLoggingOut
// // //                           ? [Colors.grey, Colors.grey.shade600]
// // //                           : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
// // //                     ),
// // //                     shape: BoxShape.circle,
// // //                     boxShadow: [
// // //                       BoxShadow(
// // //                         color: (_isLoggingOut ? Colors.grey : const Color(0xFFEF4444))
// // //                             .withOpacity(0.4),
// // //                         blurRadius: 20,
// // //                         spreadRadius: 5,
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   child: _isLoggingOut
// // //                       ? const CircularProgressIndicator(
// // //                     strokeWidth: 3,
// // //                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// // //                   )
// // //                       : const Icon(
// // //                     Icons.logout_rounded,
// // //                     color: Colors.white,
// // //                     size: 36,
// // //                   ),
// // //                 ),
// // //
// // //                 const SizedBox(height: 24),
// // //
// // //                 // Title
// // //                 Text(
// // //                   _isLoggingOut ? 'Signing Out...' : 'Ready to Sign Out?',
// // //                   style: const TextStyle(
// // //                     color: Colors.white,
// // //                     fontSize: 24,
// // //                     fontWeight: FontWeight.bold,
// // //                   ),
// // //                   textAlign: TextAlign.center,
// // //                 ),
// // //
// // //                 const SizedBox(height: 16),
// // //
// // //                 // Security message
// // //                 Container(
// // //                   padding: const EdgeInsets.all(20),
// // //                   decoration: BoxDecoration(
// // //                     color: const Color(0xFF334155),
// // //                     borderRadius: BorderRadius.circular(16),
// // //                     border: Border.all(
// // //                       color: Colors.white.withOpacity(0.1),
// // //                     ),
// // //                   ),
// // //                   child: Column(
// // //                     children: [
// // //                       const Icon(
// // //                         Icons.verified_user,
// // //                         color: Color(0xFF06B6D4),
// // //                         size: 24,
// // //                       ),
// // //                       const SizedBox(height: 12),
// // //                       Text(
// // //                         _isLoggingOut
// // //                             ? 'Saving your progress and signing out safely...'
// // //                             : 'Your learning progress is safely saved!\nYou can continue where you left off.',
// // //                         style: const TextStyle(
// // //                           color: Colors.white70,
// // //                           fontSize: 14,
// // //                           height: 1.4,
// // //                         ),
// // //                         textAlign: TextAlign.center,
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //
// // //                 const SizedBox(height: 32),
// // //
// // //                 // Action buttons
// // //                 Row(
// // //                   children: [
// // //                     // Stay button
// // //                     Expanded(
// // //                       child: Container(
// // //                         height: 50,
// // //                         decoration: BoxDecoration(
// // //                           color: Colors.transparent,
// // //                           borderRadius: BorderRadius.circular(16),
// // //                           border: Border.all(
// // //                             color: Colors.white.withOpacity(0.3),
// // //                           ),
// // //                         ),
// // //                         child: Material(
// // //                           color: Colors.transparent,
// // //                           child: InkWell(
// // //                             borderRadius: BorderRadius.circular(16),
// // //                             onTap: _isLoggingOut ? null : () => Navigator.of(context).pop(),
// // //                             child: const Center(
// // //                               child: Text(
// // //                                 'Stay Here',
// // //                                 style: TextStyle(
// // //                                   color: Colors.white70,
// // //                                   fontSize: 16,
// // //                                   fontWeight: FontWeight.w600,
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                           ),
// // //                         ),
// // //                       ),
// // //                     ),
// // //
// // //                     const SizedBox(width: 16),
// // //
// // //                     // Sign Out button
// // //                     Expanded(
// // //                       child: Container(
// // //                         height: 50,
// // //                         decoration: BoxDecoration(
// // //                           gradient: LinearGradient(
// // //                             colors: _isLoggingOut
// // //                                 ? [Colors.grey, Colors.grey.shade600]
// // //                                 : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
// // //                           ),
// // //                           borderRadius: BorderRadius.circular(16),
// // //                           boxShadow: [
// // //                             BoxShadow(
// // //                               color: (_isLoggingOut ? Colors.grey : const Color(0xFFEF4444))
// // //                                   .withOpacity(0.3),
// // //                               blurRadius: 10,
// // //                               offset: const Offset(0, 4),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                         child: Material(
// // //                           color: Colors.transparent,
// // //                           child: InkWell(
// // //                             borderRadius: BorderRadius.circular(16),
// // //                             onTap: _isLoggingOut ? null : _handleLogout,
// // //                             child: Center(
// // //                               child: Row(
// // //                                 mainAxisAlignment: MainAxisAlignment.center,
// // //                                 children: [
// // //                                   if (_isLoggingOut) ...[
// // //                                     const SizedBox(
// // //                                       width: 16,
// // //                                       height: 16,
// // //                                       child: CircularProgressIndicator(
// // //                                         strokeWidth: 2,
// // //                                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// // //                                       ),
// // //                                     ),
// // //                                   ] else ...[
// // //                                     const Icon(
// // //                                       Icons.logout_rounded,
// // //                                       color: Colors.white,
// // //                                       size: 18,
// // //                                     ),
// // //                                   ],
// // //                                   const SizedBox(width: 8),
// // //                                   Text(
// // //                                     _isLoggingOut ? 'Signing Out...' : 'Sign Out',
// // //                                     style: const TextStyle(
// // //                                       color: Colors.white,
// // //                                       fontSize: 16,
// // //                                       fontWeight: FontWeight.bold,
// // //                                     ),
// // //                                   ),
// // //                                 ],
// // //                               ),
// // //                             ),
// // //                           ),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Future<void> _handleLogout() async {
// // //     if (!mounted) return;
// // //
// // //     setState(() {
// // //       _isLoggingOut = true;
// // //     });
// // //
// // //     try {
// // //       await _performLogout();
// // //     } catch (e) {
// // //       if (mounted) {
// // //         setState(() {
// // //           _isLoggingOut = false;
// // //         });
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text('Logout failed: ${e.toString()}'),
// // //             backgroundColor: const Color(0xFFEF4444),
// // //             behavior: SnackBarBehavior.floating,
// // //             shape: RoundedRectangleBorder(
// // //               borderRadius: BorderRadius.circular(12),
// // //             ),
// // //           ),
// // //         );
// // //       }
// // //     }
// // //   }
// // //
// // //   Future<void> _performLogout() async {
// // //     try {
// // //       // Sign out from Firebase
// // //       await FirebaseAuth.instance.signOut();
// // //
// // //       // Clear SharedPreferences
// // //       final prefs = await SharedPreferences.getInstance();
// // //       await prefs.setBool('is_logged_in', false);
// // //       await prefs.remove('last_login');
// // //
// // //       if (mounted) {
// // //         Navigator.of(context).pop();
// // //         Navigator.of(context).pushAndRemoveUntil(
// // //           MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
// // //               (route) => false,
// // //         );
// // //       }
// // //     } catch (e) {
// // //       if (mounted) {
// // //         Navigator.of(context).pop();
// // //       }
// // //       throw e;
// // //     }
// // //   }
// // // }
// // //
// // //
// // //
// // //
// // // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // // import 'package:firebase_auth/firebase_auth.dart';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // import 'package:image_picker/image_picker.dart';
// // // // import 'dart:io';
// // // // import 'dart:convert';
// // // // import 'dart:typed_data';
// // // // import 'dart:ui';
// // // //
// // // // import 'email_change_verification_screen.dart';
// // // // import 'login_screen.dart';
// // // //
// // // // class ProfileScreen extends StatefulWidget {
// // // //   const ProfileScreen({super.key});
// // // //
// // // //   @override
// // // //   State<ProfileScreen> createState() => _ProfileScreenState();
// // // // }
// // // //
// // // // class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
// // // //   // Data variables
// // // //   String userName = "Loading...";
// // // //   String userEmail = "Loading...";
// // // //   String profileImageBase64 = "";
// // // //   int userPoints = 0;
// // // //   int notesCount = 0;
// // // //   int savedVideosCount = 0;
// // // //   int savedLinksCount = 0;
// // // //   int quizzesTaken = 0;
// // // //   int bestQuizScore = 0;
// // // //   String userLevel = "Rookie";
// // // //
// // // //   // UI state variables
// // // //   bool isEditing = false;
// // // //   bool isLoading = true;
// // // //   bool isUploadingImage = false;
// // // //   File? _profileImage;
// // // //
// // // //   // Controllers
// // // //   final TextEditingController _emailController = TextEditingController();
// // // //   final TextEditingController _nameController = TextEditingController();
// // // //   final ImagePicker _picker = ImagePicker();
// // // //
// // // //   // Animation controllers
// // // //   late AnimationController _fadeController;
// // // //   late AnimationController _slideController;
// // // //   late AnimationController _counterController;
// // // //   late AnimationController _pulseController;
// // // //   late AnimationController _scaleController;
// // // //   late Animation<double> _fadeAnimation;
// // // //   late Animation<Offset> _slideAnimation;
// // // //   late Animation<double> _counterAnimation;
// // // //   late Animation<double> _pulseAnimation;
// // // //   late Animation<double> _scaleAnimation;
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _initializeAnimations();
// // // //     _loadUserData();
// // // //   }
// // // //
// // // //   void _initializeAnimations() {
// // // //     _fadeController = AnimationController(
// // // //       duration: const Duration(milliseconds: 1200),
// // // //       vsync: this,
// // // //     );
// // // //     _slideController = AnimationController(
// // // //       duration: const Duration(milliseconds: 1000),
// // // //       vsync: this,
// // // //     );
// // // //     _counterController = AnimationController(
// // // //       duration: const Duration(milliseconds: 2500),
// // // //       vsync: this,
// // // //     );
// // // //     _pulseController = AnimationController(
// // // //       duration: const Duration(milliseconds: 2000),
// // // //       vsync: this,
// // // //     );
// // // //     _scaleController = AnimationController(
// // // //       duration: const Duration(milliseconds: 800),
// // // //       vsync: this,
// // // //     );
// // // //
// // // //     _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
// // // //     _slideAnimation = Tween<Offset>(
// // // //       begin: const Offset(0, 0.3),
// // // //       end: Offset.zero,
// // // //     ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
// // // //     _counterAnimation = CurvedAnimation(parent: _counterController, curve: Curves.easeOutQuart);
// // // //     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08)
// // // //         .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
// // // //     _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
// // // //   }
// // // //
// // // //   @override
// // // //   void dispose() {
// // // //     _fadeController.dispose();
// // // //     _slideController.dispose();
// // // //     _counterController.dispose();
// // // //     _pulseController.dispose();
// // // //     _scaleController.dispose();
// // // //     _nameController.dispose();
// // // //     _emailController.dispose();
// // // //     super.dispose();
// // // //   }
// // // //
// // // //   // ✅ MODERN RESPONSIVE SYSTEM
// // // //   double _getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;
// // // //   double _getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;
// // // //
// // // //   bool _isSmallMobile(BuildContext context) => _getScreenWidth(context) < 360;
// // // //   bool _isMobile(BuildContext context) => _getScreenWidth(context) < 600;
// // // //   bool _isTablet(BuildContext context) => _getScreenWidth(context) >= 600 && _getScreenWidth(context) < 1024;
// // // //   bool _isDesktop(BuildContext context) => _getScreenWidth(context) >= 1024;
// // // //
// // // //   // ✅ MODERN TYPOGRAPHY SYSTEM
// // // //   double _getHeadingSize(BuildContext context) {
// // // //     if (_isSmallMobile(context)) return 20;
// // // //     if (_isMobile(context)) return 24;
// // // //     if (_isTablet(context)) return 28;
// // // //     return 32;
// // // //   }
// // // //
// // // //   double _getSubheadingSize(BuildContext context) {
// // // //     if (_isSmallMobile(context)) return 16;
// // // //     if (_isMobile(context)) return 18;
// // // //     if (_isTablet(context)) return 20;
// // // //     return 22;
// // // //   }
// // // //
// // // //   double _getBodySize(BuildContext context) {
// // // //     if (_isSmallMobile(context)) return 12;
// // // //     if (_isMobile(context)) return 14;
// // // //     if (_isTablet(context)) return 15;
// // // //     return 16;
// // // //   }
// // // //
// // // //   double _getCaptionSize(BuildContext context) {
// // // //     if (_isSmallMobile(context)) return 10;
// // // //     if (_isMobile(context)) return 11;
// // // //     if (_isTablet(context)) return 12;
// // // //     return 13;
// // // //   }
// // // //
// // // //   // ✅ MODERN SPACING SYSTEM
// // // //   double _getSpaceXS(BuildContext context) => _isMobile(context) ? 4 : 6;
// // // //   double _getSpaceS(BuildContext context) => _isMobile(context) ? 8 : 12;
// // // //   double _getSpaceM(BuildContext context) => _isMobile(context) ? 16 : 20;
// // // //   double _getSpaceL(BuildContext context) => _isMobile(context) ? 24 : 32;
// // // //   double _getSpaceXL(BuildContext context) => _isMobile(context) ? 32 : 48;
// // // //
// // // //   // ✅ MODERN PADDING SYSTEM
// // // //   EdgeInsets _getPaddingS(BuildContext context) => EdgeInsets.all(_getSpaceS(context));
// // // //   EdgeInsets _getPaddingM(BuildContext context) => EdgeInsets.all(_getSpaceM(context));
// // // //   EdgeInsets _getPaddingL(BuildContext context) => EdgeInsets.all(_getSpaceL(context));
// // // //
// // // //   EdgeInsets _getPaddingHorizontal(BuildContext context, double multiplier) =>
// // // //       EdgeInsets.symmetric(horizontal: _getSpaceM(context) * multiplier);
// // // //
// // // //   EdgeInsets _getPaddingVertical(BuildContext context, double multiplier) =>
// // // //       EdgeInsets.symmetric(vertical: _getSpaceM(context) * multiplier);
// // // //
// // // //   // ✅ MODERN BORDER RADIUS SYSTEM
// // // //   double _getRadiusS() => 8;
// // // //   double _getRadiusM() => 16;
// // // //   double _getRadiusL() => 24;
// // // //   double _getRadiusXL() => 32;
// // // //
// // // //   // ✅ GRID SYSTEM FOR NEW LAYOUT
// // // //   int _getStatsColumns(BuildContext context) {
// // // //     if (_isSmallMobile(context)) return 2;
// // // //     if (_isMobile(context)) return 2;
// // // //     if (_isTablet(context)) return 4;
// // // //     return 4;
// // // //   }
// // // //
// // // //   double _getStatsAspectRatio(BuildContext context) {
// // // //     if (_isSmallMobile(context)) return 1.4;
// // // //     if (_isMobile(context)) return 1.2;
// // // //     return 1.0;
// // // //   }
// // // //
// // // //   // ✅ MODERN COLOR PALETTE
// // // //   Color get primaryColor => const Color(0xFF6366F1); // Indigo
// // // //   Color get primaryLight => const Color(0xFF818CF8);
// // // //   Color get primaryDark => const Color(0xFF4F46E5);
// // // //
// // // //   Color get accentColor => const Color(0xFF06B6D4); // Cyan
// // // //   Color get accentLight => const Color(0xFF22D3EE);
// // // //   Color get accentDark => const Color(0xFF0891B2);
// // // //
// // // //   Color get successColor => const Color(0xFF10B981);
// // // //   Color get warningColor => const Color(0xFFF59E0B);
// // // //   Color get errorColor => const Color(0xFFEF4444);
// // // //
// // // //   Color get surfaceColor => const Color(0xFF1E293B);
// // // //   Color get surfaceLight => const Color(0xFF334155);
// // // //   Color get surfaceDark => const Color(0xFF0F172A);
// // // //
// // // //   Color get textPrimary => Colors.white;
// // // //   Color get textSecondary => Colors.white.withOpacity(0.8);
// // // //   Color get textTertiary => Colors.white.withOpacity(0.6);
// // // //
// // // //   // Level styling methods (updated for new design)
// // // //   Color _getLevelColor() {
// // // //     switch (userLevel) {
// // // //       case 'Expert': return const Color(0xFF8B5CF6); // Purple
// // // //       case 'Advanced': return const Color(0xFF06B6D4); // Cyan
// // // //       case 'Intermediate': return const Color(0xFF3B82F6); // Blue
// // // //       case 'Beginner': return const Color(0xFFF59E0B); // Amber
// // // //       default: return const Color(0xFF6B7280); // Gray
// // // //     }
// // // //   }
// // // //
// // // //   IconData _getLevelIcon() {
// // // //     switch (userLevel) {
// // // //       case 'Expert': return Icons.emoji_events; // Trophy
// // // //       case 'Advanced': return Icons.military_tech; // Medal
// // // //       case 'Intermediate': return Icons.star; // Star
// // // //       case 'Beginner': return Icons.trending_up; // Arrow up
// // // //       default: return Icons.circle; // Dot
// // // //     }
// // // //   }
// // // //
// // // //   String _calculateUserLevel(int points) {
// // // //     if (points >= 5000) return 'Expert';
// // // //     if (points >= 3000) return 'Advanced';
// // // //     if (points >= 1500) return 'Intermediate';
// // // //     if (points >= 500) return 'Beginner';
// // // //     return 'Rookie';
// // // //   }
// // // //
// // // //   // Helper methods
// // // //   Uint8List _base64ToImage(String base64String) {
// // // //     return base64Decode(base64String);
// // // //   }
// // // //
// // // //   bool _isValidEmail(String email) {
// // // //     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
// // // //   }
// // // //
// // // //   // ✅ MODERN SNACKBAR SYSTEM
// // // //   void _showSuccessSnackBar(String message) {
// // // //     ScaffoldMessenger.of(context).showSnackBar(
// // // //       SnackBar(
// // // //         content: Container(
// // // //           padding: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
// // // //           child: Row(
// // // //             children: [
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getSpaceXS(context)),
// // // //                 decoration: BoxDecoration(
// // // //                   color: Colors.white.withOpacity(0.2),
// // // //                   shape: BoxShape.circle,
// // // //                 ),
// // // //                 child: Icon(Icons.check_circle, color: Colors.white, size: 20),
// // // //               ),
// // // //               SizedBox(width: _getSpaceS(context)),
// // // //               Expanded(
// // // //                 child: Text(
// // // //                   message,
// // // //                   style: TextStyle(
// // // //                     fontWeight: FontWeight.w600,
// // // //                     fontSize: _getBodySize(context),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //         backgroundColor: successColor,
// // // //         behavior: SnackBarBehavior.floating,
// // // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getRadiusM())),
// // // //         margin: EdgeInsets.all(_getSpaceM(context)),
// // // //         elevation: 8,
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   void _showErrorSnackBar(String message) {
// // // //     ScaffoldMessenger.of(context).showSnackBar(
// // // //       SnackBar(
// // // //         content: Container(
// // // //           padding: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
// // // //           child: Row(
// // // //             children: [
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getSpaceXS(context)),
// // // //                 decoration: BoxDecoration(
// // // //                   color: Colors.white.withOpacity(0.2),
// // // //                   shape: BoxShape.circle,
// // // //                 ),
// // // //                 child: Icon(Icons.error, color: Colors.white, size: 20),
// // // //               ),
// // // //               SizedBox(width: _getSpaceS(context)),
// // // //               Expanded(
// // // //                 child: Text(
// // // //                   message,
// // // //                   style: TextStyle(
// // // //                     fontWeight: FontWeight.w600,
// // // //                     fontSize: _getBodySize(context),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //         backgroundColor: errorColor,
// // // //         behavior: SnackBarBehavior.floating,
// // // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getRadiusM())),
// // // //         margin: EdgeInsets.all(_getSpaceM(context)),
// // // //         elevation: 8,
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   void _redirectToLogin() {
// // // //     if (mounted) {
// // // //       Navigator.pushAndRemoveUntil(
// // // //         context,
// // // //         MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
// // // //             (route) => false,
// // // //       );
// // // //     }
// // // //   }
// // // //   // ✅ DATA LOADING METHODS (Same functionality, updated animations)
// // // //
// // // //   Future<void> _loadUserData() async {
// // // //     try {
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       if (user == null) {
// // // //         _redirectToLogin();
// // // //         return;
// // // //       }
// // // //
// // // //       final userDoc = await FirebaseFirestore.instance
// // // //           .collection('users')
// // // //           .doc(user.uid)
// // // //           .get();
// // // //
// // // //       if (userDoc.exists && mounted) {
// // // //         final userData = userDoc.data()!;
// // // //         setState(() {
// // // //           userName = userData['fullName'] ?? 'Unknown User';
// // // //           userEmail = userData['email'] ?? user.email ?? '';
// // // //           _nameController.text = userName;
// // // //           _emailController.text = userEmail;
// // // //         });
// // // //
// // // //         await Future.wait([
// // // //           _loadProfileImage(),
// // // //           _loadUserStats(),
// // // //         ]);
// // // //
// // // //         if (mounted) {
// // // //           // Start new animation sequence
// // // //           _fadeController.forward();
// // // //           await Future.delayed(const Duration(milliseconds: 200));
// // // //           _slideController.forward();
// // // //           await Future.delayed(const Duration(milliseconds: 300));
// // // //           _scaleController.forward();
// // // //           await Future.delayed(const Duration(milliseconds: 200));
// // // //           _counterController.forward();
// // // //           _pulseController.repeat(reverse: true);
// // // //         }
// // // //
// // // //         setState(() {
// // // //           isLoading = false;
// // // //         });
// // // //       } else {
// // // //         _redirectToLogin();
// // // //       }
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           isLoading = false;
// // // //         });
// // // //         _showErrorSnackBar('Failed to load profile data');
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _loadUserStats() async {
// // // //     try {
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       if (user == null) return;
// // // //
// // // //       final userId = user.uid;
// // // //       final points = prefs.getInt('${userId}_user_points') ?? 0;
// // // //       final quizCount = prefs.getInt('${userId}_quizzes_taken') ?? 0;
// // // //       final bestScore = prefs.getInt('${userId}_best_score') ?? 0;
// // // //
// // // //       // Count notes from multiple sources
// // // //       int totalNotesCount = 0;
// // // //       int linksCount = 0;
// // // //       int videosCount = 0;
// // // //
// // // //       final savedNotesJson = prefs.getStringList('${userId}_saved_notes') ?? [];
// // // //       totalNotesCount += savedNotesJson.length;
// // // //
// // // //       for (final noteString in savedNotesJson) {
// // // //         try {
// // // //           if (noteString.contains('http') || noteString.contains('www.')) {
// // // //             linksCount++;
// // // //           }
// // // //         } catch (e) {
// // // //           debugPrint('Error parsing saved note: $e');
// // // //         }
// // // //       }
// // // //
// // // //       final codingNotesJson = prefs.getStringList('${userId}_coding_notes') ?? [];
// // // //       totalNotesCount += codingNotesJson.length;
// // // //
// // // //       final personalNotesJson = prefs.getStringList('${userId}_personal_notes') ?? [];
// // // //       totalNotesCount += personalNotesJson.length;
// // // //
// // // //       final studyNotesJson = prefs.getStringList('${userId}_study_notes') ?? [];
// // // //       totalNotesCount += studyNotesJson.length;
// // // //
// // // //       final savedVideosJson = prefs.getStringList('${userId}_saved_videos') ?? [];
// // // //       final bookmarkedVideosJson = prefs.getStringList('${userId}_bookmarked_videos') ?? [];
// // // //       videosCount = savedVideosJson.length + bookmarkedVideosJson.length;
// // // //
// // // //       final savedLinksJson = prefs.getStringList('${userId}_saved_links') ?? [];
// // // //       final bookmarkedLinksJson = prefs.getStringList('${userId}_bookmarked_links') ?? [];
// // // //       linksCount += savedLinksJson.length + bookmarkedLinksJson.length;
// // // //
// // // //       final level = _calculateUserLevel(points);
// // // //
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           userPoints = points;
// // // //           quizzesTaken = quizCount;
// // // //           bestQuizScore = bestScore;
// // // //           notesCount = totalNotesCount;
// // // //           savedVideosCount = videosCount;
// // // //           savedLinksCount = linksCount;
// // // //           userLevel = level;
// // // //         });
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint('❌ Error loading user stats: $e');
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           userPoints = 0;
// // // //           notesCount = 0;
// // // //           savedVideosCount = 0;
// // // //           savedLinksCount = 0;
// // // //           quizzesTaken = 0;
// // // //           bestQuizScore = 0;
// // // //           userLevel = 'Rookie';
// // // //         });
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _loadProfileImage() async {
// // // //     try {
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       if (user != null) {
// // // //         final imageKey = 'profile_image_${user.uid}';
// // // //         final savedImageBase64 = prefs.getString(imageKey);
// // // //         if (savedImageBase64 != null && savedImageBase64.isNotEmpty && mounted) {
// // // //           setState(() {
// // // //             profileImageBase64 = savedImageBase64;
// // // //           });
// // // //         }
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint('Error loading profile image: $e');
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _refreshData() async {
// // // //     setState(() {
// // // //       isLoading = true;
// // // //     });
// // // //
// // // //     // Reset animations
// // // //     _counterController.reset();
// // // //     _scaleController.reset();
// // // //
// // // //     await Future.wait([
// // // //       _loadUserStats(),
// // // //       _loadProfileImage(),
// // // //     ]);
// // // //
// // // //     if (mounted) {
// // // //       setState(() {
// // // //         isLoading = false;
// // // //       });
// // // //
// // // //       // Restart animations
// // // //       _counterController.forward();
// // // //       _scaleController.forward();
// // // //
// // // //       _showSuccessSnackBar('Profile data refreshed!');
// // // //     }
// // // //   }
// // // //
// // // //   // ✅ IMAGE HANDLING METHODS
// // // //
// // // //   Future<void> _pickImage() async {
// // // //     try {
// // // //       final XFile? image = await _picker.pickImage(
// // // //         source: ImageSource.gallery,
// // // //         maxWidth: 512,
// // // //         maxHeight: 512,
// // // //         imageQuality: 85,
// // // //       );
// // // //
// // // //       if (image != null) {
// // // //         setState(() {
// // // //           _profileImage = File(image.path);
// // // //           isUploadingImage = true;
// // // //         });
// // // //
// // // //         await _saveProfileImageLocally(File(image.path));
// // // //       }
// // // //     } catch (e) {
// // // //       _showErrorSnackBar('Failed to pick image: Please try again');
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _saveProfileImageLocally(File imageFile) async {
// // // //     try {
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       if (user == null) return;
// // // //
// // // //       final bytes = await imageFile.readAsBytes();
// // // //       final base64String = base64Encode(bytes);
// // // //
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       final imageKey = 'profile_image_${user.uid}';
// // // //       await prefs.setString(imageKey, base64String);
// // // //
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           profileImageBase64 = base64String;
// // // //           isUploadingImage = false;
// // // //         });
// // // //         _showSuccessSnackBar('Profile image updated successfully!');
// // // //       }
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           isUploadingImage = false;
// // // //           _profileImage = null;
// // // //         });
// // // //         _showErrorSnackBar('Failed to save image');
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   // ✅ PROFILE UPDATE METHODS
// // // //
// // // //   Future<void> _updateProfile() async {
// // // //     final name = _nameController.text.trim();
// // // //     final email = _emailController.text.trim();
// // // //     final currentUser = FirebaseAuth.instance.currentUser;
// // // //
// // // //     if (name.isEmpty) {
// // // //       _showErrorSnackBar('Name cannot be empty');
// // // //       return;
// // // //     }
// // // //
// // // //     if (!_isValidEmail(email)) {
// // // //       _showErrorSnackBar('Please enter a valid email address');
// // // //       return;
// // // //     }
// // // //
// // // //     if (currentUser == null) return;
// // // //
// // // //     try {
// // // //       setState(() {
// // // //         isLoading = true;
// // // //       });
// // // //
// // // //       final emailChanged = currentUser.email != email;
// // // //
// // // //       if (emailChanged) {
// // // //         await _handleEmailChange(email, name);
// // // //       } else {
// // // //         await _updateNameOnly(name);
// // // //       }
// // // //
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           isLoading = false;
// // // //         });
// // // //         _showErrorSnackBar('Failed to update profile');
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _updateNameOnly(String name) async {
// // // //     final user = FirebaseAuth.instance.currentUser;
// // // //     if (user != null) {
// // // //       await FirebaseFirestore.instance
// // // //           .collection('users')
// // // //           .doc(user.uid)
// // // //           .update({
// // // //         'fullName': name,
// // // //         'updatedAt': FieldValue.serverTimestamp(),
// // // //       });
// // // //
// // // //       await user.updateDisplayName(name);
// // // //
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           userName = name;
// // // //           isEditing = false;
// // // //           isLoading = false;
// // // //         });
// // // //         _showSuccessSnackBar('Name updated successfully!');
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _handleEmailChange(String newEmail, String name) async {
// // // //     try {
// // // //       setState(() {
// // // //         isLoading = false;
// // // //         isEditing = false;
// // // //       });
// // // //
// // // //       final result = await Navigator.push(
// // // //         context,
// // // //         MaterialPageRoute(
// // // //           builder: (context) => EmailChangeVerificationScreen(
// // // //             currentEmail: userEmail,
// // // //             newEmail: newEmail,
// // // //             userName: name,
// // // //           ),
// // // //         ),
// // // //       );
// // // //
// // // //       if (result == true) {
// // // //         await _loadUserData();
// // // //         _showSuccessSnackBar('Email updated successfully!');
// // // //       } else {
// // // //         _emailController.text = userEmail;
// // // //       }
// // // //     } catch (e) {
// // // //       setState(() {
// // // //         isLoading = false;
// // // //       });
// // // //       _emailController.text = userEmail;
// // // //       _showErrorSnackBar('Failed to initiate email change');
// // // //     }
// // // //   }
// // // //
// // // //   void _cancelEditing() {
// // // //     setState(() {
// // // //       _nameController.text = userName;
// // // //       _emailController.text = userEmail;
// // // //       isEditing = false;
// // // //     });
// // // //   }
// // // //
// // // //   // ✅ LEVEL PROGRESS CALCULATIONS
// // // //
// // // //   String _getNextLevelInfo() {
// // // //     final nextPoints = _getNextLevelPoints();
// // // //
// // // //     if (userLevel == 'Expert') {
// // // //       return 'Congratulations! You\'ve reached the highest level! 🏆';
// // // //     }
// // // //
// // // //     final needed = nextPoints - userPoints;
// // // //     final nextLevel = _getNextLevelName();
// // // //
// // // //     return '$needed points to $nextLevel';
// // // //   }
// // // //
// // // //   String _getNextLevelName() {
// // // //     switch (userLevel) {
// // // //       case 'Rookie': return 'Beginner';
// // // //       case 'Beginner': return 'Intermediate';
// // // //       case 'Intermediate': return 'Advanced';
// // // //       case 'Advanced': return 'Expert';
// // // //       default: return 'Expert';
// // // //     }
// // // //   }
// // // //
// // // //   int _getNextLevelPoints() {
// // // //     switch (userLevel) {
// // // //       case 'Rookie': return 500;
// // // //       case 'Beginner': return 1500;
// // // //       case 'Intermediate': return 3000;
// // // //       case 'Advanced': return 5000;
// // // //       default: return 5000;
// // // //     }
// // // //   }
// // // //
// // // //   int _getCurrentLevelPoints() {
// // // //     switch (userLevel) {
// // // //       case 'Rookie': return 0;
// // // //       case 'Beginner': return 500;
// // // //       case 'Intermediate': return 1500;
// // // //       case 'Advanced': return 3000;
// // // //       case 'Expert': return 5000;
// // // //       default: return 0;
// // // //     }
// // // //   }
// // // //
// // // //   double _getLevelProgress() {
// // // //     if (userLevel == 'Expert') return 1.0;
// // // //
// // // //     final nextPoints = _getNextLevelPoints();
// // // //     final currentPoints = _getCurrentLevelPoints();
// // // //     final progress = ((userPoints - currentPoints) / (nextPoints - currentPoints)).clamp(0.0, 1.0);
// // // //
// // // //     return progress;
// // // //   }
// // // //
// // // //   // ✅ LOGOUT DIALOG
// // // //
// // // //   Future<void> _showLogoutDialog() async {
// // // //     return showDialog<void>(
// // // //       context: context,
// // // //       barrierDismissible: true,
// // // //       barrierColor: Colors.black.withOpacity(0.8),
// // // //       builder: (BuildContext context) {
// // // //         return _ModernLogoutDialog();
// // // //       },
// // // //     );
// // // //   }
// // // //   // ✅ MAIN BUILD METHODS - COMPLETELY NEW MODERN UI
// // // //
// // // //   // @override
// // // //   // Widget build(BuildContext context) {
// // // //   //   return Scaffold(
// // // //   //     backgroundColor: surfaceDark,
// // // //   //     body: isLoading ? _buildModernLoadingState() : _buildModernMainContent(),
// // // //   //   );
// // // //   // }
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: surfaceDark,
// // // //       body: SafeArea(
// // // //         bottom: false, // We handle bottom padding manually
// // // //         child: isLoading ? _buildModernLoadingState() : _buildModernMainContent(),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ MODERN LOADING STATE - Glassmorphism Design
// // // //   Widget _buildModernLoadingState() {
// // // //     return Container(
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             surfaceDark,
// // // //             surfaceColor,
// // // //             surfaceLight.withOpacity(0.8),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //       child: Center(
// // // //         child: Container(
// // // //           padding: EdgeInsets.all(_getSpaceXL(context)),
// // // //           decoration: BoxDecoration(
// // // //             color: Colors.white.withOpacity(0.1),
// // // //             borderRadius: BorderRadius.circular(_getRadiusXL()),
// // // //             border: Border.all(
// // // //               color: Colors.white.withOpacity(0.2),
// // // //               width: 1,
// // // //             ),
// // // //             boxShadow: [
// // // //               BoxShadow(
// // // //                 color: Colors.black.withOpacity(0.3),
// // // //                 blurRadius: 30,
// // // //                 offset: const Offset(0, 10),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           child: Column(
// // // //             mainAxisSize: MainAxisSize.min,
// // // //             children: [
// // // //               // Modern loading spinner
// // // //               Container(
// // // //                 width: 80,
// // // //                 height: 80,
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: LinearGradient(
// // // //                     colors: [primaryColor, accentColor],
// // // //                   ),
// // // //                   shape: BoxShape.circle,
// // // //                   boxShadow: [
// // // //                     BoxShadow(
// // // //                       color: primaryColor.withOpacity(0.4),
// // // //                       blurRadius: 20,
// // // //                       spreadRadius: 5,
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //                 child: const CircularProgressIndicator(
// // // //                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// // // //                   strokeWidth: 3,
// // // //                 ),
// // // //               ),
// // // //               SizedBox(height: _getSpaceL(context)),
// // // //               // Loading text
// // // //               Text(
// // // //                 'Loading your profile...',
// // // //                 style: TextStyle(
// // // //                   color: textPrimary,
// // // //                   fontSize: _getSubheadingSize(context),
// // // //                   fontWeight: FontWeight.w600,
// // // //                 ),
// // // //               ),
// // // //               SizedBox(height: _getSpaceS(context)),
// // // //               Text(
// // // //                 'Please wait a moment',
// // // //                 style: TextStyle(
// // // //                   color: textSecondary,
// // // //                   fontSize: _getBodySize(context),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ MODERN MAIN CONTENT - New Layout Structure
// // // //   Widget _buildModernMainContent() {
// // // //     return Container(
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             surfaceDark,
// // // //             surfaceColor,
// // // //             surfaceLight.withOpacity(0.5),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //       child: SafeArea(
// // // //         child: FadeTransition(
// // // //           opacity: _fadeAnimation,
// // // //           child: _buildResponsiveLayout(),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ RESPONSIVE LAYOUT SELECTOR
// // // //   Widget _buildResponsiveLayout() {
// // // //     if (_isDesktop(context)) {
// // // //       return _buildDesktopLayout();
// // // //     } else if (_isTablet(context)) {
// // // //       return _buildTabletLayout();
// // // //     } else {
// // // //       return _buildMobileLayout();
// // // //     }
// // // //   }
// // // //
// // // //   // ✅ MOBILE LAYOUT - Card-based Stack Design
// // // //   Widget _buildMobileLayout() {
// // // //     return CustomScrollView(
// // // //       physics: const ClampingScrollPhysics(), // Changed from BouncingScrollPhysics
// // // //       slivers: [
// // // //         _buildModernAppBar(),
// // // //         SliverPadding(
// // // //           padding: EdgeInsets.only(
// // // //             left: _getSpaceM(context),
// // // //             right: _getSpaceM(context),
// // // //             bottom: MediaQuery.of(context).padding.bottom + _getSpaceXL(context),
// // // //           ),
// // // //           sliver: SliverList(
// // // //             delegate: SliverChildListDelegate([
// // // //               SizedBox(height: _getSpaceM(context)),
// // // //               _buildHeroProfileCard(),
// // // //               SizedBox(height: _getSpaceL(context)),
// // // //               _buildPointsAndLevelRow(),
// // // //               SizedBox(height: _getSpaceL(context)),
// // // //               _buildModernStatsGrid(),
// // // //               SizedBox(height: _getSpaceL(context)),
// // // //               _buildQuickActionsCard(),
// // // //               SizedBox(height: _getSpaceL(context)),
// // // //               _buildModernLearningJourney(),
// // // //               SizedBox(height: _getSpaceL(context)),
// // // //               _buildModernAccountSettings(),
// // // //               SizedBox(height: _getSpaceXL(context)),
// // // //             ]),
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //
// // // //   Widget _buildPointsAndLevelRow() {
// // // //     final screenWidth = MediaQuery.of(context).size.width;
// // // //     final useColumnLayout = screenWidth < 500;
// // // //
// // // //     if (useColumnLayout) {
// // // //       return Column(
// // // //         children: [
// // // //           _buildPointsCard(),
// // // //           SizedBox(height: _getSpaceM(context)),
// // // //           _buildLevelCard(),
// // // //         ],
// // // //       );
// // // //     }
// // // //
// // // //     return Row(
// // // //       children: [
// // // //         Expanded(child: _buildPointsCard()),
// // // //         SizedBox(width: _getSpaceM(context)),
// // // //         Expanded(child: _buildLevelCard()),
// // // //       ],
// // // //     );
// // // //   }
// // // //   // ✅ TABLET LAYOUT - Two Column Design
// // // //   Widget _buildTabletLayout() {
// // // //     return CustomScrollView(
// // // //       physics: const BouncingScrollPhysics(),
// // // //       slivers: [
// // // //         _buildModernAppBar(),
// // // //         SliverPadding(
// // // //           padding: _getPaddingHorizontal(context, 1.5),
// // // //           sliver: SliverList(
// // // //             delegate: SliverChildListDelegate([
// // // //               SizedBox(height: _getSpaceL(context)),
// // // //
// // // //               // Hero Profile Card - Full Width
// // // //               SlideTransition(
// // // //                 position: _slideAnimation,
// // // //                 child: _buildHeroProfileCard(),
// // // //               ),
// // // //               SizedBox(height: _getSpaceL(context)),
// // // //
// // // //               // Points, Level, and Stats Row
// // // //               Row(
// // // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // // //                 children: [
// // // //                   // Left Column - Points and Level
// // // //                   Expanded(
// // // //                     flex: 1,
// // // //                     child: Column(
// // // //                       children: [
// // // //                         ScaleTransition(
// // // //                           scale: _scaleAnimation,
// // // //                           child: _buildPointsCard(),
// // // //                         ),
// // // //                         SizedBox(height: _getSpaceM(context)),
// // // //                         ScaleTransition(
// // // //                           scale: _scaleAnimation,
// // // //                           child: _buildLevelCard(),
// // // //                         ),
// // // //                         SizedBox(height: _getSpaceL(context)),
// // // //                         _buildQuickActionsCard(),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //                   SizedBox(width: _getSpaceL(context)),
// // // //
// // // //                   // Right Column - Stats and Journey
// // // //                   Expanded(
// // // //                     flex: 2,
// // // //                     child: Column(
// // // //                       children: [
// // // //                         _buildModernStatsGrid(),
// // // //                         SizedBox(height: _getSpaceL(context)),
// // // //                         _buildModernLearningJourney(),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //               SizedBox(height: _getSpaceL(context)),
// // // //
// // // //               // Account Settings - Full Width
// // // //               _buildModernAccountSettings(),
// // // //               SizedBox(height: _getSpaceXL(context)),
// // // //             ]),
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ DESKTOP LAYOUT - Dashboard Style
// // // //   Widget _buildDesktopLayout() {
// // // //     return CustomScrollView(
// // // //       physics: const BouncingScrollPhysics(),
// // // //       slivers: [
// // // //         _buildModernAppBar(),
// // // //         SliverPadding(
// // // //           padding: _getPaddingHorizontal(context, 2),
// // // //           sliver: SliverList(
// // // //             delegate: SliverChildListDelegate([
// // // //               SizedBox(height: _getSpaceL(context)),
// // // //
// // // //               Row(
// // // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // // //                 children: [
// // // //                   // Left Sidebar - Profile and Actions
// // // //                   Expanded(
// // // //                     flex: 2,
// // // //                     child: Column(
// // // //                       children: [
// // // //                         SlideTransition(
// // // //                           position: _slideAnimation,
// // // //                           child: _buildHeroProfileCard(),
// // // //                         ),
// // // //                         SizedBox(height: _getSpaceL(context)),
// // // //                         _buildQuickActionsCard(),
// // // //                         SizedBox(height: _getSpaceL(context)),
// // // //                         _buildModernAccountSettings(),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //                   SizedBox(width: _getSpaceXL(context)),
// // // //
// // // //                   // Main Content Area
// // // //                   Expanded(
// // // //                     flex: 3,
// // // //                     child: Column(
// // // //                       children: [
// // // //                         // Points and Level Row
// // // //                         Row(
// // // //                           children: [
// // // //                             Expanded(
// // // //                               child: ScaleTransition(
// // // //                                 scale: _scaleAnimation,
// // // //                                 child: _buildPointsCard(),
// // // //                               ),
// // // //                             ),
// // // //                             SizedBox(width: _getSpaceL(context)),
// // // //                             Expanded(
// // // //                               child: ScaleTransition(
// // // //                                 scale: _scaleAnimation,
// // // //                                 child: _buildLevelCard(),
// // // //                               ),
// // // //                             ),
// // // //                           ],
// // // //                         ),
// // // //                         SizedBox(height: _getSpaceL(context)),
// // // //
// // // //                         // Stats Grid
// // // //                         _buildModernStatsGrid(),
// // // //                         SizedBox(height: _getSpaceL(context)),
// // // //
// // // //                         // Learning Journey
// // // //                         _buildModernLearningJourney(),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //               SizedBox(height: _getSpaceXL(context)),
// // // //             ]),
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ MODERN APP BAR - Glassmorphism Style
// // // //   Widget _buildModernAppBar() {
// // // //     return SliverAppBar(
// // // //       expandedHeight: _isMobile(context) ? 100 : 120,
// // // //       floating: true,
// // // //       pinned: true,
// // // //       elevation: 0,
// // // //       backgroundColor: Colors.transparent,
// // // //       automaticallyImplyLeading: false,
// // // //
// // // //       flexibleSpace: Container(
// // // //         decoration: BoxDecoration(
// // // //           gradient: LinearGradient(
// // // //             begin: Alignment.topLeft,
// // // //             end: Alignment.bottomRight,
// // // //             colors: [
// // // //               surfaceColor.withOpacity(0.9),
// // // //               surfaceLight.withOpacity(0.7),
// // // //             ],
// // // //           ),
// // // //           border: Border(
// // // //             bottom: BorderSide(
// // // //               color: Colors.white.withOpacity(0.1),
// // // //               width: 1,
// // // //             ),
// // // //           ),
// // // //         ),
// // // //         child: BackdropFilter(
// // // //           filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
// // // //           child: Container(
// // // //             padding: _getPaddingHorizontal(context, 1),
// // // //             child: SafeArea(
// // // //               child: Row(
// // // //                 children: [
// // // //                   // Back Button
// // // //                   Container(
// // // //                     decoration: BoxDecoration(
// // // //                       color: Colors.white.withOpacity(0.1),
// // // //                       borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //                       border: Border.all(
// // // //                         color: Colors.white.withOpacity(0.2),
// // // //                       ),
// // // //                     ),
// // // //                     child: IconButton(
// // // //                       onPressed: () => Navigator.of(context).pop(),
// // // //                       icon: Icon(
// // // //                         Icons.arrow_back_ios_new,
// // // //                         color: textPrimary,
// // // //                         size: 20,
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                   SizedBox(width: _getSpaceM(context)),
// // // //
// // // //                   // Title
// // // //                   Expanded(
// // // //                     child: Column(
// // // //                       mainAxisAlignment: MainAxisAlignment.center,
// // // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // // //                       children: [
// // // //                         Text(
// // // //                           'Profile',
// // // //                           style: TextStyle(
// // // //                             color: textPrimary,
// // // //                             fontSize: _getHeadingSize(context),
// // // //                             fontWeight: FontWeight.bold,
// // // //                           ),
// // // //                         ),
// // // //                         Text(
// // // //                           'Manage your learning profile',
// // // //                           style: TextStyle(
// // // //                             color: textSecondary,
// // // //                             fontSize: _getCaptionSize(context),
// // // //                           ),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //
// // // //                   // Refresh Button
// // // //                   Container(
// // // //                     decoration: BoxDecoration(
// // // //                       gradient: LinearGradient(
// // // //                         colors: [primaryColor, accentColor],
// // // //                       ),
// // // //                       borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //                       boxShadow: [
// // // //                         BoxShadow(
// // // //                           color: primaryColor.withOpacity(0.3),
// // // //                           blurRadius: 8,
// // // //                           offset: const Offset(0, 2),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                     child: IconButton(
// // // //                       onPressed: _refreshData,
// // // //                       icon: Icon(
// // // //                         Icons.refresh,
// // // //                         color: textPrimary,
// // // //                         size: 20,
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //   // ✅ HERO PROFILE CARD - Completely New Design
// // // //   Widget _buildHeroProfileCard() {
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: _getPaddingL(context),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Colors.white.withOpacity(0.15),
// // // //             Colors.white.withOpacity(0.05),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(_getRadiusL()),
// // // //         border: Border.all(
// // // //           color: Colors.white.withOpacity(0.2),
// // // //           width: 1,
// // // //         ),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: Colors.black.withOpacity(0.2),
// // // //             blurRadius: 20,
// // // //             offset: const Offset(0, 10),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Column(
// // // //         children: [
// // // //           // Profile Image with Level Ring
// // // //           Stack(
// // // //             alignment: Alignment.center,
// // // //             children: [
// // // //               // Animated level ring
// // // //               Container(
// // // //                 width: 120,
// // // //                 height: 120,
// // // //                 decoration: BoxDecoration(
// // // //                   shape: BoxShape.circle,
// // // //                   gradient: LinearGradient(
// // // //                     colors: [
// // // //                       _getLevelColor(),
// // // //                       _getLevelColor().withOpacity(0.6),
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //                 child: AnimatedBuilder(
// // // //                   animation: _pulseAnimation,
// // // //                   builder: (context, child) {
// // // //                     return Transform.scale(
// // // //                       scale: _pulseAnimation.value,
// // // //                       child: Container(
// // // //                         decoration: BoxDecoration(
// // // //                           shape: BoxShape.circle,
// // // //                           border: Border.all(
// // // //                             color: _getLevelColor().withOpacity(0.3),
// // // //                             width: 2,
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     );
// // // //                   },
// // // //                 ),
// // // //               ),
// // // //
// // // //               // Profile Image
// // // //               Container(
// // // //                 width: 100,
// // // //                 height: 100,
// // // //                 decoration: BoxDecoration(
// // // //                   shape: BoxShape.circle,
// // // //                   color: Colors.white,
// // // //                   boxShadow: [
// // // //                     BoxShadow(
// // // //                       color: Colors.black.withOpacity(0.2),
// // // //                       blurRadius: 15,
// // // //                       offset: const Offset(0, 5),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //                 child: ClipOval(
// // // //                   child: _profileImage != null
// // // //                       ? Image.file(_profileImage!, fit: BoxFit.cover)
// // // //                       : (profileImageBase64.isNotEmpty
// // // //                       ? Image.memory(_base64ToImage(profileImageBase64), fit: BoxFit.cover)
// // // //                       : Container(
// // // //                     decoration: BoxDecoration(
// // // //                       gradient: LinearGradient(
// // // //                         colors: [primaryColor, accentColor],
// // // //                       ),
// // // //                     ),
// // // //                     child: Center(
// // // //                       child: Text(
// // // //                         userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
// // // //                         style: TextStyle(
// // // //                           fontSize: _getHeadingSize(context),
// // // //                           fontWeight: FontWeight.bold,
// // // //                           color: textPrimary,
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                   )),
// // // //                 ),
// // // //               ),
// // // //
// // // //               // Camera Button
// // // //               Positioned(
// // // //                 bottom: 0,
// // // //                 right: 5,
// // // //                 child: GestureDetector(
// // // //                   onTap: isUploadingImage ? null : _pickImage,
// // // //                   child: Container(
// // // //                     padding: EdgeInsets.all(_getSpaceS(context)),
// // // //                     decoration: BoxDecoration(
// // // //                       gradient: LinearGradient(
// // // //                         colors: [primaryColor, accentColor],
// // // //                       ),
// // // //                       shape: BoxShape.circle,
// // // //                       border: Border.all(color: Colors.white, width: 3),
// // // //                       boxShadow: [
// // // //                         BoxShadow(
// // // //                           color: primaryColor.withOpacity(0.4),
// // // //                           blurRadius: 10,
// // // //                           offset: const Offset(0, 3),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                     child: Icon(
// // // //                       isUploadingImage ? Icons.hourglass_empty : Icons.camera_alt,
// // // //                       size: 16,
// // // //                       color: textPrimary,
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //
// // // //           SizedBox(height: _getSpaceL(context)),
// // // //
// // // //           // User Info
// // // //           Column(
// // // //             children: [
// // // //               // Name
// // // //               Text(
// // // //                 userName,
// // // //                 style: TextStyle(
// // // //                   fontSize: _getHeadingSize(context),
// // // //                   fontWeight: FontWeight.bold,
// // // //                   color: textPrimary,
// // // //                 ),
// // // //                 textAlign: TextAlign.center,
// // // //                 maxLines: 2,
// // // //                 overflow: TextOverflow.ellipsis,
// // // //               ),
// // // //               SizedBox(height: _getSpaceS(context)),
// // // //
// // // //               // Email
// // // //               Container(
// // // //                 padding: EdgeInsets.symmetric(
// // // //                   horizontal: _getSpaceM(context),
// // // //                   vertical: _getSpaceS(context),
// // // //                 ),
// // // //                 decoration: BoxDecoration(
// // // //                   color: Colors.white.withOpacity(0.1),
// // // //                   borderRadius: BorderRadius.circular(_getRadiusL()),
// // // //                   border: Border.all(
// // // //                     color: Colors.white.withOpacity(0.2),
// // // //                   ),
// // // //                 ),
// // // //                 child: Text(
// // // //                   userEmail,
// // // //                   style: TextStyle(
// // // //                     fontSize: _getBodySize(context),
// // // //                     color: textSecondary,
// // // //                   ),
// // // //                   textAlign: TextAlign.center,
// // // //                   maxLines: 1,
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //               ),
// // // //               SizedBox(height: _getSpaceL(context)),
// // // //
// // // //               // Level Badge
// // // //               Container(
// // // //                 padding: EdgeInsets.symmetric(
// // // //                   horizontal: _getSpaceL(context),
// // // //                   vertical: _getSpaceM(context),
// // // //                 ),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: LinearGradient(
// // // //                     colors: [_getLevelColor(), _getLevelColor().withOpacity(0.7)],
// // // //                   ),
// // // //                   borderRadius: BorderRadius.circular(_getRadiusL()),
// // // //                   boxShadow: [
// // // //                     BoxShadow(
// // // //                       color: _getLevelColor().withOpacity(0.4),
// // // //                       blurRadius: 15,
// // // //                       offset: const Offset(0, 5),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //                 child: Row(
// // // //                   mainAxisSize: MainAxisSize.min,
// // // //                   children: [
// // // //                     Icon(
// // // //                       _getLevelIcon(),
// // // //                       color: textPrimary,
// // // //                       size: 20,
// // // //                     ),
// // // //                     SizedBox(width: _getSpaceS(context)),
// // // //                     Text(
// // // //                       userLevel,
// // // //                       style: TextStyle(
// // // //                         fontSize: _getSubheadingSize(context),
// // // //                         fontWeight: FontWeight.bold,
// // // //                         color: textPrimary,
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ MODERN POINTS CARD - New Glassmorphism Design
// // // //   Widget _buildPointsCard() {
// // // //     return AnimatedBuilder(
// // // //       animation: _counterAnimation,
// // // //       builder: (context, child) {
// // // //         final animatedPoints = (userPoints * _counterAnimation.value).round();
// // // //
// // // //         return Container(
// // // //           width: double.infinity,
// // // //           padding: _getPaddingL(context),
// // // //           decoration: BoxDecoration(
// // // //             gradient: LinearGradient(
// // // //               begin: Alignment.topLeft,
// // // //               end: Alignment.bottomRight,
// // // //               colors: [
// // // //                 primaryColor.withOpacity(0.8),
// // // //                 accentColor.withOpacity(0.6),
// // // //               ],
// // // //             ),
// // // //             borderRadius: BorderRadius.circular(_getRadiusL()),
// // // //             boxShadow: [
// // // //               BoxShadow(
// // // //                 color: primaryColor.withOpacity(0.3),
// // // //                 blurRadius: 20,
// // // //                 offset: const Offset(0, 10),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           child: Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // //             children: [
// // // //               // Icon and Label
// // // //               Row(
// // // //                 children: [
// // // //                   Container(
// // // //                     padding: EdgeInsets.all(_getSpaceM(context)),
// // // //                     decoration: BoxDecoration(
// // // //                       color: Colors.white.withOpacity(0.2),
// // // //                       borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //                     ),
// // // //                     child: Icon(
// // // //                       Icons.stars_rounded,
// // // //                       color: textPrimary,
// // // //                       size: 24,
// // // //                     ),
// // // //                   ),
// // // //                   SizedBox(width: _getSpaceM(context)),
// // // //                   Expanded(
// // // //                     child: Text(
// // // //                       'Learning Points',
// // // //                       style: TextStyle(
// // // //                         fontSize: _getBodySize(context),
// // // //                         color: textPrimary.withOpacity(0.9),
// // // //                         fontWeight: FontWeight.w600,
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //               SizedBox(height: _getSpaceL(context)),
// // // //
// // // //               // Points Value
// // // //               Text(
// // // //                 animatedPoints.toString(),
// // // //                 style: TextStyle(
// // // //                   fontSize: _getHeadingSize(context) * 1.5,
// // // //                   fontWeight: FontWeight.bold,
// // // //                   color: textPrimary,
// // // //                 ),
// // // //               ),
// // // //               SizedBox(height: _getSpaceS(context)),
// // // //
// // // //               // Best Score
// // // //               if (bestQuizScore > 0)
// // // //                 Container(
// // // //                   padding: EdgeInsets.symmetric(
// // // //                     horizontal: _getSpaceM(context),
// // // //                     vertical: _getSpaceS(context),
// // // //                   ),
// // // //                   decoration: BoxDecoration(
// // // //                     color: Colors.white.withOpacity(0.2),
// // // //                     borderRadius: BorderRadius.circular(_getRadiusS()),
// // // //                   ),
// // // //                   child: Text(
// // // //                     'Best Quiz: $bestQuizScore pts',
// // // //                     style: TextStyle(
// // // //                       fontSize: _getCaptionSize(context),
// // // //                       color: textPrimary.withOpacity(0.8),
// // // //                       fontWeight: FontWeight.w500,
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //             ],
// // // //           ),
// // // //         );
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ MODERN LEVEL CARD - Progress Ring Design
// // // //   Widget _buildLevelCard() {
// // // //     final progress = _getLevelProgress();
// // // //
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: _getPaddingL(context),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             _getLevelColor().withOpacity(0.8),
// // // //             _getLevelColor().withOpacity(0.4),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(_getRadiusL()),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: _getLevelColor().withOpacity(0.3),
// // // //             blurRadius: 20,
// // // //             offset: const Offset(0, 10),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Column(
// // // //         children: [
// // // //           // Progress Ring
// // // //           Stack(
// // // //             alignment: Alignment.center,
// // // //             children: [
// // // //               SizedBox(
// // // //                 width: 80,
// // // //                 height: 80,
// // // //                 child: CircularProgressIndicator(
// // // //                   value: progress,
// // // //                   strokeWidth: 6,
// // // //                   backgroundColor: Colors.white.withOpacity(0.2),
// // // //                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// // // //                 ),
// // // //               ),
// // // //               Column(
// // // //                 children: [
// // // //                   Icon(
// // // //                     _getLevelIcon(),
// // // //                     color: textPrimary,
// // // //                     size: 24,
// // // //                   ),
// // // //                   Text(
// // // //                     '${(progress * 100).toInt()}%',
// // // //                     style: TextStyle(
// // // //                       fontSize: _getBodySize(context),
// // // //                       fontWeight: FontWeight.bold,
// // // //                       color: textPrimary,
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           SizedBox(height: _getSpaceL(context)),
// // // //
// // // //           // Level Info
// // // //           Text(
// // // //             userLevel,
// // // //             style: TextStyle(
// // // //               fontSize: _getSubheadingSize(context),
// // // //               fontWeight: FontWeight.bold,
// // // //               color: textPrimary,
// // // //             ),
// // // //           ),
// // // //           SizedBox(height: _getSpaceS(context)),
// // // //
// // // //           Text(
// // // //             _getNextLevelInfo(),
// // // //             style: TextStyle(
// // // //               fontSize: _getCaptionSize(context),
// // // //               color: textPrimary.withOpacity(0.8),
// // // //             ),
// // // //             textAlign: TextAlign.center,
// // // //             maxLines: 2,
// // // //             overflow: TextOverflow.ellipsis,
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //   // ✅ MODERN STATS GRID - Completely New Design
// // // //   Widget _buildModernStatsGrid() {
// // // //     return LayoutBuilder(
// // // //       builder: (context, constraints) {
// // // //         final crossAxisCount = _getStatsColumns(context);
// // // //         final aspectRatio = _getStatsAspectRatio(context);
// // // //         final spacing = _getSpaceM(context);
// // // //
// // // //         return GridView.count(
// // // //           shrinkWrap: true,
// // // //           physics: const NeverScrollableScrollPhysics(),
// // // //           crossAxisCount: crossAxisCount,
// // // //           childAspectRatio: aspectRatio,
// // // //           crossAxisSpacing: spacing,
// // // //           mainAxisSpacing: spacing,
// // // //           children: [
// // // //             _buildModernStatCard(
// // // //               icon: Icons.article_outlined,
// // // //               title: "Notes",
// // // //               value: notesCount.toString(),
// // // //               subtitle: "Saved",
// // // //               color: const Color(0xFF8B5CF6),
// // // //               gradient: [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
// // // //             ),
// // // //             _buildModernStatCard(
// // // //               icon: Icons.play_circle_outline,
// // // //               title: "Videos",
// // // //               value: savedVideosCount.toString(),
// // // //               subtitle: "Bookmarked",
// // // //               color: const Color(0xFFEF4444),
// // // //               gradient: [const Color(0xFFEF4444), const Color(0xFFF87171)],
// // // //             ),
// // // //             _buildModernStatCard(
// // // //               icon: Icons.link_outlined,
// // // //               title: "Links",
// // // //               value: savedLinksCount.toString(),
// // // //               subtitle: "Resources",
// // // //               color: const Color(0xFF3B82F6),
// // // //               gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
// // // //             ),
// // // //             _buildModernStatCard(
// // // //               icon: Icons.quiz_outlined,
// // // //               title: "Quizzes",
// // // //               value: quizzesTaken.toString(),
// // // //               subtitle: "Completed",
// // // //               color: const Color(0xFF10B981),
// // // //               gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
// // // //             ),
// // // //           ],
// // // //         );
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ MODERN STAT CARD - Glassmorphism with Animated Numbers
// // // //   Widget _buildModernStatCard({
// // // //     required IconData icon,
// // // //     required String title,
// // // //     required String value,
// // // //     required String subtitle,
// // // //     required Color color,
// // // //     required List<Color> gradient,
// // // //   }) {
// // // //     return AnimatedBuilder(
// // // //       animation: _counterAnimation,
// // // //       builder: (context, child) {
// // // //         final animatedValue = (int.tryParse(value) ?? 0) * _counterAnimation.value;
// // // //
// // // //         return Container(
// // // //           decoration: BoxDecoration(
// // // //             gradient: LinearGradient(
// // // //               begin: Alignment.topLeft,
// // // //               end: Alignment.bottomRight,
// // // //               colors: [
// // // //                 Colors.white.withOpacity(0.15),
// // // //                 Colors.white.withOpacity(0.05),
// // // //               ],
// // // //             ),
// // // //             borderRadius: BorderRadius.circular(_getRadiusL()),
// // // //             border: Border.all(
// // // //               color: Colors.white.withOpacity(0.2),
// // // //               width: 1,
// // // //             ),
// // // //             boxShadow: [
// // // //               BoxShadow(
// // // //                 color: Colors.black.withOpacity(0.1),
// // // //                 blurRadius: 15,
// // // //                 offset: const Offset(0, 5),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           child: LayoutBuilder(
// // // //             builder: (context, constraints) {
// // // //               return Padding(
// // // //                 padding: EdgeInsets.all(constraints.maxWidth * 0.08),
// // // //                 child: Column(
// // // //                   mainAxisAlignment: MainAxisAlignment.center,
// // // //                   children: [
// // // //                     // Icon with gradient background
// // // //                     Container(
// // // //                       padding: EdgeInsets.all(constraints.maxWidth * 0.08),
// // // //                       decoration: BoxDecoration(
// // // //                         gradient: LinearGradient(colors: gradient),
// // // //                         borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //                         boxShadow: [
// // // //                           BoxShadow(
// // // //                             color: color.withOpacity(0.3),
// // // //                             blurRadius: 10,
// // // //                             offset: const Offset(0, 3),
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                       child: Icon(
// // // //                         icon,
// // // //                         color: textPrimary,
// // // //                         size: (constraints.maxWidth * 0.15).clamp(16.0, 28.0),
// // // //                       ),
// // // //                     ),
// // // //
// // // //                     SizedBox(height: constraints.maxHeight * 0.08),
// // // //
// // // //                     // Animated Value
// // // //                     Flexible(
// // // //                       child: FittedBox(
// // // //                         fit: BoxFit.scaleDown,
// // // //                         child: Text(
// // // //                           animatedValue.round().toString(),
// // // //                           style: TextStyle(
// // // //                             color: textPrimary,
// // // //                             fontSize: (constraints.maxWidth * 0.2).clamp(18.0, 32.0),
// // // //                             fontWeight: FontWeight.bold,
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //
// // // //                     SizedBox(height: constraints.maxHeight * 0.02),
// // // //
// // // //                     // Title
// // // //                     Flexible(
// // // //                       child: Text(
// // // //                         title,
// // // //                         style: TextStyle(
// // // //                           color: textSecondary,
// // // //                           fontSize: (constraints.maxWidth * 0.08).clamp(10.0, 14.0),
// // // //                           fontWeight: FontWeight.w600,
// // // //                         ),
// // // //                         textAlign: TextAlign.center,
// // // //                         maxLines: 1,
// // // //                         overflow: TextOverflow.ellipsis,
// // // //                       ),
// // // //                     ),
// // // //
// // // //                     // Subtitle
// // // //                     Flexible(
// // // //                       child: Text(
// // // //                         subtitle,
// // // //                         style: TextStyle(
// // // //                           color: textTertiary,
// // // //                           fontSize: (constraints.maxWidth * 0.06).clamp(8.0, 12.0),
// // // //                         ),
// // // //                         textAlign: TextAlign.center,
// // // //                         maxLines: 1,
// // // //                         overflow: TextOverflow.ellipsis,
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               );
// // // //             },
// // // //           ),
// // // //         );
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ QUICK ACTIONS CARD - New Modern Design
// // // //   Widget _buildQuickActionsCard() {
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: _getPaddingL(context),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Colors.white.withOpacity(0.15),
// // // //             Colors.white.withOpacity(0.05),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(_getRadiusL()),
// // // //         border: Border.all(
// // // //           color: Colors.white.withOpacity(0.2),
// // // //           width: 1,
// // // //         ),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: Colors.black.withOpacity(0.1),
// // // //             blurRadius: 15,
// // // //             offset: const Offset(0, 5),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           // Header
// // // //           Row(
// // // //             children: [
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getSpaceM(context)),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: LinearGradient(
// // // //                     colors: [warningColor, warningColor.withOpacity(0.7)],
// // // //                   ),
// // // //                   borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //                 ),
// // // //                 child: Icon(
// // // //                   Icons.flash_on,
// // // //                   color: textPrimary,
// // // //                   size: 20,
// // // //                 ),
// // // //               ),
// // // //               SizedBox(width: _getSpaceM(context)),
// // // //               Expanded(
// // // //                 child: Text(
// // // //                   'Quick Actions',
// // // //                   style: TextStyle(
// // // //                     fontSize: _getSubheadingSize(context),
// // // //                     fontWeight: FontWeight.bold,
// // // //                     color: textPrimary,
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           SizedBox(height: _getSpaceL(context)),
// // // //
// // // //           // Action Buttons Grid - Modified this part
// // // //           LayoutBuilder(
// // // //             builder: (context, constraints) {
// // // //               return GridView.count(
// // // //                 shrinkWrap: true,
// // // //                 physics: const NeverScrollableScrollPhysics(),
// // // //                 crossAxisCount: 2,
// // // //                 childAspectRatio: constraints.maxWidth > 400 ? 3 : 2.5, // Responsive aspect ratio
// // // //                 crossAxisSpacing: _getSpaceM(context),
// // // //                 mainAxisSpacing: _getSpaceM(context),
// // // //                 children: [
// // // //                   _buildActionButton(
// // // //                     icon: Icons.edit,
// // // //                     label: 'Edit Profile',
// // // //                     onTap: () => setState(() => isEditing = true),
// // // //                     gradient: [primaryColor, primaryLight],
// // // //                   ),
// // // //                   _buildActionButton(
// // // //                     icon: Icons.refresh,
// // // //                     label: 'Refresh Data',
// // // //                     onTap: _refreshData,
// // // //                     gradient: [accentColor, accentLight],
// // // //                   ),
// // // //                   _buildActionButton(
// // // //                     icon: Icons.camera_alt,
// // // //                     label: 'Change Photo',
// // // //                     onTap: _pickImage,
// // // //                     gradient: [successColor, const Color(0xFF34D399)],
// // // //                   ),
// // // //                   _buildActionButton(
// // // //                     icon: Icons.logout,
// // // //                     label: 'Sign Out',
// // // //                     onTap: _showLogoutDialog,
// // // //                     gradient: [errorColor, const Color(0xFFF87171)],
// // // //                   ),
// // // //                 ],
// // // //               );
// // // //             },
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //   // ✅ ACTION BUTTON - Micro-interaction Design
// // // //   Widget _buildActionButton({
// // // //     required IconData icon,
// // // //     required String label,
// // // //     required VoidCallback onTap,
// // // //     required List<Color> gradient,
// // // //   }) {
// // // //     return GestureDetector(
// // // //       onTap: onTap,
// // // //       child: Container(
// // // //         height: 50, // Add fixed height
// // // //         decoration: BoxDecoration(
// // // //           gradient: LinearGradient(colors: gradient),
// // // //           borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //           boxShadow: [
// // // //             BoxShadow(
// // // //               color: gradient[0].withOpacity(0.3),
// // // //               blurRadius: 8,
// // // //               offset: const Offset(0, 3),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //         child: Material(
// // // //           color: Colors.transparent,
// // // //           child: InkWell(
// // // //             borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //             onTap: onTap,
// // // //             child: Padding(
// // // //               padding: EdgeInsets.symmetric( // Change to symmetric padding
// // // //                 horizontal: _getSpaceM(context),
// // // //                 vertical: _getSpaceS(context),
// // // //               ),
// // // //               child: Row(
// // // //                 mainAxisAlignment: MainAxisAlignment.center,
// // // //                 children: [
// // // //                   Icon(
// // // //                     icon,
// // // //                     color: textPrimary,
// // // //                     size: 16,
// // // //                   ),
// // // //                   SizedBox(width: _getSpaceS(context)),
// // // //                   Flexible(
// // // //                     child: Text(
// // // //                       label,
// // // //                       style: TextStyle(
// // // //                         fontSize: _getBodySize(context), // Increase font size
// // // //                         fontWeight: FontWeight.w600,
// // // //                         color: textPrimary,
// // // //                       ),
// // // //                       maxLines: 1,
// // // //                       overflow: TextOverflow.ellipsis,
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //   // ✅ MODERN LEARNING JOURNEY - Timeline Design
// // // //   Widget _buildModernLearningJourney() {
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: _getPaddingL(context),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Colors.white.withOpacity(0.15),
// // // //             Colors.white.withOpacity(0.05),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(_getRadiusL()),
// // // //         border: Border.all(
// // // //           color: Colors.white.withOpacity(0.2),
// // // //           width: 1,
// // // //         ),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: Colors.black.withOpacity(0.1),
// // // //             blurRadius: 15,
// // // //             offset: const Offset(0, 5),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           // Header
// // // //           Row(
// // // //             children: [
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getSpaceM(context)),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: LinearGradient(
// // // //                     colors: [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
// // // //                   ),
// // // //                   borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //                 ),
// // // //                 child: Icon(
// // // //                   Icons.trending_up,
// // // //                   color: textPrimary,
// // // //                   size: 20,
// // // //                 ),
// // // //               ),
// // // //               SizedBox(width: _getSpaceM(context)),
// // // //               Expanded(
// // // //                 child: Text(
// // // //                   'Learning Journey',
// // // //                   style: TextStyle(
// // // //                     fontSize: _getSubheadingSize(context),
// // // //                     fontWeight: FontWeight.bold,
// // // //                     color: textPrimary,
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           SizedBox(height: _getSpaceL(context)),
// // // //
// // // //           // Achievements Timeline
// // // //           ..._buildModernAchievements(),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   List<Widget> _buildModernAchievements() {
// // // //     List<Widget> achievements = [];
// // // //
// // // //     if (userPoints > 0) {
// // // //       achievements.add(_buildTimelineItem(
// // // //         icon: Icons.emoji_events,
// // // //         title: "Points Earned",
// // // //         subtitle: "$userPoints learning points collected!",
// // // //         time: _getPointsMessage(),
// // // //         color: warningColor,
// // // //         isFirst: true,
// // // //       ));
// // // //     }
// // // //
// // // //     if (quizzesTaken > 0) {
// // // //       achievements.add(_buildTimelineItem(
// // // //         icon: Icons.quiz,
// // // //         title: "Quiz Master",
// // // //         subtitle: "Completed $quizzesTaken ${quizzesTaken == 1 ? 'quiz' : 'quizzes'}",
// // // //         time: bestQuizScore > 0 ? "Best: $bestQuizScore pts" : "Keep going!",
// // // //         color: successColor,
// // // //       ));
// // // //     }
// // // //
// // // //     if (notesCount > 0) {
// // // //       achievements.add(_buildTimelineItem(
// // // //         icon: Icons.note_add,
// // // //         title: "Note Keeper",
// // // //         subtitle: "Saved $notesCount ${notesCount == 1 ? 'note' : 'notes'}",
// // // //         time: "Great organization!",
// // // //         color: primaryColor,
// // // //       ));
// // // //     }
// // // //
// // // //     if (savedVideosCount > 0) {
// // // //       achievements.add(_buildTimelineItem(
// // // //         icon: Icons.video_library,
// // // //         title: "Video Learner",
// // // //         subtitle: "Bookmarked $savedVideosCount ${savedVideosCount == 1 ? 'video' : 'videos'}",
// // // //         time: "Visual learning!",
// // // //         color: errorColor,
// // // //         isLast: true,
// // // //       ));
// // // //     }
// // // //
// // // //     // If no achievements yet
// // // //     if (achievements.isEmpty) {
// // // //       achievements.add(_buildTimelineItem(
// // // //         icon: Icons.rocket_launch,
// // // //         title: "Start Your Journey",
// // // //         subtitle: "Take your first quiz or save your first note!",
// // // //         time: "You've got this! 🚀",
// // // //         color: accentColor,
// // // //         isFirst: true,
// // // //         isLast: true,
// // // //       ));
// // // //     }
// // // //
// // // //     return achievements;
// // // //   }
// // // //
// // // //   String _getPointsMessage() {
// // // //     if (userPoints >= 5000) return "Amazing! 🏆";
// // // //     if (userPoints >= 3000) return "Excellent! 🌟";
// // // //     if (userPoints >= 1500) return "Great job! 🎉";
// // // //     if (userPoints >= 500) return "Keep going! 💪";
// // // //     return "Good start! 👍";
// // // //   }
// // // //
// // // //   // ✅ TIMELINE ITEM - Modern Achievement Card
// // // //   Widget _buildTimelineItem({
// // // //     required IconData icon,
// // // //     required String title,
// // // //     required String subtitle,
// // // //     required String time,
// // // //     required Color color,
// // // //     bool isFirst = false,
// // // //     bool isLast = false,
// // // //   }) {
// // // //     return Container(
// // // //       margin: EdgeInsets.only(bottom: isLast ? 0 : _getSpaceM(context)),
// // // //       child: Row(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           // Timeline indicator
// // // //           Column(
// // // //             children: [
// // // //               Container(
// // // //                 width: 40,
// // // //                 height: 40,
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: LinearGradient(
// // // //                     colors: [color, color.withOpacity(0.7)],
// // // //                   ),
// // // //                   shape: BoxShape.circle,
// // // //                   boxShadow: [
// // // //                     BoxShadow(
// // // //                       color: color.withOpacity(0.3),
// // // //                       blurRadius: 8,
// // // //                       offset: const Offset(0, 2),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //                 child: Icon(
// // // //                   icon,
// // // //                   color: textPrimary,
// // // //                   size: 20,
// // // //                 ),
// // // //               ),
// // // //               if (!isLast)
// // // //                 Container(
// // // //                   width: 2,
// // // //                   height: 40,
// // // //                   margin: EdgeInsets.symmetric(vertical: _getSpaceS(context)),
// // // //                   decoration: BoxDecoration(
// // // //                     gradient: LinearGradient(
// // // //                       begin: Alignment.topCenter,
// // // //                       end: Alignment.bottomCenter,
// // // //                       colors: [
// // // //                         color.withOpacity(0.5),
// // // //                         Colors.white.withOpacity(0.1),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //             ],
// // // //           ),
// // // //           SizedBox(width: _getSpaceM(context)),
// // // //
// // // //           // Content
// // // //           Expanded(
// // // //             child: Container(
// // // //               padding: _getPaddingM(context),
// // // //               decoration: BoxDecoration(
// // // //                 color: Colors.white.withOpacity(0.05),
// // // //                 borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //                 border: Border.all(
// // // //                   color: color.withOpacity(0.2),
// // // //                 ),
// // // //               ),
// // // //               child: Column(
// // // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // // //                 children: [
// // // //                   Row(
// // // //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                     children: [
// // // //                       Expanded(
// // // //                         child: Text(
// // // //                           title,
// // // //                           style: TextStyle(
// // // //                             color: textPrimary,
// // // //                             fontWeight: FontWeight.w600,
// // // //                             fontSize: _getBodySize(context),
// // // //                           ),
// // // //                           maxLines: 1,
// // // //                           overflow: TextOverflow.ellipsis,
// // // //                         ),
// // // //                       ),
// // // //                       if (time.isNotEmpty)
// // // //                         Text(
// // // //                           time,
// // // //                           style: TextStyle(
// // // //                             color: color,
// // // //                             fontSize: _getCaptionSize(context),
// // // //                             fontWeight: FontWeight.w500,
// // // //                           ),
// // // //                           maxLines: 1,
// // // //                           overflow: TextOverflow.ellipsis,
// // // //                         ),
// // // //                     ],
// // // //                   ),
// // // //                   SizedBox(height: _getSpaceXS(context)),
// // // //                   Text(
// // // //                     subtitle,
// // // //                     style: TextStyle(
// // // //                       color: textSecondary,
// // // //                       fontSize: _getCaptionSize(context),
// // // //                     ),
// // // //                     maxLines: 2,
// // // //                     overflow: TextOverflow.ellipsis,
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ MODERN ACCOUNT SETTINGS - New Card Design
// // // //   Widget _buildModernAccountSettings() {
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: _getPaddingL(context),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Colors.white.withOpacity(0.15),
// // // //             Colors.white.withOpacity(0.05),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(_getRadiusL()),
// // // //         border: Border.all(
// // // //           color: Colors.white.withOpacity(0.2),
// // // //           width: 1,
// // // //         ),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: Colors.black.withOpacity(0.1),
// // // //             blurRadius: 15,
// // // //             offset: const Offset(0, 5),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           // Header
// // // //           Row(
// // // //             children: [
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getSpaceM(context)),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: LinearGradient(
// // // //                     colors: [primaryColor, accentColor],
// // // //                   ),
// // // //                   borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //                 ),
// // // //                 child: Icon(
// // // //                   Icons.settings,
// // // //                   color: textPrimary,
// // // //                   size: 20,
// // // //                 ),
// // // //               ),
// // // //               SizedBox(width: _getSpaceM(context)),
// // // //               Expanded(
// // // //                 child: Text(
// // // //                   'Account Settings',
// // // //                   style: TextStyle(
// // // //                     fontSize: _getSubheadingSize(context),
// // // //                     fontWeight: FontWeight.bold,
// // // //                     color: textPrimary,
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //               if (!isEditing)
// // // //                 GestureDetector(
// // // //                   onTap: () => setState(() => isEditing = true),
// // // //                   child: Container(
// // // //                     padding: EdgeInsets.all(_getSpaceS(context)),
// // // //                     decoration: BoxDecoration(
// // // //                       color: Colors.white.withOpacity(0.1),
// // // //                       borderRadius: BorderRadius.circular(_getRadiusS()),
// // // //                       border: Border.all(
// // // //                         color: primaryColor.withOpacity(0.3),
// // // //                       ),
// // // //                     ),
// // // //                     child: Icon(
// // // //                       Icons.edit,
// // // //                       color: primaryColor,
// // // //                       size: 18,
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //             ],
// // // //           ),
// // // //           SizedBox(height: _getSpaceL(context)),
// // // //
// // // //           // Form Fields
// // // //           _buildModernTextField(
// // // //             label: "Full Name",
// // // //             value: userName,
// // // //             controller: _nameController,
// // // //             icon: Icons.person_outline,
// // // //           ),
// // // //           SizedBox(height: _getSpaceM(context)),
// // // //
// // // //           _buildModernTextField(
// // // //             label: "Email Address",
// // // //             value: userEmail,
// // // //             controller: _emailController,
// // // //             icon: Icons.email_outlined,
// // // //           ),
// // // //
// // // //           // Action Buttons
// // // //           if (isEditing) ...[
// // // //             SizedBox(height: _getSpaceL(context)),
// // // //             Row(
// // // //               children: [
// // // //                 Expanded(
// // // //                   child: _buildModernButton(
// // // //                     label: "Cancel",
// // // //                     onPressed: _cancelEditing,
// // // //                     isPrimary: false,
// // // //                   ),
// // // //                 ),
// // // //                 SizedBox(width: _getSpaceM(context)),
// // // //                 Expanded(
// // // //                   child: _buildModernButton(
// // // //                     label: "Save Changes",
// // // //                     onPressed: _updateProfile,
// // // //                     isPrimary: true,
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ],
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ MODERN TEXT FIELD - Glassmorphism Input Design
// // // //   Widget _buildModernTextField({
// // // //     required String label,
// // // //     required String value,
// // // //     required TextEditingController controller,
// // // //     required IconData icon,
// // // //   }) {
// // // //     return Container(
// // // //       padding: _getPaddingM(context),
// // // //       decoration: BoxDecoration(
// // // //         color: isEditing
// // // //             ? Colors.white.withOpacity(0.1)
// // // //             : Colors.white.withOpacity(0.05),
// // // //         borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //         border: Border.all(
// // // //           color: isEditing
// // // //               ? primaryColor.withOpacity(0.4)
// // // //               : Colors.white.withOpacity(0.1),
// // // //           width: 1.5,
// // // //         ),
// // // //       ),
// // // //       child: Row(
// // // //         children: [
// // // //           Container(
// // // //             padding: EdgeInsets.all(_getSpaceS(context)),
// // // //             decoration: BoxDecoration(
// // // //               gradient: LinearGradient(
// // // //                 colors: [primaryColor.withOpacity(0.2), accentColor.withOpacity(0.2)],
// // // //               ),
// // // //               borderRadius: BorderRadius.circular(_getRadiusS()),
// // // //             ),
// // // //             child: Icon(
// // // //               icon,
// // // //               color: primaryColor,
// // // //               size: 20,
// // // //             ),
// // // //           ),
// // // //           SizedBox(width: _getSpaceM(context)),
// // // //           Expanded(
// // // //             child: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               children: [
// // // //                 Text(
// // // //                   label,
// // // //                   style: TextStyle(
// // // //                     color: textTertiary,
// // // //                     fontSize: _getCaptionSize(context),
// // // //                     fontWeight: FontWeight.w500,
// // // //                   ),
// // // //                 ),
// // // //                 SizedBox(height: _getSpaceXS(context)),
// // // //                 isEditing
// // // //                     ? TextField(
// // // //                   controller: controller,
// // // //                   style: TextStyle(
// // // //                     color: textPrimary,
// // // //                     fontSize: _getBodySize(context),
// // // //                     fontWeight: FontWeight.w500,
// // // //                   ),
// // // //                   decoration: const InputDecoration(
// // // //                     isDense: true,
// // // //                     contentPadding: EdgeInsets.zero,
// // // //                     border: InputBorder.none,
// // // //                   ),
// // // //                   maxLines: 1,
// // // //                 )
// // // //                     : Text(
// // // //                   value,
// // // //                   style: TextStyle(
// // // //                     color: textPrimary,
// // // //                     fontSize: _getBodySize(context),
// // // //                     fontWeight: FontWeight.w500,
// // // //                   ),
// // // //                   maxLines: 1,
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ MODERN BUTTON - Gradient Design
// // // //   Widget _buildModernButton({
// // // //     required String label,
// // // //     required VoidCallback onPressed,
// // // //     required bool isPrimary,
// // // //   }) {
// // // //     return Container(
// // // //       height: 50,
// // // //       decoration: BoxDecoration(
// // // //         gradient: isPrimary
// // // //             ? LinearGradient(colors: [primaryColor, accentColor])
// // // //             : null,
// // // //         color: isPrimary ? null : Colors.white.withOpacity(0.1),
// // // //         borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //         border: isPrimary
// // // //             ? null
// // // //             : Border.all(color: Colors.white.withOpacity(0.3)),
// // // //         boxShadow: isPrimary ? [
// // // //           BoxShadow(
// // // //             color: primaryColor.withOpacity(0.3),
// // // //             blurRadius: 10,
// // // //             offset: const Offset(0, 4),
// // // //           ),
// // // //         ] : null,
// // // //       ),
// // // //       child: Material(
// // // //         color: Colors.transparent,
// // // //         child: InkWell(
// // // //           borderRadius: BorderRadius.circular(_getRadiusM()),
// // // //           onTap: onPressed,
// // // //           child: Center(
// // // //             child: Text(
// // // //               label,
// // // //               style: TextStyle(
// // // //                 color: textPrimary,
// // // //                 fontSize: _getBodySize(context),
// // // //                 fontWeight: FontWeight.w600,
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // // //
// // // // // ✅ MODERN LOGOUT DIALOG - Completely New Design
// // // // class _ModernLogoutDialog extends StatefulWidget {
// // // //   @override
// // // //   _ModernLogoutDialogState createState() => _ModernLogoutDialogState();
// // // // }
// // // //
// // // // class _ModernLogoutDialogState extends State<_ModernLogoutDialog>
// // // //     with SingleTickerProviderStateMixin {
// // // //   bool _isLoggingOut = false;
// // // //   late AnimationController _animationController;
// // // //   late Animation<double> _scaleAnimation;
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _animationController = AnimationController(
// // // //       duration: const Duration(milliseconds: 300),
// // // //       vsync: this,
// // // //     );
// // // //     _scaleAnimation = CurvedAnimation(
// // // //       parent: _animationController,
// // // //       curve: Curves.elasticOut,
// // // //     );
// // // //     _animationController.forward();
// // // //   }
// // // //
// // // //   @override
// // // //   void dispose() {
// // // //     _animationController.dispose();
// // // //     super.dispose();
// // // //   }
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Dialog(
// // // //       backgroundColor: Colors.transparent,
// // // //       elevation: 0,
// // // //       child: ScaleTransition(
// // // //         scale: _scaleAnimation,
// // // //         child: Container(
// // // //           width: double.infinity,
// // // //           constraints: BoxConstraints(
// // // //             maxWidth: MediaQuery.of(context).size.width * 0.9,
// // // //             maxHeight: MediaQuery.of(context).size.height * 0.6,
// // // //           ),
// // // //           margin: const EdgeInsets.all(20),
// // // //           decoration: BoxDecoration(
// // // //             gradient: const LinearGradient(
// // // //               begin: Alignment.topLeft,
// // // //               end: Alignment.bottomRight,
// // // //               colors: [
// // // //                 Color(0xFF1E293B),
// // // //                 Color(0xFF0F172A),
// // // //               ],
// // // //             ),
// // // //             borderRadius: BorderRadius.circular(24),
// // // //             border: Border.all(
// // // //               color: const Color(0xFFEF4444).withOpacity(0.3),
// // // //               width: 2,
// // // //             ),
// // // //             boxShadow: [
// // // //               BoxShadow(
// // // //                 color: Colors.black.withOpacity(0.5),
// // // //                 blurRadius: 30,
// // // //                 offset: const Offset(0, 15),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           child: Padding(
// // // //             padding: const EdgeInsets.all(32),
// // // //             child: Column(
// // // //               mainAxisSize: MainAxisSize.min,
// // // //               children: [
// // // //                 // Logout icon with animation
// // // //                 Container(
// // // //                   width: 80,
// // // //                   height: 80,
// // // //                   decoration: BoxDecoration(
// // // //                     gradient: LinearGradient(
// // // //                       colors: _isLoggingOut
// // // //                           ? [Colors.grey, Colors.grey.shade600]
// // // //                           : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
// // // //                     ),
// // // //                     shape: BoxShape.circle,
// // // //                     boxShadow: [
// // // //                       BoxShadow(
// // // //                         color: (_isLoggingOut ? Colors.grey : const Color(0xFFEF4444))
// // // //                             .withOpacity(0.4),
// // // //                         blurRadius: 20,
// // // //                         spreadRadius: 5,
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                   child: _isLoggingOut
// // // //                       ? const CircularProgressIndicator(
// // // //                     strokeWidth: 3,
// // // //                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// // // //                   )
// // // //                       : const Icon(
// // // //                     Icons.logout_rounded,
// // // //                     color: Colors.white,
// // // //                     size: 36,
// // // //                   ),
// // // //                 ),
// // // //
// // // //                 const SizedBox(height: 24),
// // // //
// // // //                 // Title
// // // //                 Text(
// // // //                   _isLoggingOut ? 'Signing Out...' : 'Ready to Sign Out?',
// // // //                   style: const TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: 24,
// // // //                     fontWeight: FontWeight.bold,
// // // //                   ),
// // // //                   textAlign: TextAlign.center,
// // // //                 ),
// // // //
// // // //                 const SizedBox(height: 16),
// // // //
// // // //                 // Security message
// // // //                 Container(
// // // //                   padding: const EdgeInsets.all(20),
// // // //                   decoration: BoxDecoration(
// // // //                     color: const Color(0xFF334155),
// // // //                     borderRadius: BorderRadius.circular(16),
// // // //                     border: Border.all(
// // // //                       color: Colors.white.withOpacity(0.1),
// // // //                     ),
// // // //                   ),
// // // //                   child: Column(
// // // //                     children: [
// // // //                       const Icon(
// // // //                         Icons.verified_user,
// // // //                         color: Color(0xFF06B6D4),
// // // //                         size: 24,
// // // //                       ),
// // // //                       const SizedBox(height: 12),
// // // //                       Text(
// // // //                         _isLoggingOut
// // // //                             ? 'Saving your progress and signing out safely...'
// // // //                             : 'Your learning progress is safely saved!\nYou can continue where you left off.',
// // // //                         style: const TextStyle(
// // // //                           color: Colors.white70,
// // // //                           fontSize: 14,
// // // //                           height: 1.4,
// // // //                         ),
// // // //                         textAlign: TextAlign.center,
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //
// // // //                 const SizedBox(height: 32),
// // // //
// // // //                 // Action buttons
// // // //                 Row(
// // // //                   children: [
// // // //                     // Stay button
// // // //                     Expanded(
// // // //                       child: Container(
// // // //                         height: 50,
// // // //                         decoration: BoxDecoration(
// // // //                           color: Colors.transparent,
// // // //                           borderRadius: BorderRadius.circular(16),
// // // //                           border: Border.all(
// // // //                             color: Colors.white.withOpacity(0.3),
// // // //                           ),
// // // //                         ),
// // // //                         child: Material(
// // // //                           color: Colors.transparent,
// // // //                           child: InkWell(
// // // //                             borderRadius: BorderRadius.circular(16),
// // // //                             onTap: _isLoggingOut ? null : () => Navigator.of(context).pop(),
// // // //                             child: const Center(
// // // //                               child: Text(
// // // //                                 'Stay Here',
// // // //                                 style: TextStyle(
// // // //                                   color: Colors.white70,
// // // //                                   fontSize: 16,
// // // //                                   fontWeight: FontWeight.w600,
// // // //                                 ),
// // // //                               ),
// // // //                             ),
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //
// // // //                     const SizedBox(width: 16),
// // // //
// // // //                     // Sign Out button
// // // //                     Expanded(
// // // //                       child: Container(
// // // //                         height: 50,
// // // //                         decoration: BoxDecoration(
// // // //                           gradient: LinearGradient(
// // // //                             colors: _isLoggingOut
// // // //                                 ? [Colors.grey, Colors.grey.shade600]
// // // //                                 : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
// // // //                           ),
// // // //                           borderRadius: BorderRadius.circular(16),
// // // //                           boxShadow: [
// // // //                             BoxShadow(
// // // //                               color: (_isLoggingOut ? Colors.grey : const Color(0xFFEF4444))
// // // //                                   .withOpacity(0.3),
// // // //                               blurRadius: 10,
// // // //                               offset: const Offset(0, 4),
// // // //                             ),
// // // //                           ],
// // // //                         ),
// // // //                         child: Material(
// // // //                           color: Colors.transparent,
// // // //                           child: InkWell(
// // // //                             borderRadius: BorderRadius.circular(16),
// // // //                             onTap: _isLoggingOut ? null : _handleLogout,
// // // //                             child: Center(
// // // //                               child: Row(
// // // //                                 mainAxisAlignment: MainAxisAlignment.center,
// // // //                                 children: [
// // // //                                   if (_isLoggingOut) ...[
// // // //                                     const SizedBox(
// // // //                                       width: 16,
// // // //                                       height: 16,
// // // //                                       child: CircularProgressIndicator(
// // // //                                         strokeWidth: 2,
// // // //                                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// // // //                                       ),
// // // //                                     ),
// // // //                                   ] else ...[
// // // //                                     const Icon(
// // // //                                       Icons.logout_rounded,
// // // //                                       color: Colors.white,
// // // //                                       size: 18,
// // // //                                     ),
// // // //                                   ],
// // // //                                   const SizedBox(width: 8),
// // // //                                   Text(
// // // //                                     _isLoggingOut ? 'Signing Out...' : 'Sign Out',
// // // //                                     style: const TextStyle(
// // // //                                       color: Colors.white,
// // // //                                       fontSize: 16,
// // // //                                       fontWeight: FontWeight.bold,
// // // //                                     ),
// // // //                                   ),
// // // //                                 ],
// // // //                               ),
// // // //                             ),
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   Future<void> _handleLogout() async {
// // // //     if (!mounted) return;
// // // //
// // // //     setState(() {
// // // //       _isLoggingOut = true;
// // // //     });
// // // //
// // // //     try {
// // // //       await _performLogout();
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           _isLoggingOut = false;
// // // //         });
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(
// // // //             content: Text('Logout failed: ${e.toString()}'),
// // // //             backgroundColor: const Color(0xFFEF4444),
// // // //             behavior: SnackBarBehavior.floating,
// // // //             shape: RoundedRectangleBorder(
// // // //               borderRadius: BorderRadius.circular(12),
// // // //             ),
// // // //           ),
// // // //         );
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _performLogout() async {
// // // //     try {
// // // //       // Sign out from Firebase
// // // //       await FirebaseAuth.instance.signOut();
// // // //
// // // //       // Clear SharedPreferences
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       await prefs.setBool('is_logged_in', false);
// // // //       await prefs.remove('last_login');
// // // //
// // // //       if (mounted) {
// // // //         Navigator.of(context).pop();
// // // //         Navigator.of(context).pushAndRemoveUntil(
// // // //           MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
// // // //               (route) => false,
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         Navigator.of(context).pop();
// // // //       }
// // // //       throw e;
// // // //     }
// // // //   }
// // // // }
// // //
// // //
// // //
// // //
// // // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // // import 'package:firebase_auth/firebase_auth.dart';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // import 'package:image_picker/image_picker.dart';
// // // // import 'dart:io';
// // // // import 'dart:convert';
// // // // import 'dart:typed_data';
// // // // import 'dart:ui';
// // // //
// // // // import 'email_change_verification_screen.dart';
// // // // import 'login_screen.dart';
// // // //
// // // // class ProfileScreen extends StatefulWidget {
// // // //   const ProfileScreen({super.key});
// // // //
// // // //   @override
// // // //   State<ProfileScreen> createState() => _ProfileScreenState();
// // // // }
// // // //
// // // // class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
// // // //   // Data variables
// // // //   String userName = "Loading...";
// // // //   String userEmail = "Loading...";
// // // //   String profileImageBase64 = "";
// // // //   int userPoints = 0;
// // // //   int notesCount = 0;
// // // //   int savedVideosCount = 0;
// // // //   int savedLinksCount = 0;
// // // //   int quizzesTaken = 0;
// // // //   int bestQuizScore = 0;
// // // //   String userLevel = "Rookie";
// // // //
// // // //   // UI state variables
// // // //   bool isEditing = false;
// // // //   bool isLoading = true;
// // // //   bool isUploadingImage = false;
// // // //   File? _profileImage;
// // // //
// // // //   // Controllers
// // // //   final TextEditingController _emailController = TextEditingController();
// // // //   final TextEditingController _nameController = TextEditingController();
// // // //   final ImagePicker _picker = ImagePicker();
// // // //
// // // //   // Animation controllers
// // // //   late AnimationController _fadeController;
// // // //   late AnimationController _slideController;
// // // //   late AnimationController _counterController;
// // // //   late AnimationController _pulseController;
// // // //   late Animation<double> _fadeAnimation;
// // // //   late Animation<Offset> _slideAnimation;
// // // //   late Animation<double> _counterAnimation;
// // // //   late Animation<double> _pulseAnimation;
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _initializeAnimations();
// // // //     _loadUserData();
// // // //   }
// // // //
// // // //   void _initializeAnimations() {
// // // //     _fadeController = AnimationController(
// // // //       duration: const Duration(milliseconds: 1000),
// // // //       vsync: this,
// // // //     );
// // // //     _slideController = AnimationController(
// // // //       duration: const Duration(milliseconds: 800),
// // // //       vsync: this,
// // // //     );
// // // //     _counterController = AnimationController(
// // // //       duration: const Duration(milliseconds: 2000),
// // // //       vsync: this,
// // // //     );
// // // //     _pulseController = AnimationController(
// // // //       duration: const Duration(milliseconds: 2000),
// // // //       vsync: this,
// // // //     );
// // // //
// // // //     _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
// // // //     _slideAnimation = Tween<Offset>(
// // // //       begin: const Offset(0, 0.5),
// // // //       end: Offset.zero,
// // // //     ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
// // // //     _counterAnimation = CurvedAnimation(parent: _counterController, curve: Curves.easeOutQuart);
// // // //     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05)
// // // //         .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
// // // //   }
// // // //
// // // //   @override
// // // //   void dispose() {
// // // //     _fadeController.dispose();
// // // //     _slideController.dispose();
// // // //     _counterController.dispose();
// // // //     _pulseController.dispose();
// // // //     _nameController.dispose();
// // // //     _emailController.dispose();
// // // //     super.dispose();
// // // //   }
// // // //
// // // //   // ✅ ENHANCED RESPONSIVE SYSTEM - No Pixel Overflow
// // // //   double _getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;
// // // //   double _getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;
// // // //
// // // //   // Device type detection with precise breakpoints
// // // //   bool _isSmallMobile(BuildContext context) => _getScreenWidth(context) < 360;
// // // //   bool _isMobile(BuildContext context) => _getScreenWidth(context) < 600;
// // // //   bool _isTablet(BuildContext context) => _getScreenWidth(context) >= 600 && _getScreenWidth(context) < 1024;
// // // //   bool _isDesktop(BuildContext context) => _getScreenWidth(context) >= 1024;
// // // //
// // // //   // ✅ SMART FONT SCALING - Prevents text overflow
// // // //   double _getResponsiveFontSize(BuildContext context, double baseSize) {
// // // //     final screenWidth = _getScreenWidth(context);
// // // //     if (_isSmallMobile(context)) {
// // // //       return (baseSize * 0.85).clamp(10.0, baseSize);
// // // //     } else if (_isMobile(context)) {
// // // //       return (baseSize * (screenWidth / 375)).clamp(baseSize * 0.8, baseSize * 1.1);
// // // //     } else if (_isTablet(context)) {
// // // //       return baseSize * 1.05;
// // // //     }
// // // //     return baseSize * 1.1;
// // // //   }
// // // //
// // // //   // ✅ DYNAMIC PADDING - Adapts to screen size
// // // //   EdgeInsets _getResponsivePadding(BuildContext context) {
// // // //     if (_isSmallMobile(context)) {
// // // //       return const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
// // // //     } else if (_isMobile(context)) {
// // // //       return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
// // // //     } else if (_isTablet(context)) {
// // // //       return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
// // // //     }
// // // //     return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
// // // //   }
// // // //
// // // //   // ✅ SMART SPACING - No hardcoded values
// // // //   double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
// // // //     final screenWidth = _getScreenWidth(context);
// // // //     if (_isSmallMobile(context)) {
// // // //       return baseSpacing * 0.7;
// // // //     } else if (_isMobile(context)) {
// // // //       return (baseSpacing * (screenWidth / 375)).clamp(baseSpacing * 0.7, baseSpacing * 1.1);
// // // //     } else if (_isTablet(context)) {
// // // //       return baseSpacing * 1.2;
// // // //     }
// // // //     return baseSpacing * 1.4;
// // // //   }
// // // //
// // // //   // ✅ GRID CONFIGURATION - Prevents card overflow
// // // //   int _getCrossAxisCount(BuildContext context) {
// // // //     final screenWidth = _getScreenWidth(context);
// // // //     if (screenWidth < 320) return 1; // Very small phones
// // // //     if (screenWidth < 480) return 2; // Standard phones
// // // //     if (screenWidth < 768) return 2; // Large phones/small tablets
// // // //     if (screenWidth < 1024) return 3; // Tablets
// // // //     if (screenWidth < 1440) return 4; // Small desktops
// // // //     return 4; // Large desktops
// // // //   }
// // // //
// // // //   // ✅ ASPECT RATIO - Responsive card dimensions
// // // //   double _getCardAspectRatio(BuildContext context) {
// // // //     final screenWidth = _getScreenWidth(context);
// // // //     if (screenWidth < 320) return 3.0; // Very wide cards for tiny screens
// // // //     if (screenWidth < 480) return 1.8; // Balanced for phones
// // // //     if (screenWidth < 768) return 1.5; // Slightly taller
// // // //     if (screenWidth < 1024) return 1.3; // Tablet optimized
// // // //     return 1.2; // Desktop optimized
// // // //   }
// // // //
// // // //   // ✅ CONTENT WIDTH CONSTRAINTS
// // // //   double _getMaxContentWidth(BuildContext context) {
// // // //     if (_isMobile(context)) return double.infinity;
// // // //     if (_isTablet(context)) return 900;
// // // //     return 1200;
// // // //   }
// // // //
// // // //   // ✅ PROFILE IMAGE SIZE - Scales with screen
// // // //   double _getProfileImageRadius(BuildContext context) {
// // // //     final screenWidth = _getScreenWidth(context);
// // // //     if (screenWidth < 320) return 35;
// // // //     if (screenWidth < 480) return 45;
// // // //     if (screenWidth < 768) return 55;
// // // //     if (screenWidth < 1024) return 65;
// // // //     return 70;
// // // //   }
// // // //
// // // //   // Level styling methods (same as original)
// // // //   Color _getLevelColor() {
// // // //     switch (userLevel) {
// // // //       case 'Expert': return const Color(0xFF8B5CF6);
// // // //       case 'Advanced': return const Color(0xFF00D4AA);
// // // //       case 'Intermediate': return const Color(0xFF3B82F6);
// // // //       case 'Beginner': return const Color(0xFFF59E0B);
// // // //       default: return const Color(0xFF6B7280);
// // // //     }
// // // //   }
// // // //
// // // //   IconData _getLevelIcon() {
// // // //     switch (userLevel) {
// // // //       case 'Expert': return Icons.diamond;
// // // //       case 'Advanced': return Icons.military_tech;
// // // //       case 'Intermediate': return Icons.star;
// // // //       case 'Beginner': return Icons.school;
// // // //       default: return Icons.person;
// // // //     }
// // // //   }
// // // //
// // // //   String _calculateUserLevel(int points) {
// // // //     if (points >= 5000) return 'Expert';
// // // //     if (points >= 3000) return 'Advanced';
// // // //     if (points >= 1500) return 'Intermediate';
// // // //     if (points >= 500) return 'Beginner';
// // // //     return 'Rookie';
// // // //   }
// // // //
// // // //   // Helper method to convert base64 string to Uint8List
// // // //   Uint8List _base64ToImage(String base64String) {
// // // //     return base64Decode(base64String);
// // // //   }
// // // //
// // // //   bool _isValidEmail(String email) {
// // // //     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
// // // //   }
// // // //
// // // //   // Snackbar methods
// // // //   void _showSuccessSnackBar(String message) {
// // // //     ScaffoldMessenger.of(context).showSnackBar(
// // // //       SnackBar(
// // // //         content: Row(
// // // //           children: [
// // // //             Container(
// // // //               padding: const EdgeInsets.all(4),
// // // //               decoration: BoxDecoration(
// // // //                 color: Colors.white.withOpacity(0.2),
// // // //                 shape: BoxShape.circle,
// // // //               ),
// // // //               child: const Icon(Icons.check, color: Colors.white, size: 16),
// // // //             ),
// // // //             const SizedBox(width: 12),
// // // //             Expanded(
// // // //               child: Text(
// // // //                 message,
// // // //                 style: const TextStyle(fontWeight: FontWeight.w500),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //         backgroundColor: const Color(0xFF00D4AA),
// // // //         behavior: SnackBarBehavior.floating,
// // // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // //         margin: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   void _showErrorSnackBar(String message) {
// // // //     ScaffoldMessenger.of(context).showSnackBar(
// // // //       SnackBar(
// // // //         content: Row(
// // // //           children: [
// // // //             Container(
// // // //               padding: const EdgeInsets.all(4),
// // // //               decoration: BoxDecoration(
// // // //                 color: Colors.white.withOpacity(0.2),
// // // //                 shape: BoxShape.circle,
// // // //               ),
// // // //               child: const Icon(Icons.warning, color: Colors.white, size: 16),
// // // //             ),
// // // //             const SizedBox(width: 12),
// // // //             Expanded(
// // // //               child: Text(
// // // //                 message,
// // // //                 style: const TextStyle(fontWeight: FontWeight.w500),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //         backgroundColor: Colors.red,
// // // //         behavior: SnackBarBehavior.floating,
// // // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // // //         margin: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   void _redirectToLogin() {
// // // //     if (mounted) {
// // // //       Navigator.pushAndRemoveUntil(
// // // //         context,
// // // //         MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
// // // //             (route) => false,
// // // //       );
// // // //     }
// // // //   }
// // // //   // ✅ DATA LOADING METHODS
// // // //
// // // //   Future<void> _loadUserData() async {
// // // //     try {
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       if (user == null) {
// // // //         _redirectToLogin();
// // // //         return;
// // // //       }
// // // //
// // // //       final userDoc = await FirebaseFirestore.instance
// // // //           .collection('users')
// // // //           .doc(user.uid)
// // // //           .get();
// // // //
// // // //       if (userDoc.exists && mounted) {
// // // //         final userData = userDoc.data()!;
// // // //         setState(() {
// // // //           userName = userData['fullName'] ?? 'Unknown User';
// // // //           userEmail = userData['email'] ?? user.email ?? '';
// // // //           _nameController.text = userName;
// // // //           _emailController.text = userEmail;
// // // //         });
// // // //
// // // //         await Future.wait([
// // // //           _loadProfileImage(),
// // // //           _loadUserStats(),
// // // //         ]);
// // // //
// // // //         if (mounted) {
// // // //           _fadeController.forward();
// // // //           _slideController.forward();
// // // //           _counterController.forward();
// // // //           _pulseController.repeat(reverse: true);
// // // //         }
// // // //
// // // //         setState(() {
// // // //           isLoading = false;
// // // //         });
// // // //       } else {
// // // //         _redirectToLogin();
// // // //       }
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           isLoading = false;
// // // //         });
// // // //         _showErrorSnackBar('Failed to load profile data');
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _loadUserStats() async {
// // // //     try {
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       if (user == null) return;
// // // //
// // // //       final userId = user.uid;
// // // //       final points = prefs.getInt('${userId}_user_points') ?? 0;
// // // //       final quizCount = prefs.getInt('${userId}_quizzes_taken') ?? 0;
// // // //       final bestScore = prefs.getInt('${userId}_best_score') ?? 0;
// // // //
// // // //       // Count notes from multiple sources
// // // //       int totalNotesCount = 0;
// // // //       int linksCount = 0;
// // // //       int videosCount = 0;
// // // //
// // // //       final savedNotesJson = prefs.getStringList('${userId}_saved_notes') ?? [];
// // // //       totalNotesCount += savedNotesJson.length;
// // // //
// // // //       for (final noteString in savedNotesJson) {
// // // //         try {
// // // //           if (noteString.contains('http') || noteString.contains('www.')) {
// // // //             linksCount++;
// // // //           }
// // // //         } catch (e) {
// // // //           debugPrint('Error parsing saved note: $e');
// // // //         }
// // // //       }
// // // //
// // // //       final codingNotesJson = prefs.getStringList('${userId}_coding_notes') ?? [];
// // // //       totalNotesCount += codingNotesJson.length;
// // // //
// // // //       final personalNotesJson = prefs.getStringList('${userId}_personal_notes') ?? [];
// // // //       totalNotesCount += personalNotesJson.length;
// // // //
// // // //       final studyNotesJson = prefs.getStringList('${userId}_study_notes') ?? [];
// // // //       totalNotesCount += studyNotesJson.length;
// // // //
// // // //       final savedVideosJson = prefs.getStringList('${userId}_saved_videos') ?? [];
// // // //       final bookmarkedVideosJson = prefs.getStringList('${userId}_bookmarked_videos') ?? [];
// // // //       videosCount = savedVideosJson.length + bookmarkedVideosJson.length;
// // // //
// // // //       final savedLinksJson = prefs.getStringList('${userId}_saved_links') ?? [];
// // // //       final bookmarkedLinksJson = prefs.getStringList('${userId}_bookmarked_links') ?? [];
// // // //       linksCount += savedLinksJson.length + bookmarkedLinksJson.length;
// // // //
// // // //       final level = _calculateUserLevel(points);
// // // //
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           userPoints = points;
// // // //           quizzesTaken = quizCount;
// // // //           bestQuizScore = bestScore;
// // // //           notesCount = totalNotesCount;
// // // //           savedVideosCount = videosCount;
// // // //           savedLinksCount = linksCount;
// // // //           userLevel = level;
// // // //         });
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint('❌ Error loading user stats: $e');
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           userPoints = 0;
// // // //           notesCount = 0;
// // // //           savedVideosCount = 0;
// // // //           savedLinksCount = 0;
// // // //           quizzesTaken = 0;
// // // //           bestQuizScore = 0;
// // // //           userLevel = 'Rookie';
// // // //         });
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _loadProfileImage() async {
// // // //     try {
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       if (user != null) {
// // // //         final imageKey = 'profile_image_${user.uid}';
// // // //         final savedImageBase64 = prefs.getString(imageKey);
// // // //         if (savedImageBase64 != null && savedImageBase64.isNotEmpty && mounted) {
// // // //           setState(() {
// // // //             profileImageBase64 = savedImageBase64;
// // // //           });
// // // //         }
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint('Error loading profile image: $e');
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _refreshData() async {
// // // //     setState(() {
// // // //       isLoading = true;
// // // //     });
// // // //
// // // //     await Future.wait([
// // // //       _loadUserStats(),
// // // //       _loadProfileImage(),
// // // //     ]);
// // // //
// // // //     if (mounted) {
// // // //       setState(() {
// // // //         isLoading = false;
// // // //       });
// // // //       _showSuccessSnackBar('Profile data refreshed!');
// // // //     }
// // // //   }
// // // //
// // // //   // ✅ IMAGE HANDLING METHODS
// // // //
// // // //   Future<void> _pickImage() async {
// // // //     try {
// // // //       final XFile? image = await _picker.pickImage(
// // // //         source: ImageSource.gallery,
// // // //         maxWidth: 512,
// // // //         maxHeight: 512,
// // // //         imageQuality: 80,
// // // //       );
// // // //
// // // //       if (image != null) {
// // // //         setState(() {
// // // //           _profileImage = File(image.path);
// // // //           isUploadingImage = true;
// // // //         });
// // // //
// // // //         await _saveProfileImageLocally(File(image.path));
// // // //       }
// // // //     } catch (e) {
// // // //       _showErrorSnackBar('Failed to pick image: Please try again');
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _saveProfileImageLocally(File imageFile) async {
// // // //     try {
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       if (user == null) return;
// // // //
// // // //       final bytes = await imageFile.readAsBytes();
// // // //       final base64String = base64Encode(bytes);
// // // //
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       final imageKey = 'profile_image_${user.uid}';
// // // //       await prefs.setString(imageKey, base64String);
// // // //
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           profileImageBase64 = base64String;
// // // //           isUploadingImage = false;
// // // //         });
// // // //         _showSuccessSnackBar('Profile image updated successfully!');
// // // //       }
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           isUploadingImage = false;
// // // //           _profileImage = null;
// // // //         });
// // // //         _showErrorSnackBar('Failed to save image');
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   // ✅ PROFILE UPDATE METHODS
// // // //
// // // //   Future<void> _updateProfile() async {
// // // //     final name = _nameController.text.trim();
// // // //     final email = _emailController.text.trim();
// // // //     final currentUser = FirebaseAuth.instance.currentUser;
// // // //
// // // //     if (name.isEmpty) {
// // // //       _showErrorSnackBar('Name cannot be empty');
// // // //       return;
// // // //     }
// // // //
// // // //     if (!_isValidEmail(email)) {
// // // //       _showErrorSnackBar('Please enter a valid email address');
// // // //       return;
// // // //     }
// // // //
// // // //     if (currentUser == null) return;
// // // //
// // // //     try {
// // // //       setState(() {
// // // //         isLoading = true;
// // // //       });
// // // //
// // // //       final emailChanged = currentUser.email != email;
// // // //
// // // //       if (emailChanged) {
// // // //         await _handleEmailChange(email, name);
// // // //       } else {
// // // //         await _updateNameOnly(name);
// // // //       }
// // // //
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           isLoading = false;
// // // //         });
// // // //         _showErrorSnackBar('Failed to update profile');
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _updateNameOnly(String name) async {
// // // //     final user = FirebaseAuth.instance.currentUser;
// // // //     if (user != null) {
// // // //       await FirebaseFirestore.instance
// // // //           .collection('users')
// // // //           .doc(user.uid)
// // // //           .update({
// // // //         'fullName': name,
// // // //         'updatedAt': FieldValue.serverTimestamp(),
// // // //       });
// // // //
// // // //       await user.updateDisplayName(name);
// // // //
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           userName = name;
// // // //           isEditing = false;
// // // //           isLoading = false;
// // // //         });
// // // //         _showSuccessSnackBar('Name updated successfully!');
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _handleEmailChange(String newEmail, String name) async {
// // // //     try {
// // // //       setState(() {
// // // //         isLoading = false;
// // // //         isEditing = false;
// // // //       });
// // // //
// // // //       final result = await Navigator.push(
// // // //         context,
// // // //         MaterialPageRoute(
// // // //           builder: (context) => EmailChangeVerificationScreen(
// // // //             currentEmail: userEmail,
// // // //             newEmail: newEmail,
// // // //             userName: name,
// // // //           ),
// // // //         ),
// // // //       );
// // // //
// // // //       if (result == true) {
// // // //         await _loadUserData();
// // // //         _showSuccessSnackBar('Email updated successfully!');
// // // //       } else {
// // // //         _emailController.text = userEmail;
// // // //       }
// // // //     } catch (e) {
// // // //       setState(() {
// // // //         isLoading = false;
// // // //       });
// // // //       _emailController.text = userEmail;
// // // //       _showErrorSnackBar('Failed to initiate email change');
// // // //     }
// // // //   }
// // // //
// // // //   void _cancelEditing() {
// // // //     setState(() {
// // // //       _nameController.text = userName;
// // // //       _emailController.text = userEmail;
// // // //       isEditing = false;
// // // //     });
// // // //   }
// // // //
// // // //   // ✅ LEVEL PROGRESS CALCULATIONS
// // // //
// // // //   String _getNextLevelInfo() {
// // // //     final nextPoints = _getNextLevelPoints();
// // // //
// // // //     if (userLevel == 'Expert') {
// // // //       return 'Congratulations! You\'ve reached the highest level! 🏆';
// // // //     }
// // // //
// // // //     final needed = nextPoints - userPoints;
// // // //     final nextLevel = _getNextLevelName();
// // // //
// // // //     return 'Earn $needed more points to reach $nextLevel level!';
// // // //   }
// // // //
// // // //   String _getNextLevelName() {
// // // //     switch (userLevel) {
// // // //       case 'Rookie': return 'Beginner';
// // // //       case 'Beginner': return 'Intermediate';
// // // //       case 'Intermediate': return 'Advanced';
// // // //       case 'Advanced': return 'Expert';
// // // //       default: return 'Expert';
// // // //     }
// // // //   }
// // // //
// // // //   int _getNextLevelPoints() {
// // // //     switch (userLevel) {
// // // //       case 'Rookie': return 500;
// // // //       case 'Beginner': return 1500;
// // // //       case 'Intermediate': return 3000;
// // // //       case 'Advanced': return 5000;
// // // //       default: return 5000;
// // // //     }
// // // //   }
// // // //
// // // //   int _getCurrentLevelPoints() {
// // // //     switch (userLevel) {
// // // //       case 'Rookie': return 0;
// // // //       case 'Beginner': return 500;
// // // //       case 'Intermediate': return 1500;
// // // //       case 'Advanced': return 3000;
// // // //       case 'Expert': return 5000;
// // // //       default: return 0;
// // // //     }
// // // //   }
// // // //
// // // //   double _getLevelProgress() {
// // // //     if (userLevel == 'Expert') return 1.0;
// // // //
// // // //     final nextPoints = _getNextLevelPoints();
// // // //     final currentPoints = _getCurrentLevelPoints();
// // // //     final progress = ((userPoints - currentPoints) / (nextPoints - currentPoints)).clamp(0.0, 1.0);
// // // //
// // // //     return progress;
// // // //   }
// // // //
// // // //   // ✅ LOGOUT DIALOG
// // // //
// // // //   Future<void> _showLogoutDialog() async {
// // // //     return showDialog<void>(
// // // //       context: context,
// // // //       barrierDismissible: true,
// // // //       barrierColor: Colors.black.withOpacity(0.7),
// // // //       builder: (BuildContext context) {
// // // //         return _LogoutDialogContent();
// // // //       },
// // // //     );
// // // //   }
// // // //   // ✅ MAIN BUILD METHODS
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: const Color(0xFF0D1B2A),
// // // //       body: isLoading ? _buildLoadingState() : _buildMainContent(),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ BEAUTIFUL LOADING STATE
// // // //   Widget _buildLoadingState() {
// // // //     return Container(
// // // //       decoration: const BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Color(0xFF0D1B2A),
// // // //             Color(0xFF1B263B),
// // // //             Color(0xFF415A77),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //       child: Center(
// // // //         child: Column(
// // // //           mainAxisAlignment: MainAxisAlignment.center,
// // // //           children: [
// // // //             Container(
// // // //               padding: EdgeInsets.all(_getResponsiveSpacing(context, 24)),
// // // //               decoration: BoxDecoration(
// // // //                 gradient: LinearGradient(
// // // //                   colors: [
// // // //                     const Color(0xFF00D4AA).withOpacity(0.2),
// // // //                     const Color(0xFF00A8CC).withOpacity(0.1),
// // // //                   ],
// // // //                 ),
// // // //                 shape: BoxShape.circle,
// // // //                 boxShadow: [
// // // //                   BoxShadow(
// // // //                     color: const Color(0xFF00D4AA).withOpacity(0.3),
// // // //                     blurRadius: 20,
// // // //                     spreadRadius: 5,
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //               child: const CircularProgressIndicator(
// // // //                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
// // // //                 strokeWidth: 3,
// // // //               ),
// // // //             ),
// // // //             SizedBox(height: _getResponsiveSpacing(context, 24)),
// // // //             Text(
// // // //               'Loading your learning profile...',
// // // //               style: TextStyle(
// // // //                 color: Colors.white.withOpacity(0.8),
// // // //                 fontSize: _getResponsiveFontSize(context, 16),
// // // //                 fontWeight: FontWeight.w500,
// // // //               ),
// // // //             ),
// // // //             SizedBox(height: _getResponsiveSpacing(context, 8)),
// // // //             Text(
// // // //               'Please wait a moment',
// // // //               style: TextStyle(
// // // //                 color: Colors.white.withOpacity(0.6),
// // // //                 fontSize: _getResponsiveFontSize(context, 14),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ MAIN CONTENT WITH RESPONSIVE LAYOUT
// // // //   Widget _buildMainContent() {
// // // //     return Container(
// // // //       decoration: const BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Color(0xFF0D1B2A),
// // // //             Color(0xFF1B263B),
// // // //             Color(0xFF415A77),
// // // //           ],
// // // //           stops: [0.0, 0.5, 1.0],
// // // //         ),
// // // //       ),
// // // //       child: SafeArea(
// // // //         child: FadeTransition(
// // // //           opacity: _fadeAnimation,
// // // //           child: LayoutBuilder(
// // // //             builder: (context, constraints) {
// // // //               // Choose layout based on screen size
// // // //               if (_isDesktop(context)) {
// // // //                 return _buildDesktopLayout();
// // // //               } else if (_isTablet(context)) {
// // // //                 return _buildTabletLayout();
// // // //               } else {
// // // //                 return _buildMobileLayout();
// // // //               }
// // // //             },
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ MOBILE LAYOUT - Optimized for phones
// // // //   Widget _buildMobileLayout() {
// // // //     return CustomScrollView(
// // // //       physics: const BouncingScrollPhysics(),
// // // //       slivers: [
// // // //         _buildResponsiveAppBar(),
// // // //         SliverPadding(
// // // //           padding: _getResponsivePadding(context),
// // // //           sliver: SliverList(
// // // //             delegate: SliverChildListDelegate([
// // // //               // Profile Header
// // // //               SlideTransition(
// // // //                 position: _slideAnimation,
// // // //                 child: _buildProfileHeader(),
// // // //               ),
// // // //               SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //               // Level and Points Cards - Stack vertically on mobile
// // // //               _buildLevelProgressCard(),
// // // //               SizedBox(height: _getResponsiveSpacing(context, 16)),
// // // //               AnimatedBuilder(
// // // //                 animation: _counterAnimation,
// // // //                 builder: (context, child) => _buildPointsCard(),
// // // //               ),
// // // //               SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //               // Stats Grid
// // // //               _buildStatsGrid(),
// // // //               SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //               // Account Settings
// // // //               _buildAccountSettings(),
// // // //               SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //               // Learning Journey
// // // //               _buildLearningJourney(),
// // // //               SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //               // Logout Section
// // // //               _buildLogoutSection(),
// // // //               SizedBox(height: _getResponsiveSpacing(context, 40)),
// // // //             ]),
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ TABLET LAYOUT - Optimized for tablets
// // // //   Widget _buildTabletLayout() {
// // // //     return CustomScrollView(
// // // //       physics: const BouncingScrollPhysics(),
// // // //       slivers: [
// // // //         _buildResponsiveAppBar(),
// // // //         SliverPadding(
// // // //           padding: _getResponsivePadding(context),
// // // //           sliver: SliverList(
// // // //             delegate: SliverChildListDelegate([
// // // //               Center(
// // // //                 child: ConstrainedBox(
// // // //                   constraints: BoxConstraints(maxWidth: _getMaxContentWidth(context)),
// // // //                   child: Column(
// // // //                     children: [
// // // //                       // Profile Header
// // // //                       SlideTransition(
// // // //                         position: _slideAnimation,
// // // //                         child: _buildProfileHeader(),
// // // //                       ),
// // // //                       SizedBox(height: _getResponsiveSpacing(context, 24)),
// // // //
// // // //                       // Level and Points - Side by side
// // // //                       Row(
// // // //                         children: [
// // // //                           Expanded(child: _buildLevelProgressCard()),
// // // //                           SizedBox(width: _getResponsiveSpacing(context, 16)),
// // // //                           Expanded(child: AnimatedBuilder(
// // // //                             animation: _counterAnimation,
// // // //                             builder: (context, child) => _buildPointsCard(),
// // // //                           )),
// // // //                         ],
// // // //                       ),
// // // //                       SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //                       // Stats Grid
// // // //                       _buildStatsGrid(),
// // // //                       SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //                       // Account Settings and Learning Journey
// // // //                       Row(
// // // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // // //                         children: [
// // // //                           Expanded(child: _buildAccountSettings()),
// // // //                           SizedBox(width: _getResponsiveSpacing(context, 16)),
// // // //                           Expanded(child: _buildLearningJourney()),
// // // //                         ],
// // // //                       ),
// // // //                       SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //                       // Logout Section
// // // //                       _buildLogoutSection(),
// // // //                       SizedBox(height: _getResponsiveSpacing(context, 40)),
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ]),
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ DESKTOP LAYOUT - Optimized for large screens
// // // //   Widget _buildDesktopLayout() {
// // // //     return CustomScrollView(
// // // //       physics: const BouncingScrollPhysics(),
// // // //       slivers: [
// // // //         _buildResponsiveAppBar(),
// // // //         SliverPadding(
// // // //           padding: _getResponsivePadding(context),
// // // //           sliver: SliverList(
// // // //             delegate: SliverChildListDelegate([
// // // //               Center(
// // // //                 child: ConstrainedBox(
// // // //                   constraints: BoxConstraints(maxWidth: _getMaxContentWidth(context)),
// // // //                   child: Row(
// // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // //                     children: [
// // // //                       // Left Column - Profile and Controls
// // // //                       Expanded(
// // // //                         flex: 2,
// // // //                         child: Column(
// // // //                           children: [
// // // //                             SlideTransition(
// // // //                               position: _slideAnimation,
// // // //                               child: _buildProfileHeader(),
// // // //                             ),
// // // //                             SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //                             _buildAccountSettings(),
// // // //                             SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //                             _buildLogoutSection(),
// // // //                           ],
// // // //                         ),
// // // //                       ),
// // // //
// // // //                       SizedBox(width: _getResponsiveSpacing(context, 24)),
// // // //
// // // //                       // Right Column - Stats and Progress
// // // //                       Expanded(
// // // //                         flex: 3,
// // // //                         child: Column(
// // // //                           children: [
// // // //                             // Level and Points Row
// // // //                             Row(
// // // //                               children: [
// // // //                                 Expanded(child: _buildLevelProgressCard()),
// // // //                                 SizedBox(width: _getResponsiveSpacing(context, 16)),
// // // //                                 Expanded(child: AnimatedBuilder(
// // // //                                   animation: _counterAnimation,
// // // //                                   builder: (context, child) => _buildPointsCard(),
// // // //                                 )),
// // // //                               ],
// // // //                             ),
// // // //                             SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //                             // Stats Grid
// // // //                             _buildStatsGrid(),
// // // //                             SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //                             // Learning Journey
// // // //                             _buildLearningJourney(),
// // // //                             SizedBox(height: _getResponsiveSpacing(context, 40)),
// // // //                           ],
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ]),
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ RESPONSIVE APP BAR
// // // //   Widget _buildResponsiveAppBar() {
// // // //     return SliverAppBar(
// // // //       expandedHeight: _isMobile(context) ? 80 : 120,
// // // //       floating: false,
// // // //       pinned: true,
// // // //       elevation: 0,
// // // //       backgroundColor: const Color(0xFF1B263B),
// // // //       automaticallyImplyLeading: false,
// // // //
// // // //       leading: Container(
// // // //         margin: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //         child: IconButton(
// // // //           onPressed: () => Navigator.of(context).pop(),
// // // //           icon: Icon(
// // // //             Icons.arrow_back_ios_rounded,
// // // //             color: const Color(0xFF00D4AA),
// // // //             size: _getResponsiveFontSize(context, 20),
// // // //           ),
// // // //           style: IconButton.styleFrom(
// // // //             backgroundColor: const Color(0xFF00D4AA).withOpacity(0.1),
// // // //             shape: RoundedRectangleBorder(
// // // //               borderRadius: BorderRadius.circular(12),
// // // //               side: BorderSide(
// // // //                 color: const Color(0xFF00D4AA).withOpacity(0.3),
// // // //               ),
// // // //             ),
// // // //             padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //
// // // //       flexibleSpace: FlexibleSpaceBar(
// // // //         centerTitle: false,
// // // //         titlePadding: EdgeInsets.only(
// // // //           left: _getResponsiveSpacing(context, 64),
// // // //           bottom: _getResponsiveSpacing(context, 16),
// // // //           right: _getResponsiveSpacing(context, 80),
// // // //         ),
// // // //         title: ShaderMask(
// // // //           shaderCallback: (bounds) => const LinearGradient(
// // // //             colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
// // // //           ).createShader(bounds),
// // // //           child: Text(
// // // //             'Profile',
// // // //             style: TextStyle(
// // // //               color: Colors.white,
// // // //               fontWeight: FontWeight.bold,
// // // //               fontSize: _getResponsiveFontSize(context, 18),
// // // //             ),
// // // //           ),
// // // //         ),
// // // //         background: Container(
// // // //           decoration: const BoxDecoration(
// // // //             gradient: LinearGradient(
// // // //               begin: Alignment.topLeft,
// // // //               end: Alignment.bottomRight,
// // // //               colors: [
// // // //                 Color(0xFF1B263B),
// // // //                 Color(0xFF0D1B2A),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //
// // // //       actions: [
// // // //         Container(
// // // //           margin: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //           child: _isMobile(context)
// // // //               ? IconButton(
// // // //             onPressed: _refreshData,
// // // //             icon: Icon(
// // // //               Icons.refresh_rounded,
// // // //               color: const Color(0xFF00D4AA),
// // // //               size: _getResponsiveFontSize(context, 20),
// // // //             ),
// // // //             style: IconButton.styleFrom(
// // // //               backgroundColor: const Color(0xFF00D4AA).withOpacity(0.1),
// // // //               shape: RoundedRectangleBorder(
// // // //                 borderRadius: BorderRadius.circular(12),
// // // //                 side: BorderSide(
// // // //                   color: const Color(0xFF00D4AA).withOpacity(0.3),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           )
// // // //               : TextButton.icon(
// // // //             onPressed: _refreshData,
// // // //             icon: Icon(
// // // //               Icons.refresh_rounded,
// // // //               color: const Color(0xFF00D4AA),
// // // //               size: _getResponsiveFontSize(context, 18),
// // // //             ),
// // // //             label: Text(
// // // //               'Refresh',
// // // //               style: TextStyle(
// // // //                 color: const Color(0xFF00D4AA),
// // // //                 fontSize: _getResponsiveFontSize(context, 14),
// // // //                 fontWeight: FontWeight.w600,
// // // //               ),
// // // //             ),
// // // //             style: TextButton.styleFrom(
// // // //               backgroundColor: const Color(0xFF00D4AA).withOpacity(0.1),
// // // //               shape: RoundedRectangleBorder(
// // // //                 borderRadius: BorderRadius.circular(12),
// // // //                 side: BorderSide(
// // // //                   color: const Color(0xFF00D4AA).withOpacity(0.3),
// // // //                 ),
// // // //               ),
// // // //               padding: EdgeInsets.symmetric(
// // // //                 horizontal: _getResponsiveSpacing(context, 12),
// // // //                 vertical: _getResponsiveSpacing(context, 8),
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //   // ✅ PROFILE HEADER - Fully Responsive
// // // //   Widget _buildProfileHeader() {
// // // //     final profileRadius = _getProfileImageRadius(context);
// // // //
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Colors.white.withOpacity(0.15),
// // // //             Colors.white.withOpacity(0.05),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(24),
// // // //         border: Border.all(
// // // //           color: Colors.white.withOpacity(0.2),
// // // //           width: 1.5,
// // // //         ),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: Colors.black.withOpacity(0.2),
// // // //             blurRadius: 20,
// // // //             offset: const Offset(0, 8),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Column(
// // // //         mainAxisSize: MainAxisSize.min,
// // // //         children: [
// // // //           // Profile Image with Level Badge
// // // //           Stack(
// // // //             clipBehavior: Clip.none,
// // // //             children: [
// // // //               // Glowing Profile Container
// // // //               Container(
// // // //                 padding: const EdgeInsets.all(4),
// // // //                 decoration: BoxDecoration(
// // // //                   shape: BoxShape.circle,
// // // //                   gradient: LinearGradient(
// // // //                     colors: [
// // // //                       _getLevelColor(),
// // // //                       _getLevelColor().withOpacity(0.7),
// // // //                     ],
// // // //                   ),
// // // //                   boxShadow: [
// // // //                     BoxShadow(
// // // //                       color: _getLevelColor().withOpacity(0.4),
// // // //                       blurRadius: 20,
// // // //                       spreadRadius: 2,
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //                 child: CircleAvatar(
// // // //                   radius: profileRadius,
// // // //                   backgroundColor: Colors.white,
// // // //                   backgroundImage: _profileImage != null
// // // //                       ? FileImage(_profileImage!)
// // // //                       : (profileImageBase64.isNotEmpty
// // // //                       ? MemoryImage(_base64ToImage(profileImageBase64))
// // // //                       : null) as ImageProvider?,
// // // //                   child: _profileImage == null && profileImageBase64.isEmpty
// // // //                       ? Text(
// // // //                     userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
// // // //                     style: TextStyle(
// // // //                       fontSize: _getResponsiveFontSize(context, 32),
// // // //                       fontWeight: FontWeight.bold,
// // // //                       color: _getLevelColor(),
// // // //                     ),
// // // //                   )
// // // //                       : null,
// // // //                 ),
// // // //               ),
// // // //
// // // //               // Level Badge
// // // //               Positioned(
// // // //                 top: -5,
// // // //                 right: -5,
// // // //                 child: Container(
// // // //                   padding: EdgeInsets.symmetric(
// // // //                     horizontal: _getResponsiveSpacing(context, 8),
// // // //                     vertical: _getResponsiveSpacing(context, 4),
// // // //                   ),
// // // //                   decoration: BoxDecoration(
// // // //                     gradient: LinearGradient(
// // // //                       colors: [_getLevelColor(), _getLevelColor().withOpacity(0.8)],
// // // //                     ),
// // // //                     borderRadius: BorderRadius.circular(16),
// // // //                     border: Border.all(color: Colors.white, width: 2),
// // // //                     boxShadow: [
// // // //                       BoxShadow(
// // // //                         color: _getLevelColor().withOpacity(0.3),
// // // //                         blurRadius: 8,
// // // //                         offset: const Offset(0, 2),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                   child: Row(
// // // //                     mainAxisSize: MainAxisSize.min,
// // // //                     children: [
// // // //                       Icon(
// // // //                         _getLevelIcon(),
// // // //                         color: Colors.white,
// // // //                         size: _getResponsiveFontSize(context, 12),
// // // //                       ),
// // // //                       SizedBox(width: _getResponsiveSpacing(context, 4)),
// // // //                       Text(
// // // //                         userLevel,
// // // //                         style: TextStyle(
// // // //                           color: Colors.white,
// // // //                           fontSize: _getResponsiveFontSize(context, 10),
// // // //                           fontWeight: FontWeight.bold,
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //
// // // //               // Camera Button
// // // //               Positioned(
// // // //                 bottom: 0,
// // // //                 right: 5,
// // // //                 child: GestureDetector(
// // // //                   onTap: isUploadingImage ? null : _pickImage,
// // // //                   child: Container(
// // // //                     padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //                     decoration: BoxDecoration(
// // // //                       gradient: const LinearGradient(
// // // //                         colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
// // // //                       ),
// // // //                       shape: BoxShape.circle,
// // // //                       border: Border.all(color: Colors.white, width: 3),
// // // //                       boxShadow: [
// // // //                         BoxShadow(
// // // //                           color: const Color(0xFF00D4AA).withOpacity(0.3),
// // // //                           blurRadius: 8,
// // // //                           offset: const Offset(0, 2),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                     child: Icon(
// // // //                       isUploadingImage ? Icons.hourglass_empty : Icons.camera_alt,
// // // //                       size: _getResponsiveFontSize(context, 16),
// // // //                       color: Colors.white,
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 16)),
// // // //
// // // //           // User Name
// // // //           Flexible(
// // // //             child: ShaderMask(
// // // //               shaderCallback: (bounds) => const LinearGradient(
// // // //                 colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
// // // //               ).createShader(bounds),
// // // //               child: Text(
// // // //                 userName,
// // // //                 style: TextStyle(
// // // //                   color: Colors.white,
// // // //                   fontSize: _getResponsiveFontSize(context, 22),
// // // //                   fontWeight: FontWeight.bold,
// // // //                   letterSpacing: 0.5,
// // // //                 ),
// // // //                 textAlign: TextAlign.center,
// // // //                 maxLines: 2,
// // // //                 overflow: TextOverflow.ellipsis,
// // // //               ),
// // // //             ),
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 8)),
// // // //
// // // //           // Email
// // // //           Container(
// // // //             padding: EdgeInsets.symmetric(
// // // //               horizontal: _getResponsiveSpacing(context, 12),
// // // //               vertical: _getResponsiveSpacing(context, 6),
// // // //             ),
// // // //             decoration: BoxDecoration(
// // // //               color: Colors.white.withOpacity(0.1),
// // // //               borderRadius: BorderRadius.circular(20),
// // // //             ),
// // // //             child: Text(
// // // //               userEmail,
// // // //               style: TextStyle(
// // // //                 color: Colors.white.withOpacity(0.8),
// // // //                 fontSize: _getResponsiveFontSize(context, 12),
// // // //               ),
// // // //               textAlign: TextAlign.center,
// // // //               maxLines: 1,
// // // //               overflow: TextOverflow.ellipsis,
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ LEVEL PROGRESS CARD - Responsive Design
// // // //   Widget _buildLevelProgressCard() {
// // // //     final progress = _getLevelProgress();
// // // //
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             _getLevelColor().withOpacity(0.2),
// // // //             _getLevelColor().withOpacity(0.05),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(20),
// // // //         border: Border.all(
// // // //           color: _getLevelColor().withOpacity(0.3),
// // // //           width: 1.5,
// // // //         ),
// // // //       ),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         mainAxisSize: MainAxisSize.min,
// // // //         children: [
// // // //           Row(
// // // //             children: [
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: LinearGradient(
// // // //                     colors: [_getLevelColor(), _getLevelColor().withOpacity(0.8)],
// // // //                   ),
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                 ),
// // // //                 child: Icon(
// // // //                   _getLevelIcon(),
// // // //                   color: Colors.white,
// // // //                   size: _getResponsiveFontSize(context, 18),
// // // //                 ),
// // // //               ),
// // // //               SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //               Expanded(
// // // //                 child: Column(
// // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // //                   children: [
// // // //                     Text(
// // // //                       'Level Progress',
// // // //                       style: TextStyle(
// // // //                         color: Colors.white.withOpacity(0.8),
// // // //                         fontSize: _getResponsiveFontSize(context, 12),
// // // //                         fontWeight: FontWeight.w500,
// // // //                       ),
// // // //                     ),
// // // //                     Text(
// // // //                       userLevel,
// // // //                       style: TextStyle(
// // // //                         color: Colors.white,
// // // //                         fontSize: _getResponsiveFontSize(context, 18),
// // // //                         fontWeight: FontWeight.bold,
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //               Text(
// // // //                 '${(progress * 100).toInt()}%',
// // // //                 style: TextStyle(
// // // //                   color: _getLevelColor(),
// // // //                   fontSize: _getResponsiveFontSize(context, 14),
// // // //                   fontWeight: FontWeight.bold,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 12)),
// // // //
// // // //           // Progress Bar
// // // //           Container(
// // // //             height: 8,
// // // //             decoration: BoxDecoration(
// // // //               color: Colors.white.withOpacity(0.2),
// // // //               borderRadius: BorderRadius.circular(4),
// // // //             ),
// // // //             child: LayoutBuilder(
// // // //               builder: (context, constraints) {
// // // //                 return Container(
// // // //                   width: constraints.maxWidth * progress,
// // // //                   decoration: BoxDecoration(
// // // //                     gradient: LinearGradient(
// // // //                       colors: [_getLevelColor(), _getLevelColor().withOpacity(0.7)],
// // // //                     ),
// // // //                     borderRadius: BorderRadius.circular(4),
// // // //                     boxShadow: [
// // // //                       BoxShadow(
// // // //                         color: _getLevelColor().withOpacity(0.3),
// // // //                         blurRadius: 4,
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                 );
// // // //               },
// // // //             ),
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 8)),
// // // //
// // // //           Text(
// // // //             _getNextLevelInfo(),
// // // //             style: TextStyle(
// // // //               color: Colors.white.withOpacity(0.7),
// // // //               fontSize: _getResponsiveFontSize(context, 10),
// // // //             ),
// // // //             maxLines: 2,
// // // //             overflow: TextOverflow.ellipsis,
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ POINTS CARD - Animated and Responsive
// // // //   Widget _buildPointsCard() {
// // // //     final animatedPoints = (userPoints * _counterAnimation.value).round();
// // // //
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: const LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Color(0xFF00D4AA),
// // // //             Color(0xFF00A8CC),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(20),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: const Color(0xFF00D4AA).withOpacity(0.3),
// // // //             blurRadius: 20,
// // // //             offset: const Offset(0, 8),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Row(
// // // //         children: [
// // // //           Container(
// // // //             padding: EdgeInsets.all(_getResponsiveSpacing(context, 10)),
// // // //             decoration: BoxDecoration(
// // // //               color: Colors.white.withOpacity(0.2),
// // // //               borderRadius: BorderRadius.circular(16),
// // // //             ),
// // // //             child: Icon(
// // // //               Icons.stars_rounded,
// // // //               color: Colors.white,
// // // //               size: _getResponsiveFontSize(context, 24),
// // // //             ),
// // // //           ),
// // // //           SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //           Expanded(
// // // //             child: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               mainAxisSize: MainAxisSize.min,
// // // //               children: [
// // // //                 Text(
// // // //                   "Learning Points",
// // // //                   style: TextStyle(
// // // //                     color: Colors.white.withOpacity(0.9),
// // // //                     fontSize: _getResponsiveFontSize(context, 12),
// // // //                     fontWeight: FontWeight.w500,
// // // //                   ),
// // // //                 ),
// // // //                 SizedBox(height: _getResponsiveSpacing(context, 2)),
// // // //                 FittedBox(
// // // //                   fit: BoxFit.scaleDown,
// // // //                   child: Text(
// // // //                     animatedPoints.toString(),
// // // //                     style: TextStyle(
// // // //                       color: Colors.white,
// // // //                       fontSize: _getResponsiveFontSize(context, 24),
// // // //                       fontWeight: FontWeight.bold,
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //                 if (bestQuizScore > 0) ...[
// // // //                   SizedBox(height: _getResponsiveSpacing(context, 2)),
// // // //                   Text(
// // // //                     "Best: $bestQuizScore pts",
// // // //                     style: TextStyle(
// // // //                       color: Colors.white.withOpacity(0.8),
// // // //                       fontSize: _getResponsiveFontSize(context, 10),
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // // ✅ STATS GRID - COMPLETELY FIXED FOR ALL SCREEN SIZES
// // // //   Widget _buildStatsGrid() {
// // // //     return LayoutBuilder(
// // // //       builder: (context, constraints) {
// // // //         final crossAxisCount = _getCrossAxisCount(context);
// // // //         final aspectRatio = _getCardAspectRatio(context);
// // // //         final spacing = _getResponsiveSpacing(context, 8);
// // // //
// // // //         return GridView.count(
// // // //           shrinkWrap: true,
// // // //           physics: const NeverScrollableScrollPhysics(),
// // // //           crossAxisCount: crossAxisCount,
// // // //           childAspectRatio: aspectRatio,
// // // //           crossAxisSpacing: spacing,
// // // //           mainAxisSpacing: spacing,
// // // //           children: [
// // // //             _buildStatCard(
// // // //               icon: Icons.note_alt_rounded,
// // // //               title: "Notes",
// // // //               value: notesCount.toString(),
// // // //               subtitle: "Saved",
// // // //               color: const Color(0xFF8B5CF6),
// // // //             ),
// // // //             _buildStatCard(
// // // //               icon: Icons.video_library_rounded,
// // // //               title: "Videos",
// // // //               value: savedVideosCount.toString(),
// // // //               subtitle: "Bookmarked",
// // // //               color: const Color(0xFFEF4444),
// // // //             ),
// // // //             _buildStatCard(
// // // //               icon: Icons.link_rounded,
// // // //               title: "Links",
// // // //               value: savedLinksCount.toString(),
// // // //               subtitle: "Resources",
// // // //               color: const Color(0xFF3B82F6),
// // // //             ),
// // // //             _buildStatCard(
// // // //               icon: Icons.quiz_rounded,
// // // //               title: "Quizzes",
// // // //               value: quizzesTaken.toString(),
// // // //               subtitle: "Completed",
// // // //               color: const Color(0xFF10B981),
// // // //             ),
// // // //           ],
// // // //         );
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ STAT CARD - BULLETPROOF RESPONSIVE DESIGN
// // // //   Widget _buildStatCard({
// // // //     required IconData icon,
// // // //     required String title,
// // // //     required String value,
// // // //     required String subtitle,
// // // //     required Color color,
// // // //   }) {
// // // //     return AnimatedBuilder(
// // // //       animation: _counterAnimation,
// // // //       builder: (context, child) {
// // // //         final animatedValue = (int.tryParse(value) ?? 0) * _counterAnimation.value;
// // // //
// // // //         return LayoutBuilder(
// // // //           builder: (context, constraints) {
// // // //             // Get available space
// // // //             final availableWidth = constraints.maxWidth;
// // // //             final availableHeight = constraints.maxHeight;
// // // //
// // // //             // Calculate responsive dimensions based on available space
// // // //             final minDimension = availableWidth < availableHeight ? availableWidth : availableHeight;
// // // //
// // // //             // Adaptive sizing with minimum guarantees
// // // //             final iconContainerSize = (minDimension * 0.25).clamp(32.0, 60.0);
// // // //             final iconSize = (iconContainerSize * 0.5).clamp(16.0, 28.0);
// // // //             final valueSize = (availableWidth * 0.15).clamp(16.0, 32.0);
// // // //             final titleSize = (availableWidth * 0.08).clamp(10.0, 14.0);
// // // //             final subtitleSize = (availableWidth * 0.06).clamp(8.0, 12.0);
// // // //
// // // //             // Adaptive padding that scales with card size
// // // //             final horizontalPadding = (availableWidth * 0.06).clamp(8.0, 16.0);
// // // //             final verticalPadding = (availableHeight * 0.08).clamp(8.0, 16.0);
// // // //             final iconPadding = (iconSize * 0.25).clamp(4.0, 8.0);
// // // //
// // // //             // Spacing between elements
// // // //             final spacing = (availableHeight * 0.04).clamp(2.0, 8.0);
// // // //
// // // //             return Container(
// // // //               padding: EdgeInsets.symmetric(
// // // //                 horizontal: horizontalPadding,
// // // //                 vertical: verticalPadding,
// // // //               ),
// // // //               decoration: BoxDecoration(
// // // //                 gradient: LinearGradient(
// // // //                   begin: Alignment.topLeft,
// // // //                   end: Alignment.bottomRight,
// // // //                   colors: [
// // // //                     Colors.white.withOpacity(0.12),
// // // //                     Colors.white.withOpacity(0.06),
// // // //                   ],
// // // //                 ),
// // // //                 borderRadius: BorderRadius.circular(16),
// // // //                 border: Border.all(
// // // //                   color: color.withOpacity(0.3),
// // // //                   width: 1,
// // // //                 ),
// // // //               ),
// // // //               child: Column(
// // // //                 mainAxisAlignment: MainAxisAlignment.center,
// // // //                 children: [
// // // //                   // Icon Container - Responsive
// // // //                   Container(
// // // //                     width: iconContainerSize,
// // // //                     height: iconContainerSize,
// // // //                     padding: EdgeInsets.all(iconPadding),
// // // //                     decoration: BoxDecoration(
// // // //                       gradient: LinearGradient(
// // // //                         colors: [color, color.withOpacity(0.8)],
// // // //                       ),
// // // //                       borderRadius: BorderRadius.circular(12),
// // // //                     ),
// // // //                     child: Icon(
// // // //                       icon,
// // // //                       color: Colors.white,
// // // //                       size: iconSize,
// // // //                     ),
// // // //                   ),
// // // //
// // // //                   SizedBox(height: spacing),
// // // //
// // // //                   // Value - Always fits with FittedBox
// // // //                   Flexible(
// // // //                     child: FittedBox(
// // // //                       fit: BoxFit.scaleDown,
// // // //                       child: Text(
// // // //                         animatedValue.round().toString(),
// // // //                         style: TextStyle(
// // // //                           color: Colors.white,
// // // //                           fontSize: valueSize,
// // // //                           fontWeight: FontWeight.bold,
// // // //                         ),
// // // //                         maxLines: 1,
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //
// // // //                   SizedBox(height: spacing * 0.5),
// // // //
// // // //                   // Title - Always fits
// // // //                   Flexible(
// // // //                     child: FittedBox(
// // // //                       fit: BoxFit.scaleDown,
// // // //                       child: Text(
// // // //                         title,
// // // //                         style: TextStyle(
// // // //                           color: Colors.white.withOpacity(0.8),
// // // //                           fontSize: titleSize,
// // // //                           fontWeight: FontWeight.w600,
// // // //                         ),
// // // //                         maxLines: 1,
// // // //                         textAlign: TextAlign.center,
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //
// // // //                   // Subtitle - Always fits
// // // //                   Flexible(
// // // //                     child: FittedBox(
// // // //                       fit: BoxFit.scaleDown,
// // // //                       child: Text(
// // // //                         subtitle,
// // // //                         style: TextStyle(
// // // //                           color: Colors.white.withOpacity(0.6),
// // // //                           fontSize: subtitleSize,
// // // //                         ),
// // // //                         maxLines: 1,
// // // //                         textAlign: TextAlign.center,
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             );
// // // //           },
// // // //         );
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ ACCOUNT SETTINGS - Responsive Layout
// // // //   Widget _buildAccountSettings() {
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Colors.white.withOpacity(0.12),
// // // //             Colors.white.withOpacity(0.06),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(20),
// // // //         border: Border.all(
// // // //           color: Colors.white.withOpacity(0.2),
// // // //           width: 1,
// // // //         ),
// // // //       ),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         mainAxisSize: MainAxisSize.min,
// // // //         children: [
// // // //           Row(
// // // //             children: [
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: const LinearGradient(
// // // //                     colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
// // // //                   ),
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                 ),
// // // //                 child: Icon(
// // // //                   Icons.settings_rounded,
// // // //                   color: Colors.white,
// // // //                   size: _getResponsiveFontSize(context, 18),
// // // //                 ),
// // // //               ),
// // // //               SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //               Expanded(
// // // //                 child: Text(
// // // //                   "Account Settings",
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: _getResponsiveFontSize(context, 16),
// // // //                     fontWeight: FontWeight.bold,
// // // //                   ),
// // // //                   maxLines: 1,
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //               ),
// // // //               if (!isEditing)
// // // //                 IconButton(
// // // //                   icon: Icon(
// // // //                     Icons.edit_rounded,
// // // //                     color: const Color(0xFF00D4AA),
// // // //                     size: _getResponsiveFontSize(context, 18),
// // // //                   ),
// // // //                   onPressed: () => setState(() => isEditing = true),
// // // //                 ),
// // // //             ],
// // // //           ),
// // // //           SizedBox(height: _getResponsiveSpacing(context, 12)),
// // // //           _buildEditableField(
// // // //             label: "Full Name",
// // // //             value: userName,
// // // //             controller: _nameController,
// // // //             icon: Icons.person_rounded,
// // // //           ),
// // // //           SizedBox(height: _getResponsiveSpacing(context, 8)),
// // // //           _buildEditableField(
// // // //             label: "Email",
// // // //             value: userEmail,
// // // //             controller: _emailController,
// // // //             icon: Icons.email_rounded,
// // // //           ),
// // // //           if (isEditing) ...[
// // // //             SizedBox(height: _getResponsiveSpacing(context, 12)),
// // // //             Row(
// // // //               children: [
// // // //                 Expanded(
// // // //                   child: OutlinedButton(
// // // //                     onPressed: _cancelEditing,
// // // //                     style: OutlinedButton.styleFrom(
// // // //                       side: const BorderSide(color: Colors.white54),
// // // //                       padding: EdgeInsets.symmetric(
// // // //                         vertical: _getResponsiveSpacing(context, 10),
// // // //                       ),
// // // //                       shape: RoundedRectangleBorder(
// // // //                         borderRadius: BorderRadius.circular(12),
// // // //                       ),
// // // //                     ),
// // // //                     child: Text(
// // // //                       "Cancel",
// // // //                       style: TextStyle(
// // // //                         color: Colors.white54,
// // // //                         fontSize: _getResponsiveFontSize(context, 12),
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //                 SizedBox(width: _getResponsiveSpacing(context, 8)),
// // // //                 Expanded(
// // // //                   child: ElevatedButton(
// // // //                     onPressed: _updateProfile,
// // // //                     style: ElevatedButton.styleFrom(
// // // //                       backgroundColor: const Color(0xFF00D4AA),
// // // //                       padding: EdgeInsets.symmetric(
// // // //                         vertical: _getResponsiveSpacing(context, 10),
// // // //                       ),
// // // //                       shape: RoundedRectangleBorder(
// // // //                         borderRadius: BorderRadius.circular(12),
// // // //                       ),
// // // //                     ),
// // // //                     child: Text(
// // // //                       "Save",
// // // //                       style: TextStyle(
// // // //                         color: Colors.white,
// // // //                         fontWeight: FontWeight.w600,
// // // //                         fontSize: _getResponsiveFontSize(context, 12),
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ],
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ EDITABLE FIELD - Responsive Input Fields
// // // //   Widget _buildEditableField({
// // // //     required String label,
// // // //     required String value,
// // // //     required TextEditingController controller,
// // // //     required IconData icon,
// // // //   }) {
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
// // // //       decoration: BoxDecoration(
// // // //         color: Colors.white.withOpacity(0.05),
// // // //         borderRadius: BorderRadius.circular(12),
// // // //         border: Border.all(
// // // //           color: isEditing
// // // //               ? const Color(0xFF00D4AA).withOpacity(0.3)
// // // //               : Colors.white.withOpacity(0.1),
// // // //         ),
// // // //       ),
// // // //       child: Row(
// // // //         children: [
// // // //           Icon(
// // // //             icon,
// // // //             color: const Color(0xFF00D4AA),
// // // //             size: _getResponsiveFontSize(context, 18),
// // // //           ),
// // // //           SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //           Expanded(
// // // //             child: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               mainAxisSize: MainAxisSize.min,
// // // //               children: [
// // // //                 Text(
// // // //                   label,
// // // //                   style: TextStyle(
// // // //                     color: Colors.white.withOpacity(0.7),
// // // //                     fontSize: _getResponsiveFontSize(context, 10),
// // // //                   ),
// // // //                 ),
// // // //                 SizedBox(height: _getResponsiveSpacing(context, 2)),
// // // //                 isEditing
// // // //                     ? TextField(
// // // //                   controller: controller,
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: _getResponsiveFontSize(context, 14),
// // // //                   ),
// // // //                   decoration: const InputDecoration(
// // // //                     isDense: true,
// // // //                     contentPadding: EdgeInsets.zero,
// // // //                     border: InputBorder.none,
// // // //                   ),
// // // //                   maxLines: 1,
// // // //                 )
// // // //                     : Text(
// // // //                   value,
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: _getResponsiveFontSize(context, 14),
// // // //                   ),
// // // //                   maxLines: 1,
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ LEARNING JOURNEY - Responsive Achievements
// // // //   Widget _buildLearningJourney() {
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Colors.white.withOpacity(0.12),
// // // //             Colors.white.withOpacity(0.06),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(20),
// // // //         border: Border.all(
// // // //           color: Colors.white.withOpacity(0.2),
// // // //           width: 1,
// // // //         ),
// // // //       ),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         mainAxisSize: MainAxisSize.min,
// // // //         children: [
// // // //           Row(
// // // //             children: [
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: const LinearGradient(
// // // //                     colors: [Colors.purple, Colors.deepPurple],
// // // //                   ),
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                 ),
// // // //                 child: Icon(
// // // //                   Icons.timeline_rounded,
// // // //                   color: Colors.white,
// // // //                   size: _getResponsiveFontSize(context, 18),
// // // //                 ),
// // // //               ),
// // // //               SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //               Expanded(
// // // //                 child: Text(
// // // //                   "Learning Journey",
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: _getResponsiveFontSize(context, 16),
// // // //                     fontWeight: FontWeight.bold,
// // // //                   ),
// // // //                   maxLines: 1,
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           SizedBox(height: _getResponsiveSpacing(context, 12)),
// // // //
// // // //           // Dynamic achievements based on real data
// // // //           ...(_buildAchievements()),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   List<Widget> _buildAchievements() {
// // // //     List<Widget> achievements = [];
// // // //
// // // //     if (userPoints > 0) {
// // // //       achievements.add(_buildAchievementItem(
// // // //         icon: Icons.emoji_events_rounded,
// // // //         title: "Points Earned",
// // // //         subtitle: "$userPoints learning points collected!",
// // // //         time: _getPointsMessage(),
// // // //         color: Colors.amber,
// // // //       ));
// // // //     }
// // // //
// // // //     if (quizzesTaken > 0) {
// // // //       achievements.add(_buildAchievementItem(
// // // //         icon: Icons.quiz_rounded,
// // // //         title: "Quiz Master",
// // // //         subtitle: "Completed $quizzesTaken ${quizzesTaken == 1 ? 'quiz' : 'quizzes'}",
// // // //         time: bestQuizScore > 0 ? "Best: $bestQuizScore pts" : "Keep going!",
// // // //         color: Colors.green,
// // // //       ));
// // // //     }
// // // //
// // // //     if (notesCount > 0) {
// // // //       achievements.add(_buildAchievementItem(
// // // //         icon: Icons.note_add_rounded,
// // // //         title: "Note Keeper",
// // // //         subtitle: "Saved $notesCount ${notesCount == 1 ? 'note' : 'notes'}",
// // // //         time: "Great organization!",
// // // //         color: Colors.blue,
// // // //       ));
// // // //     }
// // // //
// // // //     if (savedVideosCount > 0) {
// // // //       achievements.add(_buildAchievementItem(
// // // //         icon: Icons.video_library_rounded,
// // // //         title: "Video Learner",
// // // //         subtitle: "Bookmarked $savedVideosCount ${savedVideosCount == 1 ? 'video' : 'videos'}",
// // // //         time: "Visual learning!",
// // // //         color: Colors.red,
// // // //       ));
// // // //     }
// // // //
// // // //     // If no achievements yet
// // // //     if (achievements.isEmpty) {
// // // //       achievements.add(_buildAchievementItem(
// // // //         icon: Icons.rocket_launch_rounded,
// // // //         title: "Start Your Journey",
// // // //         subtitle: "Take your first quiz or save your first note!",
// // // //         time: "You've got this! 🚀",
// // // //         color: const Color(0xFF00D4AA),
// // // //       ));
// // // //     }
// // // //
// // // //     return achievements;
// // // //   }
// // // //
// // // //   String _getPointsMessage() {
// // // //     if (userPoints >= 5000) return "Amazing! 🏆";
// // // //     if (userPoints >= 3000) return "Excellent! 🌟";
// // // //     if (userPoints >= 1500) return "Great job! 🎉";
// // // //     if (userPoints >= 500) return "Keep going! 💪";
// // // //     return "Good start! 👍";
// // // //   }
// // // //
// // // //   Widget _buildAchievementItem({
// // // //     required IconData icon,
// // // //     required String title,
// // // //     required String subtitle,
// // // //     required String time,
// // // //     required Color color,
// // // //   }) {
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       margin: EdgeInsets.only(bottom: _getResponsiveSpacing(context, 8)),
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           colors: [
// // // //             color.withOpacity(0.1),
// // // //             color.withOpacity(0.05),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(12),
// // // //         border: Border.all(
// // // //           color: color.withOpacity(0.3),
// // // //           width: 1,
// // // //         ),
// // // //       ),
// // // //       child: Row(
// // // //         children: [
// // // //           Container(
// // // //             padding: EdgeInsets.all(_getResponsiveSpacing(context, 6)),
// // // //             decoration: BoxDecoration(
// // // //               gradient: LinearGradient(
// // // //                 colors: [color, color.withOpacity(0.8)],
// // // //               ),
// // // //               shape: BoxShape.circle,
// // // //             ),
// // // //             child: Icon(
// // // //               icon,
// // // //               color: Colors.white,
// // // //               size: _getResponsiveFontSize(context, 14),
// // // //             ),
// // // //           ),
// // // //           SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //           Expanded(
// // // //             child: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               mainAxisSize: MainAxisSize.min,
// // // //               children: [
// // // //                 Text(
// // // //                   title,
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontWeight: FontWeight.w600,
// // // //                     fontSize: _getResponsiveFontSize(context, 12),
// // // //                   ),
// // // //                   maxLines: 1,
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //                 SizedBox(height: _getResponsiveSpacing(context, 2)),
// // // //                 Text(
// // // //                   subtitle,
// // // //                   style: TextStyle(
// // // //                     color: Colors.white.withOpacity(0.8),
// // // //                     fontSize: _getResponsiveFontSize(context, 10),
// // // //                   ),
// // // //                   maxLines: 2,
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //           if (time.isNotEmpty)
// // // //             Text(
// // // //               time,
// // // //               style: TextStyle(
// // // //                 color: color,
// // // //                 fontSize: _getResponsiveFontSize(context, 8),
// // // //                 fontWeight: FontWeight.w500,
// // // //               ),
// // // //               maxLines: 1,
// // // //               overflow: TextOverflow.ellipsis,
// // // //             ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //   // ✅ LOGOUT SECTION - Responsive Design
// // // //   Widget _buildLogoutSection() {
// // // //     return Container(
// // // //       width: double.infinity,
// // // //       margin: EdgeInsets.symmetric(horizontal: _getResponsiveSpacing(context, 8)),
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Colors.red.withOpacity(0.1),
// // // //             Colors.red.withOpacity(0.05),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(20),
// // // //         border: Border.all(
// // // //           color: Colors.red.withOpacity(0.2),
// // // //           width: 1,
// // // //         ),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: Colors.black.withOpacity(0.1),
// // // //             blurRadius: 10,
// // // //             offset: const Offset(0, 4),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Column(
// // // //         mainAxisSize: MainAxisSize.min,
// // // //         children: [
// // // //           // Logout icon
// // // //           Container(
// // // //             padding: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
// // // //             decoration: BoxDecoration(
// // // //               gradient: const LinearGradient(
// // // //                 colors: [Colors.red, Color(0xFFE53E3E)],
// // // //               ),
// // // //               shape: BoxShape.circle,
// // // //               boxShadow: [
// // // //                 BoxShadow(
// // // //                   color: Colors.red.withOpacity(0.3),
// // // //                   blurRadius: 15,
// // // //                   spreadRadius: 2,
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //             child: Icon(
// // // //               Icons.logout_rounded,
// // // //               color: Colors.white,
// // // //               size: _getResponsiveFontSize(context, 20),
// // // //             ),
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 12)),
// // // //
// // // //           // Title
// // // //           Text(
// // // //             'Ready to Sign Out?',
// // // //             style: TextStyle(
// // // //               color: Colors.white,
// // // //               fontSize: _getResponsiveFontSize(context, 16),
// // // //               fontWeight: FontWeight.bold,
// // // //             ),
// // // //             textAlign: TextAlign.center,
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 6)),
// // // //
// // // //           // Description
// // // //           Text(
// // // //             'Your progress is automatically saved.\nYou can continue anytime!',
// // // //             style: TextStyle(
// // // //               color: Colors.white.withOpacity(0.7),
// // // //               fontSize: _getResponsiveFontSize(context, 12),
// // // //               height: 1.4,
// // // //             ),
// // // //             textAlign: TextAlign.center,
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 16)),
// // // //
// // // //           // Logout button
// // // //           SizedBox(
// // // //             width: double.infinity,
// // // //             child: ElevatedButton(
// // // //               onPressed: _showLogoutDialog,
// // // //               style: ElevatedButton.styleFrom(
// // // //                 backgroundColor: Colors.red,
// // // //                 foregroundColor: Colors.white,
// // // //                 padding: EdgeInsets.symmetric(
// // // //                   vertical: _getResponsiveSpacing(context, 12),
// // // //                 ),
// // // //                 shape: RoundedRectangleBorder(
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                 ),
// // // //                 elevation: 3,
// // // //               ),
// // // //               child: Row(
// // // //                 mainAxisAlignment: MainAxisAlignment.center,
// // // //                 children: [
// // // //                   Icon(Icons.logout_rounded, size: _getResponsiveFontSize(context, 16)),
// // // //                   SizedBox(width: _getResponsiveSpacing(context, 8)),
// // // //                   Text(
// // // //                     'Sign Out',
// // // //                     style: TextStyle(
// // // //                       fontSize: _getResponsiveFontSize(context, 14),
// // // //                       fontWeight: FontWeight.w600,
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 8)),
// // // //
// // // //           // Security note
// // // //           Row(
// // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // //             children: [
// // // //               Icon(
// // // //                 Icons.shield_outlined,
// // // //                 color: const Color(0xFF00D4AA),
// // // //                 size: _getResponsiveFontSize(context, 14),
// // // //               ),
// // // //               SizedBox(width: _getResponsiveSpacing(context, 4)),
// // // //               Text(
// // // //                 'Your data is safely stored',
// // // //                 style: TextStyle(
// // // //                   color: const Color(0xFF00D4AA),
// // // //                   fontSize: _getResponsiveFontSize(context, 10),
// // // //                   fontWeight: FontWeight.w500,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }
// // // //
// // // // // ✅ LOGOUT DIALOG - Responsive and Beautiful
// // // // class _LogoutDialogContent extends StatefulWidget {
// // // //   @override
// // // //   _LogoutDialogContentState createState() => _LogoutDialogContentState();
// // // // }
// // // //
// // // // class _LogoutDialogContentState extends State<_LogoutDialogContent> {
// // // //   bool _isLoggingOut = false;
// // // //
// // // //   // Responsive helper methods for dialog
// // // //   double _getResponsiveSpacing(BuildContext context, double baseSize) {
// // // //     final screenWidth = MediaQuery.of(context).size.width;
// // // //     if (screenWidth < 360) return baseSize * 0.7;
// // // //     if (screenWidth < 600) return (baseSize * screenWidth) / 375;
// // // //     return baseSize * 1.2;
// // // //   }
// // // //
// // // //   double _getResponsiveFontSize(BuildContext context, double baseSize) {
// // // //     final screenWidth = MediaQuery.of(context).size.width;
// // // //     if (screenWidth < 360) return baseSize * 0.85;
// // // //     if (screenWidth < 600) return (baseSize * screenWidth) / 375;
// // // //     return baseSize * 1.1;
// // // //   }
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Dialog(
// // // //       backgroundColor: Colors.transparent,
// // // //       elevation: 0,
// // // //       child: Container(
// // // //         width: double.infinity,
// // // //         constraints: BoxConstraints(
// // // //           maxWidth: MediaQuery.of(context).size.width * 0.9,
// // // //           maxHeight: MediaQuery.of(context).size.height * 0.7,
// // // //         ),
// // // //         margin: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
// // // //         decoration: BoxDecoration(
// // // //           gradient: const LinearGradient(
// // // //             begin: Alignment.topLeft,
// // // //             end: Alignment.bottomRight,
// // // //             colors: [
// // // //               Color(0xFF1B263B),
// // // //               Color(0xFF0D1B2A),
// // // //             ],
// // // //           ),
// // // //           borderRadius: BorderRadius.circular(24),
// // // //           border: Border.all(
// // // //             color: Colors.red.withOpacity(0.3),
// // // //             width: 2,
// // // //           ),
// // // //           boxShadow: [
// // // //             BoxShadow(
// // // //               color: Colors.red.withOpacity(0.2),
// // // //               blurRadius: 20,
// // // //               spreadRadius: 5,
// // // //             ),
// // // //             BoxShadow(
// // // //               color: Colors.black.withOpacity(0.3),
// // // //               blurRadius: 15,
// // // //               offset: const Offset(0, 8),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //         child: Padding(
// // // //           padding: EdgeInsets.all(_getResponsiveSpacing(context, 24)),
// // // //           child: Column(
// // // //             mainAxisSize: MainAxisSize.min,
// // // //             children: [
// // // //               // Logout icon
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: LinearGradient(
// // // //                     colors: _isLoggingOut
// // // //                         ? [Colors.grey, Colors.grey.shade600]
// // // //                         : [Colors.red, const Color(0xFFDC2626)],
// // // //                   ),
// // // //                   shape: BoxShape.circle,
// // // //                   boxShadow: [
// // // //                     BoxShadow(
// // // //                       color: (_isLoggingOut ? Colors.grey : Colors.red).withOpacity(0.4),
// // // //                       blurRadius: 15,
// // // //                       spreadRadius: 3,
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //                 child: _isLoggingOut
// // // //                     ? SizedBox(
// // // //                   width: _getResponsiveFontSize(context, 28),
// // // //                   height: _getResponsiveFontSize(context, 28),
// // // //                   child: const CircularProgressIndicator(
// // // //                     strokeWidth: 3,
// // // //                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// // // //                   ),
// // // //                 )
// // // //                     : Icon(
// // // //                   Icons.logout_rounded,
// // // //                   color: Colors.white,
// // // //                   size: _getResponsiveFontSize(context, 28),
// // // //                 ),
// // // //               ),
// // // //
// // // //               SizedBox(height: _getResponsiveSpacing(context, 16)),
// // // //
// // // //               // Title
// // // //               Text(
// // // //                 _isLoggingOut ? 'Signing Out...' : 'Ready to Sign Out?',
// // // //                 style: TextStyle(
// // // //                   color: Colors.red,
// // // //                   fontSize: _getResponsiveFontSize(context, 20),
// // // //                   fontWeight: FontWeight.bold,
// // // //                   letterSpacing: 0.5,
// // // //                 ),
// // // //                 textAlign: TextAlign.center,
// // // //               ),
// // // //
// // // //               SizedBox(height: _getResponsiveSpacing(context, 12)),
// // // //
// // // //               // Security message
// // // //               Container(
// // // //                 width: double.infinity,
// // // //                 padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //                 decoration: BoxDecoration(
// // // //                   color: const Color(0xFF2A3441),
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                   border: Border.all(
// // // //                     color: Colors.white.withOpacity(0.1),
// // // //                   ),
// // // //                 ),
// // // //                 child: Column(
// // // //                   mainAxisSize: MainAxisSize.min,
// // // //                   children: [
// // // //                     Icon(
// // // //                       Icons.verified_user,
// // // //                       color: const Color(0xFF00D4AA),
// // // //                       size: _getResponsiveFontSize(context, 18),
// // // //                     ),
// // // //                     SizedBox(height: _getResponsiveSpacing(context, 8)),
// // // //                     Text(
// // // //                       _isLoggingOut
// // // //                           ? 'Saving your progress and signing out safely...'
// // // //                           : 'Your learning progress is safely saved!\nYou can continue where you left off when you return.',
// // // //                       style: TextStyle(
// // // //                         color: Colors.white.withOpacity(0.8),
// // // //                         fontSize: _getResponsiveFontSize(context, 12),
// // // //                         height: 1.4,
// // // //                       ),
// // // //                       textAlign: TextAlign.center,
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //
// // // //               SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //               // Action buttons
// // // //               Row(
// // // //                 children: [
// // // //                   // Stay button
// // // //                   Expanded(
// // // //                     child: Container(
// // // //                       decoration: BoxDecoration(
// // // //                         color: Colors.transparent,
// // // //                         borderRadius: BorderRadius.circular(16),
// // // //                         border: Border.all(
// // // //                           color: Colors.white.withOpacity(0.3),
// // // //                           width: 1,
// // // //                         ),
// // // //                       ),
// // // //                       child: Material(
// // // //                         color: Colors.transparent,
// // // //                         child: InkWell(
// // // //                           borderRadius: BorderRadius.circular(16),
// // // //                           onTap: _isLoggingOut ? null : () => Navigator.of(context).pop(),
// // // //                           child: Padding(
// // // //                             padding: EdgeInsets.symmetric(
// // // //                               vertical: _getResponsiveSpacing(context, 12),
// // // //                             ),
// // // //                             child: Row(
// // // //                               mainAxisAlignment: MainAxisAlignment.center,
// // // //                               children: [
// // // //                                 Icon(
// // // //                                   Icons.arrow_back,
// // // //                                   color: Colors.white.withOpacity(_isLoggingOut ? 0.4 : 0.8),
// // // //                                   size: _getResponsiveFontSize(context, 16),
// // // //                                 ),
// // // //                                 SizedBox(width: _getResponsiveSpacing(context, 6)),
// // // //                                 Text(
// // // //                                   'Stay Here',
// // // //                                   style: TextStyle(
// // // //                                     color: Colors.white.withOpacity(_isLoggingOut ? 0.4 : 0.8),
// // // //                                     fontSize: _getResponsiveFontSize(context, 12),
// // // //                                     fontWeight: FontWeight.w600,
// // // //                                   ),
// // // //                                 ),
// // // //                               ],
// // // //                             ),
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //
// // // //                   SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //
// // // //                   // Sign Out button
// // // //                   Expanded(
// // // //                     child: Container(
// // // //                       decoration: BoxDecoration(
// // // //                         gradient: LinearGradient(
// // // //                           colors: _isLoggingOut
// // // //                               ? [Colors.grey, Colors.grey.shade600]
// // // //                               : [Colors.red, const Color(0xFFDC2626)],
// // // //                         ),
// // // //                         borderRadius: BorderRadius.circular(16),
// // // //                         boxShadow: [
// // // //                           BoxShadow(
// // // //                             color: (_isLoggingOut ? Colors.grey : Colors.red).withOpacity(0.3),
// // // //                             blurRadius: 8,
// // // //                             offset: const Offset(0, 4),
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                       child: Material(
// // // //                         color: Colors.transparent,
// // // //                         child: InkWell(
// // // //                           borderRadius: BorderRadius.circular(16),
// // // //                           onTap: _isLoggingOut ? null : _handleLogout,
// // // //                           child: Padding(
// // // //                             padding: EdgeInsets.symmetric(
// // // //                               vertical: _getResponsiveSpacing(context, 12),
// // // //                             ),
// // // //                             child: Row(
// // // //                               mainAxisAlignment: MainAxisAlignment.center,
// // // //                               children: [
// // // //                                 if (_isLoggingOut) ...[
// // // //                                   SizedBox(
// // // //                                     width: 16,
// // // //                                     height: 16,
// // // //                                     child: const CircularProgressIndicator(
// // // //                                       strokeWidth: 2,
// // // //                                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// // // //                                     ),
// // // //                                   ),
// // // //                                 ] else ...[
// // // //                                   Icon(
// // // //                                     Icons.logout_rounded,
// // // //                                     color: Colors.white,
// // // //                                     size: _getResponsiveFontSize(context, 16),
// // // //                                   ),
// // // //                                 ],
// // // //                                 SizedBox(width: _getResponsiveSpacing(context, 6)),
// // // //                                 Text(
// // // //                                   _isLoggingOut ? 'Signing Out...' : 'Sign Out',
// // // //                                   style: TextStyle(
// // // //                                     color: Colors.white,
// // // //                                     fontSize: _getResponsiveFontSize(context, 12),
// // // //                                     fontWeight: FontWeight.bold,
// // // //                                   ),
// // // //                                 ),
// // // //                               ],
// // // //                             ),
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ LOGOUT HANDLING
// // // //   Future<void> _handleLogout() async {
// // // //     if (!mounted) return;
// // // //
// // // //     setState(() {
// // // //       _isLoggingOut = true;
// // // //     });
// // // //
// // // //     try {
// // // //       await _performLogout();
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           _isLoggingOut = false;
// // // //         });
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(
// // // //             content: Text('Logout failed: ${e.toString()}'),
// // // //             backgroundColor: Colors.red,
// // // //             behavior: SnackBarBehavior.floating,
// // // //             shape: RoundedRectangleBorder(
// // // //               borderRadius: BorderRadius.circular(10),
// // // //             ),
// // // //           ),
// // // //         );
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _performLogout() async {
// // // //     try {
// // // //       // Sign out from Firebase
// // // //       await FirebaseAuth.instance.signOut();
// // // //
// // // //       // Clear SharedPreferences
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       await prefs.setBool('is_logged_in', false);
// // // //       await prefs.remove('last_login');
// // // //
// // // //       if (mounted) {
// // // //         // Close this dialog first
// // // //         Navigator.of(context).pop();
// // // //
// // // //         // Then navigate to login, removing all previous routes
// // // //         Navigator.of(context).pushAndRemoveUntil(
// // // //           MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
// // // //               (route) => false,
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         Navigator.of(context).pop(); // Close dialog on error
// // // //       }
// // // //       throw e; // Re-throw to be caught by _handleLogout
// // // //     }
// // // //   }
// // // // }
// // //
// // //
// // //
// // //
// // //
// // //
// // // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // //
// // // // import 'package:firebase_auth/firebase_auth.dart';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // import 'package:image_picker/image_picker.dart';
// // // // import 'dart:io';
// // // // import 'dart:convert';
// // // // import 'dart:typed_data';
// // // //
// // // // import 'email_change_verification_screen.dart';
// // // // import 'login_screen.dart';
// // // //
// // // // class ProfileScreen extends StatefulWidget {
// // // //   const ProfileScreen({super.key});
// // // //
// // // //   @override
// // // //   State<ProfileScreen> createState() => _ProfileScreenState();
// // // // }
// // // //
// // // // class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
// // // //   String userName = "Loading...";
// // // //   String userEmail = "Loading...";
// // // //   String profileImageBase64 = "";
// // // //
// // // //   // Real data from SharedPreferences - user-specific
// // // //   int userPoints = 0;
// // // //   int notesCount = 0;
// // // //   int savedVideosCount = 0;
// // // //   int savedLinksCount = 0;
// // // //   int quizzesTaken = 0;
// // // //   int bestQuizScore = 0;
// // // //   String userLevel = "Rookie";
// // // //
// // // //   // UI state variables
// // // //   bool isEditing = false;
// // // //   bool isLoading = true;
// // // //   bool isUploadingImage = false;
// // // //   File? _profileImage;
// // // //
// // // //   // Controllers
// // // //   final TextEditingController _emailController = TextEditingController();
// // // //   final TextEditingController _nameController = TextEditingController();
// // // //   final ImagePicker _picker = ImagePicker();
// // // //
// // // //   // Animation controllers for engaging UI
// // // //   late AnimationController _fadeController;
// // // //   late AnimationController _slideController;
// // // //   late AnimationController _counterController;
// // // //   late AnimationController _pulseController;
// // // //   late Animation<double> _fadeAnimation;
// // // //   late Animation<Offset> _slideAnimation;
// // // //   late Animation<double> _counterAnimation;
// // // //   late Animation<double> _pulseAnimation;
// // // //
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _initializeAnimations();
// // // //     _loadUserData();
// // // //   }
// // // //
// // // //   void _initializeAnimations() {
// // // //     _fadeController = AnimationController(
// // // //       duration: const Duration(milliseconds: 1000),
// // // //       vsync: this,
// // // //     );
// // // //
// // // //     _slideController = AnimationController(
// // // //       duration: const Duration(milliseconds: 800),
// // // //       vsync: this,
// // // //     );
// // // //
// // // //     _counterController = AnimationController(
// // // //       duration: const Duration(milliseconds: 2000),
// // // //       vsync: this,
// // // //     );
// // // //
// // // //     _pulseController = AnimationController(
// // // //       duration: const Duration(milliseconds: 2000),
// // // //       vsync: this,
// // // //     );
// // // //
// // // //     _fadeAnimation = CurvedAnimation(
// // // //       parent: _fadeController,
// // // //       curve: Curves.easeInOut,
// // // //     );
// // // //
// // // //     _slideAnimation = Tween<Offset>(
// // // //       begin: const Offset(0, 0.5),
// // // //       end: Offset.zero,
// // // //     ).animate(CurvedAnimation(
// // // //       parent: _slideController,
// // // //       curve: Curves.easeOutCubic,
// // // //     ));
// // // //
// // // //     _counterAnimation = CurvedAnimation(
// // // //       parent: _counterController,
// // // //       curve: Curves.easeOutQuart,
// // // //     );
// // // //
// // // //     _pulseAnimation = Tween<double>(
// // // //       begin: 1.0,
// // // //       end: 1.05,
// // // //     ).animate(CurvedAnimation(
// // // //       parent: _pulseController,
// // // //       curve: Curves.easeInOut,
// // // //     ));
// // // //   }
// // // //
// // // //   @override
// // // //   void dispose() {
// // // //     _fadeController.dispose();
// // // //     _slideController.dispose();
// // // //     _counterController.dispose();
// // // //     _pulseController.dispose();
// // // //     _nameController.dispose();
// // // //     _emailController.dispose();
// // // //     super.dispose();
// // // //   }
// // // //
// // // //   // ✅ Responsive helper methods
// // // //   double _getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;
// // // //   double _getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;
// // // //
// // // //   bool _isMobile(BuildContext context) => _getScreenWidth(context) < 600;
// // // //   bool _isTablet(BuildContext context) => _getScreenWidth(context) >= 600 && _getScreenWidth(context) < 900;
// // // //   bool _isDesktop(BuildContext context) => _getScreenWidth(context) >= 900;
// // // //
// // // //   // ✅ Better responsive font sizing
// // // //   double _getResponsiveFontSize(BuildContext context, double baseMobile) {
// // // //     if (_isMobile(context)) {
// // // //       return baseMobile * (_getScreenWidth(context) / 375).clamp(0.85, 1.2);
// // // //     } else if (_isTablet(context)) {
// // // //       return baseMobile * 1.15;
// // // //     }
// // // //     return baseMobile * 1.3;
// // // //   }
// // // //
// // // //   // ✅ Better responsive padding
// // // //   EdgeInsets _getResponsivePadding(BuildContext context) {
// // // //     if (_isMobile(context)) {
// // // //       return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
// // // //     } else if (_isTablet(context)) {
// // // //       return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
// // // //     }
// // // //     return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
// // // //   }
// // // //
// // // //   // ✅ Better responsive spacing
// // // //   double _getResponsiveSpacing(BuildContext context, double baseMobile) {
// // // //     if (_isMobile(context)) {
// // // //       return baseMobile;
// // // //     } else if (_isTablet(context)) {
// // // //       return baseMobile * 1.2;
// // // //     }
// // // //     return baseMobile * 1.5;
// // // //   }
// // // //
// // // //   // ✅ Calculate card dimensions to prevent overflow
// // // //   double _getCardHeight(BuildContext context) {
// // // //     if (_isMobile(context)) {
// // // //       return 140;
// // // //     } else if (_isTablet(context)) {
// // // //       return 160;
// // // //     }
// // // //     return 180;
// // // //   }
// // // //
// // // //   int _getCrossAxisCount(BuildContext context) {
// // // //     if (_isMobile(context)) {
// // // //       return 2;
// // // //     } else if (_isTablet(context)) {
// // // //       return 3;
// // // //     }
// // // //     return 4;
// // // //   }
// // // //   // ✅ Enhanced user data loading with better error handling
// // // //   Future<void> _loadUserData() async {
// // // //     try {
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       if (user == null) {
// // // //         _redirectToLogin();
// // // //         return;
// // // //       }
// // // //
// // // //       // Load Firebase user data
// // // //       final userDoc = await FirebaseFirestore.instance
// // // //           .collection('users')
// // // //           .doc(user.uid)
// // // //           .get();
// // // //
// // // //       if (userDoc.exists && mounted) {
// // // //         final userData = userDoc.data()!;
// // // //         setState(() {
// // // //           userName = userData['fullName'] ?? 'Unknown User';
// // // //           userEmail = userData['email'] ?? user.email ?? '';
// // // //           _nameController.text = userName;
// // // //           _emailController.text = userEmail;
// // // //         });
// // // //
// // // //         // Load profile image and stats data
// // // //         await Future.wait([
// // // //           _loadProfileImage(),
// // // //           _loadUserStats(),
// // // //         ]);
// // // //
// // // //         // Start animations after data is loaded
// // // //         if (mounted) {
// // // //           _fadeController.forward();
// // // //           _slideController.forward();
// // // //           _counterController.forward();
// // // //           _pulseController.repeat(reverse: true);
// // // //         }
// // // //
// // // //         setState(() {
// // // //           isLoading = false;
// // // //         });
// // // //       } else {
// // // //         _redirectToLogin();
// // // //       }
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           isLoading = false;
// // // //         });
// // // //         _showErrorSnackBar('Failed to load profile data');
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   // ✅ Enhanced stats loading with better calculations
// // // //   // ✅ FIXED NOTES COUNTING - Replace the _loadUserStats() method
// // // //   Future<void> _loadUserStats() async {
// // // //     try {
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       if (user == null) return;
// // // //
// // // //       final userId = user.uid;
// // // //
// // // //       // Load points and quiz data
// // // //       final points = prefs.getInt('${userId}_user_points') ?? 0;
// // // //       final quizCount = prefs.getInt('${userId}_quizzes_taken') ?? 0;
// // // //       final bestScore = prefs.getInt('${userId}_best_score') ?? 0;
// // // //
// // // //       // ✅ IMPROVED NOTES COUNTING WITH MULTIPLE SOURCES
// // // //       int totalNotesCount = 0;
// // // //       int linksCount = 0;
// // // //       int videosCount = 0;
// // // //
// // // //       // Method 1: Count saved notes
// // // //       final savedNotesJson = prefs.getStringList('${userId}_saved_notes') ?? [];
// // // //       totalNotesCount += savedNotesJson.length;
// // // //
// // // //       // Count links in saved notes
// // // //       for (final noteString in savedNotesJson) {
// // // //         try {
// // // //           if (noteString.contains('http') || noteString.contains('www.')) {
// // // //             linksCount++;
// // // //           }
// // // //         } catch (e) {
// // // //           debugPrint('Error parsing saved note: $e');
// // // //         }
// // // //       }
// // // //
// // // //       // Method 2: Count coding notes
// // // //       final codingNotesJson = prefs.getStringList('${userId}_coding_notes') ?? [];
// // // //       totalNotesCount += codingNotesJson.length;
// // // //
// // // //       // Method 3: Count personal notes (if you have this feature)
// // // //       final personalNotesJson = prefs.getStringList('${userId}_personal_notes') ?? [];
// // // //       totalNotesCount += personalNotesJson.length;
// // // //
// // // //       // Method 4: Count study notes (if you have this feature)
// // // //       final studyNotesJson = prefs.getStringList('${userId}_study_notes') ?? [];
// // // //       totalNotesCount += studyNotesJson.length;
// // // //
// // // //       // ✅ IMPROVED VIDEO COUNTING
// // // //       final savedVideosJson = prefs.getStringList('${userId}_saved_videos') ?? [];
// // // //       final bookmarkedVideosJson = prefs.getStringList('${userId}_bookmarked_videos') ?? [];
// // // //       videosCount = savedVideosJson.length + bookmarkedVideosJson.length;
// // // //
// // // //       // ✅ IMPROVED LINKS COUNTING FROM MULTIPLE SOURCES
// // // //       final savedLinksJson = prefs.getStringList('${userId}_saved_links') ?? [];
// // // //       final bookmarkedLinksJson = prefs.getStringList('${userId}_bookmarked_links') ?? [];
// // // //       linksCount += savedLinksJson.length + bookmarkedLinksJson.length;
// // // //
// // // //       // Calculate user level based on points
// // // //       final level = _calculateUserLevel(points);
// // // //
// // // //       // ✅ DEBUG LOGGING TO CHECK VALUES
// // // //       debugPrint('📊 USER STATS DEBUG:');
// // // //       debugPrint('   - User ID: $userId');
// // // //       debugPrint('   - Points: $points');
// // // //       debugPrint('   - Saved Notes: ${savedNotesJson.length}');
// // // //       debugPrint('   - Coding Notes: ${codingNotesJson.length}');
// // // //       debugPrint('   - Personal Notes: ${personalNotesJson.length}');
// // // //       debugPrint('   - Study Notes: ${studyNotesJson.length}');
// // // //       debugPrint('   - Total Notes: $totalNotesCount');
// // // //       debugPrint('   - Videos: $videosCount');
// // // //       debugPrint('   - Links: $linksCount');
// // // //       debugPrint('   - Quizzes: $quizCount');
// // // //       debugPrint('   - Level: $level');
// // // //
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           userPoints = points;
// // // //           quizzesTaken = quizCount;
// // // //           bestQuizScore = bestScore;
// // // //           notesCount = totalNotesCount; // ✅ PROPERLY SET TOTAL NOTES
// // // //           savedVideosCount = videosCount;
// // // //           savedLinksCount = linksCount;
// // // //           userLevel = level;
// // // //         });
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint('❌ Error loading user stats: $e');
// // // //       // Handle gracefully with default values
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           userPoints = 0;
// // // //           notesCount = 0;
// // // //           savedVideosCount = 0;
// // // //           savedLinksCount = 0;
// // // //           quizzesTaken = 0;
// // // //           bestQuizScore = 0;
// // // //           userLevel = 'Rookie';
// // // //         });
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   // ✅ User level calculation
// // // //   String _calculateUserLevel(int points) {
// // // //     if (points >= 5000) return 'Expert';
// // // //     if (points >= 3000) return 'Advanced';
// // // //     if (points >= 1500) return 'Intermediate';
// // // //     if (points >= 500) return 'Beginner';
// // // //     return 'Rookie';
// // // //   }
// // // //
// // // //   // ✅ Enhanced level styling
// // // //   Color _getLevelColor() {
// // // //     switch (userLevel) {
// // // //       case 'Expert':
// // // //         return const Color(0xFF8B5CF6); // Purple
// // // //       case 'Advanced':
// // // //         return const Color(0xFF00D4AA); // Teal
// // // //       case 'Intermediate':
// // // //         return const Color(0xFF3B82F6); // Blue
// // // //       case 'Beginner':
// // // //         return const Color(0xFFF59E0B); // Orange
// // // //       default:
// // // //         return const Color(0xFF6B7280); // Gray
// // // //     }
// // // //   }
// // // //
// // // //   IconData _getLevelIcon() {
// // // //     switch (userLevel) {
// // // //       case 'Expert': return Icons.diamond;
// // // //       case 'Advanced': return Icons.military_tech;
// // // //       case 'Intermediate': return Icons.star;
// // // //       case 'Beginner': return Icons.school;
// // // //       default: return Icons.person;
// // // //     }
// // // //   }
// // // //
// // // //   // ✅ Better next level info with progress
// // // //   String _getNextLevelInfo() {
// // // //     final nextPoints = _getNextLevelPoints();
// // // //     final currentPoints = _getCurrentLevelPoints();
// // // //
// // // //     if (userLevel == 'Expert') {
// // // //       return 'Congratulations! You\'ve reached the highest level! 🏆';
// // // //     }
// // // //
// // // //     final needed = nextPoints - userPoints;
// // // //     final nextLevel = _getNextLevelName();
// // // //
// // // //     return 'Earn $needed more points to reach $nextLevel level!';
// // // //   }
// // // //
// // // //   String _getNextLevelName() {
// // // //     switch (userLevel) {
// // // //       case 'Rookie': return 'Beginner';
// // // //       case 'Beginner': return 'Intermediate';
// // // //       case 'Intermediate': return 'Advanced';
// // // //       case 'Advanced': return 'Expert';
// // // //       default: return 'Expert';
// // // //     }
// // // //   }
// // // //
// // // //   int _getNextLevelPoints() {
// // // //     switch (userLevel) {
// // // //       case 'Rookie': return 500;
// // // //       case 'Beginner': return 1500;
// // // //       case 'Intermediate': return 3000;
// // // //       case 'Advanced': return 5000;
// // // //       default: return 5000; // Expert level
// // // //     }
// // // //   }
// // // //
// // // //   int _getCurrentLevelPoints() {
// // // //     switch (userLevel) {
// // // //       case 'Rookie': return 0;
// // // //       case 'Beginner': return 500;
// // // //       case 'Intermediate': return 1500;
// // // //       case 'Advanced': return 3000;
// // // //       case 'Expert': return 5000;
// // // //       default: return 0;
// // // //     }
// // // //   }
// // // //
// // // //   double _getLevelProgress() {
// // // //     if (userLevel == 'Expert') return 1.0;
// // // //
// // // //     final nextPoints = _getNextLevelPoints();
// // // //     final currentPoints = _getCurrentLevelPoints();
// // // //     final progress = ((userPoints - currentPoints) / (nextPoints - currentPoints)).clamp(0.0, 1.0);
// // // //
// // // //     return progress;
// // // //   }
// // // //
// // // //   Future<void> _loadProfileImage() async {
// // // //     try {
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       if (user != null) {
// // // //         final imageKey = 'profile_image_${user.uid}';
// // // //         final savedImageBase64 = prefs.getString(imageKey);
// // // //         if (savedImageBase64 != null && savedImageBase64.isNotEmpty && mounted) {
// // // //           setState(() {
// // // //             profileImageBase64 = savedImageBase64;
// // // //           });
// // // //         }
// // // //       }
// // // //     } catch (e) {
// // // //       debugPrint('Error loading profile image: $e');
// // // //     }
// // // //   }
// // // //
// // // //   // ✅ Refresh user data with loading state
// // // //   Future<void> _refreshData() async {
// // // //     setState(() {
// // // //       isLoading = true;
// // // //     });
// // // //
// // // //     await Future.wait([
// // // //       _loadUserStats(),
// // // //       _loadProfileImage(),
// // // //     ]);
// // // //
// // // //     if (mounted) {
// // // //       setState(() {
// // // //         isLoading = false;
// // // //       });
// // // //       _showSuccessSnackBar('Profile data refreshed!');
// // // //     }
// // // //   }
// // // //   // ✅ Enhanced image picking with better UX
// // // //   Future<void> _pickImage() async {
// // // //     try {
// // // //       final XFile? image = await _picker.pickImage(
// // // //         source: ImageSource.gallery,
// // // //         maxWidth: 512,
// // // //         maxHeight: 512,
// // // //         imageQuality: 80,
// // // //       );
// // // //
// // // //       if (image != null) {
// // // //         setState(() {
// // // //           _profileImage = File(image.path);
// // // //           isUploadingImage = true;
// // // //         });
// // // //
// // // //         await _saveProfileImageLocally(File(image.path));
// // // //       }
// // // //     } catch (e) {
// // // //       _showErrorSnackBar('Failed to pick image: Please try again');
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _saveProfileImageLocally(File imageFile) async {
// // // //     try {
// // // //       final user = FirebaseAuth.instance.currentUser;
// // // //       if (user == null) return;
// // // //
// // // //       final bytes = await imageFile.readAsBytes();
// // // //       final base64String = base64Encode(bytes);
// // // //
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       final imageKey = 'profile_image_${user.uid}';
// // // //       await prefs.setString(imageKey, base64String);
// // // //
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           profileImageBase64 = base64String;
// // // //           isUploadingImage = false;
// // // //         });
// // // //         _showSuccessSnackBar('Profile image updated successfully!');
// // // //       }
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           isUploadingImage = false;
// // // //           _profileImage = null;
// // // //         });
// // // //         _showErrorSnackBar('Failed to save image');
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   // ✅ Enhanced profile update
// // // //   // ✅ REPLACE the existing _updateProfile() method with this:
// // // //   Future<void> _updateProfile() async {
// // // //     final name = _nameController.text.trim();
// // // //     final email = _emailController.text.trim();
// // // //     final currentUser = FirebaseAuth.instance.currentUser;
// // // //
// // // //     if (name.isEmpty) {
// // // //       _showErrorSnackBar('Name cannot be empty');
// // // //       return;
// // // //     }
// // // //
// // // //     if (!_isValidEmail(email)) {
// // // //       _showErrorSnackBar('Please enter a valid email address');
// // // //       return;
// // // //     }
// // // //
// // // //     if (currentUser == null) return;
// // // //
// // // //     try {
// // // //       setState(() {
// // // //         isLoading = true;
// // // //       });
// // // //
// // // //       // ✅ CHECK IF EMAIL CHANGED
// // // //       final emailChanged = currentUser.email != email;
// // // //
// // // //       if (emailChanged) {
// // // //         // ✅ EMAIL CHANGED - Send verification to new email
// // // //         await _handleEmailChange(email, name);
// // // //       } else {
// // // //         // ✅ ONLY NAME CHANGED - Update directly
// // // //         await _updateNameOnly(name);
// // // //       }
// // // //
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           isLoading = false;
// // // //         });
// // // //         _showErrorSnackBar('Failed to update profile');
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // // // ✅ ADD THESE NEW METHODS to ProfileScreen:
// // // //
// // // //   Future<void> _updateNameOnly(String name) async {
// // // //     final user = FirebaseAuth.instance.currentUser;
// // // //     if (user != null) {
// // // //       // Update Firestore
// // // //       await FirebaseFirestore.instance
// // // //           .collection('users')
// // // //           .doc(user.uid)
// // // //           .update({
// // // //         'fullName': name,
// // // //         'updatedAt': FieldValue.serverTimestamp(),
// // // //       });
// // // //
// // // //       // Update Firebase Auth display name
// // // //       await user.updateDisplayName(name);
// // // //
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           userName = name;
// // // //           isEditing = false;
// // // //           isLoading = false;
// // // //         });
// // // //         _showSuccessSnackBar('Name updated successfully!');
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   Future<void> _handleEmailChange(String newEmail, String name) async {
// // // //     try {
// // // //       // ✅ NAVIGATE TO EMAIL CHANGE VERIFICATION SCREEN
// // // //       setState(() {
// // // //         isLoading = false;
// // // //         isEditing = false;
// // // //       });
// // // //
// // // //       final result = await Navigator.push(
// // // //         context,
// // // //         MaterialPageRoute(
// // // //           builder: (context) => EmailChangeVerificationScreen(
// // // //             currentEmail: userEmail,
// // // //             newEmail: newEmail,
// // // //             userName: name,
// // // //           ),
// // // //         ),
// // // //       );
// // // //
// // // //       // ✅ HANDLE RESULT FROM EMAIL CHANGE SCREEN
// // // //       if (result == true) {
// // // //         // Email successfully changed
// // // //         await _loadUserData(); // Refresh profile data
// // // //         _showSuccessSnackBar('Email updated successfully!');
// // // //       } else {
// // // //         // Email change cancelled or failed - revert email field
// // // //         _emailController.text = userEmail;
// // // //       }
// // // //     } catch (e) {
// // // //       setState(() {
// // // //         isLoading = false;
// // // //       });
// // // //       _emailController.text = userEmail; // Revert on error
// // // //       _showErrorSnackBar('Failed to initiate email change');
// // // //     }
// // // //   }
// // // //
// // // //   bool _isValidEmail(String email) {
// // // //     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
// // // //   }
// // // //
// // // //   // ✅ SUPER ATTRACTIVE LOGOUT DIALOG
// // // //   Future<void> _showLogoutDialog() async {
// // // //     return showDialog<void>(
// // // //       context: context,
// // // //       barrierDismissible: true,
// // // //       barrierColor: Colors.black.withOpacity(0.7),
// // // //       builder: (BuildContext context) {
// // // //         return _LogoutDialogContent();
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //
// // // //   void _redirectToLogin() {
// // // //     if (mounted) {
// // // //       Navigator.pushAndRemoveUntil(
// // // //         context,
// // // //         MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
// // // //             (route) => false,
// // // //       );
// // // //     }
// // // //   }
// // // //
// // // //   void _cancelEditing() {
// // // //     setState(() {
// // // //       _nameController.text = userName;
// // // //       _emailController.text = userEmail;
// // // //       isEditing = false;
// // // //     });
// // // //   }
// // // //
// // // //   // ✅ Enhanced snackbar methods
// // // //   void _showSuccessSnackBar(String message) {
// // // //     ScaffoldMessenger.of(context).showSnackBar(
// // // //       SnackBar(
// // // //         content: Row(
// // // //           children: [
// // // //             Container(
// // // //               padding: const EdgeInsets.all(4),
// // // //               decoration: BoxDecoration(
// // // //                 color: Colors.white.withOpacity(0.2),
// // // //                 shape: BoxShape.circle,
// // // //               ),
// // // //               child: const Icon(Icons.check, color: Colors.white, size: 16),
// // // //             ),
// // // //             const SizedBox(width: 12),
// // // //             Expanded(
// // // //               child: Text(
// // // //                 message,
// // // //                 style: const TextStyle(
// // // //                   fontWeight: FontWeight.w500,
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //         backgroundColor: const Color(0xFF00D4AA),
// // // //         behavior: SnackBarBehavior.floating,
// // // //         shape: RoundedRectangleBorder(
// // // //           borderRadius: BorderRadius.circular(12),
// // // //         ),
// // // //         margin: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   void _showErrorSnackBar(String message) {
// // // //     ScaffoldMessenger.of(context).showSnackBar(
// // // //       SnackBar(
// // // //         content: Row(
// // // //           children: [
// // // //             Container(
// // // //               padding: const EdgeInsets.all(4),
// // // //               decoration: BoxDecoration(
// // // //                 color: Colors.white.withOpacity(0.2),
// // // //                 shape: BoxShape.circle,
// // // //               ),
// // // //               child: const Icon(Icons.warning, color: Colors.white, size: 16),
// // // //             ),
// // // //             const SizedBox(width: 12),
// // // //             Expanded(
// // // //               child: Text(
// // // //                 message,
// // // //                 style: const TextStyle(
// // // //                   fontWeight: FontWeight.w500,
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //         backgroundColor: Colors.red,
// // // //         behavior: SnackBarBehavior.floating,
// // // //         shape: RoundedRectangleBorder(
// // // //           borderRadius: BorderRadius.circular(12),
// // // //         ),
// // // //         margin: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // Helper method to convert base64 string to Uint8List
// // // //   Uint8List _base64ToImage(String base64String) {
// // // //     return base64Decode(base64String);
// // // //   }
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: const Color(0xFF0D1B2A),
// // // //       body: isLoading ? _buildLoadingState() : _buildMainContent(),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ Beautiful loading state
// // // //   Widget _buildLoadingState() {
// // // //     return Container(
// // // //       decoration: const BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Color(0xFF0D1B2A),
// // // //             Color(0xFF1B263B),
// // // //             Color(0xFF415A77),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //       child: Center(
// // // //         child: Column(
// // // //           mainAxisAlignment: MainAxisAlignment.center,
// // // //           children: [
// // // //             Container(
// // // //               padding: EdgeInsets.all(_getResponsiveSpacing(context, 24)),
// // // //               decoration: BoxDecoration(
// // // //                 gradient: LinearGradient(
// // // //                   colors: [
// // // //                     const Color(0xFF00D4AA).withOpacity(0.2),
// // // //                     const Color(0xFF00A8CC).withOpacity(0.1),
// // // //                   ],
// // // //                 ),
// // // //                 shape: BoxShape.circle,
// // // //                 boxShadow: [
// // // //                   BoxShadow(
// // // //                     color: const Color(0xFF00D4AA).withOpacity(0.3),
// // // //                     blurRadius: 20,
// // // //                     spreadRadius: 5,
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //               child: const CircularProgressIndicator(
// // // //                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
// // // //                 strokeWidth: 3,
// // // //               ),
// // // //             ),
// // // //             SizedBox(height: _getResponsiveSpacing(context, 24)),
// // // //             Text(
// // // //               'Loading your learning profile...',
// // // //               style: TextStyle(
// // // //                 color: Colors.white.withOpacity(0.8),
// // // //                 fontSize: _getResponsiveFontSize(context, 16),
// // // //                 fontWeight: FontWeight.w500,
// // // //               ),
// // // //             ),
// // // //             SizedBox(height: _getResponsiveSpacing(context, 8)),
// // // //             Text(
// // // //               'Please wait a moment',
// // // //               style: TextStyle(
// // // //                 color: Colors.white.withOpacity(0.6),
// // // //                 fontSize: _getResponsiveFontSize(context, 14),
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ Main content with proper overflow handling
// // // //   Widget _buildMainContent() {
// // // //     return Container(
// // // //       decoration: const BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Color(0xFF0D1B2A),
// // // //             Color(0xFF1B263B),
// // // //             Color(0xFF415A77),
// // // //           ],
// // // //           stops: [0.0, 0.5, 1.0],
// // // //         ),
// // // //       ),
// // // //       child: SafeArea(
// // // //         child: FadeTransition(
// // // //           opacity: _fadeAnimation,
// // // //           child: CustomScrollView(
// // // //             physics: const BouncingScrollPhysics(),
// // // //             slivers: [
// // // //               // ✅ Enhanced App Bar
// // // //               _buildEnhancedAppBar(),
// // // //
// // // //               // ✅ Main content with proper spacing
// // // //               SliverPadding(
// // // //                 padding: _getResponsivePadding(context),
// // // //                 sliver: SliverList(
// // // //                   delegate: SliverChildListDelegate([
// // // //                     // Profile Header
// // // //                     SlideTransition(
// // // //                       position: _slideAnimation,
// // // //                       child: _buildProfileHeader(),
// // // //                     ),
// // // //
// // // //                     SizedBox(height: _getResponsiveSpacing(context, 24)),
// // // //
// // // //                     // Level Progress
// // // //                     _buildLevelProgressCard(),
// // // //
// // // //                     SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //                     // Points Card
// // // //                     AnimatedBuilder(
// // // //                       animation: _counterAnimation,
// // // //                       builder: (context, child) => _buildPointsCard(),
// // // //                     ),
// // // //
// // // //                     SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //                     // Stats Grid - Fixed overflow issues
// // // //                     _buildStatsGrid(),
// // // //
// // // //                     SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //                     // Account Settings
// // // //                     _buildAccountSettings(),
// // // //
// // // //                     SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //                     // Learning Journey
// // // //                     _buildLearningJourney(),
// // // //
// // // //                     // ✅ Attractive Logout Section
// // // //                     SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //                     _buildLogoutSection(),
// // // //
// // // //                     // Bottom spacing for scroll
// // // //                     SizedBox(height: _getResponsiveSpacing(context, 40)),
// // // //                   ]),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ Enhanced app bar with better design
// // // //   Widget _buildEnhancedAppBar() {
// // // //     return SliverAppBar(
// // // //       expandedHeight: _isMobile(context) ? 70 : 140,
// // // //       floating: false,
// // // //       pinned: true,
// // // //       elevation: 0,
// // // //       backgroundColor: const Color(0xFF1B263B),
// // // //       automaticallyImplyLeading: false, // ✅ Custom leading
// // // //
// // // //       // ✅ Custom back button aligned properly
// // // //       leading: Container(
// // // //         margin: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //         child: IconButton(
// // // //           onPressed: () => Navigator.of(context).pop(),
// // // //           icon: Icon(
// // // //             Icons.arrow_back_ios_rounded,
// // // //             color: const Color(0xFF00D4AA),
// // // //             size: _getResponsiveFontSize(context, 18),
// // // //           ),
// // // //           style: IconButton.styleFrom(
// // // //             backgroundColor: const Color(0xFF00D4AA).withOpacity(0.1),
// // // //             shape: RoundedRectangleBorder(
// // // //               borderRadius: BorderRadius.circular(10),
// // // //               side: BorderSide(
// // // //                 color: const Color(0xFF00D4AA).withOpacity(0.3),
// // // //               ),
// // // //             ),
// // // //             padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //
// // // //       flexibleSpace: FlexibleSpaceBar(
// // // //         centerTitle: false,
// // // //         // ✅ Proper alignment with back button and refresh button
// // // //         titlePadding: EdgeInsets.only(
// // // //           left: _getResponsiveSpacing(context, 64), // ✅ Space after back button
// // // //           bottom: _getResponsiveSpacing(context, 16),
// // // //           right: _getResponsiveSpacing(context, 100), // ✅ Space before refresh button
// // // //         ),
// // // //         title: ShaderMask(
// // // //           shaderCallback: (bounds) => const LinearGradient(
// // // //             colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
// // // //           ).createShader(bounds),
// // // //           child: Text(
// // // //             'Profile', // ✅ Changed to shorter headline
// // // //             style: TextStyle(
// // // //               color: Colors.white,
// // // //               fontWeight: FontWeight.bold,
// // // //               fontSize: _getResponsiveFontSize(context, 16), // ✅ Appropriate size for shorter text
// // // //             ),
// // // //           ),
// // // //         ),
// // // //         background: Container(
// // // //           decoration: const BoxDecoration(
// // // //             gradient: LinearGradient(
// // // //               begin: Alignment.topLeft,
// // // //               end: Alignment.bottomRight,
// // // //               colors: [
// // // //                 Color(0xFF1B263B),
// // // //                 Color(0xFF0D1B2A),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //
// // // //       actions: [
// // // //         // ✅ Refresh button aligned with back button
// // // //         Container(
// // // //           margin: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //           child: TextButton.icon(
// // // //             onPressed: _refreshData,
// // // //             icon: Icon(
// // // //               Icons.refresh_rounded,
// // // //               color: const Color(0xFF00D4AA),
// // // //               size: _getResponsiveFontSize(context, 16),
// // // //             ),
// // // //             label: Text(
// // // //               'Refresh',
// // // //               style: TextStyle(
// // // //                 color: const Color(0xFF00D4AA),
// // // //                 fontSize: _getResponsiveFontSize(context, 12),
// // // //                 fontWeight: FontWeight.w600,
// // // //               ),
// // // //             ),
// // // //             style: TextButton.styleFrom(
// // // //               backgroundColor: const Color(0xFF00D4AA).withOpacity(0.1),
// // // //               shape: RoundedRectangleBorder(
// // // //                 borderRadius: BorderRadius.circular(10),
// // // //                 side: BorderSide(
// // // //                   color: const Color(0xFF00D4AA).withOpacity(0.3),
// // // //                 ),
// // // //               ),
// // // //               padding: EdgeInsets.symmetric(
// // // //                 horizontal: _getResponsiveSpacing(context, 10),
// // // //                 vertical: _getResponsiveSpacing(context, 6),
// // // //               ),
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }
// // // //
// // // // // ✅ Helper function for mobile detection
// // // //
// // // //
// // // //
// // // //   // ✅ Redesigned profile header with better layout
// // // //   Widget _buildProfileHeader() {
// // // //     return Container(
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 24)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Colors.white.withOpacity(0.15),
// // // //             Colors.white.withOpacity(0.05),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(24),
// // // //         border: Border.all(
// // // //           color: Colors.white.withOpacity(0.2),
// // // //           width: 1.5,
// // // //         ),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: Colors.black.withOpacity(0.2),
// // // //             blurRadius: 20,
// // // //             offset: const Offset(0, 8),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Column(
// // // //         children: [
// // // //           // Profile image with level badge
// // // //           Stack(
// // // //             children: [
// // // //               // Glowing container for profile image
// // // //               Container(
// // // //                 padding: const EdgeInsets.all(4),
// // // //                 decoration: BoxDecoration(
// // // //                   shape: BoxShape.circle,
// // // //                   gradient: LinearGradient(
// // // //                     colors: [
// // // //                       _getLevelColor(),
// // // //                       _getLevelColor().withOpacity(0.7),
// // // //                     ],
// // // //                   ),
// // // //                   boxShadow: [
// // // //                     BoxShadow(
// // // //                       color: _getLevelColor().withOpacity(0.4),
// // // //                       blurRadius: 20,
// // // //                       spreadRadius: 2,
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //                 child: CircleAvatar(
// // // //                   radius: _isMobile(context) ? 50 : 60,
// // // //                   backgroundColor: Colors.white,
// // // //                   backgroundImage: _profileImage != null
// // // //                       ? FileImage(_profileImage!)
// // // //                       : (profileImageBase64.isNotEmpty
// // // //                       ? MemoryImage(_base64ToImage(profileImageBase64))
// // // //                       : null) as ImageProvider?,
// // // //                   child: _profileImage == null && profileImageBase64.isEmpty
// // // //                       ? Text(
// // // //                     userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
// // // //                     style: TextStyle(
// // // //                       fontSize: _getResponsiveFontSize(context, 36),
// // // //                       fontWeight: FontWeight.bold,
// // // //                       color: _getLevelColor(),
// // // //                     ),
// // // //                   )
// // // //                       : null,
// // // //                 ),
// // // //               ),
// // // //
// // // //               // Level badge
// // // //               Positioned(
// // // //                 top: 0,
// // // //                 right: 0,
// // // //                 child: Container(
// // // //                   padding: EdgeInsets.symmetric(
// // // //                     horizontal: _getResponsiveSpacing(context, 10),
// // // //                     vertical: _getResponsiveSpacing(context, 4),
// // // //                   ),
// // // //                   decoration: BoxDecoration(
// // // //                     gradient: LinearGradient(
// // // //                       colors: [_getLevelColor(), _getLevelColor().withOpacity(0.8)],
// // // //                     ),
// // // //                     borderRadius: BorderRadius.circular(16),
// // // //                     border: Border.all(color: Colors.white, width: 2),
// // // //                     boxShadow: [
// // // //                       BoxShadow(
// // // //                         color: _getLevelColor().withOpacity(0.3),
// // // //                         blurRadius: 8,
// // // //                         offset: const Offset(0, 2),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                   child: Row(
// // // //                     mainAxisSize: MainAxisSize.min,
// // // //                     children: [
// // // //                       Icon(
// // // //                         _getLevelIcon(),
// // // //                         color: Colors.white,
// // // //                         size: _getResponsiveFontSize(context, 14),
// // // //                       ),
// // // //                       SizedBox(width: _getResponsiveSpacing(context, 4)),
// // // //                       Text(
// // // //                         userLevel,
// // // //                         style: TextStyle(
// // // //                           color: Colors.white,
// // // //                           fontSize: _getResponsiveFontSize(context, 12),
// // // //                           fontWeight: FontWeight.bold,
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //
// // // //               // Camera button
// // // //               Positioned(
// // // //                 bottom: 0,
// // // //                 right: 0,
// // // //                 child: GestureDetector(
// // // //                   onTap: isUploadingImage ? null : _pickImage,
// // // //                   child: Container(
// // // //                     padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //                     decoration: BoxDecoration(
// // // //                       gradient: const LinearGradient(
// // // //                         colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
// // // //                       ),
// // // //                       shape: BoxShape.circle,
// // // //                       border: Border.all(color: Colors.white, width: 3),
// // // //                       boxShadow: [
// // // //                         BoxShadow(
// // // //                           color: const Color(0xFF00D4AA).withOpacity(0.3),
// // // //                           blurRadius: 8,
// // // //                           offset: const Offset(0, 2),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                     child: Icon(
// // // //                       isUploadingImage ? Icons.hourglass_empty : Icons.camera_alt,
// // // //                       size: _getResponsiveFontSize(context, 20),
// // // //                       color: Colors.white,
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //           // User name with attractive styling
// // // //           ShaderMask(
// // // //             shaderCallback: (bounds) => const LinearGradient(
// // // //               colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
// // // //             ).createShader(bounds),
// // // //             child: Text(
// // // //               userName,
// // // //               style: TextStyle(
// // // //                 color: Colors.white,
// // // //                 fontSize: _getResponsiveFontSize(context, 24),
// // // //                 fontWeight: FontWeight.bold,
// // // //                 letterSpacing: 0.5,
// // // //               ),
// // // //               textAlign: TextAlign.center,
// // // //               maxLines: 2,
// // // //               overflow: TextOverflow.ellipsis,
// // // //             ),
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 8)),
// // // //
// // // //           // Email with better styling
// // // //           Container(
// // // //             padding: EdgeInsets.symmetric(
// // // //               horizontal: _getResponsiveSpacing(context, 12),
// // // //               vertical: _getResponsiveSpacing(context, 6),
// // // //             ),
// // // //             decoration: BoxDecoration(
// // // //               color: Colors.white.withOpacity(0.1),
// // // //               borderRadius: BorderRadius.circular(20),
// // // //             ),
// // // //             child: Text(
// // // //               userEmail,
// // // //               style: TextStyle(
// // // //                 color: Colors.white.withOpacity(0.8),
// // // //                 fontSize: _getResponsiveFontSize(context, 14),
// // // //               ),
// // // //               textAlign: TextAlign.center,
// // // //               maxLines: 1,
// // // //               overflow: TextOverflow.ellipsis,
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //   // ✅ Level progress card with better design
// // // //   Widget _buildLevelProgressCard() {
// // // //     final progress = _getLevelProgress();
// // // //
// // // //     return Container(
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             _getLevelColor().withOpacity(0.2),
// // // //             _getLevelColor().withOpacity(0.05),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(20),
// // // //         border: Border.all(
// // // //           color: _getLevelColor().withOpacity(0.3),
// // // //           width: 1.5,
// // // //         ),
// // // //       ),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           Row(
// // // //             children: [
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getResponsiveSpacing(context, 10)),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: LinearGradient(
// // // //                     colors: [_getLevelColor(), _getLevelColor().withOpacity(0.8)],
// // // //                   ),
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                 ),
// // // //                 child: Icon(
// // // //                   _getLevelIcon(),
// // // //                   color: Colors.white,
// // // //                   size: _getResponsiveFontSize(context, 20),
// // // //                 ),
// // // //               ),
// // // //               SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //               Expanded(
// // // //                 child: Column(
// // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // //                   children: [
// // // //                     Text(
// // // //                       'Level Progress',
// // // //                       style: TextStyle(
// // // //                         color: Colors.white.withOpacity(0.8),
// // // //                         fontSize: _getResponsiveFontSize(context, 14),
// // // //                         fontWeight: FontWeight.w500,
// // // //                       ),
// // // //                     ),
// // // //                     Text(
// // // //                       userLevel,
// // // //                       style: TextStyle(
// // // //                         color: Colors.white,
// // // //                         fontSize: _getResponsiveFontSize(context, 20),
// // // //                         fontWeight: FontWeight.bold,
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //               Text(
// // // //                 '${(progress * 100).toInt()}%',
// // // //                 style: TextStyle(
// // // //                   color: _getLevelColor(),
// // // //                   fontSize: _getResponsiveFontSize(context, 16),
// // // //                   fontWeight: FontWeight.bold,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 16)),
// // // //
// // // //           // Progress bar with animation
// // // //           Container(
// // // //             height: 8,
// // // //             decoration: BoxDecoration(
// // // //               color: Colors.white.withOpacity(0.2),
// // // //               borderRadius: BorderRadius.circular(4),
// // // //             ),
// // // //             child: LayoutBuilder(
// // // //               builder: (context, constraints) {
// // // //                 return Container(
// // // //                   width: constraints.maxWidth * progress,
// // // //                   decoration: BoxDecoration(
// // // //                     gradient: LinearGradient(
// // // //                       colors: [_getLevelColor(), _getLevelColor().withOpacity(0.7)],
// // // //                     ),
// // // //                     borderRadius: BorderRadius.circular(4),
// // // //                     boxShadow: [
// // // //                       BoxShadow(
// // // //                         color: _getLevelColor().withOpacity(0.3),
// // // //                         blurRadius: 4,
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                 );
// // // //               },
// // // //             ),
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 12)),
// // // //
// // // //           Text(
// // // //             _getNextLevelInfo(),
// // // //             style: TextStyle(
// // // //               color: Colors.white.withOpacity(0.7),
// // // //               fontSize: _getResponsiveFontSize(context, 12),
// // // //             ),
// // // //             maxLines: 2,
// // // //             overflow: TextOverflow.ellipsis,
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ Animated points card with better design
// // // //   Widget _buildPointsCard() {
// // // //     final animatedPoints = (userPoints * _counterAnimation.value).round();
// // // //
// // // //     return Container(
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: const LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Color(0xFF00D4AA),
// // // //             Color(0xFF00A8CC),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(20),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: const Color(0xFF00D4AA).withOpacity(0.3),
// // // //             blurRadius: 20,
// // // //             offset: const Offset(0, 8),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Row(
// // // //         children: [
// // // //           Container(
// // // //             padding: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
// // // //             decoration: BoxDecoration(
// // // //               color: Colors.white.withOpacity(0.2),
// // // //               borderRadius: BorderRadius.circular(16),
// // // //             ),
// // // //             child: Icon(
// // // //               Icons.stars_rounded,
// // // //               color: Colors.white,
// // // //               size: _getResponsiveFontSize(context, 28),
// // // //             ),
// // // //           ),
// // // //           SizedBox(width: _getResponsiveSpacing(context, 16)),
// // // //           Expanded(
// // // //             child: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               children: [
// // // //                 Text(
// // // //                   "Total Learning Points",
// // // //                   style: TextStyle(
// // // //                     color: Colors.white.withOpacity(0.9),
// // // //                     fontSize: _getResponsiveFontSize(context, 14),
// // // //                     fontWeight: FontWeight.w500,
// // // //                   ),
// // // //                 ),
// // // //                 SizedBox(height: _getResponsiveSpacing(context, 4)),
// // // //                 Text(
// // // //                   animatedPoints.toString(),
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: _getResponsiveFontSize(context, 28),
// // // //                     fontWeight: FontWeight.bold,
// // // //                   ),
// // // //                 ),
// // // //                 if (bestQuizScore > 0) ...[
// // // //                   SizedBox(height: _getResponsiveSpacing(context, 4)),
// // // //                   Text(
// // // //                     "Best Quiz: $bestQuizScore pts",
// // // //                     style: TextStyle(
// // // //                       color: Colors.white.withOpacity(0.8),
// // // //                       fontSize: _getResponsiveFontSize(context, 12),
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ Fixed stats grid with proper sizing
// // // //   Widget _buildStatsGrid() {
// // // //     return LayoutBuilder(
// // // //       builder: (context, constraints) {
// // // //         // Calculate proper dimensions to prevent overflow
// // // //         final crossAxisCount = _getCrossAxisCount(context);
// // // //         final spacing = _getResponsiveSpacing(context, 12);
// // // //         final availableWidth = constraints.maxWidth - ((crossAxisCount - 1) * spacing);
// // // //         final itemWidth = availableWidth / crossAxisCount;
// // // //         final aspectRatio = itemWidth / _getCardHeight(context);
// // // //
// // // //         return GridView.count(
// // // //           shrinkWrap: true,
// // // //           physics: const NeverScrollableScrollPhysics(),
// // // //           crossAxisCount: crossAxisCount,
// // // //           childAspectRatio: aspectRatio,
// // // //           crossAxisSpacing: spacing,
// // // //           mainAxisSpacing: spacing,
// // // //           children: [
// // // //             _buildStatCard(
// // // //               icon: Icons.note_alt_rounded,
// // // //               title: "Notes",
// // // //               value: notesCount.toString(),
// // // //               subtitle: "Saved",
// // // //               color: const Color(0xFF8B5CF6),
// // // //             ),
// // // //             _buildStatCard(
// // // //               icon: Icons.video_library_rounded,
// // // //               title: "Videos",
// // // //               value: savedVideosCount.toString(),
// // // //               subtitle: "Bookmarked",
// // // //               color: const Color(0xFFEF4444),
// // // //             ),
// // // //             _buildStatCard(
// // // //               icon: Icons.link_rounded,
// // // //               title: "Links",
// // // //               value: savedLinksCount.toString(),
// // // //               subtitle: "Resources",
// // // //               color: const Color(0xFF3B82F6),
// // // //             ),
// // // //             _buildStatCard(
// // // //               icon: Icons.quiz_rounded,
// // // //               title: "Quizzes",
// // // //               value: quizzesTaken.toString(),
// // // //               subtitle: "Completed",
// // // //               color: const Color(0xFF10B981),
// // // //             ),
// // // //           ],
// // // //         );
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ Improved stat card with better text handling
// // // //   Widget _buildStatCard({
// // // //     required IconData icon,
// // // //     required String title,
// // // //     required String value,
// // // //     required String subtitle,
// // // //     required Color color,
// // // //   }) {
// // // //     return AnimatedBuilder(
// // // //       animation: _counterAnimation,
// // // //       builder: (context, child) {
// // // //         final animatedValue = (int.tryParse(value) ?? 0) * _counterAnimation.value;
// // // //
// // // //         return Container(
// // // //           padding: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
// // // //           decoration: BoxDecoration(
// // // //             gradient: LinearGradient(
// // // //               begin: Alignment.topLeft,
// // // //               end: Alignment.bottomRight,
// // // //               colors: [
// // // //                 Colors.white.withOpacity(0.12),
// // // //                 Colors.white.withOpacity(0.06),
// // // //               ],
// // // //             ),
// // // //             borderRadius: BorderRadius.circular(16),
// // // //             border: Border.all(
// // // //               color: color.withOpacity(0.3),
// // // //               width: 1,
// // // //             ),
// // // //           ),
// // // //           child: Column(
// // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // //             children: [
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: LinearGradient(
// // // //                     colors: [color, color.withOpacity(0.8)],
// // // //                   ),
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                 ),
// // // //                 child: Icon(
// // // //                   icon,
// // // //                   color: Colors.white,
// // // //                   size: _getResponsiveFontSize(context, 20),
// // // //                 ),
// // // //               ),
// // // //               SizedBox(height: _getResponsiveSpacing(context, 8)),
// // // //               Text(
// // // //                 animatedValue.round().toString(),
// // // //                 style: TextStyle(
// // // //                   color: Colors.white,
// // // //                   fontSize: _getResponsiveFontSize(context, 24),
// // // //                   fontWeight: FontWeight.bold,
// // // //                 ),
// // // //                 maxLines: 1,
// // // //                 overflow: TextOverflow.ellipsis,
// // // //               ),
// // // //               SizedBox(height: _getResponsiveSpacing(context, 2)),
// // // //               Text(
// // // //                 title,
// // // //                 style: TextStyle(
// // // //                   color: Colors.white.withOpacity(0.8),
// // // //                   fontSize: _getResponsiveFontSize(context, 12),
// // // //                   fontWeight: FontWeight.w600,
// // // //                 ),
// // // //                 maxLines: 1,
// // // //                 overflow: TextOverflow.ellipsis,
// // // //                 textAlign: TextAlign.center,
// // // //               ),
// // // //               Text(
// // // //                 subtitle,
// // // //                 style: TextStyle(
// // // //                   color: Colors.white.withOpacity(0.6),
// // // //                   fontSize: _getResponsiveFontSize(context, 10),
// // // //                 ),
// // // //                 maxLines: 1,
// // // //                 overflow: TextOverflow.ellipsis,
// // // //                 textAlign: TextAlign.center,
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         );
// // // //       },
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ Account settings with better layout
// // // //   Widget _buildAccountSettings() {
// // // //     return Container(
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Colors.white.withOpacity(0.12),
// // // //             Colors.white.withOpacity(0.06),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(20),
// // // //         border: Border.all(
// // // //           color: Colors.white.withOpacity(0.2),
// // // //           width: 1,
// // // //         ),
// // // //       ),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           Row(
// // // //             children: [
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getResponsiveSpacing(context, 10)),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: const LinearGradient(
// // // //                     colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
// // // //                   ),
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                 ),
// // // //                 child: Icon(
// // // //                   Icons.settings_rounded,
// // // //                   color: Colors.white,
// // // //                   size: _getResponsiveFontSize(context, 20),
// // // //                 ),
// // // //               ),
// // // //               SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //               Expanded(
// // // //                 child: Text(
// // // //                   "Account Settings",
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: _getResponsiveFontSize(context, 18),
// // // //                     fontWeight: FontWeight.bold,
// // // //                   ),
// // // //                   maxLines: 1,
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //               ),
// // // //               if (!isEditing)
// // // //                 IconButton(
// // // //                   icon: Icon(
// // // //                     Icons.edit_rounded,
// // // //                     color: const Color(0xFF00D4AA),
// // // //                     size: _getResponsiveFontSize(context, 20),
// // // //                   ),
// // // //                   onPressed: () => setState(() => isEditing = true),
// // // //                 ),
// // // //             ],
// // // //           ),
// // // //           SizedBox(height: _getResponsiveSpacing(context, 16)),
// // // //           _buildEditableField(
// // // //             label: "Full Name",
// // // //             value: userName,
// // // //             controller: _nameController,
// // // //             icon: Icons.person_rounded,
// // // //           ),
// // // //           SizedBox(height: _getResponsiveSpacing(context, 12)),
// // // //           _buildEditableField(
// // // //             label: "Email",
// // // //             value: userEmail,
// // // //             controller: _emailController,
// // // //             icon: Icons.email_rounded,
// // // //           ),
// // // //           if (isEditing) ...[
// // // //             SizedBox(height: _getResponsiveSpacing(context, 16)),
// // // //             Row(
// // // //               children: [
// // // //                 Expanded(
// // // //                   child: OutlinedButton(
// // // //                     onPressed: _cancelEditing,
// // // //                     style: OutlinedButton.styleFrom(
// // // //                       side: const BorderSide(color: Colors.white54),
// // // //                       padding: EdgeInsets.symmetric(
// // // //                         vertical: _getResponsiveSpacing(context, 12),
// // // //                       ),
// // // //                       shape: RoundedRectangleBorder(
// // // //                         borderRadius: BorderRadius.circular(12),
// // // //                       ),
// // // //                     ),
// // // //                     child: Text(
// // // //                       "Cancel",
// // // //                       style: TextStyle(
// // // //                         color: Colors.white54,
// // // //                         fontSize: _getResponsiveFontSize(context, 14),
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //                 SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //                 Expanded(
// // // //                   child: ElevatedButton(
// // // //                     onPressed: _updateProfile,
// // // //                     style: ElevatedButton.styleFrom(
// // // //                       backgroundColor: const Color(0xFF00D4AA),
// // // //                       padding: EdgeInsets.symmetric(
// // // //                         vertical: _getResponsiveSpacing(context, 12),
// // // //                       ),
// // // //                       shape: RoundedRectangleBorder(
// // // //                         borderRadius: BorderRadius.circular(12),
// // // //                       ),
// // // //                     ),
// // // //                     child: Text(
// // // //                       "Save",
// // // //                       style: TextStyle(
// // // //                         color: Colors.white,
// // // //                         fontWeight: FontWeight.w600,
// // // //                         fontSize: _getResponsiveFontSize(context, 14),
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ],
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   Widget _buildEditableField({
// // // //     required String label,
// // // //     required String value,
// // // //     required TextEditingController controller,
// // // //     required IconData icon,
// // // //   }) {
// // // //     return Container(
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //       decoration: BoxDecoration(
// // // //         color: Colors.white.withOpacity(0.05),
// // // //         borderRadius: BorderRadius.circular(12),
// // // //         border: Border.all(
// // // //           color: isEditing
// // // //               ? const Color(0xFF00D4AA).withOpacity(0.3)
// // // //               : Colors.white.withOpacity(0.1),
// // // //         ),
// // // //       ),
// // // //       child: Row(
// // // //         children: [
// // // //           Icon(
// // // //             icon,
// // // //             color: const Color(0xFF00D4AA),
// // // //             size: _getResponsiveFontSize(context, 20),
// // // //           ),
// // // //           SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //           Expanded(
// // // //             child: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               children: [
// // // //                 Text(
// // // //                   label,
// // // //                   style: TextStyle(
// // // //                     color: Colors.white.withOpacity(0.7),
// // // //                     fontSize: _getResponsiveFontSize(context, 12),
// // // //                   ),
// // // //                 ),
// // // //                 SizedBox(height: _getResponsiveSpacing(context, 4)),
// // // //                 isEditing
// // // //                     ? TextField(
// // // //                   controller: controller,
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: _getResponsiveFontSize(context, 16),
// // // //                   ),
// // // //                   decoration: const InputDecoration(
// // // //                     isDense: true,
// // // //                     contentPadding: EdgeInsets.zero,
// // // //                     border: InputBorder.none,
// // // //                   ),
// // // //                   maxLines: 1,
// // // //
// // // //                 )
// // // //                     : Text(
// // // //                   value,
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: _getResponsiveFontSize(context, 16),
// // // //                   ),
// // // //                   maxLines: 1,
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //   // ✅ Learning journey with achievements
// // // //   Widget _buildLearningJourney() {
// // // //     return Container(
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Colors.white.withOpacity(0.12),
// // // //             Colors.white.withOpacity(0.06),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(20),
// // // //         border: Border.all(
// // // //           color: Colors.white.withOpacity(0.2),
// // // //           width: 1,
// // // //         ),
// // // //       ),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         children: [
// // // //           Row(
// // // //             children: [
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getResponsiveSpacing(context, 10)),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: const LinearGradient(
// // // //                     colors: [Colors.purple, Colors.deepPurple],
// // // //                   ),
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                 ),
// // // //                 child: Icon(
// // // //                   Icons.timeline_rounded,
// // // //                   color: Colors.white,
// // // //                   size: _getResponsiveFontSize(context, 20),
// // // //                 ),
// // // //               ),
// // // //               SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //               Expanded(
// // // //                 child: Text(
// // // //                   "Learning Journey",
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontSize: _getResponsiveFontSize(context, 18),
// // // //                     fontWeight: FontWeight.bold,
// // // //                   ),
// // // //                   maxLines: 1,
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           SizedBox(height: _getResponsiveSpacing(context, 16)),
// // // //
// // // //           // Dynamic achievements based on real data
// // // //           ...(_buildAchievements()),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   List<Widget> _buildAchievements() {
// // // //     List<Widget> achievements = [];
// // // //
// // // //     if (userPoints > 0) {
// // // //       achievements.add(_buildAchievementItem(
// // // //         icon: Icons.emoji_events_rounded,
// // // //         title: "Points Earned",
// // // //         subtitle: "$userPoints learning points collected!",
// // // //         time: _getPointsMessage(),
// // // //         color: Colors.amber,
// // // //       ));
// // // //     }
// // // //
// // // //     if (quizzesTaken > 0) {
// // // //       achievements.add(_buildAchievementItem(
// // // //         icon: Icons.quiz_rounded,
// // // //         title: "Quiz Master",
// // // //         subtitle: "Completed $quizzesTaken ${quizzesTaken == 1 ? 'quiz' : 'quizzes'}",
// // // //         time: bestQuizScore > 0 ? "Best: $bestQuizScore pts" : "Keep going!",
// // // //         color: Colors.green,
// // // //       ));
// // // //     }
// // // //
// // // //     if (notesCount > 0) {
// // // //       achievements.add(_buildAchievementItem(
// // // //         icon: Icons.note_add_rounded,
// // // //         title: "Note Keeper",
// // // //         subtitle: "Saved $notesCount ${notesCount == 1 ? 'note' : 'notes'}",
// // // //         time: "Great organization!",
// // // //         color: Colors.blue,
// // // //       ));
// // // //     }
// // // //
// // // //     if (savedVideosCount > 0) {
// // // //       achievements.add(_buildAchievementItem(
// // // //         icon: Icons.video_library_rounded,
// // // //         title: "Video Learner",
// // // //         subtitle: "Bookmarked $savedVideosCount ${savedVideosCount == 1 ? 'video' : 'videos'}",
// // // //         time: "Visual learning!",
// // // //         color: Colors.red,
// // // //       ));
// // // //     }
// // // //
// // // //     // If no achievements yet
// // // //     if (achievements.isEmpty) {
// // // //       achievements.add(_buildAchievementItem(
// // // //         icon: Icons.rocket_launch_rounded,
// // // //         title: "Start Your Journey",
// // // //         subtitle: "Take your first quiz or save your first note!",
// // // //         time: "You've got this! 🚀",
// // // //         color: const Color(0xFF00D4AA),
// // // //       ));
// // // //     }
// // // //
// // // //     return achievements;
// // // //   }
// // // //
// // // //   String _getPointsMessage() {
// // // //     if (userPoints >= 5000) return "Amazing! 🏆";
// // // //     if (userPoints >= 3000) return "Excellent! 🌟";
// // // //     if (userPoints >= 1500) return "Great job! 🎉";
// // // //     if (userPoints >= 500) return "Keep going! 💪";
// // // //     return "Good start! 👍";
// // // //   }
// // // //
// // // //   Widget _buildAchievementItem({
// // // //     required IconData icon,
// // // //     required String title,
// // // //     required String subtitle,
// // // //     required String time,
// // // //     required Color color,
// // // //   }) {
// // // //     return Container(
// // // //       margin: EdgeInsets.only(bottom: _getResponsiveSpacing(context, 12)),
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           colors: [
// // // //             color.withOpacity(0.1),
// // // //             color.withOpacity(0.05),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(12),
// // // //         border: Border.all(
// // // //           color: color.withOpacity(0.3),
// // // //           width: 1,
// // // //         ),
// // // //       ),
// // // //       child: Row(
// // // //         children: [
// // // //           Container(
// // // //             padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
// // // //             decoration: BoxDecoration(
// // // //               gradient: LinearGradient(
// // // //                 colors: [color, color.withOpacity(0.8)],
// // // //               ),
// // // //               shape: BoxShape.circle,
// // // //             ),
// // // //             child: Icon(
// // // //               icon,
// // // //               color: Colors.white,
// // // //               size: _getResponsiveFontSize(context, 16),
// // // //             ),
// // // //           ),
// // // //           SizedBox(width: _getResponsiveSpacing(context, 12)),
// // // //           Expanded(
// // // //             child: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               children: [
// // // //                 Text(
// // // //                   title,
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontWeight: FontWeight.w600,
// // // //                     fontSize: _getResponsiveFontSize(context, 14),
// // // //                   ),
// // // //                   maxLines: 1,
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //                 SizedBox(height: _getResponsiveSpacing(context, 2)),
// // // //                 Text(
// // // //                   subtitle,
// // // //                   style: TextStyle(
// // // //                     color: Colors.white.withOpacity(0.8),
// // // //                     fontSize: _getResponsiveFontSize(context, 12),
// // // //                   ),
// // // //                   maxLines: 2,
// // // //                   overflow: TextOverflow.ellipsis,
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //           if (time.isNotEmpty)
// // // //             Text(
// // // //               time,
// // // //               style: TextStyle(
// // // //                 color: color,
// // // //                 fontSize: _getResponsiveFontSize(context, 10),
// // // //                 fontWeight: FontWeight.w500,
// // // //               ),
// // // //               maxLines: 1,
// // // //               overflow: TextOverflow.ellipsis,
// // // //             ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ SUPER ATTRACTIVE LOGOUT SECTION - The main attraction!
// // // //   Widget _buildLogoutSection() {
// // // //     return Container(
// // // //       margin: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //       padding: EdgeInsets.all(_getResponsiveSpacing(context, 24)),
// // // //       decoration: BoxDecoration(
// // // //         gradient: LinearGradient(
// // // //           begin: Alignment.topLeft,
// // // //           end: Alignment.bottomRight,
// // // //           colors: [
// // // //             Colors.red.withOpacity(0.1),
// // // //             Colors.red.withOpacity(0.05),
// // // //           ],
// // // //         ),
// // // //         borderRadius: BorderRadius.circular(20),
// // // //         border: Border.all(
// // // //           color: Colors.red.withOpacity(0.2),
// // // //           width: 1,
// // // //         ),
// // // //         boxShadow: [
// // // //           BoxShadow(
// // // //             color: Colors.black.withOpacity(0.1),
// // // //             blurRadius: 10,
// // // //             offset: const Offset(0, 4),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       child: Column(
// // // //         children: [
// // // //           // Logout icon
// // // //           Container(
// // // //             padding: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
// // // //             decoration: BoxDecoration(
// // // //               gradient: const LinearGradient(
// // // //                 colors: [Colors.red, Color(0xFFE53E3E)],
// // // //               ),
// // // //               shape: BoxShape.circle,
// // // //               boxShadow: [
// // // //                 BoxShadow(
// // // //                   color: Colors.red.withOpacity(0.3),
// // // //                   blurRadius: 15,
// // // //                   spreadRadius: 2,
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //             child: Icon(
// // // //               Icons.logout_rounded,
// // // //               color: Colors.white,
// // // //               size: _getResponsiveFontSize(context, 24),
// // // //             ),
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 16)),
// // // //
// // // //           // Title
// // // //           Text(
// // // //             'Ready to Sign Out?',
// // // //             style: TextStyle(
// // // //               color: Colors.white,
// // // //               fontSize: _getResponsiveFontSize(context, 18),
// // // //               fontWeight: FontWeight.bold,
// // // //             ),
// // // //             textAlign: TextAlign.center,
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 8)),
// // // //
// // // //           // Description
// // // //           Text(
// // // //             'Your progress is automatically saved.\nYou can continue anytime!',
// // // //             style: TextStyle(
// // // //               color: Colors.white.withOpacity(0.7),
// // // //               fontSize: _getResponsiveFontSize(context, 14),
// // // //               height: 1.5,
// // // //             ),
// // // //             textAlign: TextAlign.center,
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //           // Logout button
// // // //           SizedBox(
// // // //             width: double.infinity,
// // // //             child: ElevatedButton(
// // // //               onPressed: _showLogoutDialog,
// // // //               style: ElevatedButton.styleFrom(
// // // //                 backgroundColor: Colors.red,
// // // //                 foregroundColor: Colors.white,
// // // //                 padding: EdgeInsets.symmetric(
// // // //                   vertical: _getResponsiveSpacing(context, 14),
// // // //                 ),
// // // //                 shape: RoundedRectangleBorder(
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                 ),
// // // //                 elevation: 3,
// // // //               ),
// // // //               child: Row(
// // // //                 mainAxisAlignment: MainAxisAlignment.center,
// // // //                 children: [
// // // //                   const Icon(Icons.logout_rounded, size: 20),
// // // //                   SizedBox(width: _getResponsiveSpacing(context, 8)),
// // // //                   Text(
// // // //                     'Sign Out',
// // // //                     style: TextStyle(
// // // //                       fontSize: _getResponsiveFontSize(context, 16),
// // // //                       fontWeight: FontWeight.w600,
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ),
// // // //
// // // //           SizedBox(height: _getResponsiveSpacing(context, 12)),
// // // //
// // // //           // Security note
// // // //           Row(
// // // //             mainAxisAlignment: MainAxisAlignment.center,
// // // //             children: [
// // // //               Icon(
// // // //                 Icons.shield_outlined,
// // // //                 color: const Color(0xFF00D4AA),
// // // //                 size: _getResponsiveFontSize(context, 16),
// // // //               ),
// // // //               SizedBox(width: _getResponsiveSpacing(context, 6)),
// // // //               Text(
// // // //                 'Your data is safely stored',
// // // //                 style: TextStyle(
// // // //                   color: const Color(0xFF00D4AA),
// // // //                   fontSize: _getResponsiveFontSize(context, 12),
// // // //                   fontWeight: FontWeight.w500,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //
// // // //
// // // // // Improved logout dialog
// // // //
// // // //
// // // // }
// // // // // ✅ FIXED LOGOUT DIALOG - Replace the entire _LogoutDialogContent class
// // // // class _LogoutDialogContent extends StatefulWidget {
// // // //   @override
// // // //   _LogoutDialogContentState createState() => _LogoutDialogContentState();
// // // // }
// // // //
// // // // class _LogoutDialogContentState extends State<_LogoutDialogContent> {
// // // //   bool _isLoggingOut = false;
// // // //
// // // //   double _getResponsiveSpacing(BuildContext context, double baseSize) {
// // // //     final screenWidth = MediaQuery.of(context).size.width;
// // // //     return (baseSize * screenWidth) / 375;
// // // //   }
// // // //
// // // //   double _getResponsiveFontSize(BuildContext context, double baseSize) {
// // // //     final screenWidth = MediaQuery.of(context).size.width;
// // // //     return (baseSize * screenWidth) / 375;
// // // //   }
// // // //
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Dialog(
// // // //       backgroundColor: Colors.transparent,
// // // //       elevation: 0,
// // // //       child: Container(
// // // //         margin: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
// // // //         decoration: BoxDecoration(
// // // //           gradient: const LinearGradient(
// // // //             begin: Alignment.topLeft,
// // // //             end: Alignment.bottomRight,
// // // //             colors: [
// // // //               Color(0xFF1B263B),
// // // //               Color(0xFF0D1B2A),
// // // //             ],
// // // //           ),
// // // //           borderRadius: BorderRadius.circular(24),
// // // //           border: Border.all(
// // // //             color: Colors.red.withOpacity(0.3),
// // // //             width: 2,
// // // //           ),
// // // //           boxShadow: [
// // // //             BoxShadow(
// // // //               color: Colors.red.withOpacity(0.2),
// // // //               blurRadius: 20,
// // // //               spreadRadius: 5,
// // // //             ),
// // // //             BoxShadow(
// // // //               color: Colors.black.withOpacity(0.3),
// // // //               blurRadius: 15,
// // // //               offset: const Offset(0, 8),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //         child: Padding(
// // // //           padding: EdgeInsets.all(_getResponsiveSpacing(context, 24)),
// // // //           child: Column(
// // // //             mainAxisSize: MainAxisSize.min,
// // // //             children: [
// // // //               // Logout icon
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
// // // //                 decoration: BoxDecoration(
// // // //                   gradient: LinearGradient(
// // // //                     colors: _isLoggingOut
// // // //                         ? [Colors.grey, Colors.grey.shade600]
// // // //                         : [Colors.red, const Color(0xFFDC2626)],
// // // //                   ),
// // // //                   shape: BoxShape.circle,
// // // //                   boxShadow: [
// // // //                     BoxShadow(
// // // //                       color: (_isLoggingOut ? Colors.grey : Colors.red).withOpacity(0.4),
// // // //                       blurRadius: 15,
// // // //                       spreadRadius: 3,
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //                 child: _isLoggingOut
// // // //                     ? SizedBox(
// // // //                   width: _getResponsiveFontSize(context, 32),
// // // //                   height: _getResponsiveFontSize(context, 32),
// // // //                   child: const CircularProgressIndicator(
// // // //                     strokeWidth: 3,
// // // //                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// // // //                   ),
// // // //                 )
// // // //                     : Icon(
// // // //                   Icons.logout_rounded,
// // // //                   color: Colors.white,
// // // //                   size: _getResponsiveFontSize(context, 32),
// // // //                 ),
// // // //               ),
// // // //
// // // //               SizedBox(height: _getResponsiveSpacing(context, 20)),
// // // //
// // // //               // Title
// // // //               Text(
// // // //                 _isLoggingOut ? 'Signing Out...' : 'Ready to Sign Out?',
// // // //                 style: TextStyle(
// // // //                   color: Colors.red,
// // // //                   fontSize: _getResponsiveFontSize(context, 24),
// // // //                   fontWeight: FontWeight.bold,
// // // //                   letterSpacing: 0.5,
// // // //                 ),
// // // //                 textAlign: TextAlign.center,
// // // //               ),
// // // //
// // // //               SizedBox(height: _getResponsiveSpacing(context, 16)),
// // // //
// // // //               // Security message
// // // //               Container(
// // // //                 padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
// // // //                 decoration: BoxDecoration(
// // // //                   color: const Color(0xFF2A3441),
// // // //                   borderRadius: BorderRadius.circular(12),
// // // //                   border: Border.all(
// // // //                     color: Colors.white.withOpacity(0.1),
// // // //                   ),
// // // //                 ),
// // // //                 child: Column(
// // // //                   children: [
// // // //                     Icon(
// // // //                       Icons.verified_user,
// // // //                       color: const Color(0xFF00D4AA),
// // // //                       size: _getResponsiveFontSize(context, 20),
// // // //                     ),
// // // //                     SizedBox(height: _getResponsiveSpacing(context, 8)),
// // // //                     Text(
// // // //                       _isLoggingOut
// // // //                           ? 'Saving your progress and signing out safely...'
// // // //                           : 'Your learning progress is safely saved!\nYou can continue where you left off when you return.',
// // // //                       style: TextStyle(
// // // //                         color: Colors.white.withOpacity(0.8),
// // // //                         fontSize: _getResponsiveFontSize(context, 14),
// // // //                         height: 1.4,
// // // //                       ),
// // // //                       textAlign: TextAlign.center,
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //
// // // //               SizedBox(height: _getResponsiveSpacing(context, 24)),
// // // //
// // // //               // Action buttons
// // // //               Row(
// // // //                 children: [
// // // //                   // Stay button
// // // //                   Expanded(
// // // //                     child: Container(
// // // //                       decoration: BoxDecoration(
// // // //                         color: Colors.transparent,
// // // //                         borderRadius: BorderRadius.circular(16),
// // // //                         border: Border.all(
// // // //                           color: Colors.white.withOpacity(0.3),
// // // //                           width: 1,
// // // //                         ),
// // // //                       ),
// // // //                       child: Material(
// // // //                         color: Colors.transparent,
// // // //                         child: InkWell(
// // // //                           borderRadius: BorderRadius.circular(16),
// // // //                           onTap: _isLoggingOut ? null : () => Navigator.of(context).pop(),
// // // //                           child: Padding(
// // // //                             padding: EdgeInsets.symmetric(
// // // //                               vertical: _getResponsiveSpacing(context, 16),
// // // //                             ),
// // // //                             child: Row(
// // // //                               mainAxisAlignment: MainAxisAlignment.center,
// // // //                               children: [
// // // //                                 Icon(
// // // //                                   Icons.arrow_back,
// // // //                                   color: Colors.white.withOpacity(_isLoggingOut ? 0.4 : 0.8),
// // // //                                   size: _getResponsiveFontSize(context, 18),
// // // //                                 ),
// // // //                                 SizedBox(width: _getResponsiveSpacing(context, 8)),
// // // //                                 Text(
// // // //                                   'Stay Here',
// // // //                                   style: TextStyle(
// // // //                                     color: Colors.white.withOpacity(_isLoggingOut ? 0.4 : 0.8),
// // // //                                     fontSize: _getResponsiveFontSize(context, 14),
// // // //                                     fontWeight: FontWeight.w600,
// // // //                                   ),
// // // //                                 ),
// // // //                               ],
// // // //                             ),
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //
// // // //                   SizedBox(width: _getResponsiveSpacing(context, 16)),
// // // //
// // // //                   // Sign Out button
// // // //                   Expanded(
// // // //                     child: Container(
// // // //                       decoration: BoxDecoration(
// // // //                         gradient: LinearGradient(
// // // //                           colors: _isLoggingOut
// // // //                               ? [Colors.grey, Colors.grey.shade600]
// // // //                               : [Colors.red, const Color(0xFFDC2626)],
// // // //                         ),
// // // //                         borderRadius: BorderRadius.circular(16),
// // // //                         boxShadow: [
// // // //                           BoxShadow(
// // // //                             color: (_isLoggingOut ? Colors.grey : Colors.red).withOpacity(0.3),
// // // //                             blurRadius: 8,
// // // //                             offset: const Offset(0, 4),
// // // //                           ),
// // // //                         ],
// // // //                       ),
// // // //                       child: Material(
// // // //                         color: Colors.transparent,
// // // //                         child: InkWell(
// // // //                           borderRadius: BorderRadius.circular(16),
// // // //                           onTap: _isLoggingOut ? null : _handleLogout,
// // // //                           child: Padding(
// // // //                             padding: EdgeInsets.symmetric(
// // // //                               vertical: _getResponsiveSpacing(context, 16),
// // // //                             ),
// // // //                             child: Row(
// // // //                               mainAxisAlignment: MainAxisAlignment.center,
// // // //                               children: [
// // // //                                 if (_isLoggingOut) ...[
// // // //                                   const SizedBox(
// // // //                                     width: 18,
// // // //                                     height: 18,
// // // //                                     child: CircularProgressIndicator(
// // // //                                       strokeWidth: 2,
// // // //                                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// // // //                                     ),
// // // //                                   ),
// // // //                                 ] else ...[
// // // //                                   Icon(
// // // //                                     Icons.logout_rounded,
// // // //                                     color: Colors.white,
// // // //                                     size: _getResponsiveFontSize(context, 18),
// // // //                                   ),
// // // //                                 ],
// // // //                                 SizedBox(width: _getResponsiveSpacing(context, 8)),
// // // //                                 Text(
// // // //                                   _isLoggingOut ? 'Signing Out...' : 'Sign Out',
// // // //                                   style: TextStyle(
// // // //                                     color: Colors.white,
// // // //                                     fontSize: _getResponsiveFontSize(context, 14),
// // // //                                     fontWeight: FontWeight.bold,
// // // //                                   ),
// // // //                                 ),
// // // //                               ],
// // // //                             ),
// // // //                           ),
// // // //                         ),
// // // //                       ),
// // // //                     ),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // //
// // // //   // ✅ SIMPLIFIED LOGOUT HANDLING - No nested dialogs
// // // //   Future<void> _handleLogout() async {
// // // //     if (!mounted) return;
// // // //
// // // //     setState(() {
// // // //       _isLoggingOut = true;
// // // //     });
// // // //
// // // //     try {
// // // //       // ✅ DIRECT LOGOUT WITHOUT ADDITIONAL DIALOGS
// // // //       await _performLogout();
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         setState(() {
// // // //           _isLoggingOut = false;
// // // //         });
// // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // //           SnackBar(
// // // //             content: Text('Logout failed: ${e.toString()}'),
// // // //             backgroundColor: Colors.red,
// // // //             behavior: SnackBarBehavior.floating,
// // // //             shape: RoundedRectangleBorder(
// // // //               borderRadius: BorderRadius.circular(10),
// // // //             ),
// // // //           ),
// // // //         );
// // // //       }
// // // //     }
// // // //   }
// // // //
// // // //   // ✅ CLEAN LOGOUT PROCESS
// // // //   Future<void> _performLogout() async {
// // // //     try {
// // // //       // Sign out from Firebase
// // // //       await FirebaseAuth.instance.signOut();
// // // //
// // // //       // Clear SharedPreferences
// // // //       final prefs = await SharedPreferences.getInstance();
// // // //       await prefs.setBool('is_logged_in', false);
// // // //       await prefs.remove('last_login');
// // // //
// // // //       // ✅ CLEAN NAVIGATION - Remove all overlapping dialogs and navigate
// // // //       if (mounted) {
// // // //         // Close this dialog first
// // // //         Navigator.of(context).pop();
// // // //
// // // //         // Then navigate to login, removing all previous routes
// // // //         Navigator.of(context).pushAndRemoveUntil(
// // // //           MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
// // // //               (route) => false,
// // // //         );
// // // //       }
// // // //     } catch (e) {
// // // //       if (mounted) {
// // // //         Navigator.of(context).pop(); // Close dialog on error
// // // //       }
// // // //       throw e; // Re-throw to be caught by _handleLogout
// // // //     }
// // // //   }
// // // // }