import 'package:CodePulse/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/splash_screen.dart';

// Global navigation key for easy navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Simple app lifecycle observer
class AppLifecycleObserver extends WidgetsBindingObserver {
  static bool _isNavigating = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
      // User came back to app
        _updateUserStatus(user.uid, true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      // User left the app
        _updateUserStatus(user.uid, false);
        break;
      default:
        break;
    }
  }

  void _updateUserStatus(String userId, bool isOnline) {
    FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isOnline': isOnline,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }).catchError((e) => debugPrint('Status update failed: $e'));
  }

  // Static method to prevent navigation conflicts
  static void setNavigating(bool value) {
    _isNavigating = value;
  }

  static bool get isNavigating => _isNavigating;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // System UI setup
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0D1B2A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize Firebase
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');

    // Run the app
    runApp(const CodePulseApp());

  } catch (e) {
    debugPrint('❌ App initialization failed: $e');
    runApp(const ErrorApp());
  }
}

class CodePulseApp extends StatefulWidget {
  const CodePulseApp({super.key});

  @override
  State<CodePulseApp> createState() => _CodePulseAppState();
}

class _CodePulseAppState extends State<CodePulseApp> {
  final AppLifecycleObserver _lifecycleObserver = AppLifecycleObserver();

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    debugPrint('🚀 CodePulse App started');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Pulse',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,

      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.teal,
        primaryColor: const Color(0xFF00D4AA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4AA),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
      ),

      // Always start with splash screen
      home: const SplashScreen(),

      // Simple route builder
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return _buildRoute(const SplashScreen());
          default:
            return null;
        }
      },

      // Handle unknown routes
      onUnknownRoute: (settings) => _buildRoute(
        const Scaffold(
          body: Center(
            child: Text('Page not found'),
          ),
        ),
      ),
    );
  }

  PageRouteBuilder _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, _) => page,
      transitionsBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

// Simple error app for critical failures
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodePulse - Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please restart the application',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Close App',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Extension for easy user session management
extension UserSessionExtensions on BuildContext {
  // Check if user is logged in
  bool get isUserLoggedIn => FirebaseAuth.instance.currentUser != null;

  // Get current user
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Sign out user
  Future<void> signOutUser() async {
    try {
      AppLifecycleObserver.setNavigating(true);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update offline status before signing out
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isOnline': false,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseAuth.instance.signOut();

      // Clear any cached data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      debugPrint('✅ User signed out');

      AppLifecycleObserver.setNavigating(false);
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      AppLifecycleObserver.setNavigating(false);
    }
  }

  // Navigate safely without conflicts
  void navigateToHome() {
    if (!AppLifecycleObserver.isNavigating) {
      AppLifecycleObserver.setNavigating(true);
      Navigator.pushAndRemoveUntil(
        this,
        MaterialPageRoute(builder: (_) => HomeScreen()),
            (route) => false,
      );
      AppLifecycleObserver.setNavigating(false);
    }
  }
}

// Simple utility functions
class AppUtils {
  // Save user login time
  static Future<void> saveLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_login', DateTime.now().toIso8601String());
  }

  // Get last login time
  static Future<DateTime?> getLastLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('last_login');
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  // Show simple snackbar
  static void showSnackbar(String message, {Color? color}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color ?? const Color(0xFF00D4AA),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}