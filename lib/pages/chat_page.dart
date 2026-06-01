import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/connection_service.dart';
import '../widgets/chat_bubble.dart';
import '../theme.dart';

class ChatPage extends StatefulWidget {
  final String partnerName;

  const ChatPage({super.key, required this.partnerName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // 3D Sticker Drawer state variables
  bool _showStickerDrawer = false;

  final List<Map<String, String>> _fluent3DStickers = const [
    {
      'name': 'Heart Ribbon',
      'url': 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Heart%20with%20ribbon/3D/heart_with_ribbon_3d.png',
    },
    {
      'name': 'Hearts Face',
      'url': 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Smiling%20face%20with%20hearts/3D/smiling_face_with_hearts_3d.png',
    },
    {
      'name': 'Kiss Face',
      'url': 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Face%20blowing%20a%20kiss/3D/face_blowing_a_kiss_3d.png',
    },
    {
      'name': 'Red Heart',
      'url': 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Red%20heart/3D/red_heart_3d.png',
    },
    {
      'name': 'Sparkles',
      'url': 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Sparkles/3D/sparkles_3d.png',
    },
    {
      'name': 'Fire',
      'url': 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Fire/3D/fire_3d.png',
    },
    {
      'name': 'Tears of Joy',
      'url': 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Face%20with%20tears%20of%20joy/3D/face_with_tears_of_joy_3d.png',
    },
    {
      'name': 'Loudly Crying',
      'url': 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Loudly%20crying%20face/3D/loudly_crying_face_3d.png',
    },
    {
      'name': 'Teddy Bear',
      'url': 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Teddy%20bear/3D/teddy_bear_3d.png',
    },
    {
      'name': 'Rose',
      'url': 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Rose/3D/rose_3d.png',
    },
    {
      'name': 'Two Hearts',
      'url': 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Two%20hearts/3D/two_hearts_3d.png',
    },
    {
      'name': 'Ring',
      'url': 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Ring/3D/ring_3d.png',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(ConnectionService conn) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    conn.sendLoveEvent('chat', message: text);
    _messageController.clear();
    
    // Smooth scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildDateDivider(DateTime timestamp) {
    final now = DateTime.now();
    String dateStr;
    if (timestamp.day == now.day && timestamp.month == now.month && timestamp.year == now.year) {
      dateStr = 'Today';
    } else {
      final yesterday = now.subtract(const Duration(days: 1));
      if (timestamp.day == yesterday.day && timestamp.month == yesterday.month && timestamp.year == yesterday.year) {
        dateStr = 'Yesterday';
      } else {
        dateStr = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.withOpacity(0.12), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateStr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.withOpacity(0.12), thickness: 1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final conn = Provider.of<ConnectionService>(context);
    
    final myUid = auth.currentUser?.uid ?? '';
    final myPhotoUrl = auth.currentUser?.photoUrl;
    final myName = auth.currentUser?.displayName ?? '';
    final partnerPhotoUrl = conn.partnerPhotoUrl;

    // Generate list of items (bubbles and dividers) in order from latest to oldest
    final List<Widget> chatItems = [];
    for (int i = 0; i < conn.events.length; i++) {
      final event = conn.events[i];
      final isSelf = event.senderId == myUid;
      
      chatItems.add(
        ChatBubble(
          event: event,
          isSelf: isSelf,
          partnerName: widget.partnerName,
          partnerPhotoUrl: partnerPhotoUrl,
          myPhotoUrl: myPhotoUrl,
          myName: myName,
        ),
      );

      // Add date divider above (which in reverse list is next in sequence)
      if (i == conn.events.length - 1) {
        chatItems.add(_buildDateDivider(event.timestamp));
      } else {
        final olderEvent = conn.events[i + 1];
        if (event.timestamp.day != olderEvent.timestamp.day ||
            event.timestamp.month != olderEvent.timestamp.month ||
            event.timestamp.year != olderEvent.timestamp.year) {
          chatItems.add(_buildDateDivider(event.timestamp));
        }
      }
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Redesigned status Header matching Image 2
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.transparent,
            child: Row(
              children: [
                // Partner Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFFFEAEE),
                    backgroundImage: partnerPhotoUrl != null && partnerPhotoUrl.isNotEmpty 
                        ? NetworkImage(partnerPhotoUrl) 
                        : null,
                    child: partnerPhotoUrl == null || partnerPhotoUrl.isEmpty
                        ? Text(
                            widget.partnerName.isNotEmpty ? widget.partnerName[0].toUpperCase() : 'K',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF5350),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Partner Name
                Text(
                  widget.partnerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF5350), // Red/coral matching Katija text in Image 2
                  ),
                ),
                const Spacer(),
                // Online status dot & text
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: (conn.partnerShowOnline && conn.partnerIsOnline)
                            ? const Color(0xFF34C759)
                            : Colors.grey, // Grey dot if offline or hidden
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (conn.partnerShowOnline && conn.partnerIsOnline) ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: (conn.partnerShowOnline && conn.partnerIsOnline)
                            ? const Color(0xFF34C759)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.transparent),

          // 2. CHAT TIMELINE LIST
          Expanded(
            child: conn.events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 48,
                          color: AppTheme.textLight.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No love taps sent yet.',
                          style: TextStyle(
                            color: AppTheme.textLight.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Tap the heart on home to show you care!',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true, // latest first
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    itemCount: chatItems.length,
                    itemBuilder: (context, index) {
                      return chatItems[index];
                    },
                  ),
          ),

          // 3. FLOATING BOTTOM INPUT BAR & STICKERS DRAWER (Image 2 style)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onTap: () {
                            if (_showStickerDrawer) {
                              setState(() => _showStickerDrawer = false);
                            }
                          },
                          style: const TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 15,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Write your message...',
                            hintStyle: TextStyle(
                              color: Color(0x99796E70),
                              fontSize: 15,
                            ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(conn),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3D Stickers Toggle button
                      IconButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _showStickerDrawer = !_showStickerDrawer;
                          });
                        },
                        icon: Icon(
                          _showStickerDrawer
                              ? Icons.keyboard_rounded
                              : Icons.emoji_emotions_outlined,
                          color: _showStickerDrawer ? AppTheme.primary : AppTheme.textLight,
                          size: 24,
                        ),
                      ),
                      // Send Icon
                      IconButton(
                        onPressed: () => _sendMessage(conn),
                        icon: const Icon(
                          Icons.send_rounded,
                          color: AppTheme.textDark,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3D Sticker Grid Drawer
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                height: _showStickerDrawer ? 240 : 0,
                color: Colors.white.withOpacity(0.95),
                child: _showStickerDrawer
                    ? GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemCount: _fluent3DStickers.length,
                        itemBuilder: (context, index) {
                          final sticker = _fluent3DStickers[index];
                          return GestureDetector(
                            onTap: () {
                              conn.sendLoveEvent('sticker', message: sticker['url']!);
                              HapticFeedback.mediumImpact();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                              ),
                              child: Image.network(
                                sticker['url']!,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 110), // clearance for bottom capsule nav bar
            ],
          ),
        ],
      ),
    );
  }
}
