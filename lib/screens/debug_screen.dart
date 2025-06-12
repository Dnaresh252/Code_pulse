import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../services/gemini_service.dart';
import '../models/programming_language.dart';

import '../widgets/code_editor.dart';


// Debug Note model for saving debug results
class DebugNote {
  final String id;
  final String code;
  final String language;
  final String debugResult;
  final DateTime timestamp;

  DebugNote({
    required this.id,
    required this.code,
    required this.language,
    required this.debugResult,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'language': language,
    'debugResult': debugResult,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DebugNote.fromJson(Map<String, dynamic> json) => DebugNote(
    id: json['id'],
    code: json['code'],
    language: json['language'],
    debugResult: json['debugResult'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  _DebugScreenState createState() => _DebugScreenState();
}
class _DebugScreenState extends State<DebugScreen>
    with TickerProviderStateMixin {
  final GeminiService _geminiService = GeminiService();
  String _selectedLanguage = ProgrammingLanguages.languages.first.name;
  String _code = '';
  String _response = '';
  bool _isLoading = false;
  AnimationController? _animationController;
  AnimationController? _cardAnimationController;
  Animation<double>? _cardSlideAnimation;
  Animation<double>? _cardFadeAnimation;
  List<DebugNote> _savedDebugs = [];
  bool _hasResponse = false;
  bool _isNoteSaved = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedDebugs();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )
      ..repeat();

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _cardSlideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController!,
      curve: Curves.elasticOut,
    ));

    _cardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _cardAnimationController?.dispose();
    super.dispose();
  }

