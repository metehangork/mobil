class ConversationSummary {
  final int id;
  final int user1Id;
  final int user2Id;
  final String matchType;
  final String status;
  final DateTime? lastMessageAt;
  final String lastMessageText;
  final int unreadCount;
  final int otherUserId;

  ConversationSummary({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.matchType,
    required this.status,
    required this.lastMessageAt,
    required this.lastMessageText,
    required this.unreadCount,
    required this.otherUserId,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) => ConversationSummary(
        id: (json['id'] as num).toInt(),
        user1Id: (json['user1Id'] as num).toInt(),
        user2Id: (json['user2Id'] as num).toInt(),
        matchType: json['matchType']?.toString() ?? 'direct',
        status: json['status']?.toString() ?? 'accepted',
        lastMessageAt: json['lastMessageAt'] != null ? DateTime.tryParse(json['lastMessageAt'].toString()) : null,
        lastMessageText: json['lastMessageText']?.toString() ?? '',
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
        otherUserId: (json['otherUserId'] as num).toInt(),
      );
}

class ChatMessage {
  final int id;
  final int senderId;
  final String text;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: (json['id'] as num).toInt(),
        senderId: (json['sender_id'] as num).toInt(),
        text: json['message_text']?.toString() ?? '',
        type: json['message_type']?.toString() ?? 'text',
        isRead: (json['is_read'] as bool?) ?? false,
        createdAt: DateTime.parse(json['created_at'].toString()),
      );
}
