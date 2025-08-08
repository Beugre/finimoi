import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/real_chat_service.dart';
import '../../data/models/message_model.dart';

// Provider pour les conversations de l'utilisateur
final userConversationsProvider = StreamProvider<List<ConversationModel>>((
  ref,
) {
  return RealChatService.getUserConversations();
});

// Provider pour les messages d'une conversation
final conversationMessagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, conversationId) {
      return RealChatService.getConversationMessages(conversationId);
    });

// Provider pour envoyer un message
final sendMessageProvider = FutureProvider.family<void, Map<String, dynamic>>((
  ref,
  messageData,
) async {
  return RealChatService.sendMessage(
    conversationId: messageData['conversationId'],
    content: messageData['content'],
    type: MessageType.values.firstWhere(
      (e) => e.name == (messageData['type'] ?? 'text'),
      orElse: () => MessageType.text,
    ),
    metadata: messageData['metadata'],
  );
});

// Provider pour créer une conversation
final createConversationProvider =
    FutureProvider.family<String?, Map<String, dynamic>>((
      ref,
      conversationData,
    ) async {
      return RealChatService.createConversation(
        otherUserId: conversationData['otherUserId'],
      );
    });

// Provider pour rechercher des utilisateurs
final searchUsersProvider =
    FutureProvider.family<List<UserSearchResult>, String>((ref, query) async {
      if (query.trim().isEmpty) return [];
      return RealChatService.searchUsers(query);
    });

// Provider pour marquer les messages comme lus
final markMessagesAsReadProvider = FutureProvider.family<void, String>((
  ref,
  conversationId,
) async {
  return RealChatService.markMessagesAsRead(conversationId);
});
