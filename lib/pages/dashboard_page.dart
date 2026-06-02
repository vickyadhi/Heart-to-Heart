import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:home_widget/home_widget.dart';
import '../models/love_event.dart';
import '../services/auth_service.dart';
import '../services/connection_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/pulsing_heart.dart';
import '../widgets/floating_hearts.dart';
import '../widgets/editable_sticky_note.dart';
import '../widgets/skeleton_loader.dart';
import '../theme.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'pairing_page.dart';
import 'love_draw_page.dart';
import 'write_note_page.dart';
import 'login_page.dart';
import 'ghost_type_game_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  final GlobalKey<FloatingHeartsOverlayState> _heartsOverlayKey = GlobalKey<FloatingHeartsOverlayState>();
  bool _isNavigatingToPairing = false; // guard against repeated pushes

  // In-app alert notification banner state variables
  LoveEvent? _incomingAlertEvent;
  bool _showAlert = false;

  @override
  void initState() {
    super.initState();
    // Link incoming real-time notifications callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final conn = Provider.of<ConnectionService>(context, listen: false);
      conn.onIncomingLoveEvent = _handleIncomingLoveEvent;
      _checkPairingConfirmation();
    });
  }

  Future<void> _checkPairingConfirmation() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final conn = Provider.of<ConnectionService>(context, listen: false);
    if (auth.isAuthenticated && auth.isPaired) {
      final confirmed = await HomeWidget.getWidgetData<bool>('pairing_confirmed') ?? false;
      if (!confirmed) {
        if (mounted) {
          _showContinuePairingDialog(context, auth, conn);
        }
      }
    }
  }

  void _showContinuePairingDialog(BuildContext context, AuthService auth, ConnectionService conn) {
    final partnerName = conn.partnerDisplayName ?? auth.currentUser?.partnerName ?? 'your partner';
    showDialog(
      context: context,
      barrierDismissible: false,
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
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/hands_heart_3d.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'You were previously paired with $partnerName. Would you like to continue this connection?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.textLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            // Choose No: unpair
                            await auth.unpairPartner();
                            await HomeWidget.saveWidgetData<bool>('pairing_confirmed', false);
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const PairingPage()),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            // Choose Yes: confirm connection
                            await HomeWidget.saveWidgetData<bool>('pairing_confirmed', true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleIncomingLoveEvent(LoveEvent event) {
    if (!mounted) return;

    // Trigger phone vibration / haptic feedback
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser?.vibrationEnabled ?? true) {
      HapticFeedback.vibrate();
    }

    // Trigger sweet customized in-app slide down banner notification
    setState(() {
      _incomingAlertEvent = event;
      _showAlert = true;
    });

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showAlert = false);
      }
    });
  }

  void _sendLoveTap(ConnectionService conn) {
    conn.sendLoveEvent('love_tap');
    _heartsOverlayKey.currentState?.spawnHearts();
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser?.vibrationEnabled ?? true) {
      HapticFeedback.vibrate(); // Direct phone vibration when big heart is tapped!
    }
  }

  void _sendMoodTap(ConnectionService conn, String type, String emoji, String label) {
    conn.sendLoveEvent(type);
    _heartsOverlayKey.currentState?.spawnHearts(emoji: emoji);
    // Removed vibration/haptics from emoji taps per user request

    final partnerName = Provider.of<AuthService>(context, listen: false).currentUser?.partnerName ?? 'Partner';
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sent "$label" $emoji to $partnerName!',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3), // 3 seconds only
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final conn = Provider.of<ConnectionService>(context);

    // Real-time unauthenticated navigation: if not authenticated, redirect to LoginPage immediately
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      });
      return Container(
        decoration: AppTheme.romanticGradient(),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SkeletonLoader(),
          ),
        ),
      );
    }

    // Real-time unpairing navigation: if authenticated but unpaired, redirect to PairingPage immediately
    if (auth.isAuthenticated && !auth.isPaired) {
      if (!_isNavigatingToPairing) {
        _isNavigatingToPairing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const PairingPage()),
            );
          }
        });
      }
      return Container(
        decoration: AppTheme.romanticGradient(),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SkeletonLoader(),
          ),
        ),
      );
    }

    final partnerName = conn.partnerDisplayName ?? 'Partner';

    final List<Widget> pages = [
      _buildHomeDashboard(auth, conn, partnerName),
      ChatPage(partnerName: partnerName),
      ProfilePage(partnerName: partnerName),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Dynamic gradient background
          Container(
            decoration: AppTheme.romanticGradient(),
          ),

          // Splash graphics
          Positioned(
            top: -150,
            right: -100,
            child: Icon(Icons.favorite, size: 360, color: Colors.white.withOpacity(0.035)),
          ),

          // Soft background hearts matching Image 2
          const BackgroundHeartsLayer(),

          // Main page contents with smooth premium fade transitions
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: pages[_currentIndex],
              ),
            ),
          ),

          // Floating Nav Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),

          // IN-APP ROMANTIC SLIDE-DOWN NOTIFICATION BANNER
          if (_showAlert && _incomingAlertEvent != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              top: _showAlert ? MediaQuery.of(context).padding.top + 12 : -100,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() => _showAlert = false);
                  setState(() => _currentIndex = 1); // switch to chat tab
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.premiumShadow,
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              partnerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _incomingAlertEvent!.displayTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight, size: 24),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard(AuthService auth, ConnectionService conn, String partnerName) {
    final user = auth.currentUser;
    final streak = user?.streakCount ?? 0;
    final sent = user?.loveSentCount ?? 0;
    final emojisSent = user?.emojisSentCount ?? 0;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return FloatingHeartsOverlay(
      key: _heartsOverlayKey,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // HEADER ROW (Connected Avatar & Streak chip)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Partner profile chip matching reference screen
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.pink.withOpacity(0.1),
                          child: Text(
                            partnerName[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Connected to',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                           Row(
                            children: [
                              Text(
                                partnerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Online status pulsing dot
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: (conn.partnerShowOnline && conn.partnerIsOnline)
                                      ? AppTheme.success
                                      : Colors.grey.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Streak chip (removed 'For us')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '$streak',
                          style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // SUBTITLE: "Tap to send love"
              Center(
                child: Text(
                  'Tap to send love',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLight.withOpacity(0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // MAIN PULSING HEART BUTTON
              Center(
                child: PulsingHeart(
                  onTap: () => _sendLoveTap(conn),
                ),
              ),

              const SizedBox(height: 52), // Increased space below central heart to avoid overlapping/disturbance!

              // HORIZONTAL EMOJIS MOOD ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ThreeDEmojiButton(
                    onTap: () => _sendMoodTap(conn, 'miss_you', '🥺', 'Miss You'),
                    emoji: '🥺',
                  ),
                  ThreeDEmojiButton(
                    onTap: () => _sendMoodTap(conn, 'sad', '😢', 'Sad'),
                    emoji: '😢',
                  ),
                  ThreeDEmojiButton(
                    onTap: () => _sendMoodTap(conn, 'excited', '🤩', 'Excited'),
                    emoji: '🤩',
                  ),
                  ThreeDEmojiButton(
                    onTap: () => _sendMoodTap(conn, 'thinking', '💭', 'Thinking'),
                    emoji: '💭',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // STATS CARDS ROW (Three Box)
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      icon: Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: isSmallScreen ? 20.0 : 24.0),
                      value: '$streak',
                      label: 'Love Streak',
                      context: context,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatsCard(
                      icon: Icon(Icons.favorite_rounded, color: AppTheme.primary, size: isSmallScreen ? 18.0 : 22.0),
                      value: '$sent',
                      label: 'Love Sent',
                      context: context,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatsCard(
                      icon: Icon(Icons.emoji_emotions_rounded, color: Colors.amber, size: isSmallScreen ? 18.0 : 22.0),
                      value: '$emojisSent',
                      label: 'Emojis Sent',
                      context: context,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (auth.currentUser?.partnerUid != null && auth.currentUser!.partnerUid!.isNotEmpty) ...[
                // update your status card
                _buildPartnerStatusCard(auth, conn, partnerName),
                const SizedBox(height: 16),
                _buildNextMeetingCard(auth, conn),
                const SizedBox(height: 16),
                // note card
                _buildStickyNotesCard(auth, conn, partnerName),
                const SizedBox(height: 16),
                // battery percentage card
                _buildPartnerBatteryCard(conn, partnerName),
                const SizedBox(height: 16),
                // map card
                _buildGPSMapCard(conn, auth),
                const SizedBox(height: 16),
                // draw card
                _buildLoveDrawCard(conn, auth),
                const SizedBox(height: 16),
                // game card
                _buildGameCard(conn, auth),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 36),

              // BRANDING FOOTER (Instamart style)
              Center(
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                      ).createShader(bounds),
                      child: const Text(
                        'h2h',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Connected • Closer • Forever',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 1.5,
                      color: AppTheme.primary.withOpacity(0.08),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Crafted with ',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textLight.withOpacity(0.5),
                          ),
                        ),
                        const Icon(Icons.favorite_rounded, color: AppTheme.primary, size: 10),
                        Text(
                          ' in India',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textLight.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 98), // optimized capsule bottom bar clearancece for bottom floating navigation bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerBatteryCard(ConnectionService conn, String partnerName) {
    final batteryLevel = conn.partnerBatteryLevel;
    final isCharging = conn.partnerIsCharging;

    List<List<dynamic>> batteryIcon;
    Color batteryColor;

    if (batteryLevel == null) {
      batteryIcon = HugeIcons.strokeRoundedBatteryCharging01;
      batteryColor = AppTheme.textLight.withValues(alpha: 0.6);
    } else if (isCharging) {
      batteryIcon = HugeIcons.strokeRoundedBatteryCharging02;
      batteryColor = Colors.green;
    } else if (batteryLevel > 80) {
      batteryIcon = HugeIcons.strokeRoundedBatteryFull;
      batteryColor = Colors.green;
    } else if (batteryLevel > 20) {
      batteryIcon = HugeIcons.strokeRoundedBatteryMedium01;
      batteryColor = Colors.orange;
    } else {
      batteryIcon = HugeIcons.strokeRoundedBatteryLow;
      batteryColor = Colors.redAccent;
    }

    final isLowBattery = batteryLevel != null && batteryLevel <= 20;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: batteryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: batteryIcon,
              color: batteryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$partnerName's Battery Status",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  batteryLevel == null
                      ? 'No status received'
                      : isCharging
                          ? 'Charging now'
                          : isLowBattery
                              ? 'Low battery alert'
                              : 'Unplugged',
                  style: TextStyle(
                    fontSize: 11,
                    color: isLowBattery 
                        ? Colors.redAccent 
                        : AppTheme.textLight.withValues(alpha: 0.8),
                    fontWeight: isLowBattery ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Text(
            batteryLevel != null ? '$batteryLevel%' : '--%',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusFallbackEmoji(String status) {
    switch (status) {
      case 'Active': return '😊';
      case 'Busy': return '💻';
      case 'Sleeping': return '😴';
      case 'Driving': return '🚗';
      case 'Movie': return '🍿';
      default: return '😊';
    }
  }

  List<List<dynamic>> _getStatusIcon(String status) {
    switch (status) {
      case 'Active': return HugeIcons.strokeRoundedSmile;
      case 'Busy': return HugeIcons.strokeRoundedBriefcase01;
      case 'Sleeping': return HugeIcons.strokeRoundedMoon02;
      case 'Driving': return HugeIcons.strokeRoundedCar02;
      case 'Movie': return HugeIcons.strokeRoundedTicket01;
      default: return HugeIcons.strokeRoundedSmile;
    }
  }

  Widget _buildPartnerStatusCard(AuthService auth, ConnectionService conn, String partnerName) {
    final status = conn.partnerCustomStatus ?? 'Active';
    final partnerOnline = conn.partnerShowOnline && conn.partnerIsOnline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: _getStatusIcon(status),
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$partnerName is $status",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: partnerOnline ? AppTheme.success : AppTheme.textLight.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          partnerOnline ? 'Active on app now' : 'Offline right now',
                          style: TextStyle(
                            fontSize: 11,
                            color: partnerOnline ? AppTheme.success : AppTheme.textLight.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 12),
          const Text(
            "Update your status:",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(auth, 'Active', HugeIcons.strokeRoundedSmile),
                _buildStatusChip(auth, 'Busy', HugeIcons.strokeRoundedBriefcase01),
                _buildStatusChip(auth, 'Sleeping', HugeIcons.strokeRoundedMoon02),
                _buildStatusChip(auth, 'Driving', HugeIcons.strokeRoundedCar02),
                _buildStatusChip(auth, 'Movie', HugeIcons.strokeRoundedTicket01),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AuthService auth, String status, List<List<dynamic>> icon) {
    final isSelected = auth.currentUser?.customStatus == status;
    return GestureDetector(
      onTap: () {
        auth.updateCustomStatus(status, _getStatusFallbackEmoji(status));
        if (auth.currentUser?.vibrationEnabled ?? true) {
          HapticFeedback.selectionClick();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: isSelected ? Colors.white : AppTheme.primary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextMeetingCard(AuthService auth, ConnectionService conn) {
    final date = conn.partnerNextMeetingDate ?? auth.currentUser?.nextMeetingDate;
    final hasDate = date != null;

    int days = 0;
    int hours = 0;
    int minutes = 0;

    if (hasDate) {
      final diff = date.difference(DateTime.now());
      if (diff.isNegative) {
        days = 0;
        hours = 0;
        minutes = 0;
      } else {
        days = diff.inDays;
        hours = diff.inHours % 24;
        minutes = diff.inMinutes % 60;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedAirplane01, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Next Meeting",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppTheme.primary,
                            onPrimary: Colors.white,
                            onSurface: AppTheme.textDark,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    await auth.updateNextMeetingDate(picked);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Next meeting date updated!', style: TextStyle(fontWeight: FontWeight.w600)),
                        backgroundColor: AppTheme.primary,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: Text(
                  hasDate ? "Change Date" : "Schedule",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasDate) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeUnit(days.toString().padLeft(2, '0'), 'DAYS'),
                const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                _buildTimeUnit(hours.toString().padLeft(2, '0'), 'HOURS'),
                const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'MINS'),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                "until we see each other again!",
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textLight.withValues(alpha: 0.8),
                ),
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  await auth.updateNextMeetingDate(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12), style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedCalendar03, color: AppTheme.primary, size: 28),
                    const SizedBox(height: 8),
                    const Text(
                      "No meeting scheduled yet.",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Tap here to countdown to your next flight!",
                      style: TextStyle(fontSize: 11, color: AppTheme.textLight.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }



  Widget _buildStatsCard({
    required Widget icon,
    required String value,
    required String label,
    required BuildContext context,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 12.0, 
        vertical: isSmallScreen ? 12.0 : 16.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(height: isSmallScreen ? 4.0 : 8.0),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 15.0 : 18.0,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSmallScreen ? 8.5 : 10.0,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLoveDrawCard(ConnectionService conn, AuthService auth) {
    final latestEvent = conn.events.isNotEmpty 
        ? conn.events.firstWhere((e) => e.type == 'love_draw', orElse: () => LoveEvent(id: '', senderId: '', receiverId: '', type: '', message: '', timestamp: DateTime.now())) 
        : null;
    
    final hasDrawing = latestEvent != null && latestEvent.id.isNotEmpty;
    final isFromPartner = hasDrawing && latestEvent.senderId != auth.currentUser?.uid;
    final partnerName = auth.currentUser?.partnerName ?? 'Partner';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Love Draw',
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              if (hasDrawing)
                Text(
                  isFromPartner ? 'New from $partnerName!' : 'Sent by you',
                  style: GoogleFonts.quicksand(
                    fontSize: 11,
                    color: isFromPartner ? AppTheme.primary : AppTheme.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasDrawing) ...[
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF16121E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Center(
                child: Image.memory(
                  base64Decode(latestEvent.message),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoveDrawPage(
                    initialBase64Drawing: isFromPartner ? latestEvent.message : null,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              isFromPartner ? 'Reply & Draw Back!' : 'Start Drawing',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGPSMapCard(ConnectionService conn, AuthService auth) {
    final lat = conn.partnerLatitude;
    final lng = conn.partnerLongitude;
    final myLat = conn.myLatitude;
    final myLng = conn.myLongitude;
    final partnerName = conn.partnerDisplayName ?? 'Partner';
    final partnerGender = conn.partnerGender;
    final partnerPhoto = conn.partnerPhotoUrl;
    
    final myPhoto = auth.currentUser?.photoUrl;
    final myGender = auth.currentUser?.gender;

    final bool hasPartnerLocation = lat != null && lng != null && !lat.isNaN && !lng.isNaN;
    final bool hasMyLocation = myLat != null && myLng != null && !myLat.isNaN && !myLng.isNaN;
    final bool showMap = hasPartnerLocation || hasMyLocation;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  showMap ? "Live Map" : "Partner's Location",
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Refresh button
              GestureDetector(
                onTap: () {
                  if (auth.currentUser?.vibrationEnabled ?? true) {
                    HapticFeedback.selectionClick();
                  }
                  conn.refreshPartnerLocation();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Colors.blue, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!showMap)
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📍', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 12),
                    Text(
                      'Waiting for $partnerName\'s location...',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Ensure location permission is enabled on both devices and tap refresh.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          color: AppTheme.textLight.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Builder(builder: (context) {
              final centerLat = hasPartnerLocation ? lat : myLat!;
              final centerLng = hasPartnerLocation ? lng : myLng!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: fm.FlutterMap(
                      key: ValueKey('map_${centerLat}_${centerLng}_${lat}_${myLat}'),
                      options: fm.MapOptions(
                        initialCenter: LatLng(centerLat, centerLng),
                        initialZoom: 14.5,
                        minZoom: 2.0,
                        maxZoom: 18.0,
                        interactionOptions: const fm.InteractionOptions(
                          flags: fm.InteractiveFlag.pinchZoom | fm.InteractiveFlag.drag,
                        ),
                      ),
                      children: [
                        fm.TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.h2h',
                        ),
                        fm.MarkerLayer(
                          markers: [
                            if (hasPartnerLocation)
                              fm.Marker(
                                width: 56,
                                height: 56,
                                point: LatLng(lat, lng),
                                child: _buildMapMarker(partnerPhoto, partnerGender ?? 'Other', isPartner: true),
                              ),
                            if (hasMyLocation)
                              fm.Marker(
                                width: 56,
                                height: 56,
                                point: LatLng(myLat, myLng),
                                child: _buildMapMarker(myPhoto, myGender ?? 'Other', isPartner: false),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          hasPartnerLocation ? 'Showing $partnerName\'s location' : 'Showing your location ($partnerName offline)',
                          style: GoogleFonts.quicksand(fontSize: 10, color: AppTheme.textLight.withValues(alpha: 0.6)),
                        ),
                      ),
                      if (conn.partnerLocationUpdatedAt != null && hasPartnerLocation)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh_rounded, size: 12, color: AppTheme.textLight.withValues(alpha: 0.6)),
                              const SizedBox(width: 4),
                              Text(
                                'Updated ${_formatLocationTime(conn.partnerLocationUpdatedAt!)}',
                                style: GoogleFonts.quicksand(fontSize: 11, color: AppTheme.textLight.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  // Map marker with photo or 3D emoji, no boxy background
  Widget _buildMapMarker(String? photoUrl, String gender, {required bool isPartner}) {
    Widget avatar;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
        avatar = ClipOval(
          child: Image.network(
            photoUrl,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => _genderEmojiMarker(gender),
          ),
        );
      } else {
        try {
          String base64Str = photoUrl;
          if (photoUrl.contains(',')) base64Str = photoUrl.split(',').last;
          avatar = ClipOval(
            child: Image.memory(
              base64Decode(base64Str),
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => _genderEmojiMarker(gender),
            ),
          );
        } catch (e) {
          avatar = _genderEmojiMarker(gender);
        }
      }
    } else {
      avatar = _genderEmojiMarker(gender);
    }

    final markerColor = isPartner ? AppTheme.primary : Colors.blue;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: markerColor.withValues(alpha: 0.15),
            border: Border.all(color: markerColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: markerColor.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(child: avatar),
        ),
      ],
    );
  }

  Widget _genderEmojiMarker(String gender) {
    String emoji = '😊';
    if (gender.toLowerCase() == 'male') emoji = '👦';
    if (gender.toLowerCase() == 'female') emoji = '👧';
    return Text(emoji, style: const TextStyle(fontSize: 26));
  }

  // ─── STICKY NOTES ────────────────────────────────────────────────────────
  Widget _buildStickyNotesCard(AuthService auth, ConnectionService conn, String partnerName) {
    final partnerNote = conn.partnerStickyNote ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row with round background icon & Title & Write button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.note_alt_outlined,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Daily Note",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: "Your partner's changes will appear here in real-time. Tap 'Write' to update the note shown on their screen.",
                    triggerMode: TooltipTriggerMode.tap,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    showDuration: const Duration(seconds: 6),
                    textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.textLight.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ),
                ],
              ),
              // Capsule button: Write
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WriteNotePage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Write',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          EditableStickyNote(
            name: partnerName,
            content: partnerNote,
            color: const Color(0xFFDDF1FF), // soft sky blue paper
            lineColor: const Color(0xFF9DD4F0),
            nameColor: const Color(0xFF0070A8),
            isEditable: false, // partner's note to me (read-only for me)
            isTypingHint: conn.partnerIsTyping,
            onSave: null,
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(ConnectionService conn, AuthService auth) {
    final myScore = auth.currentUser?.gameScore ?? 0;
    final partnerScore = conn.partnerGameScore;
    final partnerName = conn.partnerDisplayName ?? auth.currentUser?.partnerName ?? 'Partner';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Ghost Type & Play Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.keyboard_alt_outlined,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Ghost Type",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              // Play button on the right
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GhostTypeGamePage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Play',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Scores UI
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'My Score',
                        style: TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$myScore',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$partnerName's Score",
                        style: const TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$partnerScore',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  String _formatLocationTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// ── Ruled notebook line painter for sticky notes ──────────────────────────
class _RuledLinePainter extends CustomPainter {
  final Color lineColor;
  final double lineSpacing;
  final double topOffset;
  final int lineCount;

  const _RuledLinePainter({
    required this.lineColor,
    required this.lineSpacing,
    required this.topOffset,
    required this.lineCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withOpacity(0.55)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < lineCount; i++) {
      final y = topOffset + i * lineSpacing;
      if (y < size.height - 6) {
        canvas.drawLine(
          Offset(12, y),
          Offset(size.width - 12, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RuledLinePainter oldDelegate) => false;
}

class ThreeDEmojiButton extends StatefulWidget {

  final VoidCallback onTap;
  final String emoji;

  const ThreeDEmojiButton({
    super.key,
    required this.onTap,
    required this.emoji,
  });

  @override
  State<ThreeDEmojiButton> createState() => _ThreeDEmojiButtonState();
}

class _ThreeDEmojiButtonState extends State<ThreeDEmojiButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double depth = 6.0;
    final double activeDepth = _isPressed ? 1.5 : depth;
    final double translation = _isPressed ? depth - 1.5 : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, translation, 0),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey[100]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white,
            width: 2.0,
          ),
          boxShadow: [
            // Bottom dark 3D depth shadow matching theme primary accent
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.18),
              offset: Offset(0, activeDepth),
              blurRadius: _isPressed ? 2.5 : 6.0,
              spreadRadius: 0.5,
            ),
            if (!_isPressed)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                offset: const Offset(0, 1),
                blurRadius: 1,
              ),
          ],
        ),
        child: Center(
          child: Transform.scale(
            scale: _isPressed ? 0.94 : 1.0,
            child: Text(
              widget.emoji,
              style: TextStyle(
                fontSize: 28,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.12),
                    offset: const Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BackgroundHeartsLayer extends StatelessWidget {
  const BackgroundHeartsLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Top Left
          Positioned(
            top: MediaQuery.of(context).size.height * 0.12,
            left: MediaQuery.of(context).size.width * 0.28,
            child: Icon(
              Icons.favorite_rounded,
              size: 24,
              color: const Color(0xFFF34D5F).withOpacity(0.06),
            ),
          ),
          // Middle Left
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.45,
            left: MediaQuery.of(context).size.width * 0.08,
            child: Icon(
              Icons.favorite_rounded,
              size: 28,
              color: const Color(0xFFF34D5F).withOpacity(0.05),
            ),
          ),
          // Middle Right
          Positioned(
            top: MediaQuery.of(context).size.height * 0.28,
            right: MediaQuery.of(context).size.width * 0.06,
            child: Icon(
              Icons.favorite_rounded,
              size: 32,
              color: const Color(0xFFF34D5F).withOpacity(0.07),
            ),
          ),
          // Bottom Right
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.24,
            right: MediaQuery.of(context).size.width * 0.16,
            child: Icon(
              Icons.favorite_rounded,
              size: 22,
              color: const Color(0xFFF34D5F).withOpacity(0.06),
            ),
          ),
          // Bottom Left
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.03,
            left: MediaQuery.of(context).size.width * 0.08,
            child: Icon(
              Icons.favorite_rounded,
              size: 38,
              color: const Color(0xFFF34D5F).withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }
}

