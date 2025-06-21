import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'email_verification.dart';
import 'login_screen.dart';

class DarkSignUpScreen extends StatefulWidget {
  const DarkSignUpScreen({super.key});

  @override
  State<DarkSignUpScreen> createState() => _DarkSignUpScreenState();
}

class _DarkSignUpScreenState extends State<DarkSignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _privacyPolicyAccepted = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;

  // Animation controllers for auto-tick functionality
  late AnimationController _checkboxController;
  late Animation<double> _checkboxAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Privacy Policy and Terms URLs
  static const String privacyPolicyUrl = 'https://www.privacypolicies.com/live/b6f32c1b-382d-4462-aadf-599ed158ff56';


  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _checkboxController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _checkboxController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkboxAnimation = CurvedAnimation(
      parent: _checkboxController,
      curve: Curves.elasticOut,
    );
  }

  void _animateCheckbox() {
    _checkboxController.forward().then(() {
      _checkboxController.reverse();
    } as FutureOr Function(void value));
  }

  // Updated Privacy Policy navigation with web URL
  Future<void> _showPrivacyPolicy() async {
    try {
      HapticFeedback.lightImpact();

      final Uri uri = Uri.parse(privacyPolicyUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        // Show confirmation dialog after launching URL
        if (mounted) {
          await Future.delayed(const Duration(seconds: 1));
          _showPrivacyPolicyConfirmationDialog();
        }
      } else {
        throw 'Could not launch $privacyPolicyUrl';
      }
    } catch (e) {
      //debugPrint('Error launching privacy policy: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error opening privacy policy. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showPrivacyPolicyConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.privacy_tip,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Privacy Policy",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          "Have you read and understood our Privacy Policy?",
          style: TextStyle(
            color: Colors.white70,
            height: 1.5,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Auto-tick the privacy policy checkbox
              setState(() {
                _privacyPolicyAccepted = true;
              });
              _animateCheckbox();
              HapticFeedback.mediumImpact();

              // Show success feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Color(0xFF00D4AA),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Privacy Policy accepted! ✓',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF00D4AA),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.all(16),
                  elevation: 6,
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Yes, I Accept"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "No, Let me read again",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }





  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least:\n- 1 uppercase letter\n- 1 lowercase letter\n- 1 number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;}

  // Updated Sign Up with Email Verification Requirement
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_privacyPolicyAccepted) {
      setState(() {
        _errorMessage = 'Please accept  Privacy Policy';
      });
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create Firebase Auth user
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;

        // Update display name
        await user.updateDisplayName(_nameController.text.trim());

        // Create Firestore document with email verification status
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'isOnline': false,
          'emailVerified': false, // Initially false
          'canAccessApp': false, // Cannot access app until email verified
          'privacyPolicyAccepted': true,
          'termsAccepted': true,
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        // Send email verification
        await user.sendEmailVerification();

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_unread, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Account created! Please verify your email to continue.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF00D4AA),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
              margin: const EdgeInsets.all(16),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));

          // Navigate to email verification screen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationScreen(
                  email: _emailController.text.trim(),
                  userName: _nameController.text.trim(),
                ),
              ),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account already exists with this email.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled.';
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your connection and try again.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please try again later.';
            break;
          default:
            errorMessage = 'Failed to create account: ${e.message}';
        }
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  _buildHeader(screenWidth),
                  SizedBox(height: screenHeight * 0.02),
                  _buildAvatar(screenWidth),
                  SizedBox(height: screenHeight * 0.03),
                  if (_errorMessage != null) _buildErrorMessage(),
                  _buildFormCard(screenWidth, screenHeight),
                  SizedBox(height: screenHeight * 0.025),
                  _buildLoginNavigation(screenWidth),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4AA).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch,
              size: 35,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
            ).createShader(bounds),
            child: Text(
              "Join the Coding Revolution!",
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
            "Your coding adventure starts here",
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
    );
  }

  Widget _buildAvatar(double screenWidth) {
    return ClipOval(
      child: Container(
        width: screenWidth * 0.25,
        height: screenWidth * 0.25,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
          ),
        ),
        child: Image.network(
          'https://res.cloudinary.com/dsgjptfqj/image/upload/v1749390711/image-removebg-preview_1_yudzkj.png',
          width: screenWidth * 0.25,
          height: screenWidth * 0.25,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
    );
  }

  Widget _buildFormCard(double screenWidth, double screenHeight) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, color: Colors.white.withOpacity(0.7), size: 20),
              const SizedBox(width: 8),
              Text(
                "Create your developer profile",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.025),
          _buildInputField(
            controller: _nameController,
            label: "Full Name",
            hint: "Enter your full name",
            icon: Icons.person_outline,
            validator: _validateName,
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildInputField(
            controller: _emailController,
            label: "Email",
            hint: "Enter your email",
            icon: Icons.email_outlined,
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildInputField(
            controller: _passwordController,
            label: "Password",
            hint: "Create password",
            icon: Icons.lock_outline,
            isPassword: true,
            isPasswordVisible: _isPasswordVisible,
            onVisibilityToggle: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
            validator: _validatePassword,
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildInputField(
            controller: _confirmPasswordController,
            label: "Confirm Password",
            hint: "Confirm your password",
            icon: Icons.lock_outline,
            isPassword: true,
            isPasswordVisible: _isConfirmPasswordVisible,
            onVisibilityToggle: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
            validator: _validateConfirmPassword,
          ),
          _buildLegalConsentSection(),
          SizedBox(height: screenHeight * 0.025),
          _buildSignUpButton(screenWidth, screenHeight),
          SizedBox(height: screenHeight * 0.02),
          _buildBenefitsSection(),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(double screenWidth, double screenHeight) {
    final bool isButtonEnabled = !_isLoading && _privacyPolicyAccepted ;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: isButtonEnabled ? _signUp : null,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isButtonEnabled
                  ? [const Color(0xFF00D4AA), const Color(0xFF00A8CC)]
                  : [Colors.grey, Colors.grey.shade600],
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
                const Icon(Icons.email, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Create Account & Verify Email",
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
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user,
                color: Color(0xFF00D4AA),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                "Secure & Verified Account Required",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBenefitItem("Email\nVerification", Icons.mark_email_read),
              _buildBenefitItem("Free\nCourses", Icons.school),
              _buildBenefitItem("Safe\n& Secure", Icons.security),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00D4AA), size: 18),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icon, color: Colors.white54),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.white54,
              ),
              onPressed: onVisibilityToggle,
            )
                : null,
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Updated Legal Consent Section with enhanced auto-tick functionality
  Widget _buildLegalConsentSection() {
    return Column(
      children: [
        // Privacy Policy Checkbox with auto-tick functionality
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _privacyPolicyAccepted
                ? const Color(0xFF00D4AA).withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _privacyPolicyAccepted
                  ? const Color(0xFF00D4AA).withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: CheckboxListTile(
            value: _privacyPolicyAccepted,
            onChanged: (value) {
              if (value == true) {
                _showPrivacyPolicy(); // This will auto-tick if accepted
              } else {
                setState(() => _privacyPolicyAccepted = false);
              }
            },
            title: Text.rich(
              TextSpan(
                text: "I agree to the ",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                children: [
                  TextSpan(
                    text: "Privacy Policy",
                    style: const TextStyle(
                      color: Color(0xFF00D4AA),
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _showPrivacyPolicy,
                  ),
                  const TextSpan(
                    text: " (tap to read)",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (_privacyPolicyAccepted)
                    const TextSpan(
                      text: " ✓ Read & Accepted",
                      style: TextStyle(
                        color: Color(0xFF00D4AA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            tileColor: Colors.transparent,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            activeColor: const Color(0xFF00D4AA),
            side: BorderSide(
              color: _privacyPolicyAccepted
                  ? const Color(0xFF00D4AA)
                  : Colors.white54,
              width: 2,
            ),
          ),
        ),


        // Success indicator when both are accepted
        if (_privacyPolicyAccepted)
          AnimatedBuilder(
            animation: _checkboxAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_checkboxAnimation.value * 0.05),
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00D4AA).withOpacity(0.3),
                        const Color(0xFF00A8CC).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00D4AA).withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4AA).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00D4AA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "All legal requirements accepted ✓",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF00D4AA),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLoginNavigation(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: _isLoading
            ? null
            : () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DarkLoginScreen(),
            ),
          );
        },
        child: Text.rich(
          TextSpan(
            text: "Already part of our community? ",
            style: TextStyle(
              color: Colors.white70,
              fontSize: screenWidth * 0.04,
            ),
            children: [
              TextSpan(
                text: "Welcome back!",
                style: TextStyle(
                  color: const Color(0xFF00D4AA),
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}