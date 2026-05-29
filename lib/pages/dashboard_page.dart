import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
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
    HapticFeedback.vibrate(); // Direct phone vibration when big heart is tapped!
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

              const SizedBox(height: 52), // Increased space below central heart to avoid overlapping/disturbance!

              // HORIZONTAL EMOJIS MOOD ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ThreeDEmojiButton(
                    onTap: () => _sendMoodTap(conn, 'miss_you', '🥺', 'Miss You'),
                    emoji: '🥺',
                    label: 'Miss You',
                  ),
                  ThreeDEmojiButton(
                    onTap: () => _sendMoodTap(conn, 'sad', '😢', 'Sad'),
                    emoji: '😢',
                    label: 'Sad',
                  ),
                  ThreeDEmojiButton(
                    onTap: () => _sendMoodTap(conn, 'excited', '🤩', 'Excited'),
                    emoji: '🤩',
                    label: 'Excited',
                  ),
                  ThreeDEmojiButton(
                    onTap: () => _sendMoodTap(conn, 'thinking', '💭', 'Thinking'),
                    emoji: '💭',
                    label: 'Thinking',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (auth.currentUser?.partnerUid != null && auth.currentUser!.partnerUid!.isNotEmpty) ...[
                _buildPartnerBatteryCard(conn, partnerName),
                const SizedBox(height: 16),
                _buildPartnerStatusCard(auth, conn, partnerName),
                const SizedBox(height: 16),
                _buildNextMeetingCard(auth, conn),
                const SizedBox(height: 20),
              ],

              // REDESIGNED DYNAMIC COUPLES SPARK CARD (Ultra Premium Adaptive Skeuomorphic UI, moved below Next Meeting)
              _buildDailySparkCard(isSmallScreen),

              const SizedBox(height: 20),

              // BOTTOM STATS CARDS ROW (Highly Adaptive for All Screens)
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
                      icon: Icon(Icons.diamond_rounded, color: Colors.blueAccent, size: isSmallScreen ? 18.0 : 22.0),
                      value: '$hearts',
                      label: 'Hearts',
                      context: context,
                    ),
                  ),
                ],
              ),

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
                        'heart to heart',
                        style: TextStyle(
                          fontFamily: 'Outfit',
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
                        fontFamily: 'Inter',
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
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: AppTheme.textLight.withOpacity(0.5),
                          ),
                        ),
                        const Icon(Icons.favorite_rounded, color: AppTheme.primary, size: 10),
                        Text(
                          ' in India',
                          style: TextStyle(
                            fontFamily: 'Inter',
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
                              ? 'Low battery alert'
                              : 'Unplugged',
                  style: TextStyle(
                    fontFamily: 'Inter',
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
                        fontFamily: 'Outfit',
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
                            fontFamily: 'Inter',
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
              fontFamily: 'Outfit',
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
        HapticFeedback.selectionClick();
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
                fontFamily: 'Outfit',
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
                      fontFamily: 'Outfit',
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
                        content: const Text('Next meeting date updated!', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
                        backgroundColor: AppTheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(
                  hasDate ? "Change Date" : "Schedule",
                  style: const TextStyle(
                    fontFamily: 'Outfit',
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
                  fontFamily: 'Inter',
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
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Tap here to countdown to your next flight!",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppTheme.textLight.withValues(alpha: 0.8)),
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
              fontFamily: 'Outfit',
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
            fontFamily: 'Inter',
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
              fontFamily: 'Outfit',
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
              fontFamily: 'Inter',
              fontSize: isSmallScreen ? 8.5 : 10.0,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySparkCard(bool isSmallScreen) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _coupleTips.length;
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 14.0 : 20.0, 
          vertical: isSmallScreen ? 14.0 : 18.0,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFEAEE), // Soft romantic sunset pink
              Color(0xFFFFF5E4), // Gentle gold peach
              Color(0xFFF2E7FF), // Soft lavender dream
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 28),
          border: Border.all(
            color: Colors.white.withOpacity(0.9),
            width: isSmallScreen ? 1.8 : 2.5,
          ),
          boxShadow: [
            // Skeuomorphic drop shadow
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.12),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            // Inner highlight shadow (white reflection)
            BoxShadow(
              color: Colors.white.withOpacity(0.85),
              blurRadius: 8,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 3D Glowing Bulb Container
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF9E80), // Vibrant peach-orange
                    Color(0xFFFF5252), // Glowing coral-red
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.lightbulb_rounded, // Solid lightbulb for premium feel
                color: Colors.white,
                size: isSmallScreen ? 18.0 : 22.0,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with premium "NEW" or "SPARK" tag
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        "Couple's Daily Spark",
                        style: TextStyle(
                          fontFamily: 'Outfit', 
                          fontWeight: FontWeight.w900,
                          fontSize: isSmallScreen ? 13.0 : 15.0,
                          color: AppTheme.primaryDark,
                          letterSpacing: 0.1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accent],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "SPARK ✨",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _coupleTips[_currentTipIndex],
                    style: TextStyle(
                      fontFamily: 'Inter', 
                      fontSize: isSmallScreen ? 11.0 : 12.0,
                      color: AppTheme.textDark,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Tap to discover new inspiration • Let's talk! 💖",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isSmallScreen ? 8.5 : 9.5,
                      color: AppTheme.textLight.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded, 
                color: AppTheme.primary, 
                size: isSmallScreen ? 10.0 : 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThreeDEmojiButton extends StatefulWidget {
  final VoidCallback onTap;
  final String emoji;
  final String label;

  const ThreeDEmojiButton({
    super.key,
    required this.onTap,
    required this.emoji,
    required this.label,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
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
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
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

