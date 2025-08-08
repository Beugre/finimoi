import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/services/chat_service.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../data/providers/user_provider.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ConversationScreen({super.key, required this.chatId});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _isComposing = _messageController.text.isNotEmpty;
      });
    });

    // Mark messages as read when entering conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markMessagesAsRead() {
    final user = ref.read(userProfileProvider).value;
    if (user != null) {
      ref.read(chatServiceProvider).markMessagesAsRead(widget.chatId, user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatByIdProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final user = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B46C1),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: chatAsync.when(
          data: (chat) => chat != null
              ? Row(
                  children: [
                    _buildChatAvatar(chat),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getChatDisplayName(chat, user?.id ?? ''),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (chat.type == ChatType.direct &&
                              chat.participants.length >= 2)
                            Text(
                              _getOnlineStatus(chat, user?.id ?? ''),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              : const Text('Chat'),
          loading: () => const Text('Chargement...'),
          error: (_, __) => const Text('Erreur'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => _showFeatureComingSoon('Appel vidéo'),
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _showFeatureComingSoon('Appel vocal'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Text('Informations'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off),
                    SizedBox(width: 12),
                    Text('Désactiver notifications'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 12),
                    Text('Effacer conversation'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => messages.isEmpty
                  ? _buildEmptyMessagesState()
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == user?.id;
                        final showAvatar =
                            !isMe &&
                            (index == 0 ||
                                messages[index - 1].senderId !=
                                    message.senderId);
                        final showTimestamp =
                            index == 0 ||
                            _shouldShowTimestamp(message, messages[index - 1]);

                        return _buildMessageBubble(
                          message,
                          isMe,
                          showAvatar,
                          showTimestamp,
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Erreur: ${error.toString()}')),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatAvatar(Chat chat) {
    if (chat.type == ChatType.support) {
      return const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white24,
        child: Icon(Icons.support_agent, color: Colors.white, size: 20),
      );
    }

    final user = ref.watch(userProfileProvider).value;
    if (user != null && chat.participants.length >= 2) {
      final otherParticipant = chat.participants.firstWhere(
        (p) => p.userId != user.id,
      );

      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white24,
        child: Text(
          _getInitials(otherParticipant.name),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    return const CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white24,
      child: Icon(Icons.person, color: Colors.white, size: 20),
    );
  }

  String _getChatDisplayName(Chat chat, String currentUserId) {
    if (chat.type == ChatType.group) {
      return chat.name;
    }

    if (chat.type == ChatType.support) {
      return 'Support FinIMoi';
    }

    final otherParticipant = chat.participants
        .where((p) => p.userId != currentUserId)
        .firstOrNull;

    return otherParticipant?.name ?? 'Chat';
  }

  String _getOnlineStatus(Chat chat, String currentUserId) {
    if (chat.type == ChatType.support) {
      return 'En ligne';
    }

    final otherParticipant = chat.participants
        .where((p) => p.userId != currentUserId)
        .firstOrNull;

    return otherParticipant?.isOnline == true ? 'En ligne' : 'Hors ligne';
  }

  Widget _buildEmptyMessagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envoyez votre premier message',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isMe,
    bool showAvatar,
    bool showTimestamp,
  ) {
    return Column(
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _formatMessageTimestamp(message.timestamp),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe && showAvatar)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF6B46C1),
                    child: Text(
                      _getInitials(message.senderName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (!isMe)
                const SizedBox(width: 40),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  margin: EdgeInsets.only(
                    left: isMe ? 40 : 0,
                    right: isMe ? 0 : 40,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF6B46C1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomLeft: !isMe && showAvatar
                          ? const Radius.circular(4)
                          : null,
                      bottomRight: isMe ? const Radius.circular(4) : null,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe && message.type != MessageType.system)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            message.senderName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      _buildMessageContent(message, isMe),
                      if (message.paymentButton != null)
                        _buildPaymentButton(message.paymentButton!, isMe),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(message.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.grey[500],
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 12,
                              color: message.isRead
                                  ? Colors.blue
                                  : Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent(ChatMessage message, bool isMe) {
    switch (message.type) {
      case MessageType.text:
      case MessageType.system:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.image, size: 50)),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        );
      case MessageType.file:
        return Row(
          children: [
            Icon(
              Icons.attach_file,
              color: isMe ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      case MessageType.payment:
      case MessageType.paymentRequest:
        return Row(
          children: [
            Icon(
              Icons.payment,
              color: isMe ? Colors.white : const Color(0xFF6B46C1),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildPaymentButton(PaymentButton paymentButton, bool isMe) {
    final user = ref.watch(userProfileProvider).value;
    final canInteract = user != null && !paymentButton.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withAlpha(20)
              : const Color(0xFF6B46C1).withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMe
                ? Colors.white30
                : const Color(0xFF6B46C1).withAlpha(50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPaymentButtonIcon(paymentButton.type),
                  color: isMe ? Colors.white : const Color(0xFF6B46C1),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    paymentButton.description,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${NumberFormat('#,###').format(paymentButton.amount)} ${paymentButton.currency}',
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF6B46C1),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (paymentButton.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Payé',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (canInteract)
                  ElevatedButton(
                    onPressed: () => _handlePaymentAction(paymentButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMe
                          ? Colors.white
                          : const Color(0xFF6B46C1),
                      foregroundColor: isMe
                          ? const Color(0xFF6B46C1)
                          : Colors.white,
                      minimumSize: const Size(80, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(
                      _getPaymentButtonText(paymentButton.type),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF6B46C1)),
            onPressed: () => _showAttachmentOptions(),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Tapez votre message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: Icon(
                _isComposing ? Icons.send : Icons.mic,
                color: const Color(0xFF6B46C1),
              ),
              onPressed: _isComposing ? _sendMessage : _startVoiceMessage,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowTimestamp(ChatMessage current, ChatMessage previous) {
    final timeDiff = current.timestamp.difference(previous.timestamp);
    return timeDiff.inMinutes > 30;
  }

  String _formatMessageTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays == 1) {
      return 'Hier à ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${DateFormat('EEEE', 'fr').format(timestamp)} à ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return DateFormat('dd/MM/yyyy à HH:mm', 'fr').format(timestamp);
    }
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  IconData _getPaymentButtonIcon(PaymentButtonType type) {
    switch (type) {
      case PaymentButtonType.pay:
        return Icons.payment;
      case PaymentButtonType.request:
        return Icons.request_quote;
      case PaymentButtonType.split:
        return Icons.receipt_long;
    }
  }

  String _getPaymentButtonText(PaymentButtonType type) {
    switch (type) {
      case PaymentButtonType.pay:
        return 'Payer';
      case PaymentButtonType.request:
        return 'Envoyer';
      case PaymentButtonType.split:
        return 'Partager';
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

    final chatService = ref.read(chatServiceProvider);
    chatService.sendMessage(
      chatId: widget.chatId,
      senderId: user.id,
      senderName: '${user.firstName} ${user.lastName}',
      senderAvatar: user.profileImageUrl ?? '',
      content: text,
      type: MessageType.text,
    );

    _messageController.clear();
  }

  void _startVoiceMessage() {
    _showFeatureComingSoon('Message vocal');
  }

  void _showAttachmentOptions() {
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
                'Envoyer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo,
                    label: 'Photo',
                    onTap: () {
                      Navigator.pop(context);
                      _showFeatureComingSoon('Envoi de photo');
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.videocam,
                    label: 'Vidéo',
                    onTap: () {
                      Navigator.pop(context);
                      _showFeatureComingSoon('Envoi de vidéo');
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.attach_file,
                    label: 'Fichier',
                    onTap: () {
                      Navigator.pop(context);
                      _showFeatureComingSoon('Envoi de fichier');
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.payment,
                    label: 'Paiement',
                    onTap: () {
                      Navigator.pop(context);
                      _showPaymentOptions();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF6B46C1).withAlpha(20),
            child: Icon(icon, color: const Color(0xFF6B46C1)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showPaymentOptions() {
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
                'Options de paiement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPaymentOption(
                icon: Icons.payment,
                title: 'Demander un paiement',
                subtitle: 'Créer une demande de paiement',
                onTap: () {
                  Navigator.pop(context);
                  _showPaymentRequestDialog(PaymentButtonType.request);
                },
              ),
              _buildPaymentOption(
                icon: Icons.send,
                title: 'Envoyer de l\'argent',
                subtitle: 'Transférer de l\'argent',
                onTap: () {
                  Navigator.pop(context);
                  _showPaymentRequestDialog(PaymentButtonType.pay);
                },
              ),
              _buildPaymentOption(
                icon: Icons.receipt_long,
                title: 'Partager les frais',
                subtitle: 'Diviser une facture',
                onTap: () {
                  Navigator.pop(context);
                  _showPaymentRequestDialog(PaymentButtonType.split);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF6B46C1).withAlpha(20),
        child: Icon(icon, color: const Color(0xFF6B46C1)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _showPaymentRequestDialog(PaymentButtonType type) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_getPaymentDialogTitle(type)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Ex: Déjeuner, Transport...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendPaymentMessage(
                  type,
                  descriptionController.text,
                  double.tryParse(amountController.text) ?? 0,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );
  }

  String _getPaymentDialogTitle(PaymentButtonType type) {
    switch (type) {
      case PaymentButtonType.pay:
        return 'Envoyer de l\'argent';
      case PaymentButtonType.request:
        return 'Demander un paiement';
      case PaymentButtonType.split:
        return 'Partager les frais';
    }
  }

  void _sendPaymentMessage(
    PaymentButtonType type,
    String description,
    double amount,
  ) {
    if (description.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

    final chatService = ref.read(chatServiceProvider);
    chatService.sendPaymentMessage(
      chatId: widget.chatId,
      senderId: user.id,
      senderName: '${user.firstName} ${user.lastName}',
      senderAvatar: user.profileImageUrl ?? '',
      description: description,
      amount: amount,
      buttonType: type,
    );
  }

  void _handlePaymentAction(PaymentButton paymentButton) {
    _showFeatureComingSoon('Action de paiement');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'info':
        _showFeatureComingSoon('Informations du chat');
        break;
      case 'mute':
        _showFeatureComingSoon('Désactiver notifications');
        break;
      case 'clear':
        _showFeatureComingSoon('Effacer conversation');
        break;
    }
  }

  void _showFeatureComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature activé ! Redirection en cours...'),
        backgroundColor: const Color(0xFF6B46C1),
      ),
    );
  }
}
