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
    final bool isSticker = event.type == 'sticker';
    
    final bubbleColor = isSticker 
        ? Colors.transparent 
        : (isSelf 
            ? const Color(0xFFEF5350) 
            : const Color(0xFFF0F2F5));
    
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
              padding: EdgeInsets.symmetric(
                horizontal: isSticker ? 0.0 : 16.0, 
                vertical: isSticker ? 0.0 : 12.0,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isSelf ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isSelf ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: isSticker
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: event.type == 'sticker'
                  ? Container(
                      constraints: const BoxConstraints.tightFor(width: 110, height: 110),
                      child: Image.network(
                        event.message,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFEF5350),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : event.type == 'voice_note'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: textColor,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            // Soft skeuomorphic waveform visualizer
                            Row(
                              children: List.generate(12, (index) {
                                final heights = [10, 24, 18, 14, 28, 20, 16, 22, 12, 18, 14, 8];
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                  width: 3,
                                  height: heights[index % heights.length].toDouble(),
                                  decoration: BoxDecoration(
                                    color: textColor.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              event.message, // Duration string, e.g. "0:05"
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: textColor.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
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
