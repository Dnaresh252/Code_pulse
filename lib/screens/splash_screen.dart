import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _logoSlideAnimation;

  bool _isNavigating = false;
  String _loadingMessage = "Initializing app...";
  bool _isConnected = false;
  double _currentProgress = 0.0;
  Timer? _progressTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static bool _hasNavigated = false; // Prevent multiple navigations globally

  @override
  void initState() {
    super.initState();
    _hasNavigated = false; // Reset on splash screen creation
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Set status bar to transparent
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0D1B2A),
        systemNavigationBarIconBrightness: Brightness.light,
      ));

      // Initialize animation controllers
      _initializeAnimations();

      // Start animations
      _startAnimations();

      // Start connectivity monitoring and progress
      await _startConnectivityMonitoring();

    } catch (e) {

      _handleError();
    }
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Initialize animations
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
        _particleController.repeat();
      }
    });
  }

  Future<void> _startConnectivityMonitoring() async {
    try {
      // Check initial connectivity
      final connectivityResults = await Connectivity().checkConnectivity();
      _isConnected = !connectivityResults.contains(ConnectivityResult.none);

      // Listen for connectivity changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
            (List<ConnectivityResult> results) {
          final wasConnected = _isConnected;
          _isConnected = !results.contains(ConnectivityResult.none);

          if (!wasConnected && _isConnected) {
            // Connection restored
            _updateLoadingMessage(_currentProgress, reconnected: true);
            _resumeProgress();
          } else if (wasConnected && !_isConnected) {
            // Connection lost
            _updateLoadingMessage(_currentProgress, disconnected: true);
            _pauseProgress();
          }
        },
      );

      // Start smart progress
      _startSmartProgress();

    } catch (e) {
      _handleError();
    }
  }

  void _startSmartProgress() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isConnected) {
        // Progress faster when connected
        _currentProgress += 0.015; // Complete in ~6.7 seconds when connected
      } else {
        // Progress much slower when disconnected
        _currentProgress += 0.003; // Very slow progress when offline
      }

      // Cap progress at different levels based on connection
      if (!_isConnected && _currentProgress > 0.3) {
        _currentProgress = 0.3; // Stop at 30% if no internet
        _updateLoadingMessage(_currentProgress, waiting: true);
      } else if (_currentProgress >= 1.0) {
        _currentProgress = 1.0;
        timer.cancel();
        _finishLoading();
      }

      // Update progress animation
      _progressController.animateTo(_currentProgress);
      _updateLoadingMessage(_currentProgress);
    });
  }

  void _pauseProgress() {
    _progressTimer?.cancel();
  }

  void _resumeProgress() {
    if (_currentProgress < 1.0) {
      _startSmartProgress();
    }
  }

  void _updateLoadingMessage(double progress, {
    bool disconnected = false,
    bool reconnected = false,
    bool waiting = false,
  }) {
    if (disconnected) {
      _loadingMessage = "No internet connection... 📶";
    } else if (reconnected) {
      _loadingMessage = "Connection restored! Continuing... ✅";
    } else if (waiting && !_isConnected) {
      _loadingMessage = "Waiting for internet connection... ⏳";
    } else if (_isConnected) {
      if (progress < 0.2) {
        _loadingMessage = "Checking internet connection... 🌐";
      } else if (progress < 0.4) {
        _loadingMessage = "Connecting to Firebase... 🔥";
      } else if (progress < 0.6) {
        _loadingMessage = "Loading awesome features... ✨";
      } else if (progress < 0.8) {
        _loadingMessage = "Preparing your workspace... 💻";
      } else if (progress < 0.95) {
        _loadingMessage = "Almost ready to code! 🚀";
      } else {
        _loadingMessage = "Welcome to your coding journey! 🎉";
      }
    } else {
      _loadingMessage = "Please check your internet connection 📱";
    }

    if (mounted) setState(() {});
  }

  // UPDATED: Finish loading with better navigation
  Future<void> _finishLoading() async {
    if (_isNavigating || !mounted || _hasNavigated) return;

    try {
      await _checkAuthenticationAndNavigate();
    } catch (e) {
      _handleError();
    }
  }

  // UPDATED: Better authentication check with strict validation
  Future<void> _checkAuthenticationAndNavigate() async {
    if (_hasNavigated || _isNavigating || !mounted) {
      return;
    }

    if (!_isConnected) {
      _showNoInternetDialog();
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      // If no user at all, go to login
      if (user == null) {
        await _clearAppSession();
        _navigateToLogin();
        return;
      }

      // If user exists, validate their Firestore document
      bool isValidSession = await _validateUserSession(user);

      // Smooth transition delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted || _isNavigating || _hasNavigated) return;

      if (isValidSession) {
        // User has valid document, go to home
        await _saveAppSession();
        _navigateToHome();
      } else {
        // User exists but no valid Firestore document, go to login
        await _clearAppSession();
        _navigateToLogin();
      }

    } catch (e) {
      // On any error, clear session and go to login
      await _clearAppSession();
      _handleError();
    }
  }

  // UPDATED: Better session validation with strict checking
  Future<bool> _validateUserSession(User user) async {
    try {
      // Test Firestore connection with timeout
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      // If user document doesn't exist, validation fails
      if (!userDoc.exists) {
        // Sign out the user since they don't have a proper account
        await FirebaseAuth.instance.signOut();
        return false;
      }

      final userData = userDoc.data();

      // Check if user document has all required data
      if (userData == null ||
          userData['email'] == null ||
          userData['fullName'] == null ||
          userData['email'].toString().isEmpty ||
          userData['fullName'].toString().isEmpty) {
        // User document is incomplete, sign out and send to registration
        await FirebaseAuth.instance.signOut();
        return false;
      }

      // Update user status only if validation passes
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'lastActiveAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'lastAppOpen': FieldValue.serverTimestamp(),
      });

      return true;

    } catch (e) {
      // On any error, sign out user for safety
      try {
        await FirebaseAuth.instance.signOut();
      } catch (signOutError) {
        // Handle silently
      }
      return false;
    }
  }

  // NEW: Save app session data
  Future<void> _saveAppSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_login', DateTime.now().toIso8601String());
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('app_version', '1.0.0');
    } catch (e) {
      // Handle silently
    }
  }

  // NEW: Clear app session data
  Future<void> _clearAppSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('last_login');
    } catch (e) {
      // Handle silently
    }
  }

  void _showNoInternetDialog() {
    if (!mounted || _hasNavigated) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1B263B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text(
                'No Internet',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This app requires an internet connection to work properly.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Please check your connection and try again.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _retryConnection();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigateToLogin(); // Go to login anyway (offline mode)
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
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
  }

  void _retryConnection() {
    _currentProgress = 0.0;
    _progressController.reset();
    _startConnectivityMonitoring();
  }

  void _handleError() {
    if (!mounted || _isNavigating || _hasNavigated) return;

    // Clear any existing session on error
    _clearAppSession();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isNavigating && !_hasNavigated) {
        _navigateToLogin();
      }
    });
  }

  // UPDATED: Safe navigation to Home with prevention of multiple calls
  void _navigateToHome() {
    if (_isNavigating || !mounted || _hasNavigated) {
      return;
    }

    _isNavigating = true;
    _hasNavigated = true;

    Navigator.of(context).pushAndRemoveUntil(
      _createFadeRoute(const HomeScreen()),
          (route) => false, // Remove all previous routes
    );
  }

  // UPDATED: Safe navigation to Login with prevention of multiple calls
  void _navigateToLogin() {
    if (_isNavigating || !mounted || _hasNavigated) {
      return;
    }

    _isNavigating = true;
    _hasNavigated = true;

    Navigator.of(context).pushAndRemoveUntil(
      _createFadeRoute(const DarkLoginScreen()),
          (route) => false, // Remove all previous routes
    );
  }

  PageRouteBuilder _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 800),
      reverseTransitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _connectivitySubscription?.cancel();
    _progressController.dispose();
    _fadeController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isLandscape = size.width > size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            // Animated floating particles
            ...List.generate(
              isTablet ? 20 : 15,
                  (index) => SplashParticle(
                index: index,
                controller: _particleController,
                screenSize: size,
              ),
            ),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              // Top spacing
                              SizedBox(
                                height: isLandscape
                                    ? constraints.maxHeight * 0.1
                                    : constraints.maxHeight * 0.15,
                              ),

                              // Logo section with animations
                              _buildLogoSection(isTablet, isLandscape),

                              // Middle spacing
                              SizedBox(
                                height: isLandscape
                                    ? constraints.maxHeight * 0.1
                                    : constraints.maxHeight * 0.15,
                              ),

                              // Progress section
                              _buildProgressSection(isTablet, constraints),

                              // Bottom spacing
                              SizedBox(
                                height: isLandscape
                                    ? constraints.maxHeight * 0.05
                                    : constraints.maxHeight * 0.1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Connection status indicator
            _buildConnectionIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    return Positioned(
      top: 50,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isConnected
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isConnected ? Colors.green : Colors.red,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _isConnected ? 'Online' : 'Offline',
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isTablet, bool isLandscape) {
    final logoSize = isTablet ? 140.0 : (isLandscape ? 100.0 : 120.0);
    final titleSize = isTablet ? 42.0 : (isLandscape ? 28.0 : 36.0);
    final subtitleSize = isTablet ? 18.0 : (isLandscape ? 14.0 : 16.0);

    return SlideTransition(
      position: _logoSlideAnimation,
      child: ScaleTransition(
        scale: _logoScaleAnimation,
        child: Column(
          children: [
            // Animated logo with glow effect
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4AA).withOpacity(0.4 * _pulseAnimation.value),
                        blurRadius: 30 * _pulseAnimation.value,
                        spreadRadius: 10 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: Container(
                    width: logoSize,
                    height: logoSize,
                    padding: EdgeInsets.all(logoSize * 0.15),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                      ),
                    ),
                    child: RotationTransition(
                      turns: _logoRotateAnimation,
                      child: CustomPaint(
                        painter: CurlyBracePainter(),
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: isLandscape ? 20 : 30),

            // CodePulse text with gradient
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF00A8CC), Colors.white],
                stops: [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: Text(
                'CodePulse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),

            SizedBox(height: isLandscape ? 8 : 12),

            // Animated tagline
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 20,
                vertical: isTablet ? 10 : 8,
              ),
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
                'Learn. Code. Grow. 🚀',
                style: TextStyle(
                  color: const Color(0xFF00D4AA),
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(bool isTablet, BoxConstraints constraints) {
    final horizontalPadding = isTablet ? 80.0 : 60.0;
    final maxWidth = constraints.maxWidth - (horizontalPadding * 2);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          // Loading text with connection status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Loading ${(_currentProgress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!_isConnected) ...[
                SizedBox(width: 8),
                Icon(
                  Icons.cloud_off,
                  color: Colors.orange,
                  size: isTablet ? 16 : 14,
                ),
              ],
            ],
          ),

          SizedBox(height: isTablet ? 20 : 16),

          // Enhanced smart progress bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                width: maxWidth,
                height: isTablet ? 8 : 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isTablet ? 4 : 3),
                  boxShadow: [
                    BoxShadow(
                      color: (_isConnected ? const Color(0xFF00D4AA) : Colors.orange)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isTablet ? 4 : 3),
                  child: LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isConnected ? const Color(0xFF00D4AA) : Colors.orange,
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: isTablet ? 50 : 40),

          // Smart loading messages
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_isConnected ? const Color(0xFF00D4AA) : Colors.orange)
                    .withOpacity(0.3),
              ),
            ),
            child: Text(
              _loadingMessage,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: isTablet ? 80 : 60),

          // Enhanced copyright with branding
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.code,
                  color: const Color(0xFF00D4AA),
                  size: isTablet ? 16 : 14,
                ),
                SizedBox(width: isTablet ? 10 : 8),
                Flexible(
                  child: Text(
                    '© ${DateTime.now().year} CodePulse - Learn to Code',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: isTablet ? 13 : 11,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Custom painter for curly braces logo
class CurlyBracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.05
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Left curly brace with smoother curves
    path.moveTo(size.width * 0.35, size.height * 0.1);
    path.quadraticBezierTo(
      size.width * 0.15, size.height * 0.15,
      size.width * 0.15, size.height * 0.35,
    );
    path.quadraticBezierTo(
      size.width * 0.15, size.height * 0.45,
      size.width * 0.05, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.15, size.height * 0.55,
      size.width * 0.15, size.height * 0.65,
    );
    path.quadraticBezierTo(
      size.width * 0.15, size.height * 0.85,
      size.width * 0.35, size.height * 0.9,
    );

    // Right curly brace with smoother curves
    path.moveTo(size.width * 0.65, size.height * 0.1);
    path.quadraticBezierTo(
      size.width * 0.85, size.height * 0.15,
      size.width * 0.85, size.height * 0.35,
    );
    path.quadraticBezierTo(
      size.width * 0.85, size.height * 0.45,
      size.width * 0.95, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.85, size.height * 0.55,
      size.width * 0.85, size.height * 0.65,
    );
    path.quadraticBezierTo(
      size.width * 0.85, size.height * 0.85,
      size.width * 0.65, size.height * 0.9,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Enhanced floating particle animation widget
class SplashParticle extends StatefulWidget {
  final int index;
  final AnimationController controller;
  final Size screenSize;

  const SplashParticle({
    Key? key,
    required this.index,
    required this.controller,
    required this.screenSize,
  }) : super(key: key);

  @override
  State<SplashParticle> createState() => _SplashParticleState();
}

class _SplashParticleState extends State<SplashParticle> {
  late Animation<double> _animation;
  late double _horizontalPosition;
  late double _particleSize;

  @override
  void initState() {
    super.initState();

    _horizontalPosition = (widget.index % 6) * (widget.screenSize.width / 6) +
        (30 * (widget.index % 3 - 1));
    _particleSize = 2.0 + (widget.index % 4);

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: widget.controller,
      curve: Interval(
        (widget.index % 8) * 0.125,
        1.0,
        curve: Curves.easeInOut,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final verticalPosition = widget.screenSize.height * _animation.value;
        final opacity = 0.1 + (0.3 * (1 - _animation.value));

        return Positioned(
          left: _horizontalPosition.clamp(0.0, widget.screenSize.width - _particleSize),
          top: verticalPosition,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: _particleSize,
              height: _particleSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}