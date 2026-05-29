class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;
  final String? partnerUid;
  final String? partnerName;
  final String? partnerNickname;
  final String? pairingCode;
  final DateTime? connectedAt;
  final DateTime? anniversaryDate;
  final int streakCount;
  final int loveSentCount;
  final int loveReceivedCount;
  final int heartsCount;
  final DateTime? lastActive;
  final bool isOnline;

  final bool pushNotificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool emailNotificationsEnabled;
  final bool showOnlineStatus;
  final bool readReceipts;

  // Real-time custom status and next meeting countdowns for couples
  final String? customStatus;
  final String? customStatusEmoji;
  final DateTime? nextMeetingDate;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    this.photoUrl,
    this.partnerUid,
    this.partnerName,
    this.partnerNickname,
    this.pairingCode,
    this.connectedAt,
    this.anniversaryDate,
    this.streakCount = 0,
    this.loveSentCount = 0,
    this.loveReceivedCount = 0,
    this.heartsCount = 0,
    this.lastActive,
    this.isOnline = false,
    this.pushNotificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.emailNotificationsEnabled = true,
    this.showOnlineStatus = true,
    this.readReceipts = true,
    this.customStatus,
    this.customStatusEmoji,
    this.nextMeetingDate,
  });

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    String? partnerUid,
    String? partnerName,
    String? partnerNickname,
    String? pairingCode,
    DateTime? connectedAt,
    DateTime? anniversaryDate,
    int? streakCount,
    int? loveSentCount,
    int? loveReceivedCount,
    int? heartsCount,
    DateTime? lastActive,
    bool? isOnline,
    bool? pushNotificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? emailNotificationsEnabled,
    bool? showOnlineStatus,
    bool? readReceipts,
    String? customStatus,
    String? customStatusEmoji,
    DateTime? nextMeetingDate,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      partnerUid: partnerUid ?? this.partnerUid,
      partnerName: partnerName ?? this.partnerName,
      partnerNickname: partnerNickname ?? this.partnerNickname,
      pairingCode: pairingCode ?? this.pairingCode,
      connectedAt: connectedAt ?? this.connectedAt,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      streakCount: streakCount ?? this.streakCount,
      loveSentCount: loveSentCount ?? this.loveSentCount,
      loveReceivedCount: loveReceivedCount ?? this.loveReceivedCount,
      heartsCount: heartsCount ?? this.heartsCount,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      readReceipts: readReceipts ?? this.readReceipts,
      customStatus: customStatus ?? this.customStatus,
      customStatusEmoji: customStatusEmoji ?? this.customStatusEmoji,
      nextMeetingDate: nextMeetingDate ?? this.nextMeetingDate,
    );
  }

  UserProfile clearPartner() {
    return UserProfile(
      uid: uid,
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      partnerUid: null,
      partnerName: null,
      partnerNickname: null,
      pairingCode: pairingCode,
      connectedAt: null,
      anniversaryDate: anniversaryDate,
      streakCount: streakCount,
      loveSentCount: loveSentCount,
      loveReceivedCount: loveReceivedCount,
      heartsCount: heartsCount,
      lastActive: lastActive,
      isOnline: isOnline,
      pushNotificationsEnabled: pushNotificationsEnabled,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled,
      showOnlineStatus: showOnlineStatus,
      readReceipts: readReceipts,
      customStatus: customStatus,
      customStatusEmoji: customStatusEmoji,
      nextMeetingDate: nextMeetingDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'partnerUid': partnerUid,
      'partnerName': partnerName,
      'partnerNickname': partnerNickname,
      'pairingCode': pairingCode,
      'connectedAt': connectedAt?.toIso8601String(),
      'anniversaryDate': anniversaryDate?.toIso8601String(),
      'streakCount': streakCount,
      'loveSentCount': loveSentCount,
      'loveReceivedCount': loveReceivedCount,
      'heartsCount': heartsCount,
      'lastActive': lastActive?.toIso8601String(),
      'isOnline': isOnline,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'showOnlineStatus': showOnlineStatus,
      'readReceipts': readReceipts,
      'customStatus': customStatus,
      'customStatusEmoji': customStatusEmoji,
      'nextMeetingDate': nextMeetingDate?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      photoUrl: map['photoUrl'],
      partnerUid: map['partnerUid'],
      partnerName: map['partnerName'],
      partnerNickname: map['partnerNickname'],
      pairingCode: map['pairingCode'],
      connectedAt: map['connectedAt'] != null ? DateTime.tryParse(map['connectedAt']) : null,
      anniversaryDate: map['anniversaryDate'] != null ? DateTime.tryParse(map['anniversaryDate']) : null,
      streakCount: map['streakCount'] ?? 0,
      loveSentCount: map['loveSentCount'] ?? 0,
      loveReceivedCount: map['loveReceivedCount'] ?? 0,
      heartsCount: map['heartsCount'] ?? 0,
      lastActive: map['lastActive'] != null ? DateTime.tryParse(map['lastActive']) : null,
      isOnline: map['isOnline'] ?? false,
      pushNotificationsEnabled: map['pushNotificationsEnabled'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      emailNotificationsEnabled: map['emailNotificationsEnabled'] ?? true,
      showOnlineStatus: map['showOnlineStatus'] ?? true,
      readReceipts: map['readReceipts'] ?? true,
      customStatus: map['customStatus'],
      customStatusEmoji: map['customStatusEmoji'],
      nextMeetingDate: map['nextMeetingDate'] != null ? DateTime.tryParse(map['nextMeetingDate']) : null,
    );
  }
}
