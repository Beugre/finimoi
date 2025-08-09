import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/user_service.dart';
import '../../../data/services/chat_service.dart';
import '../../../domain/entities/chat_message.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class RequestMoneyScreen extends ConsumerStatefulWidget {
  const RequestMoneyScreen({super.key});

  @override
  ConsumerState<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends ConsumerState<RequestMoneyScreen> {
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final recipientEmail = _emailController.text.trim();
      // final amount = double.parse(_amountController.text);
      // final description = _descriptionController.text.trim();

      // Vérifier que l'utilisateur destinataire existe
      final recipient = await UserService.findUserByEmail(recipientEmail);
      if (recipient == null) {
        throw Exception('Aucun utilisateur trouvé avec cet email');
      }

      if (recipient.id == currentUser.uid) {
        throw Exception(
          'Vous ne pouvez pas vous demander de l\'argent à vous-même',
        );
      }

      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();
      final chatService = ref.read(chatServiceProvider);

      final chatId =
          await chatService.getOrCreateDirectChat(currentUser.uid, recipient.id);

      await chatService.sendPaymentMessage(
        chatId: chatId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Utilisateur',
        senderAvatar: currentUser.photoURL ?? '',
        description: description,
        amount: amount,
        buttonType: PaymentButtonType.request,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande envoyée à ${recipient.fullName}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Demander de l\'argent',
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryViolet.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primaryViolet),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Créez une demande de paiement et l\'utilisateur recevra une notification.',
                        style: TextStyle(
                          color: AppColors.primaryViolet,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Email field
              Text(
                'Email du destinataire',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'exemple@email.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Amount field
              Text(
                'Montant (FCFA)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _amountController,
                label: 'Montant',
                hint: '0',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide';
                  }
                  if (amount < 100) {
                    return 'Montant minimum: 100 FCFA';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Description field
              Text(
                'Description (optionnel)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Motif de la demande...',
                maxLines: 3,
                prefixIcon: Icons.description_outlined,
              ),

              const SizedBox(height: 48),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isLoading ? 'Création...' : 'Créer la demande',
                  onPressed: _isLoading ? null : _createRequest,
                  variant: ButtonVariant.primary,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
