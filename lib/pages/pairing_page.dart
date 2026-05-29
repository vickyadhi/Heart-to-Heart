import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'login_page.dart';
import 'info_page.dart';

class PairingPage extends StatefulWidget {
  const PairingPage({super.key});

  @override
  State<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<PairingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<TextEditingController> _codeFields = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  String? _pairingError;
  bool _isShowingConfirmDialog = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Automatically trigger code generation on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final conn = Provider.of<ConnectionService>(context, listen: false);
      if (conn.generatedCode == null) {
        conn.generatePairingCode();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthService>(context);
    if (auth.isPaired && !_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Successfully connected with partner! 💖',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              duration: const Duration(seconds: 4),
            ),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const InfoPage()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _codeFields) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onCodeInput(String val, int index) {
    if (val.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _verifyCode() async {
    final conn = Provider.of<ConnectionService>(context, listen: false);
    final inputCode = _codeFields.map((c) => c.text.trim()).join();
    
    if (inputCode.length < 4) return;

    setState(() => _pairingError = null);
    try {
      final success = await conn.connectWithPartnerCode(inputCode);
      if (!success) {
        setState(() => _pairingError = 'Pairing request declined or timed out.');
        for (var c in _codeFields) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      setState(() => _pairingError = e.toString().replaceAll('Exception: ', '').trim());
    }
  }

  void _showPairingConfirmDialog(BuildContext context, ConnectionService conn) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppTheme.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pairing Request! 💖',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppTheme.textDark,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: conn.requesterName ?? 'Someone',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                      const TextSpan(text: ' wants to connect with you.\n\nDo you want to accept and pair dashboards?'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() => _isShowingConfirmDialog = false);
                          await conn.declinePairingRequest();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppTheme.textLight.withOpacity(0.2), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          foregroundColor: AppTheme.textLight,
                        ),
                        child: const Text('Decline', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() => _isShowingConfirmDialog = false);
                          try {
                            await conn.acceptPairingRequest();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Connection failed: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: AppTheme.primary,
                        ),
                        child: const Text('Connect', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conn = Provider.of<ConnectionService>(context);

    // Reactively trigger confirm dialog when requesterUid is detected
    if (conn.requesterUid != null && conn.requesterName != null && !_isShowingConfirmDialog) {
      _isShowingConfirmDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPairingConfirmDialog(context, conn);
      });
    }

    return Container(
      decoration: AppTheme.romanticGradient(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Heading matching reference: "Let's Connect Your Hearts"
                const Text(
                  "Let's Connect Your Hearts",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Share the code and bring your love online",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 36),

                // TAB SELECTOR
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.04),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.textLight,
                    labelStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Generate Pairing Code'),
                      Tab(text: "Enter Partner's Code"),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // TAB VIEWS
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: GENERATE CODE
                      _buildGenerateTab(conn),
                      
                      // TAB 2: ENTER CODE
                      _buildEnterTab(conn),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final auth = Provider.of<AuthService>(context, listen: false);
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateTab(ConnectionService conn) {
    final code = conn.generatedCode ?? '----';
    final codeDigits = code.split('');

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  // Code Box Grid matching reference (spaced boxes)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final digit = codeDigits.length > index ? codeDigits[index] : '-';
                      return Container(
                        width: 58,
                        height: 68,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.08),
                            width: 1.5,
                          ),
                          boxShadow: AppTheme.premiumShadow,
                        ),
                        child: Center(
                          child: conn.isGeneratingCode
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                                )
                              : Text(
                                  digit,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(flex: 3),

                  // Re-generate button
                  TextButton(
                    onPressed: conn.isGeneratingCode ? null : () => conn.generatePairingCode(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textLight,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      'Generate new code',
                      style: TextStyle(fontFamily: 'Outfit', 
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildEnterTab(ConnectionService conn) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Code error display
                  if (_pairingError != null) ...[
                    Text(_pairingError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                  ],

                  const Spacer(flex: 1),
                  // Visual digit entry inputs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        width: 56,
                        height: 66,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.premiumShadow,
                        ),
                        child: Center(
                          child: TextField(
                            controller: _codeFields[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                            decoration: const InputDecoration(
                              filled: false,
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onChanged: (val) => _onCodeInput(val, index),
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(flex: 3),

                  // Connect Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: conn.isConnecting ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: conn.isConnecting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Connect'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Enter the 4-digit code shown on your partner's app screen to establish secure pairing.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight.withOpacity(0.6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
