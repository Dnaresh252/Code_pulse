import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../services/gemini_service.dart';
import '../models/programming_language.dart';
import 'debug_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Simple Note model for AI answers
class CodingNote {
  final String id;
  final String question;
  final String language;
  final String answer;
  final DateTime timestamp;

  CodingNote({
    required this.id,
    required this.question,
    required this.language,
    required this.answer,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'language': language,
    'answer': answer,
    'timestamp': timestamp.toIso8601String(),
  };

  factory CodingNote.fromJson(Map<String, dynamic> json) => CodingNote(
    id: json['id'],
    question: json['question'],
    language: json['language'],
    answer: json['answer'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class CodingHelpScreen extends StatefulWidget {
  const CodingHelpScreen({Key? key}) : super(key: key);

  @override
  _CodingHelpScreenState createState() => _CodingHelpScreenState();
}
class _CodingHelpScreenState extends State<CodingHelpScreen>
    with TickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  String _selectedLanguage = ProgrammingLanguages.languages.first.name;
  String _response = '';
  bool _isLoading = false;
  AnimationController? _animationController;
  AnimationController? _cardAnimationController;
  Animation<double>? _cardSlideAnimation;
  Animation<double>? _cardFadeAnimation;
  List<CodingNote> _savedNotes = [];
  bool _hasResponse = false;
  bool _isNoteSaved = false;

  get progress => null;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedNotes();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();

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
    _questionController.dispose();
    _animationController?.dispose();
    _cardAnimationController?.dispose();
    super.dispose();
  }
  // Load saved notes from SharedPreferences
  Future<void> _loadSavedNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return; // No user logged in
      final notesJson = prefs.getStringList('${userId}_coding_notes') ?? [];
      setState(() {
        _savedNotes = notesJson
            .map((json) => CodingNote.fromJson(jsonDecode(json)))
            .toList();
      });
    } catch (e) {
      print('Error loading notes: $e');
    }
  }

