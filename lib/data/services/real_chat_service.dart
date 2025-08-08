import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class RealChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir toutes les conversations de l'utilisateur
  static Stream<List<ConversationModel>> getUserConversations() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ConversationModel.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  // Obtenir les messages d'une conversation
  static Stream<List<MessageModel>> getConversationMessages(
    String conversationId,
  ) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return MessageModel(
              id: doc.id,
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
          }).toList();
        });
  }

  // Envoyer un message
  static Future<void> sendMessage({
    required String conversationId,
    required String content,
    required MessageType type,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté');

    // Obtenir les participants de la conversation
    final conversationDoc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (!conversationDoc.exists) {
      throw Exception('Conversation introuvable');
    }

    final participants = List<String>.from(
      conversationDoc.data()!['participants'],
    );
    final receiverId = participants.firstWhere(
      (id) => id != userId,
      orElse: () => '',
    );

    final messageData = {
      'senderId': userId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'isDelivered': true,
      'metadata': metadata ?? {},
    };

    // Ajouter le message
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(messageData);

    // Mettre à jour la conversation
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': content,
      'lastMessageTime': Timestamp.now(),
      'lastMessageSenderId': userId,
    });
  }

  // Créer une nouvelle conversation
  static Future<String> createConversation({
    required String otherUserId,
    String? initialMessage,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté');

    // Vérifier si une conversation existe déjà
    final existingConversation = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();

    for (var doc in existingConversation.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(otherUserId) && participants.length == 2) {
        return doc.id;
      }
    }

    // Créer une nouvelle conversation
    final conversationData = {
      'participants': [userId, otherUserId],
      'createdAt': Timestamp.now(),
      'lastMessage': initialMessage ?? '',
      'lastMessageTime': Timestamp.now(),
      'lastMessageSenderId': userId,
    };

    final conversationRef = await _firestore
        .collection('conversations')
        .add(conversationData);

    // Envoyer le message initial si fourni
    if (initialMessage != null && initialMessage.isNotEmpty) {
      await sendMessage(
        conversationId: conversationRef.id,
        content: initialMessage,
        type: MessageType.text,
      );
    }

    return conversationRef.id;
  }

  // Marquer les messages comme lus
  static Future<void> markMessagesAsRead(String conversationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Obtenir le nombre de messages non lus
  static Stream<int> getUnreadMessagesCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((conversations) async {
          int totalUnread = 0;

          for (var conversation in conversations.docs) {
            final unreadMessages = await _firestore
                .collection('conversations')
                .doc(conversation.id)
                .collection('messages')
                .where('senderId', isNotEqualTo: userId)
                .where('isRead', isEqualTo: false)
                .get();

            totalUnread += unreadMessages.docs.length;
          }

          return totalUnread;
        });
  }

  // Rechercher des utilisateurs pour démarrer une conversation
  static Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return [];

    // Recherche par nom ou tag FinIMoi
    final usersQuery = await _firestore
        .collection('users')
        .where('finimoimtag', isGreaterThanOrEqualTo: query.toLowerCase())
        .where(
          'finimoimtag',
          isLessThanOrEqualTo: '${query.toLowerCase()}\\uf8ff',
        )
        .limit(10)
        .get();

    final results = <UserSearchResult>[];

    for (var doc in usersQuery.docs) {
      if (doc.id != currentUserId) {
        final userData = doc.data();
        results.add(
          UserSearchResult(
            userId: doc.id,
            fullName: userData['fullName'] ?? 'Utilisateur',
            finimoimTag: userData['finimoimtag'] ?? '',
            profilePicture: userData['profilePicture'],
          ),
        );
      }
    }

    return results;
  }

  // Envoyer un message de demande d'argent
  static Future<void> sendMoneyRequest({
    required String conversationId,
    required double amount,
    required String currency,
    String? reason,
  }) async {
    await sendMessage(
      conversationId: conversationId,
      content: reason ?? 'Demande d\'argent',
      type: MessageType.moneyRequest,
      metadata: {
        'amount': amount,
        'currency': currency,
        'status': 'pending',
        'requestId': _firestore.collection('money_requests').doc().id,
      },
    );
  }

  // Envoyer un message de transfert d'argent
  static Future<void> sendMoneyTransfer({
    required String conversationId,
    required double amount,
    required String currency,
    required String transactionId,
    String? message,
  }) async {
    await sendMessage(
      conversationId: conversationId,
      content: message ?? 'Transfert d\'argent',
      type: MessageType.moneyTransfer,
      metadata: {
        'amount': amount,
        'currency': currency,
        'transactionId': transactionId,
        'status': 'completed',
      },
    );
  }

  // Supprimer une conversation
  static Future<void> deleteConversation(String conversationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Supprimer tous les messages
    final messages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Supprimer la conversation
    batch.delete(_firestore.collection('conversations').doc(conversationId));

    await batch.commit();
  }

  // Obtenir les informations d'un utilisateur
  static Future<UserInfo?> getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        return UserInfo(
          userId: userId,
          fullName: data['fullName'] ?? 'Utilisateur',
          finimoimTag: data['finimoimtag'] ?? '',
          profilePicture: data['profilePicture'],
          isOnline: data['isOnline'] ?? false,
          lastSeen: data['lastSeen']?.toDate(),
        );
      }

      return null;
    } catch (e) {
      print('Erreur lors de la récupération des infos utilisateur: $e');
      return null;
    }
  }
}

// Modèles de données pour le chat
class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    required this.createdAt,
  });

  factory ConversationModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return ConversationModel(
      id: id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class UserSearchResult {
  final String userId;
  final String fullName;
  final String finimoimTag;
  final String? profilePicture;

  UserSearchResult({
    required this.userId,
    required this.fullName,
    required this.finimoimTag,
    this.profilePicture,
  });
}

class UserInfo {
  final String userId;
  final String fullName;
  final String finimoimTag;
  final String? profilePicture;
  final bool isOnline;
  final DateTime? lastSeen;

  UserInfo({
    required this.userId,
    required this.fullName,
    required this.finimoimTag,
    this.profilePicture,
    required this.isOnline,
    this.lastSeen,
  });
}
