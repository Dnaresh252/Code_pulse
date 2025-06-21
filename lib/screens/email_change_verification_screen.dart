import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class EmailChangeVerificationScreen extends StatefulWidget {
  final String currentEmail;
  final String newEmail;
  final String userName;

  const EmailChangeVerificationScreen({
    super.key,
    required this.currentEmail,
    required this.newEmail,
    required this.userName,
  });

  @override
  State<EmailChangeVerificationScreen> createState() => _EmailChangeVerificationScreenState();
}

class _EmailChangeVerificationScreenState extends State<EmailChangeVerificationScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;


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
  static const int _maxChecks = 300; // 5 minutes of checking

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _sendEmailChangeVerification();
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



    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  Future<void> _sendEmailChangeVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // ✅ SEND EMAIL CHANGE VERIFICATION
        await user.verifyBeforeUpdateEmail(widget.newEmail);

        setState(() {
          _successMessage = 'Verification email sent to ${widget.newEmail}';
        });

        _startEmailVerificationCheck();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send verification email. Please try again.';
      });
    }
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _checkEmailVerification();
      _checkCount++;

      if (_checkCount >= _maxChecks) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _errorMessage = 'Verification timeout. Please try again.';
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

        // ✅ CHECK IF EMAIL WAS UPDATED
        if (user?.email == widget.newEmail) {
          setState(() {
            _isEmailVerified = true;
            _successMessage = 'Email updated successfully! 🎉';
          });

          // ✅ UPDATE FIRESTORE WITH NEW EMAIL
          await _firestore.collection('users').doc(user!.uid).update({
            'email': widget.newEmail,
            'emailVerified': true,
            'emailUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          _timer?.cancel();

          // Show success message briefly before returning
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            Navigator.pop(context, true); // Return success
          }
        }
      }
    } catch (e) {
      //debugPrint('Error checking email verification: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
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
    final size = MediaQuery
        .of(context)
        .size;
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
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // Animated email icon (same as your EmailVerificationScreen)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isEmailVerified
                                ? [
                              const Color(0xFF4CAF50),
                              const Color(0xFF66BB6A)
                            ]
                                : [
                              const Color(0xFF00D4AA),
                              const Color(0xFF00A8CC)
                            ],
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
                          _isEmailVerified ? Icons.verified : Icons
                              .email_outlined,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: screenHeight * 0.04),

                // Main content (similar structure to your EmailVerificationScreen)
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
                  ),
                  child: Column(
                    children: [
                      // Title
                      Text(
                        _isEmailVerified
                            ? "Email Updated! 🎉"
                            : "Verify New Email 📧",
                        style: TextStyle(
                          fontSize: screenWidth * 0.065,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Email change info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            _buildEmailRow(
                                "Current Email:", widget.currentEmail,
                                Icons.email),
                            const SizedBox(height: 12),
                            _buildEmailRow("New Email:", widget.newEmail,
                                Icons.mark_email_read),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Status message
                      Text(
                        _isEmailVerified
                            ? "Your email has been successfully updated!"
                            : "We've sent a verification link to your new email address. Click the link to confirm the change.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: screenWidth * 0.04,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Error/Success messages (similar to your existing screen)
                      if (_errorMessage != null) ...[
                        SizedBox(height: screenHeight * 0.02),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red,
                                  size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_successMessage != null) ...[
                        SizedBox(height: screenHeight * 0.02),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4AA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: Color(0xFF00D4AA), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: const TextStyle(
                                      color: Color(0xFF00D4AA), fontSize: 14),
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

  Widget _buildEmailRow(String label, String email, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00D4AA), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                email,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}