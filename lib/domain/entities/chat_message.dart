import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final List<String> readBy;
  final PaymentButton? paymentButton;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.metadata,
    required this.readBy,
    this.paymentButton,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatar: data['senderAvatar'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] is Timestamp
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      metadata: data['metadata'],
      readBy: List<String>.from(data['readBy'] ?? []),
      paymentButton: data['paymentButton'] != null
          ? PaymentButton.fromMap(data['paymentButton'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'metadata': metadata,
      'readBy': readBy,
      'paymentButton': paymentButton?.toMap(),
    };
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
    List<String>? readBy,
    PaymentButton? paymentButton,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      readBy: readBy ?? this.readBy,
      paymentButton: paymentButton ?? this.paymentButton,
    );
  }
}

enum MessageType { text, image, file, payment, paymentRequest, system }

class PaymentButton {
  final String id;
  final PaymentButtonType type;
  final double amount;
  final String currency;
  final String description;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? transactionId;

  const PaymentButton({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.description,
    required this.isCompleted,
    this.completedAt,
    this.transactionId,
  });

  factory PaymentButton.fromMap(Map<String, dynamic> map) {
    return PaymentButton(
      id: map['id'] ?? '',
      type: PaymentButtonType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => PaymentButtonType.pay,
      ),
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'FCFA',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] is Timestamp
                ? (map['completedAt'] as Timestamp).toDate()
                : null)
          : null,
      transactionId: map['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'description': description,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'transactionId': transactionId,
    };
  }
}

enum PaymentButtonType { pay, request, split }

class Chat {
  final String id;
  final String name;
  final String? description;
  final ChatType type;
  final List<String> participantIds;
  final List<ChatParticipant> participants;
  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, int> unreadCounts;
  final String? groupAvatar;
  final String? createdBy;

  const Chat({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.participantIds,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.unreadCounts,
    this.groupAvatar,
    this.createdBy,
  });

  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;

  String getDisplayName(String currentUserId) {
    if (type == ChatType.group) {
      return name;
    }

    // For direct chats, show the other person's name
    final otherParticipant = participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.name;
  }

  String? getDisplayAvatar(String currentUserId) {
    if (type == ChatType.group) {
      return groupAvatar;
    }

    final otherParticipant = participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.first,
    );
    return otherParticipant.avatar;
  }

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      type: ChatType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ChatType.direct,
      ),
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participants:
          (data['participants'] as List<dynamic>?)
              ?.map((e) => ChatParticipant.fromMap(e))
              .toList() ??
          [],
      lastMessage: data['lastMessage'] != null
          ? ChatMessage.fromFirestore(data['lastMessage'])
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      groupAvatar: data['groupAvatar'],
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'participantIds': participantIds,
      'participants': participants.map((p) => p.toMap()).toList(),
      'lastMessage': lastMessage?.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadCounts': unreadCounts,
      'groupAvatar': groupAvatar,
      'createdBy': createdBy,
    };
  }
}

enum ChatType { direct, group, support }

class ChatParticipant {
  final String userId;
  final String name;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeen;
  final ChatRole role;

  const ChatParticipant({
    required this.userId,
    required this.name,
    this.avatar,
    required this.isOnline,
    this.lastSeen,
    required this.role,
  });

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      avatar: map['avatar'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : null,
      role: ChatRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => ChatRole.member,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'avatar': avatar,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'role': role.name,
    };
  }
}

enum ChatRole { admin, member, support }
