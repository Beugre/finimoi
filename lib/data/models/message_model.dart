import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.metadata,
  });

  factory MessageModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      isDelivered: data['isDelivered'] ?? false,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isDelivered': isDelivered,
      'metadata': metadata,
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    bool? isDelivered,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper pour les messages de transfert d'argent
  double? get transferAmount {
    if (type == MessageType.moneyTransfer && metadata != null) {
      return metadata!['amount']?.toDouble();
    }
    return null;
  }

  String? get transferCurrency {
    if (type == MessageType.moneyTransfer && metadata != null) {
      return metadata!['currency']?.toString();
    }
    return null;
  }

  String? get transactionId {
    if ((type == MessageType.moneyTransfer ||
            type == MessageType.moneyRequest) &&
        metadata != null) {
      return metadata!['transactionId']?.toString();
    }
    return null;
  }

  // Helper pour les demandes d'argent
  double? get requestAmount {
    if (type == MessageType.moneyRequest && metadata != null) {
      return metadata!['amount']?.toDouble();
    }
    return null;
  }

  String? get requestCurrency {
    if (type == MessageType.moneyRequest && metadata != null) {
      return metadata!['currency']?.toString();
    }
    return null;
  }

  String? get requestStatus {
    if (type == MessageType.moneyRequest && metadata != null) {
      return metadata!['status']?.toString();
    }
    return null;
  }

  // Helper pour les images
  String? get imageUrl {
    if (type == MessageType.image && metadata != null) {
      return metadata!['imageUrl']?.toString();
    }
    return null;
  }

  // Helper pour les fichiers
  String? get fileUrl {
    if (type == MessageType.file && metadata != null) {
      return metadata!['fileUrl']?.toString();
    }
    return null;
  }

  String? get fileName {
    if (type == MessageType.file && metadata != null) {
      return metadata!['fileName']?.toString();
    }
    return null;
  }

  int? get fileSize {
    if (type == MessageType.file && metadata != null) {
      return metadata!['fileSize']?.toInt();
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, content: $content, type: $type, timestamp: $timestamp)';
  }
}

enum MessageType {
  text,
  image,
  file,
  moneyRequest,
  moneyTransfer,
  system,
  notification,
}

extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Message texte';
      case MessageType.image:
        return 'Image';
      case MessageType.file:
        return 'Fichier';
      case MessageType.moneyRequest:
        return 'Demande d\'argent';
      case MessageType.moneyTransfer:
        return 'Transfert d\'argent';
      case MessageType.system:
        return 'Message système';
      case MessageType.notification:
        return 'Notification';
    }
  }

  bool get isMoneyRelated {
    return this == MessageType.moneyRequest ||
        this == MessageType.moneyTransfer;
  }

  bool get isMediaMessage {
    return this == MessageType.image || this == MessageType.file;
  }
}
