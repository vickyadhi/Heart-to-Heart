import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/connection_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

enum StrokeType { freehand, line, circle, rect }

class DrawingPoint {
  final Offset? offset;
  final Paint paint;
  final StrokeType type;

  DrawingPoint({
    this.offset,
    required this.paint,
    this.type = StrokeType.freehand,
  });
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double size;
  final StrokeType type;
  final bool isEraser;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.size,
    this.type = StrokeType.freehand,
    this.isEraser = false,
  });
}

class LoveDrawPage extends StatefulWidget {
  final String? initialBase64Drawing; // Partner's drawing to display/reply to

  const LoveDrawPage({super.key, this.initialBase64Drawing});

  @override
  State<LoveDrawPage> createState() => _LoveDrawPageState();
}

class _LoveDrawPageState extends State<LoveDrawPage> {
  final List<DrawingStroke> _strokes = [];
  final List<DrawingStroke> _redoHistory = [];
  
  List<Offset> _currentPoints = [];
  Color _currentColor = const Color(0xFFF05053); // Default neon primary
  double _brushSize = 5.0;
  StrokeType _currentType = StrokeType.freehand;
  bool _isEraser = false;
  bool _isSending = false;

  final GlobalKey _canvasKey = GlobalKey();

  final List<Color> _neonColors = [
    const Color(0xFFF05053), // Neon Brand Pink
    const Color(0xFFFF9F0A), // Neon Orange
    const Color(0xFFFFD60A), // Neon Yellow
    const Color(0xFF30E3CA), // Neon Teal
    const Color(0xFF00F2FE), // Neon Cyan
    const Color(0xFFBF5AF2), // Neon Purple
    const Color(0xFFFFFFFF), // White
  ];

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _redoHistory.add(_strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      setState(() {
        _strokes.add(_redoHistory.removeLast());
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _redoHistory.clear();
      _currentPoints.clear();
    });
  }

  Future<void> _sendDrawing() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draw something sweet first!')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1. Capture drawing canvas as PNG bytes using RepaintBoundary
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Failed to find canvas render boundary.");
      
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Failed to serialize canvas image.");
      
      final bytes = byteData.buffer.asUint8List();
      final base64Drawing = base64Encode(bytes);