  // Save notes to SharedPreferences
  Future<void> _saveNotesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = _savedNotes
          .map((note) => jsonEncode(note.toJson()))
          .toList();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return; // No user logged in
      await prefs.setStringList('${userId}_coding_notes', notesJson);
    } catch (e) {
      print('Error saving notes: $e');
    }
  }

  // Get AI response
  Future<void> _getResponse() async {
    if (_questionController.text.trim().isEmpty) {
      _showSnackBar('Please enter a question', Icons.warning_amber_rounded, Colors.orange);
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
You are an expert ${_selectedLanguage} developer and coding tutor. Provide a helpful, clear, and educational response to the following question. 

Structure your response with:
1. Brief explanation of the concept
2. Step-by-step solution with code examples
3. Best practices and tips
4. Common mistakes to avoid

Question: ${_questionController.text}

Make it beginner-friendly while being comprehensive for ${_selectedLanguage} development.
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

  // Save note
  Future<void> _saveNote() async {
    if (_response.isNotEmpty && !_isNoteSaved) {
      final note = CodingNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: _questionController.text,
        language: _selectedLanguage,
        answer: _response,
        timestamp: DateTime.now(),
      );

      setState(() {
        _savedNotes.insert(0, note);
        _isNoteSaved = true;
      });

      await _saveNotesToStorage();
      _showSnackBar('Note saved successfully!', Icons.bookmark_added, Colors.green);
    }
  }

  // Delete note
  Future<void> _deleteNote(String noteId) async {
    setState(() {
      _savedNotes.removeWhere((note) => note.id == noteId);
    });
    await _saveNotesToStorage();
    _showSnackBar('Note deleted!', Icons.delete, Colors.red);
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
      _showSnackBar('Answer copied to clipboard!', Icons.copy, Colors.blue);
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
                  color: Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.code, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Coding Assistant',
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
                  onPressed: _showSavedNotes,
                  tooltip: 'Saved Notes',
                ),
                if (_savedNotes.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '${_savedNotes.length}',
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
                          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF3B82F6).withOpacity(0.3),
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
                                  '👋 Ready to Code?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Ask any coding question and get detailed explanations!',
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
                              Icons.lightbulb_outline,
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
                        border: Border.all(
                            color: Color(0xFF3B82F6).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.language, color: Color(0xFF3B82F6),
                                  size: 20),
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
                              border: Border.all(color: Color(0xFF3B82F6)
                                  .withOpacity(0.5)),
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

                    // Question Input Card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF23252C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Color(0xFF3B82F6).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.help_outline, color: Color(0xFF3B82F6),
                                  size: 20),
                              SizedBox(width: 8),
                              Text(
                                'What would you like to learn?',
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            constraints: BoxConstraints(
                              maxHeight: isPortrait
                                  ? screenHeight * 0.2
                                  : screenHeight * 0.3,
                              minHeight: 120,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2D37),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFF3B82F6)
                                  .withOpacity(0.5)),
                            ),
                            child: TextField(
                              controller: _questionController,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16),
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: InputDecoration(
                                hintText: 'E.g., How do I implement a binary search tree?\nExplain recursion with examples\nWhat are design patterns?',
                                hintStyle: TextStyle(
                                  color: Color(0xFFB0B0B0),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Ask Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF3B82F6).withOpacity(0.4),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _getResponse,
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            strokeWidth: 2.0,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology, color: Colors.white,
                                size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Get Smart Answer',
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

                    // Response Card (continues in Part 5)
                    // Response Card (add this before the closing brackets of ListView children)
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
                                      color: Color(0xFF3B82F6).withOpacity(
                                          0.3)),
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
                                              color: Color(0xFF3B82F6),
                                              borderRadius: BorderRadius
                                                  .circular(8),
                                            ),
                                            child: Icon(Icons.auto_awesome,
                                                color: Colors.white, size: 16),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _isLoading
                                                  ? 'AI is thinking...'
                                                  : 'Your Answer',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (_response.isNotEmpty) ...[
                                            IconButton(
                                              icon: Icon(Icons.copy,
                                                  color: Color(0xFF3B82F6)),
                                              onPressed: _copyToClipboard,
                                              tooltip: 'Copy answer',
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                _isNoteSaved
                                                    ? Icons.bookmark
                                                    : Icons.bookmark_add,
                                                color: _isNoteSaved ? Colors
                                                    .green : Color(0xFF3B82F6),
                                              ),
                                              onPressed: _isNoteSaved
                                                  ? null
                                                  : _saveNote,
                                              tooltip: _isNoteSaved
                                                  ? 'Saved!'
                                                  : 'Save note',
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
                                            Icon(Icons.chat_bubble_outline,
                                                size: 48,
                                                color: Colors.grey[600]),
                                            SizedBox(height: 16),
                                            Text(
                                              'Ready to help you learn!',
                                              style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Ask any coding question to get started',
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
                                                child: _animationController !=
                                                    null
                                                    ? CustomCodeLoader(
                                                    animation: _animationController!)
                                                    : CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<
                                                      Color>(Color(0xFF3B82F6)),
                                                ),
                                              ),
                                              SizedBox(height: 24),
                                              Text(
                                                '🤖 ${_selectedLanguage} Expert is working...',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight
                                                        .w600),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Crafting a detailed explanation just for you',
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
                                            maxHeight: MediaQuery
                                                .of(context)
                                                .size
                                                .height * 0.6,
                                          ),
                                          child: SingleChildScrollView(
                                            child: MarkdownBody(
                                              data: _response,
                                              selectable: true,
                                              styleSheet: MarkdownStyleSheet(
                                                p: TextStyle(
                                                    color: Color(0xFFE0E0E0),
                                                    fontSize: 15,
                                                    height: 1.6),
                                                code: TextStyle(
                                                    color: Color(0xFF7DD3FC),
                                                    fontSize: 14,
                                                    backgroundColor: Color(
                                                        0xFF1A1F2E)),
                                                codeblockDecoration: BoxDecoration(
                                                  color: Color(0xFF1A1F2E),
                                                  borderRadius: BorderRadius
                                                      .circular(8),
                                                  border: Border.all(
                                                      color: Color(0xFF3B82F6)
                                                          .withOpacity(0.3),
                                                      width: 1),
                                                ),
                                                codeblockPadding: EdgeInsets
                                                    .all(16),
                                                h1: TextStyle(
                                                    color: Color(0xFF3B82F6),
                                                    fontSize: 24,
                                                    fontWeight: FontWeight
                                                        .bold),
                                                h2: TextStyle(
                                                    color: Color(0xFF60A5FA),
                                                    fontSize: 20,
                                                    fontWeight: FontWeight
                                                        .bold),
                                                h3: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight
                                                        .w600),
                                                blockquote: TextStyle(
                                                    color: Color(0xFF10B981),
                                                    fontSize: 14,
                                                    fontStyle: FontStyle
                                                        .italic),
                                                strong: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight
                                                        .bold),
                                                listBullet: TextStyle(
                                                    color: Color(0xFF3B82F6)),
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
                )
            )
        )
    );
  }

// Fix 1: Close the build method properly
// Around line 400, after the ListView children, add these closing brackets:



