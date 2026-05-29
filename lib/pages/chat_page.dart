import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/connection_service.dart';
import '../widgets/chat_bubble.dart';
import '../models/love_event.dart';
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
                fontFamily: 'Outfit',
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
                              fontFamily: 'Outfit',
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
                    fontFamily: 'Outfit',
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
                      decoration: const BoxDecoration(
                        color: Color(0xFF34C759), // Green dot
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34C759),
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
                            fontFamily: 'Outfit',
                            color: AppTheme.textLight.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Tap the heart on home to show you care!',
                          style: TextStyle(
                            fontFamily: 'Outfit',
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

          // 3. FLOATING BOTTOM INPUT BAR (Image 2 style)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 116), // optimized capsule bottom nav clearance
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
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: AppTheme.textDark,
                        fontSize: 15,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Write your message...',
                        hintStyle: TextStyle(
                          fontFamily: 'Outfit',
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
                  // Microphone Icon
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.mic_none_rounded,
                      color: AppTheme.textLight,
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
        ],
      ),
    );
  }
}
