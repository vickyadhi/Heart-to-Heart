import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/connection_service.dart';
import '../theme.dart';

class WriteNotePage extends StatefulWidget {
  const WriteNotePage({super.key});

  @override
  State<WriteNotePage> createState() => _WriteNotePageState();
}

class _WriteNotePageState extends State<WriteNotePage> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    _controller = TextEditingController(text: auth.currentUser?.stickyNote ?? '');
    
    // Focus the text field automatically after page transition
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String text, ConnectionService conn) {
    // Notify partner that user is typing
    conn.onUserTypingNote();
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      conn.onUserStoppedTypingNote();
    });
  }

  void _saveNote(AuthService auth, ConnectionService conn) async {
    final noteText = _controller.text.trim();
    conn.onUserStoppedTypingNote();
    await auth.updateStickyNote(noteText);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Note saved & shared with partner! ❤️', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final conn = Provider.of<ConnectionService>(context);
    final partnerName = conn.partnerDisplayName ?? 'Partner';

    return Container(
      decoration: AppTheme.romanticGradient(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
            onPressed: () {
              conn.onUserStoppedTypingNote();
              Navigator.pop(context);
            },
          ),
          title: Text(
            'Write to $partnerName',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFBEB), // Soft creme ivory paper
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFE6E5D0),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Custom Painter for Ruled Lines background
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _NotebookLinesPainter(),
                            ),
                          ),
                          
                          // TextField
                          Positioned.fill(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C2525),
                                height: 1.5, // 24.0 px line spacing (16 * 1.5)
                              ),
                              onChanged: (text) => _onTextChanged(text, conn),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.fromLTRB(56, 12, 16, 16), // 56px left leaves room for margin line
                                hintText: 'Write your thoughts here...',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.withOpacity(0.6),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bottom Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Row(
                  children: [
                    // Erase Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (auth.currentUser?.vibrationEnabled ?? true) {
                            HapticFeedback.selectionClick();
                          }
                          _controller.clear();
                          _onTextChanged('', conn);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Erase',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Save Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _saveNote(auth, conn),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotebookLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw left red margin line
    final marginPaint = Paint()
      ..color = const Color(0xFFFFB3B3) // Soft pinkish red vertical line
      ..strokeWidth = 1.5;
    
    canvas.drawLine(
      const Offset(44, 0),
      Offset(44, size.height),
      marginPaint,
    );

    // 2. Draw horizontal blue notebook rules
    final linePaint = Paint()
      ..color = const Color(0xFFDCDBC9) // Soft blue/grey notebook line
      ..strokeWidth = 1.0;

    const double lineSpacing = 24.0; // matching height of 1.5 with font size 16
    const double topOffset = 12.0 + 13.0; // padding top (12) + text baseline alignment offset (13)

    final int numberOfLines = (size.height / lineSpacing).floor();
    for (int i = 0; i < numberOfLines; i++) {
      final y = topOffset + (i * lineSpacing);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
