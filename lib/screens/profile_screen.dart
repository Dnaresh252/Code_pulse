import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import '../widgets/profile_dialogs.dart';
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
          return;
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
      return;
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

  // ✅ IMPROVED ACCOUNT DELETION WITH BETTER ERROR HANDLING
  Future<void> _deleteUserAccount(String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('No user found. Please login again.');
        return;
      }

      setState(() {
        isLoading = true;
      });



      // Step 1: Re-authenticate the user
      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);

      } catch (authError) {
        setState(() {
          isLoading = false;
        });

        _showErrorSnackBar('Invalid password. Please try again.');
        return;
      }

      final userId = user.uid;

      // Step 2: Clear SharedPreferences data
      try {
        final prefs = await SharedPreferences.getInstance();
        final keysToRemove = [
          '${userId}_user_points',
          '${userId}_quizzes_taken',
          '${userId}_best_score',
          '${userId}_saved_notes',
          '${userId}_coding_notes',
          '${userId}_personal_notes',
          '${userId}_study_notes',
          '${userId}_saved_videos',
          '${userId}_bookmarked_videos',
          '${userId}_saved_links',
          '${userId}_bookmarked_links',
          'profile_image_${userId}',
          'is_logged_in',
          'last_login',
        ];

        for (String key in keysToRemove) {
          await prefs.remove(key);
        }

      } catch (prefsError) {

        // Continue with deletion even if this fails
      }

      // Step 3: Delete Firestore user document
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();

      } catch (firestoreError) {

        // Continue with account deletion even if this fails
      }

      // Step 4: Delete Firebase Auth account
      try {
        await user.delete();

      } catch (deleteError) {
        setState(() {
          isLoading = false;
        });

        _showErrorSnackBar('Failed to delete account: ${deleteError.toString()}');
        return;
      }

      // Step 5: Success - Navigate to login
      if (mounted) {
        setState(() {
          isLoading = false;
        });


        // Show success message
        _showSuccessSnackBar('Account deleted successfully');

        // Small delay to show the success message
        await Future.delayed(const Duration(milliseconds: 1500));

        // Navigate to login screen
        _navigateToLoginScreen();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        _showErrorSnackBar('Failed to delete account: ${e.toString()}');
      }
    }
  }

  // ✅ IMPROVED NAVIGATION TO LOGIN
  void _navigateToLoginScreen() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
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

  // ✅ LEVEL PROGRESS CALCULATIONS
  String _getNextLevelInfo() {
    final nextPoints = _getNextLevelPoints();

    if (userLevel == 'Expert') {
      return 'Congratulations! You\'ve reached the highest level!';
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

  // ✅ IMPROVED REAUTHENTICATION DIALOG
  Future<void> _showReauthenticationDialog() async {
    final TextEditingController passwordController = TextEditingController();
    bool isLoading = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: EdgeInsets.all(_getSpaceL(context)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      surfaceColor,
                      surfaceDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(_getRadiusL()),
                  border: Border.all(
                    color: errorColor.withOpacity(0.3),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [errorColor, errorColor.withOpacity(0.7)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: errorColor.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    SizedBox(height: _getSpaceL(context)),

                    // Title
                    Text(
                      'Confirm Your Identity',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: _getSubheadingSize(context),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: _getSpaceM(context)),

                    // Description
                    Text(
                      'For security, please enter your password to confirm account deletion.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: _getBodySize(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: _getSpaceL(context)),

                    // Password Field
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _getSpaceM(context),
                        vertical: _getSpaceS(context),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(_getRadiusM()),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: _getBodySize(context),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(
                            color: textTertiary,
                            fontSize: _getBodySize(context),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: primaryColor,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    SizedBox(height: _getSpaceL(context)),

                    // Action Buttons
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(_getRadiusM()),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(_getRadiusM()),
                                onTap: isLoading
                                    ? null
                                    : () {
                                  passwordController.dispose();
                                  Navigator.of(dialogContext).pop();
                                },
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: _getBodySize(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: _getSpaceM(context)),

                        // Confirm Button
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [errorColor, errorColor.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(_getRadiusM()),
                              boxShadow: [
                                BoxShadow(
                                  color: errorColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(_getRadiusM()),
                                onTap: isLoading
                                    ? null
                                    : () async {
                                  if (passwordController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Please enter your password'),
                                        backgroundColor: errorColor,
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() {
                                    isLoading = true;
                                  });

                                  // Close the dialog first
                                  Navigator.of(dialogContext).pop();

                                  // Then call the deletion method
                                  await _deleteUserAccount(passwordController.text.trim());

                                  passwordController.dispose();
                                },
                                child: Center(
                                  child: isLoading
                                      ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                      : Text(
                                    'Confirm Delete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _getBodySize(context),
                                      fontWeight: FontWeight.bold,
                                    ),
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
            );
          },
        );
      },
    );
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

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return ModernLogoutDialog(); // Updated to use new dialog
      },
    );
  }

  // ✅ NAVIGATION TO DELETE ACCOUNT SCREEN
  void _navigateToDeleteAccount() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return ModernDeleteAccountDialog(
          onConfirmDelete: _showReauthenticationDialog,  // ✅ Pass function reference, not call it
        );
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

  // ✅ MODERN MAIN CONTENT - Updated with Delete Section
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
                    SizedBox(height: _getSpaceL(context)),
                    // ✅ NEW DELETE ACCOUNT SECTION AT BOTTOM
                    _buildDeleteAccountSection(),
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

  // ✅ QUICK ACTIONS CARD - Updated without Delete Button
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

          // Action Buttons Grid - Removed Delete Button
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
    if (userPoints >= 5000) return "Amazing! ";
    if (userPoints >= 3000) return "Excellent! ";
    if (userPoints >= 1500) return "Great job! ";
    if (userPoints >= 500) return "Keep going! ";
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

  // ✅ NEW DELETE ACCOUNT SECTION AT BOTTOM
  Widget _buildDeleteAccountSection() {
    return Container(
      width: double.infinity,
      padding: _getPaddingL(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            errorColor.withOpacity(0.1),
            errorColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(_getRadiusL()),
        border: Border.all(
          color: errorColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: errorColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with warning icon
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getSpaceM(context)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [errorColor, errorColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(_getRadiusM()),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: textPrimary,
                  size: 20,
                ),
              ),
              SizedBox(width: _getSpaceM(context)),
              Expanded(
                child: Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontSize: _getSubheadingSize(context),
                    fontWeight: FontWeight.bold,
                    color: errorColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _getSpaceL(context)),

          // Warning message
          Container(
            padding: _getPaddingM(context),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_getRadiusM()),
              border: Border.all(
                color: errorColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: errorColor,
                      size: 20,
                    ),
                    SizedBox(width: _getSpaceS(context)),
                    Expanded(
                      child: Text(
                        'Delete Account Permanently',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: _getBodySize(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _getSpaceS(context)),
                Text(
                  'This action cannot be undone. All your learning data, progress, notes, and saved content will be permanently deleted.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: _getCaptionSize(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _getSpaceL(context)),

          // Delete button - full width
          Container(
            width: double.infinity,
            height: _isSmallMobile(context) ? 50 : 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [errorColor, const Color(0xFFF87171)],
              ),
              borderRadius: BorderRadius.circular(_getRadiusM()),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: errorColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(_getRadiusM()),
                onTap: _navigateToDeleteAccount,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getSpaceM(context),
                    vertical: _getSpaceS(context),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                          size: _isSmallMobile(context) ? 18 : 20,
                        ),
                      ),
                      SizedBox(width: _getSpaceM(context)),
                      Text(
                        'Delete My Account',
                        style: TextStyle(
                          fontSize: _isSmallMobile(context) ? 14 : _getBodySize(context),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: _getSpaceM(context)),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
class ModernLogoutDialog extends StatefulWidget {
  @override
  _ModernLogoutDialogState createState() => _ModernLogoutDialogState();
}

class _ModernLogoutDialogState extends State<ModernLogoutDialog>
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