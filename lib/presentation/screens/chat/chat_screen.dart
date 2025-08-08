import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/chat_service.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../data/providers/user_provider.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher une conversation...',
                  border: InputBorder.none,
                ),
                autofocus: true,
                onSubmitted: (value) {
                  // TODO: Implement search
                },
              )
            : const Text('Messages'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ref
                .watch(userChatsProvider(user.id))
                .when(
                  data: (chats) => chats.isEmpty
                      ? _buildEmptyState()
                      : _buildChatList(chats),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildErrorState(error),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatOptions(context),
        backgroundColor: const Color(0xFF6B46C1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez une nouvelle conversation',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showNewChatOptions(context),
            icon: const Icon(Icons.add),
            label: const Text('Nouveau message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B46C1),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<Chat> chats) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return _buildChatTile(chat);
      },
    );
  }

  Widget _buildChatTile(Chat chat) {
    final user = ref.watch(userProfileProvider).value;
    if (user == null) return const SizedBox.shrink();

    final unreadCount = chat.unreadCounts[user.id] ?? 0;
    final lastMessage = chat.lastMessage;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildChatAvatar(chat),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _getChatDisplayName(chat, user.id),
                style: TextStyle(
                  fontWeight: unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF6B46C1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (lastMessage != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getLastMessagePreview(lastMessage),
                      style: TextStyle(
                        color: unreadCount > 0
                            ? Colors.black87
                            : Colors.grey[600],
                        fontWeight: unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(lastMessage.timestamp),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Aucun message',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ],
        ),
        onTap: () => _openChat(chat),
      ),
    );
  }

  Widget _buildChatAvatar(Chat chat) {
    if (chat.type == ChatType.group && chat.groupAvatar != null) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(chat.groupAvatar!),
      );
    }

    if (chat.type == ChatType.support) {
      return const CircleAvatar(
        radius: 24,
        backgroundColor: Color(0xFF6B46C1),
        child: Icon(Icons.support_agent, color: Colors.white),
      );
    }

    // For direct chats, show the other participant's avatar
    final user = ref.watch(userProfileProvider).value;
    if (user != null && chat.participants.length >= 2) {
      final otherParticipant = chat.participants.firstWhere(
        (p) => p.userId != user.id,
      );

      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF6B46C1),
        child: Text(
          _getInitials(otherParticipant.name),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return const CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, color: Colors.white),
    );
  }

  String _getChatDisplayName(Chat chat, String currentUserId) {
    if (chat.type == ChatType.group) {
      return chat.name;
    }

    if (chat.type == ChatType.support) {
      return 'Support FinIMoi';
    }

    // For direct chats, show the other participant's name
    final otherParticipant = chat.participants
        .where((p) => p.userId != currentUserId)
        .firstOrNull;

    return otherParticipant?.name ?? 'Chat';
  }

  String _getLastMessagePreview(ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 Fichier';
      case MessageType.payment:
        if (message.paymentButton != null) {
          switch (message.paymentButton!.type) {
            case PaymentButtonType.pay:
              return '💳 Paiement demandé';
            case PaymentButtonType.request:
              return '💰 Demande de paiement';
            case PaymentButtonType.split:
              return '🧾 Partage de frais';
          }
        }
        return '💳 Message de paiement';
      case MessageType.paymentRequest:
        return '💰 Demande de paiement';
      case MessageType.system:
        return message.content;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'fr').format(timestamp);
    } else {
      return DateFormat('dd/MM/yy').format(timestamp);
    }
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  void _openChat(Chat chat) {
    // Navigate to conversation screen
    context.push('/chat/${chat.id}');
  }

  void _showNewChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nouveau message',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildOptionTile(
                icon: Icons.person_add,
                title: 'Message direct',
                subtitle: 'Envoyer un message à un contact',
                onTap: () {
                  Navigator.pop(context);
                  _showContactPicker();
                },
              ),
              _buildOptionTile(
                icon: Icons.group_add,
                title: 'Nouveau groupe',
                subtitle: 'Créer un groupe de discussion',
                onTap: () {
                  Navigator.pop(context);
                  _showGroupCreation();
                },
              ),
              _buildOptionTile(
                icon: Icons.support_agent,
                title: 'Contacter le support',
                subtitle: 'Obtenir de l\'aide',
                onTap: () async {
                  Navigator.pop(context);
                  await _openSupportChat();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF6B46C1).withOpacity(0.1),
        child: Icon(icon, color: const Color(0xFF6B46C1)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _showContactPicker() {
    // TODO: Implement contact picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sélection de contact à implémenter'),
        backgroundColor: Color(0xFF6B46C1),
      ),
    );
  }

  void _showGroupCreation() {
    // TODO: Implement group creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Création de groupe à implémenter'),
        backgroundColor: Color(0xFF6B46C1),
      ),
    );
  }

  Future<void> _openSupportChat() async {
    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

    try {
      final chatService = ref.read(chatServiceProvider);
      final supportChatId = await chatService.getSupportChat(user.id);

      if (mounted) {
        context.push('/chat/$supportChatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
