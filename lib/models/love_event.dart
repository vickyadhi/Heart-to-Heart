import 'package:cloud_firestore/cloud_firestore.dart';

class LoveEvent {
  final String id;
  final String senderId;
  final String receiverId;
  final String type; // 'miss_you', 'love_tap', 'sad', 'excited', 'thinking', 'chat'
  final String message;
  final DateTime timestamp;

  LoveEvent({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory LoveEvent.fromMap(Map<String, dynamic> map) {
    DateTime parsedTime = DateTime.now();
    final ts = map['timestamp'];
    if (ts != null) {
      if (ts is Timestamp) {
        parsedTime = ts.toDate();
      } else if (ts is String) {
        parsedTime = DateTime.tryParse(ts) ?? DateTime.now();
      }
    }
    return LoveEvent(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      type: map['type'] ?? '',
      message: map['message'] ?? '',
      timestamp: parsedTime,
    );
  }

  // Visual text helper matching reference screens
  String get displayTitle {
    switch (type) {
      case 'miss_you':
        return 'Your partner is missing you';
      case 'love_tap':
        return 'Your partner sent you love';
      case 'sad':
        return 'Your partner is feeling sad';
      case 'excited':
        return 'Your partner sent you excitement';
      case 'thinking':
        return 'Your partner is thinking of you';
      case 'chat':
        return message;
      case 'voice_note':
        return 'Voice Message 🎙️ ($message)';
      case 'sticker':
        return 'Sent a 3D Sticker ✨';
      default:
        return 'Sent you a heartbeat';
    }
  }

  String get selfDisplayTitle {
    switch (type) {
      case 'miss_you':
        return 'You missed your partner';
      case 'love_tap':
        return 'You sent love';
      case 'sad':
        return 'You sent a sad status';
      case 'excited':
        return 'You sent excitement';
      case 'thinking':
        return 'You thinking your partner';
      case 'chat':
        return message;
      case 'voice_note':
        return 'Voice Message 🎙️ ($message)';
      case 'sticker':
        return 'You sent a 3D Sticker ✨';
      default:
        return 'You sent a heartbeat';
    }
  }
}
