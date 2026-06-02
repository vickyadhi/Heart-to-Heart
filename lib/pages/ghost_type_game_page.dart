import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/connection_service.dart';
import '../theme.dart';

class GhostTypeGamePage extends StatefulWidget {
  const GhostTypeGamePage({super.key});

  @override
  State<GhostTypeGamePage> createState() => _GhostTypeGamePageState();
}

class _GhostTypeGamePageState extends State<GhostTypeGamePage> {
  final List<String> _quotes = [
    "i love you so much",
    "miss you everyday",
    "thinking of you",
    "closer hearts",
    "you are my favorite",
    "forever and always",
    "heart to heart",
    "you make me smile",
  ];

  late String _targetText;
  int _currentIndex = 0;
  String? _wrongChar;
  int _secondsRemaining = 15;
  Timer? _timer;
  bool _gameEnded = false;
  late List<bool> _fadedChars;

  final List<String> _row1 = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
  final List<String> _row2 = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
  final List<String> _row3 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _timer?.cancel();
    setState(() {
      _targetText = (_quotes..shuffle()).first;
      _currentIndex = 0;
      _wrongChar = null;
      _gameEnded = false;
      _fadedChars = List.filled(_targetText.length, false);
      // Dynamic time limit: 0.75s per character + 4s base
      _secondsRemaining = (_targetText.length * 0.75 + 4).round();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _onTimeOut();
      }
    });
  }

  void _onTimeOut() {
    _timer?.cancel();
    if (_gameEnded) return;
    setState(() {
      _gameEnded = true;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final conn = Provider.of<ConnectionService>(context, listen: false);
    
    final currentScore = auth.currentUser?.gameScore ?? 0;
    final earnedPoints = _currentIndex; // 1 point per correct letter typed

    if (earnedPoints > 0) {
      conn.updateMyGameScore(currentScore + earnedPoints);
    }

    _showResultDialog(
      title: "Time's Up! ⏰",
      message: earnedPoints > 0
          ? "You ran out of time, but you typed $earnedPoints letters correctly and got +$earnedPoints points!"
          : "You ran out of time. Don't worry, keep practicing your keyboard muscle memory!",
      success: earnedPoints > 0,
      earnedPoints: earnedPoints,
    );
  }

  void _handleKeyPress(String char) {
    if (_gameEnded) return;
    if (_currentIndex >= _targetText.length) return; // Waiting for submit

    final auth = Provider.of<AuthService>(context, listen: false);
    final targetChar = _targetText[_currentIndex];

    if (char.toLowerCase() == targetChar.toLowerCase()) {
      if (auth.currentUser?.vibrationEnabled ?? true) {
        HapticFeedback.lightImpact();
      }

      final int indexToFade = _currentIndex;
      setState(() {
        _currentIndex++;
        _wrongChar = null;
      });

      // Start 1-second fade timer for this character
      Timer(const Duration(seconds: 1), () {
        if (mounted && !_gameEnded) {
          setState(() {
            _fadedChars[indexToFade] = true;
          });
        }
      });
    } else {
      if (auth.currentUser?.vibrationEnabled ?? true) {
        HapticFeedback.heavyImpact();
      }

      setState(() {
        _wrongChar = char;
      });

      // Revert wrong character visual after 600ms
      Timer(const Duration(milliseconds: 600), () {
        if (mounted && _wrongChar == char) {
          setState(() {
            _wrongChar = null;
          });
        }
      });
    }
  }

  void _handleBackspace() {
    if (_gameEnded) return;
    if (_currentIndex > 0) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.currentUser?.vibrationEnabled ?? true) {
        HapticFeedback.lightImpact();
      }

      setState(() {
        _currentIndex--;
        _wrongChar = null;
        _fadedChars[_currentIndex] = false; // Restore visibility
      });
    }
  }

  void _submitGame() {
    if (_gameEnded) return;
    _timer?.cancel();
    setState(() {
      _gameEnded = true;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final conn = Provider.of<ConnectionService>(context, listen: false);
    
    final currentScore = auth.currentUser?.gameScore ?? 0;
    final earnedPoints = _currentIndex; // 1 point per correct letter typed

    conn.updateMyGameScore(currentScore + earnedPoints);

    _showResultDialog(
      title: "Excellent! 🏆",
      message: "You typed the phrase successfully and got +$earnedPoints points added to your score!",
      success: true,
      earnedPoints: earnedPoints,
    );
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool success,
    required int earnedPoints,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: success ? const Color(0xFF2E7D32) : AppTheme.primary,
              ),
            ),
            content: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.textLight,
                height: 1.45,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Go back to dashboard
                },
                child: Text(
                  'Exit',
                  style: TextStyle(color: AppTheme.textLight.withOpacity(0.8), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _startNewGame();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Play Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKey(String letter) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _handleKeyPress(letter),
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: const Center(
            child: SizedBox(), // Completely invisible letters for ghost typing!
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({required Widget child, required VoidCallback onTap, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTapDown: (_) => onTap(),
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECEFF1),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> charWidgets = [];
    for (int i = 0; i < _targetText.length; i++) {
      final targetChar = _targetText[i];
      final bool isCorrect = i < _currentIndex;
      final bool isFaded = _fadedChars[i];
      final bool isCurrent = i == _currentIndex;
      final bool isError = isCurrent && _wrongChar != null;
      final String displayChar = isError ? _wrongChar! : targetChar;

      charWidgets.add(
        GhostCharWidget(
          char: displayChar,
          isCorrect: isCorrect,
          isFaded: isFaded,
          isError: isError,
          isCurrent: isCurrent,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ghost Type 👻',
          style: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Timer block
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _secondsRemaining <= 5 
                      ? Colors.redAccent.withOpacity(0.1) 
                      : Colors.purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _secondsRemaining <= 5 ? Colors.redAccent : Colors.purple,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: _secondsRemaining <= 5 ? Colors.redAccent : Colors.purple,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_secondsRemaining s',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _secondsRemaining <= 5 ? Colors.redAccent : Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Instruction text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Type the correct letters on the invisible keyboard:",
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Target Text Display Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2.0,
                  runSpacing: 4.0,
                  children: charWidgets,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: _currentIndex == _targetText.length && !_gameEnded ? _submitGame : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.textLight.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: AppTheme.textLight.withOpacity(0.4),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: _currentIndex == _targetText.length ? 4 : 0,
                  shadowColor: AppTheme.primary.withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: _currentIndex == _targetText.length 
                          ? Colors.white 
                          : AppTheme.textLight.withOpacity(0.4),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SUBMIT',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),

            // Custom Invisible Keypad
            Container(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _row1.map((l) => _buildKey(l)).toList(),
                  ),
                  // Row 2
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 1),
                      ..._row2.map((l) => _buildKey(l)),
                      const Spacer(flex: 1),
                    ],
                  ),
                  // Row 3
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ..._row3.map((l) => _buildKey(l)),
                      _buildSpecialKey(
                        child: const Icon(Icons.backspace_outlined, size: 18, color: AppTheme.textDark),
                        onTap: _handleBackspace,
                        flex: 2,
                      ),
                    ],
                  ),
                  // Spacebar Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSpecialKey(
                        child: const Text('SPACE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                        onTap: () => _handleKeyPress(' '),
                        flex: 6,
                      ),
                    ],
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

class GhostCharWidget extends StatefulWidget {
  final String char;
  final bool isCorrect;
  final bool isFaded;
  final bool isError;
  final bool isCurrent;

  const GhostCharWidget({
    super.key,
    required this.char,
    required this.isCorrect,
    required this.isFaded,
    required this.isError,
    required this.isCurrent,
  });

  @override
  State<GhostCharWidget> createState() => _GhostCharWidgetState();
}

class _GhostCharWidgetState extends State<GhostCharWidget> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    if (widget.isError) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant GhostCharWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isError && !oldWidget.isError) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color charColor;
    if (widget.isFaded) {
      charColor = Colors.transparent;
    } else if (widget.isError) {
      charColor = Colors.redAccent;
    } else if (widget.isCorrect) {
      charColor = const Color(0xFF2E7D32); // Beautiful Green
    } else if (widget.isCurrent) {
      charColor = AppTheme.primary; // Underlined Active Cursor character
    } else {
      charColor = AppTheme.textLight.withOpacity(0.3); // Normal idle character
    }

    String displayChar = widget.char;
    if (widget.isCurrent && displayChar == ' ') {
      displayChar = '␣';
    }

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final double progress = _shakeController.value;
        // Dampened sine wave for a beautiful premium shake animation
        final double offset = 8 * math.sin(progress * 4 * math.pi) * (1 - progress);
        
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Text(
            displayChar,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: charColor,
              decoration: (widget.isCurrent && !widget.isError && !widget.isFaded)
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
          ),
        );
      },
    );
  }
}
