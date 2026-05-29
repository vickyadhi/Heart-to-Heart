import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

class FloatingHeartsOverlay extends StatefulWidget {
  final Widget child;

  const FloatingHeartsOverlay({super.key, required this.child});

  @override
  State<FloatingHeartsOverlay> createState() => FloatingHeartsOverlayState();
}

class _FloatingHeart {
  final double startX;
  final double scale;
  final Color color;
  final String symbol; // Emoji or '❤️'
  double y = 0.0;
  double drift = 0.0;
  double speed = 1.0;
  double opacity = 0.8;
  double angle = 0.0;

  _FloatingHeart({
    required this.startX,
    required this.scale,
    required this.color,
    required this.speed,
    required this.symbol,
  });
}

class FloatingHeartsOverlayState extends State<FloatingHeartsOverlay> with SingleTickerProviderStateMixin {
  final List<_FloatingHeart> _hearts = [];
  late AnimationController _animController;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        setState(() {
          for (var i = _hearts.length - 1; i >= 0; i--) {
            final h = _hearts[i];
            h.y += h.speed * 3.8;
            h.drift = sin(h.y / 20) * 18;
            h.opacity = (1.0 - (h.y / 280)).clamp(0.0, 0.8);
            h.angle += 0.02 * (_rand.nextBool() ? 1 : -1);
            if (h.y >= 280) {
              _hearts.removeAt(i);
            }
          }
        });
        if (_hearts.isEmpty && _animController.isAnimating) {
          _animController.stop();
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Spawns a beautiful burst of floating heart or specific emoji particles!
  void spawnHearts({String emoji = '❤️'}) {
    final colors = [
      AppTheme.primary.withOpacity(0.8),
      AppTheme.accent.withOpacity(0.8),
      const Color(0xFFFF5278),
      const Color(0xFFFFB0C1),
    ];
    
    setState(() {
      for (int i = 0; i < 8; i++) {
        _hearts.add(_FloatingHeart(
          startX: _rand.nextDouble() * 120 - 60, // spawn around center
          scale: _rand.nextDouble() * 0.7 + 0.4, // varying sizes
          color: colors[_rand.nextInt(colors.length)],
          speed: _rand.nextDouble() * 0.9 + 0.7, // varying speeds
          symbol: emoji,
        ));
      }
    });

    if (!_animController.isAnimating) {
      _animController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // HEARTS/EMOJIS CANVAS LAYER
        IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _HeartsPainter(_hearts),
          ),
        ),
      ],
    );
  }
}

class _HeartsPainter extends CustomPainter {
  final List<_FloatingHeart> hearts;

  _HeartsPainter(this.hearts);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    // Spawn baseline at the lower middle of screen (right above navigation bar)
    final centerY = size.height * 0.48; 

    for (final h in hearts) {
      canvas.save();
      // Translate to position
      canvas.translate(centerX + h.startX + h.drift, centerY - h.y);
      canvas.scale(h.scale);
      canvas.rotate(h.angle);

      if (h.symbol == '❤️') {
        final paint = Paint()
          ..color = h.color.withOpacity(h.opacity)
          ..style = PaintingStyle.fill;
        // Draw sweet mini vector heart path
        final path = Path();
        path.moveTo(0, -6);
        path.cubicTo(-6, -12, -12, -6, -12, 0);
        path.cubicTo(-12, 6, -6, 12, 0, 18);
        path.cubicTo(6, 12, 12, 6, 12, 0);
        path.cubicTo(12, -6, 6, -12, 0, -6);
        path.close();

        canvas.drawPath(path, paint);
      } else {
        // Use saveLayer to fade the beautiful native-colored emoji without distorting its colors!
        canvas.saveLayer(
          Rect.fromCircle(center: Offset.zero, radius: 28),
          Paint()..color = Colors.white.withOpacity(h.opacity),
        );
        
        final textSpan = TextSpan(
          text: h.symbol,
          style: const TextStyle(
            fontSize: 30, // Gorgeous, premium size
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        // Center the emoji text bounds perfectly
        textPainter.paint(
          canvas, 
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        
        canvas.restore();
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
