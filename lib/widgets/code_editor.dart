import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeEditor extends StatefulWidget {
  final String initialCode;
  final String language;
  final Function(String) onCodeChanged;
  final double height;

  const CodeEditor({
    Key? key,
    this.initialCode = '',
    required this.language,
    required this.onCodeChanged,
    this.height = 300,
  }) : super(key: key);

  @override
  _CodeEditorState createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode);
    _focusNode = FocusNode();
    _controller.addListener(() {
      widget.onCodeChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.language,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.content_copy, color: Colors.white),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: _controller.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Code copied to clipboard')),
                        );
                      },
                      tooltip: 'Copy to clipboard',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      iconSize: 20,
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _controller.clear();
                        });
                      },
                      tooltip: 'Clear code',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter your code here...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
                cursorColor: Colors.blue,
                cursorWidth: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
