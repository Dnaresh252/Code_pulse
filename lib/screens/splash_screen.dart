import 'package:code_assistant/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
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

  @override
  void initState() {
    super.initState();

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Initialize animation controllers
    _progressController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: Duration(seconds: 4),
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
      begin: 0.5,
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
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations with delays
    _fadeController.forward();

    Future.delayed(Duration(milliseconds: 300), () {
      _logoController.forward();
    });

    Future.delayed(Duration(milliseconds: 500), () {
      _progressController.forward();
      _pulseController.repeat(reverse: true);
      _particleController.repeat();
    });

    // Navigate to login screen after splash duration
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToLogin();
      }
    });
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => DarkLoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
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
            ...List.generate(15, (index) => SplashParticle(
              index: index,
              controller: _particleController,
            )),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: double.infinity,
                  child: Column(
                    children: [
                      // Top spacing
                      Expanded(
                        flex: 2,
                        child: Container(),
                      ),

                      // Logo section with animations
                      SlideTransition(
                        position: _logoSlideAnimation,
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: Container(
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
                                        width: 120,
                                        height: 120,
                                        padding: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
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

                                SizedBox(height: 30),

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
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 12),

                                // Animated tagline
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                                      color: Color(0xFF00D4AA),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Middle spacing
                      Expanded(
                        flex: 2,
                        child: Container(),
                      ),

                      // Progress section with enhanced styling
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 60),
                        child: Column(
                          children: [
                            // Loading text
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return Text(
                                  'Loading ${(_progressAnimation.value * 100).toInt()}%',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 16),

                            // Enhanced progress bar
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00D4AA).withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: _progressAnimation.value,
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF00D4AA),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 40),

                            // Fun loading messages
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                String message = "Initializing...";
                                if (_progressAnimation.value > 0.3) {
                                  message = "Loading awesome features... ✨";
                                }
                                if (_progressAnimation.value > 0.6) {
                                  message = "Almost ready to code! 💻";
                                }
                                if (_progressAnimation.value > 0.9) {
                                  message = "Welcome to your coding journey! 🎉";
                                }

                                return Text(
                                  message,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),

                            SizedBox(height: 60),

                            // Enhanced copyright with branding
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                    color: Color(0xFF00D4AA),
                                    size: 14,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '© 2025 CodePulse - Empowering Coders',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

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

// Floating particle animation widget for splash
class SplashParticle extends StatefulWidget {
  final int index;
  final AnimationController controller;

  const SplashParticle({Key? key, required this.index, required this.controller}) : super(key: key);

  @override
  State<SplashParticle> createState() => _SplashParticleState();
}

class _SplashParticleState extends State<SplashParticle> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animation = Tween<double>(
        begin: 0,
        end: 1
    ).animate(CurvedAnimation(
      parent: widget.controller,
      curve: Interval(
        (widget.index % 4) * 0.25,
        1.0,
        curve: Curves.easeInOut,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: (widget.index % 6) * (size.width / 6) +
              (30 * (1 - _animation.value)),
          top: size.height * _animation.value,
          child: Opacity(
            opacity: 0.15 + (0.25 * (1 - _animation.value)),
            child: Container(
              width: 3 + (widget.index % 3),
              height: 3 + (widget.index % 3),
              decoration: BoxDecoration(
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