      // 2. Upload to Firestore and trigger FCM via ConnectionService
      final conn = Provider.of<ConnectionService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      
      await conn.sendLoveEvent('love_draw', message: base64Drawing);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Drawing sent successfully to ${auth.currentUser?.partnerName ?? 'Partner'}!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send drawing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B13), // Deep romantic space background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Love Draw',
          style: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded, color: Colors.white),
            onPressed: _strokes.isEmpty ? null : _undo,
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded, color: Colors.white),
            onPressed: _redoHistory.isEmpty ? null : _redo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: _strokes.isEmpty ? null : _clear,
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas Space
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16121E),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  children: [
                    // A. Display partner's drawing if replying
                    if (widget.initialBase64Drawing != null)
                      Opacity(
                        opacity: 0.35, // Ghost overlay of partner's drawing
                        child: Center(
                          child: Image.memory(
                            base64Decode(widget.initialBase64Drawing!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      
                    // B. Interactive paint canvas area
                    RepaintBoundary(
                      key: _canvasKey,
                      child: GestureDetector(
                        onPanStart: (details) {
                          _redoHistory.clear();
                          setState(() {
                            _currentPoints = [details.localPosition];
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _currentPoints.add(details.localPosition);
                          });
                        },
                        onPanEnd: (_) {
                          if (_currentPoints.isNotEmpty) {
                            setState(() {
                              _strokes.add(
                                DrawingStroke(
                                  points: List.from(_currentPoints),
                                  color: _isEraser ? const Color(0xFF16121E) : _currentColor,
                                  size: _brushSize,
                                  type: _currentType,
                                  isEraser: _isEraser,
                                ),
                              );
                              _currentPoints.clear();
                            });
                          }
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: double.infinity,
                          height: double.infinity,
                          child: CustomPaint(
                            painter: DrawingPainter(
                              strokes: _strokes,
                              currentPoints: _currentPoints,
                              currentColor: _isEraser ? const Color(0xFF16121E) : _currentColor,
                              currentSize: _brushSize,
                              currentType: _currentType,
                              isEraser: _isEraser,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tools Panel
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            decoration: BoxDecoration(
              color: const Color(0xFF161220),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Color Picker Row (horizontal scrolling)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Eraser option
                      GestureDetector(
                        onTap: () => setState(() => _isEraser = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: _isEraser ? AppTheme.primary : const ui.Color(0xFF221B2F),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cleaning_services_rounded,
                            color: _isEraser ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                      
                      // Divider
                      Container(width: 1, height: 28, color: Colors.white12, margin: const EdgeInsets.only(right: 12)),
                      
                      // Colors List
                      ..._neonColors.map((color) {
                        final isSelected = !_isEraser && _currentColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _isEraser = false;
                              _currentColor = color;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: isSelected ? 8 : 2,
                                  spreadRadius: isSelected ? 1 : 0,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Controls: Brush size & Tool selections
                Row(
                  children: [
                    // Brush Size label and slider
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.blur_on_rounded, color: Colors.grey, size: 20),
                          Expanded(
                            child: Slider(
                              value: _brushSize,
                              min: 2.0,
                              max: 20.0,
                              activeColor: AppTheme.primary,
                              inactiveColor: const Color(0xFF221B2F),
                              onChanged: (val) => setState(() => _brushSize = val),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Shapes and Freehand buttons
                    Row(
                      children: [
                        _buildToolButton(StrokeType.freehand, Icons.gesture_rounded),
                        const SizedBox(width: 6),
                        _buildToolButton(StrokeType.line, Icons.horizontal_rule_rounded),
                        const SizedBox(width: 6),
                        _buildToolButton(StrokeType.circle, Icons.radio_button_unchecked_rounded),
                        const SizedBox(width: 6),
                        _buildToolButton(StrokeType.rect, Icons.check_box_outline_blank_rounded),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. Send Drawing Button
                ElevatedButton(
                  onPressed: _isSending ? null : _sendDrawing,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Send Drawing to Partner',
                          style: GoogleFonts.quicksand(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(StrokeType type, IconData icon) {
    final isSelected = _currentType == type;
    return GestureDetector(
      onTap: () => setState(() => _currentType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFF221B2F),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey,
          size: 16,
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentSize;
  final StrokeType currentType;
  final bool isEraser;

  DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentSize,
    required this.currentType,
    required this.isEraser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // A. Draw all completed historical strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.size, stroke.type, stroke.isEraser);
    }

    // B. Draw current active user drawing stroke in real-time
    if (currentPoints.isNotEmpty) {
      _drawStroke(canvas, currentPoints, currentColor, currentSize, currentType, isEraser);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> pts, Color col, double sz, StrokeType type, bool eraser) {
    if (pts.isEmpty) return;

    final paint = Paint()
      ..color = col
      ..strokeCap = StrokeCap.round
      ..strokeWidth = sz
      ..style = ui.PaintingStyle.stroke;

    // Neon glowing brush stroke filters (shadows & blurs, ignored for eraser)
    if (!eraser && col != Colors.white) {
      paint.imageFilter = ui.ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8);
    }

    if (type == StrokeType.freehand) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, paint);
    } else {
      // Shape logic based on start and endpoints
      final start = pts.first;
      final end = pts.last;

      if (type == StrokeType.line) {
        canvas.drawLine(start, end, paint);
      } else if (type == StrokeType.circle) {
        final radius = (end - start).distance / 2.0;
        final center = Offset((start.dx + end.dx) / 2.0, (start.dy + end.dy) / 2.0);
        canvas.drawCircle(center, radius, paint);
      } else if (type == StrokeType.rect) {
        canvas.drawRect(Rect.fromPoints(start, end), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
