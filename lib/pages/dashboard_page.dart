import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/love_event.dart';
import '../services/auth_service.dart';
import '../services/connection_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/pulsing_heart.dart';
import '../widgets/floating_hearts.dart';
import '../theme.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'pairing_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  final GlobalKey<FloatingHeartsOverlayState> _heartsOverlayKey = GlobalKey<FloatingHeartsOverlayState>();

  // Cute relationship tips for couples
  final List<String> _coupleTips = [
    "Distance is only temporary. Closer hearts beat as one! ❤️",
    "Candlelight virtual dates: Sync your dinners this weekend! 🕯️",
    "Share a song that perfectly defines your feelings today. 🎵",
    "Surprise them with a quick voice note in the Chat tab! 🎙️",
    "Write 3 things you are incredibly grateful for about your partner. ✍️",
    "Little things matter: send a tap just to say you woke up! ☀️",
  ];
  int _currentTipIndex = 0;

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
    });
  }

  void _handleIncomingLoveEvent(LoveEvent event) {
    if (!mounted) return;

    // Trigger phone vibration / haptic feedback
    HapticFeedback.vibrate();

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
    HapticFeedback.lightImpact();
  }

  void _sendMoodTap(ConnectionService conn, String type, String emoji, String label) {
    conn.sendLoveEvent(type);
    _heartsOverlayKey.currentState?.spawnHearts(emoji: emoji);
    HapticFeedback.mediumImpact();

    final partnerName = Provider.of<AuthService>(context, listen: false).currentUser?.partnerName ?? 'Partner';
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sent "$label" $emoji to $partnerName!',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final conn = Provider.of<ConnectionService>(context);

    // Real-time unpairing navigation: if authenticated but unpaired, redirect to PairingPage immediately
    if (auth.isAuthenticated && !auth.isPaired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PairingPage()),
        );
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final partnerName = auth.currentUser?.partnerName ?? 'Partner';

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
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _incomingAlertEvent!.displayTitle,
                              style: const TextStyle(
                                fontFamily: 'Inter',
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
    final streak = user?.streakCount ?? 127;
    final sent = user?.loveSentCount ?? 324;
    final hearts = user?.heartsCount ?? 8;

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
                            style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: AppTheme.primary),
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
                                  fontFamily: 'Inter',
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
                                  fontFamily: 'Outfit',
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
                                decoration: const BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Leaf/streak chip "For us" or dynamic badge matching mockup
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.spa_rounded, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'For us',
                          style: TextStyle(fontFamily: 'Outfit', 
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
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
                    fontFamily: 'Inter',
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

              const SizedBox(height: 24),

              // HORIZONTAL EMOJIS MOOD ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEmojiButton(conn, 'miss_you', '🥺', 'Miss You'),
                  _buildEmojiButton(conn, 'sad', '😢', 'Sad'),
                  _buildEmojiButton(conn, 'excited', '🤩', 'Excited'),
                  _buildEmojiButton(conn, 'thinking', '💭', 'Thinking'),
                ],
              ),

              const SizedBox(height: 24),

              // COUPLES SPARK CARD (Useful advice for couples!)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentTipIndex = (_currentTipIndex + 1) % _coupleTips.length;
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.premiumShadow,
                    border: Border.all(color: AppTheme.primary.withOpacity(0.08), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Couple's Daily Spark ✨",
                              style: TextStyle(fontFamily: 'Outfit', 
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _coupleTips[_currentTipIndex],
                              style: TextStyle(fontFamily: 'Inter', 
                                fontSize: 11,
                                color: AppTheme.textDark,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppTheme.textLight.withOpacity(0.4), size: 18),
                    ],
                  ),
                ),
              ),

              if (auth.currentUser?.partnerUid != null && auth.currentUser!.partnerUid!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPartnerBatteryCard(conn, partnerName),
              ],

              const SizedBox(height: 20),

              // BOTTOM STATS CARDS ROW
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      icon: const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 24),
                      value: '$streak',
                      label: 'Love Streak',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatsCard(
                      icon: const Icon(Icons.favorite_rounded, color: AppTheme.primary, size: 22),
                      value: '$sent',
                      label: 'Love Sent',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatsCard(
                      icon: const Icon(Icons.diamond_rounded, color: Colors.blueAccent, size: 22),
                      value: '$hearts',
                      label: 'Hearts',
                    ),
                  ),
                ],
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

    IconData batteryIcon;
    Color batteryColor;

    if (batteryLevel == null) {
      batteryIcon = Icons.battery_unknown_rounded;
      batteryColor = AppTheme.textLight.withOpacity(0.6);
    } else if (isCharging) {
      batteryIcon = Icons.battery_charging_full_rounded;
      batteryColor = Colors.green;
    } else if (batteryLevel > 80) {
      batteryIcon = Icons.battery_full_rounded;
      batteryColor = Colors.green;
    } else if (batteryLevel > 50) {
      batteryIcon = Icons.battery_5_bar_rounded;
      batteryColor = Colors.green[600]!;
    } else if (batteryLevel > 20) {
      batteryIcon = Icons.battery_3_bar_rounded;
      batteryColor = Colors.orange;
    } else {
      batteryIcon = Icons.battery_alert_rounded;
      batteryColor = Colors.redAccent;
    }

    final isLowBattery = batteryLevel != null && batteryLevel <= 20;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: batteryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              batteryIcon,
              color: batteryColor,
              size: 24,
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
                    fontFamily: 'Outfit',
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
                              ? 'Low battery! ⚠️'
                              : 'Unplugged',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: isLowBattery 
                        ? Colors.redAccent 
                        : AppTheme.textLight.withOpacity(0.8),
                    fontWeight: isLowBattery ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Text(
            batteryLevel != null ? '$batteryLevel%' : '--%',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(ConnectionService conn, String type, String emoji, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _sendMoodTap(conn, type, emoji, label),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppTheme.premiumShadow,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard({
    required Widget icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textLight.withOpacity(0.7),
            ),
          ),
        ],
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

