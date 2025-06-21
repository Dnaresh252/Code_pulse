import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';

// ✅ MODERN LOGOUT DIALOG - No changes needed, working correctly
class ModernLogoutDialog extends StatefulWidget {
  @override
  ModernLogoutDialogState createState() => ModernLogoutDialogState();
}

class ModernLogoutDialogState extends State<ModernLogoutDialog>
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

// ✅ FIXED DELETE ACCOUNT DIALOG - CRITICAL CHANGES MADE
class ModernDeleteAccountDialog extends StatefulWidget {
  final Future<void> Function() onConfirmDelete; // ⚠️ CHANGED: Now expects async function

  const ModernDeleteAccountDialog({required this.onConfirmDelete});

  @override
  ModernDeleteAccountDialogState createState() => ModernDeleteAccountDialogState();
}

class ModernDeleteAccountDialogState extends State<ModernDeleteAccountDialog>
    with SingleTickerProviderStateMixin {
  bool _isDeleting = false;
  bool _confirmationChecked = false;
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

  // ✅ ENHANCED RESPONSIVE HELPER METHODS
  bool _isSmallScreen(BuildContext context) => MediaQuery.of(context).size.width < 360;
  bool _isVerySmallScreen(BuildContext context) => MediaQuery.of(context).size.width < 320;

  double _getDialogPadding(BuildContext context) {
    if (_isVerySmallScreen(context)) return 12.0;
    if (_isSmallScreen(context)) return 16.0;
    return 20.0;
  }

  double _getTitleSize(BuildContext context) {
    if (_isVerySmallScreen(context)) return 16.0;
    if (_isSmallScreen(context)) return 18.0;
    return 20.0;
  }

  double _getBodySize(BuildContext context) {
    if (_isVerySmallScreen(context)) return 11.0;
    if (_isSmallScreen(context)) return 12.0;
    return 14.0;
  }

  double _getButtonTextSize(BuildContext context) {
    if (_isVerySmallScreen(context)) return 12.0;
    if (_isSmallScreen(context)) return 13.0;
    return 14.0;
  }

  double _getCaptionSize(BuildContext context) {
    if (_isVerySmallScreen(context)) return 9.0;
    if (_isSmallScreen(context)) return 10.0;
    return 11.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.95,
              maxHeight: screenHeight * 0.9,
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
                color: const Color(0xFFEF4444).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.all(_getDialogPadding(context)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Warning icon with animation
                            Container(
                              width: _isVerySmallScreen(context) ? 60 : (_isSmallScreen(context) ? 70 : 80),
                              height: _isVerySmallScreen(context) ? 60 : (_isSmallScreen(context) ? 70 : 80),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isDeleting
                                      ? [Colors.grey, Colors.grey.shade600]
                                      : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isDeleting ? Colors.grey : const Color(0xFFEF4444))
                                        .withOpacity(0.5),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: _isDeleting
                                  ? const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                                  : Icon(
                                Icons.warning_rounded,
                                color: Colors.white,
                                size: _isVerySmallScreen(context) ? 25 : (_isSmallScreen(context) ? 30 : 35),
                              ),
                            ),

                            SizedBox(height: _getDialogPadding(context)),

                            // Title
                            Text(
                              _isDeleting ? 'Deleting Account...' : 'Delete Account',
                              style: TextStyle(
                                color: const Color(0xFFEF4444),
                                fontSize: _getTitleSize(context),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: _getDialogPadding(context) * 0.5),

                            // Warning message
                            Container(
                              padding: EdgeInsets.all(_getDialogPadding(context) * 0.75),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: const Color(0xFFEF4444),
                                    size: _isVerySmallScreen(context) ? 20 : (_isSmallScreen(context) ? 24 : 28),
                                  ),
                                  SizedBox(height: _getDialogPadding(context) * 0.5),
                                  Text(
                                    'This action is PERMANENT and cannot be undone!',
                                    style: TextStyle(
                                      color: const Color(0xFFEF4444),
                                      fontSize: _getBodySize(context),
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: _getDialogPadding(context) * 0.25),
                                  Text(
                                    'All your data will be permanently deleted from our servers.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: _getCaptionSize(context),
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: _getDialogPadding(context)),

                            // Data deletion list
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.delete_forever,
                                        color: const Color(0xFFEF4444),
                                        size: _isVerySmallScreen(context) ? 16 : (_isSmallScreen(context) ? 18 : 20),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'The following data will be deleted:',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: _getBodySize(context),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: _getDialogPadding(context) * 0.5),
                                  ..._buildDataDeletionList(),
                                ],
                              ),
                            ),

                            SizedBox(height: _getDialogPadding(context)),

                            // Confirmation checkbox
                            Container(
                              padding: EdgeInsets.all(_getDialogPadding(context) * 0.75),
                              decoration: BoxDecoration(
                                color: const Color(0xFF475569),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _confirmationChecked
                                      ? const Color(0xFFEF4444)
                                      : Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Transform.scale(
                                    scale: _isVerySmallScreen(context) ? 0.8 : (_isSmallScreen(context) ? 0.9 : 1.0),
                                    child: Checkbox(
                                      value: _confirmationChecked,
                                      onChanged: _isDeleting ? null : (value) {
                                        setState(() {
                                          _confirmationChecked = value ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFFEF4444),
                                      checkColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: _getDialogPadding(context) * 0.5),
                                  Expanded(
                                    child: Text(
                                      'I understand this action is permanent and cannot be undone',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: _getCaptionSize(context),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: _getDialogPadding(context) * 1.5),

                            // Action buttons
                            Row(
                              children: [
                                // Cancel button
                                Expanded(
                                  child: Container(
                                    height: _isVerySmallScreen(context) ? 42 : (_isSmallScreen(context) ? 45 : 48),
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
                                        onTap: _isDeleting ? null : () => Navigator.of(context).pop(),
                                        child: Center(
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: _getButtonTextSize(context),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(width: _getDialogPadding(context) * 0.75),

                                // Delete button
                                Expanded(
                                  child: Container(
                                    height: _isVerySmallScreen(context) ? 42 : (_isSmallScreen(context) ? 45 : 48),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _isDeleting || !_confirmationChecked
                                            ? [Colors.grey, Colors.grey.shade600]
                                            : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: _confirmationChecked && !_isDeleting ? [
                                        BoxShadow(
                                          color: const Color(0xFFEF4444).withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ] : null,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: (_isDeleting || !_confirmationChecked)
                                            ? null
                                            : _handleDeleteAccount,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_isDeleting) ...[
                                                SizedBox(
                                                  width: _isVerySmallScreen(context) ? 12 : (_isSmallScreen(context) ? 14 : 16),
                                                  height: _isVerySmallScreen(context) ? 12 : (_isSmallScreen(context) ? 14 : 16),
                                                  child: const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                ),
                                              ] else ...[
                                                Icon(
                                                  Icons.delete_forever,
                                                  color: Colors.white,
                                                  size: _isVerySmallScreen(context) ? 14 : (_isSmallScreen(context) ? 16 : 18),
                                                ),
                                              ],
                                              SizedBox(width: _isVerySmallScreen(context) ? 4 : (_isSmallScreen(context) ? 6 : 8)),
                                              Flexible(
                                                child: Text(
                                                  _isDeleting ? 'Deleting...' : 'Delete Forever',
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
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDataDeletionList() {
    final dataItems = [
      'Profile information and settings',
      'All saved notes and documents',
      'Bookmarked videos and links',
      'Quiz results and learning progress',
      'Account preferences and history',
    ];

    return dataItems.map((item) => Padding(
      padding: EdgeInsets.only(bottom: _isVerySmallScreen(context) ? 2 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6),
            width: _isVerySmallScreen(context) ? 3 : 4,
            height: _isVerySmallScreen(context) ? 3 : 4,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: _isVerySmallScreen(context) ? 6 : 8),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                color: Colors.white70,
                fontSize: _getCaptionSize(context),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  // ✅ CRITICAL FIX: This is the main issue - the callback wasn't being awaited
  Future<void> _handleDeleteAccount() async {
    if (!_confirmationChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please confirm that you understand this action is permanent',
                  style: TextStyle(fontSize: _getCaptionSize(context)),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      print('🔄 Dialog: Starting account deletion...');

      // ⚠️ CRITICAL FIX: Now properly awaiting the async callback
      await widget.onConfirmDelete();

      print('✅ Dialog: Account deletion completed');

      // ⚠️ CRITICAL FIX: Don't close dialog immediately - let the ProfileScreen handle navigation
      // The dialog will be closed when the app navigates to login screen

    } catch (e) {
      print('❌ Dialog: Account deletion failed: $e');
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to delete account: ${e.toString()}',
                    style: TextStyle(fontSize: _getCaptionSize(context)),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}