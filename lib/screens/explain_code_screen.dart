import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:math' as math;
import '../services/gemini_service.dart';
import '../models/programming_language.dart';
import '../widgets/code_editor.dart';

class ExplainCodeScreen extends StatefulWidget {
  const ExplainCodeScreen({Key? key}) : super(key: key);

  @override
  _ExplainCodeScreenState createState() => _ExplainCodeScreenState();
}

class _ExplainCodeScreenState extends State<ExplainCodeScreen>
    with SingleTickerProviderStateMixin {
  final GeminiService _geminiService = GeminiService();
  String _selectedLanguage = ProgrammingLanguages.languages.first.name;
  String _code = '';
  String _response = '';
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _explainCode() async {
    if (_code.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter some code to explain')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final response =
          await _geminiService.explainCode(_code, _selectedLanguage);

      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = "Error: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Color(0xFF2E2E4E),
        elevation: 0,
        title: Text('Explain Code'),
      ),
      body: SafeArea(
    child: LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Your "Select language" dropdown
                Text('Select language:', style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF2E2E4E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    dropdownColor: Color(0xFF2E2E4E),
                    isExpanded: true,
                    underline: SizedBox(),
                    style: TextStyle(color: Colors.white),
                    items: ProgrammingLanguages.languages.map((lang) => DropdownMenuItem<String>(
                      value: lang.name,
                      child: Text('${lang.icon} ${lang.name}', style: TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(height: 16),

                // Code input label and editor
                Text('Enter code to explain:', style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(height: 8),

                // Make CodeEditor flexible, avoid fixed height if possible
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200,
                  ),
                  child: CodeEditor(
                    language: _selectedLanguage,
                    onCodeChanged: (code) {
                      setState(() {
                        _code = code;
                      });
                    },
                    // Remove height param or keep max height in ConstrainedBox
                  ),
                ),

                SizedBox(height: 16),

                // Explain Code button
                ElevatedButton(
                  onPressed: _isLoading ? null : _explainCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size(double.infinity, 50),
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
                      : Text(
                    'Explain Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                SizedBox(height: 24),

                // Response container: wrap in Flexible to take remaining space
                Flexible(
                  child: _response.isEmpty && !_isLoading
                      ? Center(
                    child: Text(
                      'Enter code to get an explanation',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  )
                      : Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF2E2E4E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isLoading
                        ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 80,
                            width: 80,
                            child: CustomCodeLoader(animation: _animationController),
                          ),
                          SizedBox(height: 24),
                          Text(
                            '${_selectedLanguage} AI is thinking...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Analyzing and explaining your code',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                        : SingleChildScrollView(
                      child: MarkdownBody(
                        data: _response,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                          code: TextStyle(
                            color: Colors.lightBlueAccent,
                            backgroundColor: Color(0xFF1E1E2E),
                            fontSize: 14,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Color(0xFF1E1E2E),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Color(0xFF3E3E5E), width: 1),
                          ),
                          h1: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          h2: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          h3: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          blockquote: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          strong: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    },
    ),
    ),

    );
  }
}

class CustomCodeLoader extends StatelessWidget {
  final Animation<double> animation;

  const CustomCodeLoader({
    Key? key,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: CodePainter(
            progress: animation.value,
          ),
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

    // Draw outline
    final outlinePaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(Offset(centerX, centerY), radius, outlinePaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Draw code symbols
    final codePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final symbols = ['{', '}', '<', '>', '(', ')', ';', '[', ']'];
    final codeRadius = radius * 0.7;

    for (int i = 0; i < 8; i++) {
      final angle = math.pi * 2 * i / 8 + progress * math.pi * 2;
      final x = centerX + codeRadius * math.cos(angle);
      final y = centerY + codeRadius * math.sin(angle);

      // Draw code symbol
      final textSpan = TextSpan(
        text: symbols[i % symbols.length],
        style: TextStyle(
          color: Colors.white
              .withOpacity(0.5 + 0.5 * math.sin(progress * math.pi * 2 + i)),
          fontSize: 12 + 4 * math.sin(progress * math.pi * 2 + i),
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(CodePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
