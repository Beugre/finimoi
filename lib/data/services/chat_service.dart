import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _chatsCollection => _firestore.collection('chats');
  CollectionReference get _messagesCollection =>
      _firestore.collection('messages');

  // Get user's chats
  Stream<List<Chat>> getUserChats(String userId) {
    return _chatsCollection
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList(),
        );
  }

  // Get chat messages
  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _messagesCollection
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  // Send text message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
    PaymentButton? paymentButton,
  }) async {
    final message = ChatMessage(
      id: '',
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      metadata: metadata,
      readBy: [],
      paymentButton: paymentButton,
    );

    await _firestore.runTransaction((transaction) async {
      // Add message
      final messageRef = _messagesCollection.doc();
      transaction.set(messageRef, message.toFirestore());

      // Update chat's last message and timestamp
      final chatRef = _chatsCollection.doc(chatId);
      transaction.update(chatRef, {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'lastMessage': message.toFirestore(),
      });

      // Update unread counts for other participants
      final chatDoc = await transaction.get(chatRef);
      if (chatDoc.exists) {
        final chat = Chat.fromFirestore(chatDoc);
        final updatedUnreadCounts = Map<String, int>.from(chat.unreadCounts);

        for (final participantId in chat.participantIds) {
          if (participantId != senderId) {
            updatedUnreadCounts[participantId] =
                (updatedUnreadCounts[participantId] ?? 0) + 1;
          }
        }

        transaction.update(chatRef, {'unreadCounts': updatedUnreadCounts});
      }
    });
  }

  // Send payment message with button
  Future<void> sendPaymentMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String description,
    required double amount,
    required PaymentButtonType buttonType,
  }) async {
    final paymentButton = PaymentButton(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: buttonType,
      amount: amount,
      currency: 'FCFA',
      description: description,
      isCompleted: false,
    );

    String content;
    switch (buttonType) {
      case PaymentButtonType.pay:
        content = 'Paiement demandé: $description';
        break;
      case PaymentButtonType.request:
        content = 'Demande de paiement: $description';
        break;
      case PaymentButtonType.split:
        content = 'Partage de frais: $description';
        break;
    }

    await sendMessage(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      type: MessageType.payment,
      paymentButton: paymentButton,
    );
  }

  // Complete payment button action
  Future<void> completePaymentAction({
    required String messageId,
    required String transactionId,
  }) async {
    await _messagesCollection.doc(messageId).update({
      'paymentButton.isCompleted': true,
      'paymentButton.completedAt': Timestamp.fromDate(DateTime.now()),
      'paymentButton.transactionId': transactionId,
    });
  }

  // Create new chat
  Future<String> createChat({
    required String name,
    required List<String> participantIds,
    required List<ChatParticipant> participants,
    required String createdBy,
    ChatType type = ChatType.direct,
    String? description,
    String? groupAvatar,
  }) async {
    final chat = Chat(
      id: '',
      name: name,
      description: description,
      type: type,
      participantIds: participantIds,
      participants: participants,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      unreadCounts: {},
      groupAvatar: groupAvatar,
      createdBy: createdBy,
    );

    final docRef = await _chatsCollection.add(chat.toFirestore());
    return docRef.id;
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      // Reset unread count for this user
      final chatRef = _chatsCollection.doc(chatId);
      final chatDoc = await transaction.get(chatRef);

      if (chatDoc.exists) {
        final chat = Chat.fromFirestore(chatDoc);
        final updatedUnreadCounts = Map<String, int>.from(chat.unreadCounts);
        updatedUnreadCounts[userId] = 0;

        transaction.update(chatRef, {'unreadCounts': updatedUnreadCounts});
      }

      // Mark recent messages as read by this user
      final messagesQuery = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      for (final messageDoc in messagesQuery.docs) {
        final message = ChatMessage.fromFirestore(messageDoc);
        if (!message.readBy.contains(userId)) {
          final updatedReadBy = [...message.readBy, userId];
          transaction.update(messageDoc.reference, {'readBy': updatedReadBy});
        }
      }
    });
  }

  // Get or create direct chat between two users
  Future<String> getOrCreateDirectChat(String userId1, String userId2) async {
    // Check if chat already exists
    final existingChats = await _chatsCollection
        .where('type', isEqualTo: ChatType.direct.name)
        .where('participantIds', arrayContains: userId1)
        .get();

    for (final doc in existingChats.docs) {
      final chat = Chat.fromFirestore(doc);
      if (chat.participantIds.contains(userId2)) {
        return doc.id;
      }
    }

    // Create new direct chat
    // This would need actual user data from UserService
    final chatId = await createChat(
      name: 'Chat Direct',
      participantIds: [userId1, userId2],
      participants: [
        ChatParticipant(
          userId: userId1,
          name: 'Utilisateur 1',
          isOnline: false,
          role: ChatRole.member,
        ),
        ChatParticipant(
          userId: userId2,
          name: 'Utilisateur 2',
          isOnline: false,
          role: ChatRole.member,
        ),
      ],
      createdBy: userId1,
      type: ChatType.direct,
    );

    return chatId;
  }

  // Get chat by id
  Future<Chat?> getChatById(String chatId) async {
    final doc = await _chatsCollection.doc(chatId).get();
    if (doc.exists) {
      return Chat.fromFirestore(doc);
    }
    return null;
  }

  // Search chats
  Future<List<Chat>> searchChats(String userId, String query) async {
    final chats = await _chatsCollection
        .where('participantIds', arrayContains: userId)
        .get();

    return chats.docs
        .map((doc) => Chat.fromFirestore(doc))
        .where((chat) => chat.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get support chat
  Future<String> getSupportChat(String userId) async {
    // Check if support chat exists
    final existingChats = await _chatsCollection
        .where('type', isEqualTo: ChatType.support.name)
        .where('participantIds', arrayContains: userId)
        .get();

    if (existingChats.docs.isNotEmpty) {
      return existingChats.docs.first.id;
    }

    // Create support chat
    final chatId = await createChat(
      name: 'Support FinIMoi',
      participantIds: [userId, 'support_bot'],
      participants: [
        ChatParticipant(
          userId: userId,
          name: 'Utilisateur',
          isOnline: false,
          role: ChatRole.member,
        ),
        ChatParticipant(
          userId: 'support_bot',
          name: 'Support FinIMoi',
          isOnline: true,
          role: ChatRole.support,
        ),
      ],
      createdBy: 'support_bot',
      type: ChatType.support,
    );

    // Send welcome message
    await sendMessage(
      chatId: chatId,
      senderId: 'support_bot',
      senderName: 'Support FinIMoi',
      senderAvatar: '',
      content: 'Bonjour ! Comment puis-je vous aider aujourd\'hui ?',
      type: MessageType.text,
    );

    return chatId;
  }

  Future<String> createGroupChat({
    required String groupName,
    required List<String> memberIds,
    required String createdBy,
  }) async {
    // This is a simplified version. In a real app, you'd fetch user data for participants.
    final participants = memberIds.map((id) => ChatParticipant(
      userId: id,
      name: 'Utilisateur', // Placeholder
      isOnline: false,
      role: id == createdBy ? ChatRole.admin : ChatRole.member,
    )).toList();

    return await createChat(
      name: groupName,
      participantIds: memberIds,
      participants: participants,
      createdBy: createdBy,
      type: ChatType.group,
    );
  }
}

// Providers
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final userChatsProvider = StreamProvider.family<List<Chat>, String>((
  ref,
  userId,
) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getUserChats(userId);
});

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  chatId,
) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getChatMessages(chatId);
});

final chatByIdProvider = FutureProvider.family<Chat?, String>((ref, chatId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getChatById(chatId);
});