  // Load saved debug notes from SharedPreferences
  Future<void> _loadSavedDebugs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return; // No user logged in
      final debugsJson = prefs.getStringList('${userId}_debug_notes') ?? [];
      setState(() {
        _savedDebugs = debugsJson
            .map((json) => DebugNote.fromJson(jsonDecode(json)))
            .toList();
      });
    } catch (e) {
      print('Error loading debug notes: $e');
    }
  }

  // Save debug notes to SharedPreferences
  Future<void> _saveDebugsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final debugsJson = _savedDebugs
          .map((debug) => jsonEncode(debug.toJson()))
          .toList();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return; // No user logged in
      await prefs.setStringList('${userId}_debug_notes', debugsJson);
    } catch (e) {
      print('Error saving debug notes: $e');
    }
  }

  // Debug code with AI
  Future<void> _debugCode() async {
    if (_code
        .trim()
        .isEmpty) {
      _showSnackBar(
          'Please enter some code to debug', Icons.warning_amber_rounded,
          Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _response = '';
      _hasResponse = false;
      _isNoteSaved = false;
    });

    try {
      final prompt = """
You are an expert ${_selectedLanguage} code debugger and analyzer. Analyze the following code and provide a comprehensive debugging report.

Please structure your response with:
1. **Code Analysis** - What the code is trying to do
2. **Issues Found** - List all bugs, errors, and potential problems
3. **Fixed Code** - Provide corrected version with improvements
4. **Explanation** - Explain what was wrong and why the fixes work
5. **Best Practices** - Suggest coding best practices for this type of code

Code to debug (${_selectedLanguage}):
```${_selectedLanguage.toLowerCase()}
${_code}
```

Make your analysis thorough and educational, suitable for helping developers learn from their mistakes.
""";

      final response = await _geminiService.getCodingHelp(prompt);

      setState(() {
        _response = response;
        _isLoading = false;
        _hasResponse = true;
      });

      _cardAnimationController?.reset();
      _cardAnimationController?.forward();
    } catch (e) {
      setState(() {
        _response = "Error: ${e.toString()}";
        _isLoading = false;
        _hasResponse = true;
      });
    }
  }

  // Save debug result
  Future<void> _saveDebug() async {
    if (_response.isNotEmpty && !_isNoteSaved) {
      final debug = DebugNote(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        code: _code,
        language: _selectedLanguage,
        debugResult: _response,
        timestamp: DateTime.now(),
      );

      setState(() {
        _savedDebugs.insert(0, debug);
        _isNoteSaved = true;
      });

      await _saveDebugsToStorage();
      _showSnackBar('Debug result saved successfully!', Icons.bookmark_added,
          Colors.green);
    }
  }

  // Delete debug note
  Future<void> _deleteDebug(String debugId) async {
    setState(() {
      _savedDebugs.removeWhere((debug) => debug.id == debugId);
    });
    await _saveDebugsToStorage();
    _showSnackBar('Debug note deleted!', Icons.delete, Colors.red);
  }

  // Utility methods
  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _copyToClipboard() {
    if (_response.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _response));
      _showSnackBar(
          'Debug result copied to clipboard!', Icons.copy, Colors.blue);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery
        .of(context)
        .orientation == Orientation.portrait;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      backgroundColor: Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1F2E),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.bug_report, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'Code Debugger',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                    Icons.bookmark_border, color: Colors.white, size: 26),
                onPressed: _showSavedDebugs,
                tooltip: 'Saved Debug Results',
              ),
              if (_savedDebugs.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${_savedDebugs.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1419), Color(0xFF1A1F2E)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Welcome Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🐛 Debug Your Code',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Find and fix bugs with AI-powered analysis!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Language Selection Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF23252C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Select Programming Language',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFF2A2D37),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        dropdownColor: Color(0xFF2A2D37),
                        isExpanded: true,
                        underline: SizedBox(),
                        style: TextStyle(color: Colors.white),
                        items: ProgrammingLanguages.languages
                            .map((lang) =>
                            DropdownMenuItem<String>(
                              value: lang.name,
                              child: Text(
                                '${lang.icon} ${lang.name}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Code Input Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF23252C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.code, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Enter Code to Debug',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      height: isPortrait ? 200 : 150,
                      decoration: BoxDecoration(
                        color: Color(0xFF2A2D37),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: CodeEditor(
                        language: _selectedLanguage,
                        onCodeChanged: (code) {
                          setState(() {
                            _code = code;
                          });
                        },
                        height: isPortrait ? 200 : 150,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Debug Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _debugCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(double.infinity, 56),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bug_report, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Debug Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Response Card
              if (_hasResponse || _isLoading)
                AnimatedBuilder(
                  animation: _cardAnimationController ??
                      AlwaysStoppedAnimation(1.0),
                  builder: (context, child) {
                    final slideValue = _cardSlideAnimation?.value ?? 0.0;
                    final fadeValue = _cardFadeAnimation?.value ?? 1.0;

                    return Transform.translate(
                      offset: Offset(0, slideValue),
                      child: Opacity(
                        opacity: fadeValue,
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color(0xFF23252C),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.red.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_response.isNotEmpty || _isLoading) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.auto_fix_high,
                                          color: Colors.white, size: 16),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _isLoading
                                            ? 'AI is debugging...'
                                            : 'Debug Results',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (_response.isNotEmpty) ...[
                                      IconButton(
                                        icon: Icon(
                                            Icons.copy, color: Colors.red),
                                        onPressed: _copyToClipboard,
                                        tooltip: 'Copy results',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          _isNoteSaved ? Icons.bookmark : Icons
                                              .bookmark_add,
                                          color: _isNoteSaved
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        onPressed: _isNoteSaved
                                            ? null
                                            : _saveDebug,
                                        tooltip: _isNoteSaved
                                            ? 'Saved!'
                                            : 'Save debug',
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 16),
                              ],

                              if (_response.isEmpty && !_isLoading)
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.bug_report_outlined, size: 48,
                                          color: Colors.grey[600]),
                                      SizedBox(height: 16),
                                      Text(
                                        'Ready to debug your code!',
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Paste your code above to get started',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                if (_isLoading)
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 80,
                                          width: 80,
                                          child: _animationController != null
                                              ? CustomCodeLoader(
                                              animation: _animationController!)
                                              : CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<
                                                Color>(Colors.red),
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        Text(
                                          '🔍 ${_selectedLanguage} AI is analyzing...',
                                          style: TextStyle(color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Finding bugs and suggesting fixes',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: 100,
                                      maxHeight: screenHeight * 0.6,
                                    ),
                                    child: SingleChildScrollView(
                                      child: MarkdownBody(
                                        data: _response,
                                        selectable: true,
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(color: Color(0xFFE0E0E0),
                                              fontSize: 15,
                                              height: 1.6),
                                          code: TextStyle(
                                              color: Color(0xFFFF6B6B),
                                              fontSize: 14,
                                              backgroundColor: Color(
                                                  0xFF1A1F2E)),
                                          codeblockDecoration: BoxDecoration(
                                            color: Color(0xFF1A1F2E),
                                            borderRadius: BorderRadius.circular(
                                                8),
                                            border: Border.all(
                                                color: Colors.red.withOpacity(
                                                    0.3), width: 1),
                                          ),
                                          codeblockPadding: EdgeInsets.all(16),
                                          h1: TextStyle(color: Colors.red,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold),
                                          h2: TextStyle(
                                              color: Color(0xFFFF8A80),
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                          h3: TextStyle(color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                          blockquote: TextStyle(
                                              color: Color(0xFFFFAB91),
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic),
                                          strong: TextStyle(color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                          listBullet: TextStyle(
                                              color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Show saved debug results bottom sheet
  void _showSavedDebugs() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1A1F2E),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery
              .of(context)
              .size
              .height * 0.8,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.bookmark, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Saved Debug Results (${_savedDebugs.length})',
                      style: TextStyle(color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.grey[400]),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: _savedDebugs.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bug_report_outlined, size: 64,
                          color: Colors.grey[600]),
                      SizedBox(height: 16),
                      Text('No saved debug results yet!',
                          style: TextStyle(color: Colors.grey[400],
                              fontSize: 18)),
                      SizedBox(height: 8),
                      Text('Debug your code and save the results',
                          style: TextStyle(color: Colors.grey[500],
                              fontSize: 14)),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _savedDebugs.length,
                  itemBuilder: (context, index) {
                    final debug = _savedDebugs[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF23252C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.red,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(debug.language, style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Debug Session',
                                  style: TextStyle(color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        AlertDialog(
                                          backgroundColor: Color(0xFF1A1F2E),
                                          title: Text('Delete Debug Result',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          content: Text('Are you sure?',
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text('Cancel',
                                                  style: TextStyle(
                                                      color: Colors.grey[400])),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                _deleteDebug(debug.id);
                                                Navigator.pop(context);
                                                Navigator.pop(context);
                                              },
                                              child: Text('Delete',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                                child: Icon(
                                    Icons.delete_outline, color: Colors.red,
                                    size: 20),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text('Code:', style: TextStyle(
                              color: Color(0xFFFF8A80),
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Color(0xFF1A1F2E),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              debug.code.length > 80 ? debug.code.substring(
                                  0, 80) + '...' : debug.code,
                              style: TextStyle(color: Color(0xFFFF6B6B),
                                  fontSize: 12,
                                  fontFamily: 'monospace'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Color(0xFF1A1F2E),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              debug.debugResult.length > 100 ? debug.debugResult
                                  .substring(0, 100) + '...' : debug
                                  .debugResult,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDate(debug.timestamp),
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12)),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(
                                          text: debug.debugResult));
                                      _showSnackBar(
                                          'Debug result copied!', Icons.copy,
                                          Colors.blue);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                              6)),
                                      child: Icon(Icons.copy, color: Colors.red,
                                          size: 16),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showDebugDetail(debug);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                              6)),
                                      child: Icon(
                                          Icons.visibility, color: Colors.green,
                                          size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDebugDetail(DebugNote debug) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1A1F2E),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) =>
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.9,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(debug.language, style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Debug Session', style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: Colors.grey[400]),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text('Original Code:', style: TextStyle(color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF23252C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      debug.code,
                      style: TextStyle(color: Color(0xFFFF6B6B),
                          fontSize: 14,
                          fontFamily: 'monospace'),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Text('Debug Analysis:', style: TextStyle(color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: debug.debugResult));
                        _showSnackBar(
                            'Debug result copied!', Icons.copy, Colors.blue);
                      },
                      child: Icon(Icons.copy, color: Colors.red),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Color(0xFF23252C),
                          borderRadius: BorderRadius.circular(12)),
                      child: MarkdownBody(
                        data: debug.debugResult,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(color: Color(0xFFE0E0E0),
                              fontSize: 15,
                              height: 1.6),
                          code: TextStyle(
                              color: Color(0xFFFF6B6B), fontSize: 14),
                          h1: TextStyle(color: Colors.red,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          h2: TextStyle(color: Color(0xFFFF8A80),
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          h3: TextStyle(color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text('Debugged on ${_formatDate(debug.timestamp)}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ],
            ),
          ),
    );
  }
}


// Custom loader widget for debug screen
class CustomCodeLoader extends StatelessWidget {
  final Animation<double> animation;

  const CustomCodeLoader({Key? key, required this.animation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: CodePainter(progress: animation.value),
          child: Container(),
        );
      },
    );
  }
}

class CodePainter extends CustomPainter {
  final double progress;

  CodePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(centerX, centerY) - 5;

    // Draw outer glow
    final glowPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(Offset(centerX, centerY), radius + 3, glowPaint);

    // Draw outline
    final outlinePaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(Offset(centerX, centerY), radius, outlinePaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Draw debug symbols with enhanced animation
    final symbols = ['🐛', '🔍', '⚠️', '🔧', '✅', '❌', '💡', '🚨'];
    final codeRadius = radius * 0.6;

    for (int i = 0; i < symbols.length; i++) {
      final angle = math.pi * 2 * i / symbols.length + progress * math.pi * 2;
      final x = centerX + codeRadius * math.cos(angle);
      final y = centerY + codeRadius * math.sin(angle);

      final opacity = 0.4 + 0.6 * math.sin(progress * math.pi * 2 + i);
      final scale = 0.8 + 0.4 * math.sin(progress * math.pi * 2 + i);

      final textSpan = TextSpan(
        text: symbols[i],
        style: TextStyle(fontSize: 16 * scale),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final paint = Paint()..color = Colors.white.withOpacity(opacity);
      canvas.saveLayer(
        Rect.fromCenter(
          center: Offset(x, y),
          width: textPainter.width,
          height: textPainter.height,
        ),
        paint,
      );

      textPainter.paint(canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CodePainter oldDelegate) => oldDelegate.progress != progress;
}
