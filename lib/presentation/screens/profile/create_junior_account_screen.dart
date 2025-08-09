import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/presentation/widgets/common/custom_text_field.dart';
import 'package:finimoi/presentation/widgets/common/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:finimoi/data/providers/user_provider.dart';
import 'package:finimoi/data/providers/auth_provider.dart';

class CreateJuniorAccountScreen extends ConsumerStatefulWidget {
  const CreateJuniorAccountScreen({super.key});

  @override
  ConsumerState<CreateJuniorAccountScreen> createState() =>
      _CreateJuniorAccountScreenState();
}

class _CreateJuniorAccountScreenState
    extends ConsumerState<CreateJuniorAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final parentId = ref.read(currentUserProvider)?.uid;
    if (parentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Utilisateur parent non trouvé.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await ref.read(userServiceProvider).createJuniorAccount(
        parentAccountId: parentId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );
      if (mounted) {
        ref.invalidate(juniorAccountsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Créer un Compte Junior'),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _firstNameController,
                label: 'Prénom de l\'enfant',
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _lastNameController,
                label: 'Nom de l\'enfant',
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Créer le Compte',
                onPressed: _createAccount,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
