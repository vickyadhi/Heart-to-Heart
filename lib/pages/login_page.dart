import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'name_page.dart';
import 'pairing_page.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Only for signup

  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth(AuthService authService) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    try {
      if (_isSignUp) {
        await authService.signUpWithEmail(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await authService.loginWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      _navigateNext(authService);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '').trim();
      });
    }
  }

  void _showGoogleErrorBypassDialog(AuthService authService, String errorMsg) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Setup Needed ⚙️',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.settings_suggest_rounded,
                        color: AppTheme.primary,
                        size: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Google Sign-In failed (API Exception 10).\n\nThis usually means the SHA-1 fingerprint for this build hasn't been registered in the Firebase Console yet.\n\nWould you like to instantly sign in with a Demo Test Account to preview the app?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppTheme.textLight.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() => _errorMessage = null);
                        try {
                          // Try logging in with demo account
                          bool loggedIn = false;
                          try {
                            loggedIn = await authService.loginWithEmail('demo@h2h.com', 'password123');
                          } catch (_) {
                            // If it doesn't exist, automatically sign up the demo account!
                            loggedIn = await authService.signUpWithEmail('Demo User', 'demo@h2h.com', 'password123');
                          }
                          if (loggedIn) {
                            _navigateNext(authService);
                          }
                        } catch (err) {
                          setState(() {
                            _errorMessage = err.toString().replaceAll('Exception: ', '').trim();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Text('Use Demo Account', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleGoogleAuth(AuthService authService) async {
    setState(() => _errorMessage = null);
    try {
      final success = await authService.loginWithGoogle();
      if (success) {
        _navigateNext(authService);
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('10') || errStr.contains('sign_in_failed') || errStr.contains('ApiException')) {
        _showGoogleErrorBypassDialog(authService, errStr);
      } else {
        setState(() {
          _errorMessage = errStr.replaceAll('Exception: ', '').trim();
        });
      }
    }
  }


  void _navigateNext(AuthService authService) {
    if (!mounted) return;
    
    if (!authService.isPaired) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PairingPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Container(
      decoration: AppTheme.romanticGradient(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // CARD SHEET
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: AppTheme.premiumShadow,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Premium 3D H2H Hands Heart Logo
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                'assets/images/hands_heart_3d.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'h2h',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Error Box
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Sign up name field
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: AppTheme.textDark, fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: 'How should they call you?',
                                prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textLight, size: 20),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: AppTheme.textDark, fontSize: 15),
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'eg. wikki@gmail.com',
                              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textLight, size: 20),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Please enter email';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                  return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: AppTheme.textDark, fontSize: 15),
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textLight, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppTheme.textLight,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Please enter password';
                              if (val.trim().length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          
                          if (!_isSignUp) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppTheme.textLight.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                          ],

                          // Auth Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authService.isLoading ? null : () => _handleAuth(authService),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shadowColor: AppTheme.primary.withOpacity(0.4),
                              ),
                              child: authService.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(_isSignUp ? 'Sign Up' : 'Login'),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Toggle Sign Up / Login
                          GestureDetector(
                            onTap: () => setState(() {
                              _isSignUp = !_isSignUp;
                              _errorMessage = null;
                            }),
                            child: RichText(
                              text: TextSpan(
                                text: _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                                style: TextStyle(fontFamily: 'Inter', color: AppTheme.textLight, fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: _isSignUp ? 'Sign In' : 'Sign Up',
                                    style: TextStyle(fontFamily: 'Outfit', 
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          
                          // Or divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: AppTheme.textLight.withOpacity(0.15), thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Or', style: TextStyle(color: AppTheme.textLight.withOpacity(0.5), fontSize: 12)),
                              ),
                              Expanded(child: Divider(color: AppTheme.textLight.withOpacity(0.15), thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Social Login Buttons
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: authService.isLoading ? null : () => _handleGoogleAuth(authService),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: AppTheme.textLight.withOpacity(0.2), width: 1.5),
                                foregroundColor: AppTheme.textDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text('Continue with Google', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
