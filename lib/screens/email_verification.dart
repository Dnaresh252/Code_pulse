import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String userName;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.userName,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  Timer? _timer;
  Timer? _resendTimer;
  bool _isEmailVerified = false;
  bool _isCheckingVerification = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  String? _errorMessage;
  String? _successMessage;
  bool _canResend = true;
  int _checkCount = 0;
  static const int _maxChecks = 180; // 3 minutes of checking

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEmailVerificationCheck();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _checkEmailVerification();
      _checkCount++;

      if (_checkCount >= _maxChecks) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _errorMessage = 'Verification check timeout. Please try logging in.';
          });
        }
      }
    });
  }

  Future<void> _checkEmailVerification() async {
    if (_isCheckingVerification) return;

    setState(() {
      _isCheckingVerification = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        user = _auth.currentUser;

        if (user?.emailVerified == true) {
          setState(() {
            _isEmailVerified = true;
            _successMessage = 'Email verified successfully! 🎉';
          });
          // ✅ ADD SHARED PREFERENCES HERE - User is now fully authenticated
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('last_login', DateTime.now().toIso8601String());
          await prefs.setString('user_uid', user!.uid);

          // Update Firestore with verification status
          await _firestore.collection('users').doc(user!.uid).update({
            'emailVerified': true,
            'isOnline': true,
            'lastLoginAt': FieldValue.serverTimestamp(),
          });

          _timer?.cancel();

          // Show success message briefly before navigation
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking email verification: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();

        setState(() {
          _successMessage = 'Verification email sent! Check your inbox 📧';
          _canResend = false;
          _resendCountdown = 60; // 60 seconds cooldown
        });

        // Start resend cooldown timer
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _resendCountdown--;
          });

          if (_resendCountdown <= 0) {
            timer.cancel();
            setState(() {
              _canResend = true;
            });
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please wait before trying again.';
          break;
        case 'user-not-found':
          errorMessage = 'User not found. Please sign up again.';
          break;
        default:
          errorMessage = 'Failed to send verification email. Please try again.';
      }
      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DarkLoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendTimer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.06,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.05),

                // Animated email icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value * 2 * 3.14159,
                            child: Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _isEmailVerified
                                      ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                                      : [const Color(0xFF00D4AA), const Color(0xFF00A8CC)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isEmailVerified
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF00D4AA)).withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isEmailVerified ? Icons.verified : Icons.mark_email_unread,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                SizedBox(height: screenHeight * 0.04),

                // Main content card
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Title with gradient
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: _isEmailVerified
                              ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                              : [const Color(0xFF00D4AA), const Color(0xFF00A8CC)],
                        ).createShader(bounds),
                        child: Text(
                          _isEmailVerified
                              ? "Welcome to CodeMaster! 🎉"
                              : "Verify Your Email 📧",
                          style: TextStyle(
                            fontSize: screenWidth * 0.065,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // User info section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFF00D4AA).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: const Color(0xFF00D4AA),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Hello, ${widget.userName}! 👋",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  color: const Color(0xFF00D4AA),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.email,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Status message
                      if (!_isEmailVerified) ...[
                        Text(
                          "We've sent a verification link to your email address. Click the link to activate your account and start your coding journey!",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: screenWidth * 0.04,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: screenHeight * 0.025),

                        // Verification status
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Waiting for email verification...",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Success message
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: const Color(0xFF4CAF50),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Email verified! Redirecting to your dashboard...",
                                  style: TextStyle(
                                    color: const Color(0xFF4CAF50),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Error message
                      if (_errorMessage != null) ...[
                        SizedBox(height: screenHeight * 0.02),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Success message
                      if (_successMessage != null) ...[
                        SizedBox(height: screenHeight * 0.02),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4AA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00D4AA).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: const Color(0xFF00D4AA),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: TextStyle(
                                    color: const Color(0xFF00D4AA),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (!_isEmailVerified) ...[
                        SizedBox(height: screenHeight * 0.03),

                        // Resend button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.018,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ).copyWith(
                              backgroundColor: MaterialStateProperty.all(Colors.transparent),
                            ),
                            onPressed: _canResend && !_isResending ? _resendVerificationEmail : null,
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: (_canResend && !_isResending)
                                      ? [const Color(0xFF00D4AA), const Color(0xFF00A8CC)]
                                      : [Colors.grey, Colors.grey.shade600],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.018,
                                ),
                                child: _isResending
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.refresh, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _canResend
                                          ? "Resend Verification Email"
                                          : "Resend in ${_resendCountdown}s",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Tips section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "💡 Quick Tips:",
                                style: TextStyle(
                                  color: const Color(0xFF00D4AA),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildTipItem("Check your spam/junk folder"),
                              _buildTipItem("Make sure you clicked the verification link"),
                              _buildTipItem("The verification link expires in 24 hours"),
                              _buildTipItem("Contact support if you need help"),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Sign out button
                        TextButton(
                          onPressed: _signOut,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.white.withOpacity(0.7),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Sign out and try different email",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.white.withOpacity(0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}