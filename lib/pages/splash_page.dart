import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'login_page.dart';
import 'pairing_page.dart';
import 'dashboard_page.dart';
import 'info_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  double _loadProgress = 0.0;
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Loader progress simulation
    _loadTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        if (_loadProgress < 1.0) {
          _loadProgress += 0.02;
        } else {
          _loadTimer?.cancel();
          _navigateNext();
        }
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadTimer?.cancel();
    super.dispose();
  }

  void _navigateNext() {
    if (!mounted) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (!authService.isInitialized) {
      Future.delayed(const Duration(milliseconds: 100), _navigateNext);
      return;
    }
    
    if (!authService.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else if (!authService.isPaired) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PairingPage()),
      );
    } else if (authService.currentUser?.setupComplete != true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InfoPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }
  }

  Widget _buildBackgroundHeart({
    required double top,
    required double left,
    required double size,
    required double rotation,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Transform.rotate(
        angle: rotation,
        child: Icon(
          Icons.favorite_rounded,
          size: size,
          color: Colors.white.withOpacity(opacity),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Image.asset(
        'assets/images/app_logo_flat.png',
        width: 110,
        height: 110,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Background scattered hearts matching Image 3 pattern
              _buildBackgroundHeart(top: h * 0.12, left: w * 0.45, size: 28, rotation: -0.1, opacity: 0.16),
              _buildBackgroundHeart(top: h * 0.04, left: w * 0.85, size: 32, rotation: 0.2, opacity: 0.12),
              _buildBackgroundHeart(top: h * 0.15, left: w * 0.06, size: 36, rotation: 0.3, opacity: 0.14),
              _buildBackgroundHeart(top: h * 0.28, left: w * 0.36, size: 40, rotation: -0.2, opacity: 0.15),
              _buildBackgroundHeart(top: h * 0.36, left: w * 0.82, size: 24, rotation: 0.1, opacity: 0.16),
              _buildBackgroundHeart(top: h * 0.46, left: w * 0.12, size: 28, rotation: -0.3, opacity: 0.14),
              _buildBackgroundHeart(top: h * 0.64, left: w * 0.84, size: 30, rotation: 0.4, opacity: 0.15),
              _buildBackgroundHeart(top: h * 0.69, left: w * 0.22, size: 38, rotation: -0.15, opacity: 0.13),
              _buildBackgroundHeart(top: h * 0.78, left: w * 0.62, size: 26, rotation: 0.25, opacity: 0.15),
              _buildBackgroundHeart(top: h * 0.88, left: w * 0.14, size: 34, rotation: -0.2, opacity: 0.14),
              _buildBackgroundHeart(top: h * 0.92, left: w * 0.86, size: 22, rotation: 0.1, opacity: 0.16),

              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Beautiful scaling vector double heart logo
                      ScaleTransition(
                        scale: _logoScale,
                        child: _buildLogo(),
                      ),
                      const SizedBox(height: 20),
                      // App Name
                      const Text(
                        'h2h',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Circular Loading Indicator
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
