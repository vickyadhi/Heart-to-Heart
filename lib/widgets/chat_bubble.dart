import 'package:flutter/material.dart';
import '../models/love_event.dart';

class ChatBubble extends StatelessWidget {
  final LoveEvent event;
  final bool isSelf;
  final String partnerName;
  final String? partnerPhotoUrl;
  final String? myPhotoUrl;
  final String myName;

  const ChatBubble({
    super.key,
    required this.event,
    required this.isSelf,
    required this.partnerName,
    this.partnerPhotoUrl,
    this.myPhotoUrl,
    required this.myName,
  });

  @override
  Widget build(BuildContext context) {
    final bool isChat = event.type == 'chat';
    final bubbleColor = isSelf 
        ? const Color(0xFFEF5350) 
        : const Color(0xFFF0F2F5);
    
    final textColor = isSelf 
        ? Colors.white 
        : const Color(0xFF2C2525);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left partner avatar for incoming messages
          if (!isSelf) ...[
            _buildAvatar(partnerPhotoUrl, partnerName.isNotEmpty ? partnerName[0] : 'K'),
            const SizedBox(width: 8),
          ],
          
          // Event Body Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isSelf ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isSelf ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                isSelf ? event.selfDisplayTitle : event.displayTitle,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: textColor,
                  fontSize: 14.5,
                  fontWeight: isChat ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
          ),

          // Right user avatar for outgoing messages
          if (isSelf) ...[
            const SizedBox(width: 8),
            _buildAvatar(myPhotoUrl, myName.isNotEmpty ? myName[0] : 'U'),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl, String initial) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFFFFEAEE),
        backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl == null || photoUrl.isEmpty
            ? Text(
                initial.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF5350),
                ),
              )
            : null,
      ),
    );
  }
}
