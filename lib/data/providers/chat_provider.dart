import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/real_chat_service.dart';
import '../models/message_model.dart';

// Provider pour les conversations de l'utilisateur
final userConversationsProvider = StreamProvider<List<ConversationModel>>((
  ref,
) {
  return RealChatService.getUserConversations();
});

// Provider pour les messages d'une conversation spécifique
final conversationMessagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, conversationId) {
      return RealChatService.getConversationMessages(conversationId);
    });

// Provider pour le nombre de messages non lus
final unreadMessagesCountProvider = StreamProvider<int>((ref) {
  return RealChatService.getUnreadMessagesCount();
});

// Provider pour la recherche d'utilisateurs
final userSearchProvider =
    FutureProvider.family<List<UserSearchResult>, String>((ref, query) {
      return RealChatService.searchUsers(query);
    });

// Provider pour les informations d'un utilisateur
final userInfoProvider = FutureProvider.family<UserInfo?, String>((
  ref,
  userId,
) {
  return RealChatService.getUserInfo(userId);
});

// Provider pour gérer l'état du chat (conversation actuelle, etc.)
final chatStateProvider = StateNotifierProvider<ChatStateNotifier, ChatState>((
  ref,
) {
  return ChatStateNotifier();
});

class ChatState {
  final String? currentConversationId;
  final bool isTyping;
  final String? typingUserId;
  final bool isSearching;
  final List<UserSearchResult> searchResults;

  ChatState({
    this.currentConversationId,
    this.isTyping = false,
    this.typingUserId,
    this.isSearching = false,
    this.searchResults = const [],
  });

  ChatState copyWith({
    String? currentConversationId,
    bool? isTyping,
    String? typingUserId,
    bool? isSearching,
    List<UserSearchResult>? searchResults,
  }) {
    return ChatState(
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      isTyping: isTyping ?? this.isTyping,
      typingUserId: typingUserId ?? this.typingUserId,
      isSearching: isSearching ?? this.isSearching,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}

class ChatStateNotifier extends StateNotifier<ChatState> {
  ChatStateNotifier() : super(ChatState());

  void setCurrentConversation(String? conversationId) {
    state = state.copyWith(currentConversationId: conversationId);
  }

  void setTyping(bool isTyping, {String? userId}) {
    state = state.copyWith(isTyping: isTyping, typingUserId: userId);
  }

  void setSearching(bool isSearching) {
    state = state.copyWith(isSearching: isSearching);
  }

  void updateSearchResults(List<UserSearchResult> results) {
    state = state.copyWith(searchResults: results);
  }

  void clearSearchResults() {
    state = state.copyWith(searchResults: []);
  }
}

// Controller pour les actions du chat
final chatControllerProvider = Provider((ref) => ChatController(ref));

class ChatController {
  final Ref _ref;

  ChatController(this._ref);

  // Envoyer un message texte
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    await RealChatService.sendMessage(
      conversationId: conversationId,
      content: content,
      type: MessageType.text,
    );
  }

  // Envoyer une demande d'argent
  Future<void> sendMoneyRequest({
    required String conversationId,
    required double amount,
    required String currency,
    String? reason,
  }) async {
    await RealChatService.sendMoneyRequest(
      conversationId: conversationId,
      amount: amount,
      currency: currency,
      reason: reason,
    );
  }

  // Envoyer un transfert d'argent
  Future<void> sendMoneyTransfer({
    required String conversationId,
    required double amount,
    required String currency,
    required String transactionId,
    String? message,
  }) async {
    await RealChatService.sendMoneyTransfer(
      conversationId: conversationId,
      amount: amount,
      currency: currency,
      transactionId: transactionId,
      message: message,
    );
  }

  // Créer une nouvelle conversation
  Future<String> createConversation({
    required String otherUserId,
    String? initialMessage,
  }) async {
    return await RealChatService.createConversation(
      otherUserId: otherUserId,
      initialMessage: initialMessage,
    );
  }

  // Marquer les messages comme lus
  Future<void> markMessagesAsRead(String conversationId) async {
    await RealChatService.markMessagesAsRead(conversationId);
  }

  // Rechercher des utilisateurs
  Future<void> searchUsers(String query) async {
    final chatState = _ref.read(chatStateProvider.notifier);

    if (query.trim().isEmpty) {
      chatState.clearSearchResults();
      return;
    }

    chatState.setSearching(true);

    try {
      final results = await RealChatService.searchUsers(query);
      chatState.updateSearchResults(results);
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      chatState.clearSearchResults();
    } finally {
      chatState.setSearching(false);
    }
  }

  // Supprimer une conversation
  Future<void> deleteConversation(String conversationId) async {
    await RealChatService.deleteConversation(conversationId);
  }

  // Obtenir les informations d'un utilisateur
  Future<UserInfo?> getUserInfo(String userId) async {
    return await RealChatService.getUserInfo(userId);
  }
}
