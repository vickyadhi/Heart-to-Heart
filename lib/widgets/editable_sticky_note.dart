import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditableStickyNote extends StatefulWidget {
  final String name;
  final String content;
  final Color color;
  final Color lineColor;
  final Color nameColor;
  final bool isEditable;
  final Function(String)? onSave;
  final VoidCallback? onTyping;     // called while actively typing
  final VoidCallback? onStopTyping; // called when typing stops / unfocused
  final bool isTypingHint;          // shows "✏️ typing..." on read-only side

  const EditableStickyNote({
    super.key,
    required this.name,
    required this.content,
    required this.color,
    required this.lineColor,
    required this.nameColor,
    required this.isEditable,
    this.onSave,
    this.onTyping,
    this.onStopTyping,
    this.isTypingHint = false,
  });

  @override
  State<EditableStickyNote> createState() => _EditableStickyNoteState();
}

class _EditableStickyNoteState extends State<EditableStickyNote> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
  }

  @override
  void didUpdateWidget(covariant EditableStickyNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controller if content changed from the outside AND user is not actively editing
    if (widget.content != oldWidget.content && widget.content != _controller.text) {
      final oldSelection = _controller.selection;
      _controller.text = widget.content;
      try {
        _controller.selection = oldSelection;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    widget.onTyping?.call();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      widget.onSave?.call(text);
      widget.onStopTyping?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    const double lineSpacing = 24.0;
    const int lineCount = 5;
    const double headerH = 28.0;
    const double topPad = 10.0;
    const double firstLineY = topPad + headerH + 4;

    return Container(
      constraints: const BoxConstraints(minHeight: 168),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Ruled lines background
            Positioned.fill(
              child: CustomPaint(
                painter: _RuledLinePainter(
                  lineColor: widget.lineColor,
                  lineSpacing: lineSpacing,
                  topOffset: topPad + headerH + 19.5,
                  lineCount: lineCount,
                ),
              ),
            ),

            // Content padding
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pin + Name header
                  SizedBox(
                    height: headerH,
                    child: Row(
                      children: [
                        Icon(Icons.push_pin_rounded, size: 13, color: widget.nameColor.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: widget.isTypingHint
                              ? Row(
                                  children: [
                                    Text(
                                      widget.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: widget.nameColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '✏️ typing…',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 10,
                                        color: widget.nameColor.withOpacity(0.7),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  widget.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.quicksand(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: widget.nameColor,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: lineSpacing * lineCount,
                    child: widget.isEditable
                        ? TextField(
                            controller: _controller,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                              height: lineSpacing / 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Write a note...',
                              hintStyle: GoogleFonts.quicksand(
                                fontSize: 13,
                                color: widget.nameColor.withOpacity(0.45),
                                height: lineSpacing / 13,
                              ),
                              border: const OutlineInputBorder(borderSide: BorderSide.none),
                              enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
                              focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none),
                              disabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
                              errorBorder: const OutlineInputBorder(borderSide: BorderSide.none),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              fillColor: Colors.transparent,
                              filled: false,
                            ),
                            onChanged: _onChanged,
                            onTapOutside: (_) {
                              FocusScope.of(context).unfocus();
                              widget.onSave?.call(_controller.text);
                              widget.onStopTyping?.call();
                            },
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: widget.content.isEmpty
                                ? Text(
                                    '(no note yet)',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 12,
                                      color: widget.nameColor.withOpacity(0.4),
                                      fontStyle: FontStyle.italic,
                                      height: lineSpacing / 13,
                                    ),
                                  )
                                : Text(
                                    widget.content,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF333333),
                                      height: lineSpacing / 13,
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
    );
  }
}

class _RuledLinePainter extends CustomPainter {
  final Color lineColor;
  final double lineSpacing;
  final double topOffset;
  final int lineCount;

  _RuledLinePainter({
    required this.lineColor,
    required this.lineSpacing,
    required this.topOffset,
    required this.lineCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < lineCount; i++) {
      final y = topOffset + (i * lineSpacing);
      canvas.drawLine(
        Offset(12, y),
        Offset(size.width - 12, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RuledLinePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.lineSpacing != lineSpacing ||
        oldDelegate.topOffset != topOffset ||
        oldDelegate.lineCount != lineCount;
  }
}
