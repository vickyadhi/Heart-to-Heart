import 'package:flutter/material.dart';
import '../theme.dart';

class PulsingHeart extends StatefulWidget {
  final VoidCallback onTap;

  const PulsingHeart({super.key, required this.onTap});

  @override
  State<PulsingHeart> createState() => _PulsingHeartState();
}

class _HeartRipple {
  final double key;
  double radius = 0.0;
  double opacity = 0.6;

  _HeartRipple(this.key);
}

class _PulsingHeartState extends State<PulsingHeart> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Ripple waves
  final List<_HeartRipple> _ripples = [];
  late AnimationController _rippleController;
  double _rippleKey = 0.0;

  // Continuous ambient slow ripple
  late AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    
    // Slow, organic heartbeat breathing scale
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ripple animator
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(() {
        setState(() {
          for (var i = _ripples.length - 1; i >= 0; i--) {
            final r = _ripples[i];
            r.radius += 2.8;
            r.opacity = (1.0 - (r.radius / 130.0)).clamp(0.0, 0.6);
            if (r.radius >= 130.0) {
              _ripples.removeAt(i);
            }
          }
        });
        if (_ripples.isEmpty && _rippleController.isAnimating) {
          _rippleController.stop();
        }
      });

    // Continuous ambient slow ripple (repeating every 3 seconds)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _triggerTapAnimation() {
    widget.onTap();
    
    // Spawn 1-2 new ripple waves
    setState(() {
      _rippleKey++;
      _ripples.add(_HeartRipple(_rippleKey));
    });

    if (!_rippleController.isAnimating) {
      _rippleController.repeat();
    }
  }

  Widget _buildAmbientRipple(double t) {
    final double size = 146.0 + (t * 60.0);
    final double opacity = ((1.0 - t) * 0.22).clamp(0.0, 1.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary.withOpacity(opacity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double stackSize = 146.0;
    return GestureDetector(
      onTap: _triggerTapAnimation,
      child: SizedBox(
        width: stackSize,
        height: stackSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // AMBIENT CONTINUOUS RIPPLE
            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                final t1 = _ambientController.value;
                final t2 = (t1 + 0.5) % 1.0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildAmbientRipple(t1),
                    _buildAmbientRipple(t2),
                  ],
                );
              },
            ),

            // RIPPLE WAVES LAYER
            ..._ripples.map((ripple) {
              final double size = 140.0 + (ripple.radius * 2);
              return Positioned(
                left: (stackSize - size) / 2,
                top: (stackSize - size) / 2,
                width: size,
                height: size,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(ripple.opacity),
                  ),
                ),
              );
            }),

            // MAIN BREATHING GLOWING BUTTON
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: stackSize,
                height: stackSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      spreadRadius: 6,
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                    ),
                    child: Center(
                      // Romantic heart icon composition
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Left heart half / Right heart half or standard icon
                          const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 54,
                          ),
                          // Small overlay ring
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
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
      ),
    );
  }
}
