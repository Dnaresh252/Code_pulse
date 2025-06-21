import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _successController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successAnimation;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers and validation
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocusNode = FocusNode();

  // UI state management
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendTimer = 0;
  bool _canResend = true;
  int _attemptCount = 0;
  Timer? _resendTimerInstance;

  // Rate limiting constants
  static const int _maxAttempts = 5;
  static const int _cooldownMinutes = 15;
  static const int _resendCooldownSeconds = 60;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPreviousAttempts();
    _setupFocusListeners();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _resendTimerInstance?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _setupFocusListeners() {
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        if (_errorMessage != null) {
          setState(() {
            _errorMessage = null;
          });
        }
      }
    });
  }

  // ✅ Load previous attempt data for rate limiting
  Future<void> _loadPreviousAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAttemptTime = prefs.getInt('last_password_reset_attempt') ?? 0;
      final attemptCount = prefs.getInt('password_reset_attempt_count') ?? 0;
      final lastAttemptEmail = prefs.getString('last_password_reset_email') ?? '';

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTime - lastAttemptTime;
      final cooldownTime = _cooldownMinutes * 60 * 1000;

      if (timeDifference > cooldownTime) {
        await prefs.remove('password_reset_attempt_count');
        await prefs.remove('last_password_reset_attempt');
        await prefs.remove('last_password_reset_email');
        _attemptCount = 0;
      } else {
        _attemptCount = attemptCount;
        if (lastAttemptEmail.isNotEmpty) {
          _emailController.text = lastAttemptEmail;
        }
      }
    } catch (e) {
      //debugPrint('Error loading previous attempts: $e');
    }
  }

  // ✅ Comprehensive email validation
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }

    final email = value.trim().toLowerCase();

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    if (email.length > 254) {
      return 'Email address is too long';
    }

    if (email.startsWith('.') || email.endsWith('.')) {
      return 'Invalid email format';
    }

    if (email.contains('..')) {
      return 'Invalid email format';
    }

    if (email.contains(' ')) {
      return 'Email cannot contain spaces';
    }

    return null;
  }

  // ✅ Check network connectivity
  Future<bool> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      debugPrint('Network check error: $e');
      return false;
    }
  }

  // ✅ Check rate limiting
  bool _isRateLimited() {
    if (_attemptCount >= _maxAttempts) {
      setState(() {
        _errorMessage = 'Too many attempts. Please try again in $_cooldownMinutes minutes.';
      });
      return true;
    }
    return false;
  }

  // ✅ Save attempt data for rate limiting
  Future<void> _saveAttemptData(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_password_reset_attempt', DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt('password_reset_attempt_count', _attemptCount + 1);
      await prefs.setString('last_password_reset_email', email);
    } catch (e) {
      debugPrint('Error saving attempt data: $e');
    }
  }

  // ✅ FIXED: Simplified password reset method
  Future<void> _sendPasswordResetEmail() async {
    // Clear previous messages
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Check rate limiting
    if (_isRateLimited()) return;

    // Check network connectivity
    final hasNetwork = await _checkNetworkConnectivity();
    if (!hasNetwork) {
      setState(() {
        _errorMessage = 'No internet connection. Please check your network and try again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String email = _emailController.text.trim().toLowerCase();

      // FIXED: Simple password reset without ActionCodeSettings
      await _auth.sendPasswordResetEmail(email: email);

      // Success handling
      setState(() {
        _emailSent = true;
        _successMessage = "Password reset link sent successfully!";
        _attemptCount++;
      });

      await _saveAttemptData(email);
      _successController.forward();
      _startResendTimer();

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Password reset link sent! Check your email 📧",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00D4AA),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Optional: Update Firestore (but don't let it block the process)
      _updateFirestoreOptional(email);

    } on FirebaseAuthException catch (e) {
     // debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
      _attemptCount++;
      await _saveAttemptData(_emailController.text.trim());
    } catch (e) {
     // debugPrint('General Exception: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ Optional Firestore update that won't block the main process
  Future<void> _updateFirestoreOptional(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await _firestore.collection('users').doc(querySnapshot.docs.first.id).update({
          'lastPasswordResetRequest': FieldValue.serverTimestamp(),
          'passwordResetRequests': FieldValue.increment(1),
        });
      }
    } catch (e) {
     // debugPrint('Optional Firestore update failed: $e');
      // Don't show error to user since main operation succeeded
    }
  }

  // ✅ Enhanced Firebase error handling
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or create a new account.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many reset attempts. Please wait before trying again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'auth/operation-not-allowed':
        return 'Password reset is not enabled. Please contact support.';
      case 'auth/invalid-continue-uri':
        return 'Invalid configuration. Please contact support.';
      case 'auth/unauthorized-continue-uri':
        return 'Unauthorized domain. Please contact support.';
      case 'quota-exceeded':
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return 'Failed to send reset email. Please try again.';
    }
  }

  // ✅ Resend timer functionality
  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = _resendCooldownSeconds;
    });

    _resendTimerInstance?.cancel();
    _resendTimerInstance = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendTimer--;
        });

        if (_resendTimer <= 0) {
          timer.cancel();
          setState(() {
            _canResend = true;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  // ✅ Resend functionality
  Future<void> _resendResetEmail() async {
    if (!_canResend) return;
    if (_isRateLimited()) return;
    await _sendPasswordResetEmail();
  }

  // ✅ Clear form data
  void _clearFormData() {
    _emailController.clear();
    _emailFocusNode.unfocus();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _emailSent = false;
      _isLoading = false;
    });
    _resendTimerInstance?.cancel();
    _successController.reset();
  }

  // ✅ Handle back navigation
  Future<bool> _onWillPop() async {
    if (_emailSent) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1B263B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            'Leave Password Reset?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'You\'ve requested a password reset. Are you sure you want to leave this screen?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Stay',
                style: TextStyle(color: Color(0xFF00D4AA)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Leave',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  // ✅ DEBUG: Test Firebase connection
  Future<void> _testFirebaseConnection() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Test basic Firebase Auth
      debugPrint('Testing Firebase Auth...');
      final user = _auth.currentUser;
      debugPrint('Current user: $user');

      // Test sending a password reset to a test email
      final testEmail = _emailController.text.trim();
      if (testEmail.isEmpty) {
        setState(() {
          _errorMessage = 'Enter an email first to test';
        });
        return;
      }

      await _auth.sendPasswordResetEmail(email: testEmail);

      setState(() {
        _successMessage = 'Test successful! Firebase is working correctly.';
      });

    } catch (e) {
      //debugPrint('Firebase test error: $e');
      setState(() {
        _errorMessage = 'Firebase test failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
          child: Stack(
            children: [
              // Animated background particles
              ...List.generate(15, (index) => FloatingParticle(index: index)),

              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenHeight * 0.02,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Back button
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () async {
                                  final canPop = await _onWillPop();
                                  if (canPop && mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white70,
                                  size: 24,
                                ),
                                tooltip: 'Back to Login',
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            // Header section with animated icon
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  // Animated main icon
                                  ScaleTransition(
                                    scale: _pulseAnimation,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: _emailSent
                                              ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                                              : [const Color(0xFF00D4AA), const Color(0xFF00A8CC)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_emailSent
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFF00D4AA)).withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Title with gradient
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                                    ).createShader(bounds),
                                    child: Text(
                                      _emailSent ? "Check Your Email! 📧" : "Forgot Password? 🔐",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.065,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    _emailSent
                                        ? "We've sent a password reset link to your email.\nClick the link to reset your password."
                                        : "Don't worry! We'll help you reset it.\nEnter your email to get back on track.",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            // Success animation icon
                            if (_emailSent)
                              ScaleTransition(
                                scale: _successAnimation,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF00D4AA).withOpacity(0.2),
                                    border: Border.all(
                                      color: const Color(0xFF00D4AA),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 40,
                                    color: Color(0xFF00D4AA),
                                  ),
                                ),
                              ),

                            if (!_emailSent) SizedBox(height: screenHeight * 0.02),

                            // Main form container
                            Container(
                              width: double.infinity,
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
                                borderRadius: BorderRadius.circular(20),
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
                                  _buildMessageSection(),
                                  _buildSecurityIndicator(),
                                  const SizedBox(height: 24),
                                  if (!_emailSent) ...[
                                    _buildEmailInput(),
                                    const SizedBox(height: 20),
                                  ],
                                  _buildActionButtons(screenWidth, screenHeight),

                                  // DEBUG: Add test button (remove in production)
                                  if (!_emailSent) ...[
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: _testFirebaseConnection,
                                      child: const Text(
                                        'Test Firebase Connection',
                                        style: TextStyle(color: Colors.orange),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 16),
                                  _buildBackToLoginButton(),
                                  const SizedBox(height: 16),
                                  _buildHelpInformation(),
                                ],
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02),
                            _buildSecurityFeaturesSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Message section with error and success handling
  Widget _buildMessageSection() {
    return Column(
      children: [
        // Error message display
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
              ),
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
                IconButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.red, size: 16),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

        // Success message display
        if (_successMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00D4AA).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(
                      color: Color(0xFF00D4AA),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Rate limiting warning
        if (_attemptCount >= _maxAttempts - 1 && _attemptCount < _maxAttempts)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_outlined, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Warning: Only ${_maxAttempts - _attemptCount} attempt remaining. Then you\'ll need to wait $_cooldownMinutes minutes.',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ✅ Security indicator
  Widget _buildSecurityIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.security, color: Colors.white.withOpacity(0.7), size: 20),
        const SizedBox(width: 8),
        Text(
          "Secure password recovery",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ✅ Email input field
  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Email Address",
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          style: const TextStyle(color: Colors.white),
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _sendPasswordResetEmail(),
          decoration: InputDecoration(
            hintText: "Enter your registered email 📧",
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
            suffixIcon: _emailController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.white54),
              onPressed: _clearFormData,
            )
                : null,
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  // ✅ Action buttons
  Widget _buildActionButtons(double screenWidth, double screenHeight) {
    if (!_emailSent) {
      return _buildSendResetButton(screenWidth, screenHeight);
    } else {
      return _buildResendSection(screenWidth);
    }
  }

  Widget _buildSendResetButton(double screenWidth, double screenHeight) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ).copyWith(
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
        ),
        onPressed: (_isLoading || _isRateLimited()) ? null : _sendPasswordResetEmail,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: (_isLoading || _isRateLimited())
                  ? [Colors.grey, Colors.grey.shade600]
                  : [const Color(0xFF00D4AA), const Color(0xFF00A8CC)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
            child: _isLoading
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
                const Icon(Icons.send, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Send Reset Link",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection(double screenWidth) {
    return Column(
      children: [
        if (!_canResend) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Text(
                  "You can resend the email in $_resendTimer seconds",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ).copyWith(
              backgroundColor: MaterialStateProperty.all(Colors.transparent),
            ),
            onPressed: (_canResend && !_isLoading && !_isRateLimited()) ? _resendResetEmail : null,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: (_canResend && !_isLoading && !_isRateLimited())
                      ? [const Color(0xFF00D4AA), const Color(0xFF00A8CC)]
                      : [Colors.grey, Colors.grey.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _isLoading
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
                    Icon(
                      _canResend ? Icons.refresh : Icons.timer,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _canResend ? "Resend Email" : "Please Wait",
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
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
      ],
    );
  }

  // ✅ Back to login button
  Widget _buildBackToLoginButton() {
    return TextButton(
      onPressed: () async {
        final canPop = await _onWillPop();
        if (canPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.arrow_back, color: Color(0xFF00D4AA), size: 18),
          SizedBox(width: 8),
          Text(
            "Back to Login",
            style: TextStyle(
              color: Color(0xFF00D4AA),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Help information section
  Widget _buildHelpInformation() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF00D4AA),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Check your spam folder if you don't see the email 📬",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (_emailSent) ...[
            const SizedBox(height: 8),
            Text(
              "The reset link will expire in 24 hours for security reasons.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Having trouble? Contact support for assistance.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ✅ Security features section
  Widget _buildSecurityFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Why trust our security?",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSecurityItem("Encrypted", "256-bit SSL", Icons.security),
              _buildSecurityItem("Fast", "< 2 minutes", Icons.speed),
              _buildSecurityItem("Private", "No data stored", Icons.verified_user),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String title, String subtitle, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00D4AA), size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ✅ Enhanced floating particle animation widget
class FloatingParticle extends StatefulWidget {
  final int index;

  const FloatingParticle({super.key, required this.index});

  @override
  State<FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _startX;
  late double _startY;
  late double _endX;
  late double _endY;
  late double _size;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 8 + (widget.index % 4)),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );

    _initializeProperties();
    _controller.repeat();
  }

  void _initializeProperties() {
    final random = DateTime.now().millisecondsSinceEpoch + widget.index;
    _startX = (random % 100).toDouble();
    _startY = (random % 150).toDouble();
    _endX = ((random * 3) % 100).toDouble();
    _endY = _startY + 200 + ((random % 100).toDouble());
    _size = 3 + (widget.index % 4).toDouble();

    // Vary colors slightly
    if (widget.index % 3 == 0) {
      _color = const Color(0xFF00D4AA);
    } else if (widget.index % 3 == 1) {
      _color = const Color(0xFF00A8CC);
    } else {
      _color = const Color(0xFF778DA9);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentX = _startX + (_endX - _startX) * _animation.value;
        final currentY = _startY + (_endY - _startY) * _animation.value;

        if (currentY > screenSize.height) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeProperties();
          });
        }

        return Positioned(
          left: currentX,
          top: currentY,
          child: Opacity(
            opacity: 0.1 + (0.3 * (1 - _animation.value)),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _color.withOpacity(0.6),
                    _color.withOpacity(0.4),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _color.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