// Fix 2: Move _showSavedNotes method inside the class
// The _showSavedNotes method should be inside the _CodingHelpScreenState class
void _showSavedNotes() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Color(0xFF1A1F2E),
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
    ),
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.bookmark, color: Color(0xFF3B82F6)),
                SizedBox(width: 12),
                Text(
                    'Saved Notes (${_savedNotes.length})',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                    )
                ),
                Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.grey[400]),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: _savedNotes.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_add, size: 64, color: Colors.grey[600]),
                    SizedBox(height: 16),
                    Text(
                        'No saved notes yet!',
                        style: TextStyle(color: Colors.grey[400], fontSize: 18)
                    ),
                    SizedBox(height: 8),
                    Text(
                        'Save your AI answers to review later',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14)
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _savedNotes.length,
                itemBuilder: (context, index) {
                  final note = _savedNotes[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF23252C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Color(0xFF3B82F6).withOpacity(0.3)
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(8)
                              ),
                              child: Text(
                                  note.language,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold
                                  )
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                note.question.length > 40
                                    ? note.question.substring(0, 40) + '...'
                                    : note.question,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Color(0xFF1A1F2E),
                                    title: Text(
                                        'Delete Note',
                                        style: TextStyle(color: Colors.white)
                                    ),
                                    content: Text(
                                        'Are you sure?',
                                        style: TextStyle(color: Colors.white70)
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                            'Cancel',
                                            style: TextStyle(color: Colors.grey[400])
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteNote(note.id);
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red)
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Q: ${note.question}',
                          style: TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 14
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Color(0xFF1A1F2E),
                              borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                            note.answer.length > 100
                                ? note.answer.substring(0, 100) + '...'
                                : note.answer,
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                _formatDate(note.timestamp),
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12
                                )
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: note.answer)
                                    );
                                    _showSnackBar(
                                        'Answer copied!',
                                        Icons.copy,
                                        Colors.blue
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color: Color(0xFF3B82F6).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6)
                                    ),
                                    child: Icon(
                                        Icons.copy,
                                        color: Color(0xFF3B82F6),
                                        size: 16
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showNoteDetail(note);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6)
                                    ),
                                    child: Icon(
                                        Icons.visibility,
                                        color: Colors.green,
                                        size: 16
                                    ),
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

// Fix 3: Add the missing _showNoteDetail method
void _showNoteDetail(CodingNote note) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Color(0xFF1A1F2E),
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
    ),
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8)
                ),
                child: Text(
                    note.language,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    )
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                    'Saved Note',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    )
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: Colors.grey[400]),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
              'Question:',
              style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              )
          ),
          SizedBox(height: 8),
          Text(
              note.question,
              style: TextStyle(color: Colors.white, fontSize: 15)
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Text(
                  'Answer:',
                  style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                  )
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: note.answer));
                  _showSnackBar('Answer copied!', Icons.copy, Colors.blue);
                },
                child: Icon(Icons.copy, color: Color(0xFF3B82F6)),
              ),
            ],
          ),
          SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Color(0xFF23252C),
                    borderRadius: BorderRadius.circular(12)
                ),
                child: MarkdownBody(
                  data: note.answer,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 15,
                        height: 1.6
                    ),
                    code: TextStyle(
                        color: Color(0xFF7DD3FC),
                        fontSize: 14
                    ),
                    h1: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                    ),
                    h2: TextStyle(
                        color: Color(0xFF60A5FA),
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
              'Saved on ${_formatDate(note.timestamp)}',
              style: TextStyle(color: Colors.grey[400], fontSize: 14)
          ),
        ],
      ),
    ),
  );
}

// Fix 4: Fix the CodePainter paint method
// In the CodePainter class, fix the paint method:
@override
void paint(Canvas canvas, Size size) {
  final centerX = size.width / 2;
  final centerY = size.height / 2;
  final radius = math.min(centerX, centerY) - 5;

  // Draw outer glow
  final glowPaint = Paint()
    ..color = Color(0xFF3B82F6).withOpacity(0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

  canvas.drawCircle(Offset(centerX, centerY), radius + 3, glowPaint);

  // Draw outline
  final outlinePaint = Paint()
    ..color = Color(0xFF3B82F6).withOpacity(0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  canvas.drawCircle(Offset(centerX, centerY), radius, outlinePaint);

  // Draw progress arc
  final progressPaint = Paint()
    ..color = Color(0xFF3B82F6)
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

  // Draw code symbols with enhanced animation
  final symbols = ['💻', '🔧', '⚡', '🚀', '💡', '🎯', '✨', '🔥'];
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

    textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2)
    );

    canvas.restore();
  }

}
  @override
  bool shouldRepaint(CodePainter oldDelegate) => oldDelegate.progress != progress;
}