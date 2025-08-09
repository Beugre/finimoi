import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/presentation/widgets/common/custom_text_field.dart';
import 'package:finimoi/presentation/widgets/common/custom_button.dart';
import 'package:finimoi/data/providers/subscription_provider.dart';

class CreateSubscriptionPlanScreen extends ConsumerStatefulWidget {
  const CreateSubscriptionPlanScreen({super.key});

  @override
  ConsumerState<CreateSubscriptionPlanScreen> createState() =>
      _CreateSubscriptionPlanScreenState();
}

class _CreateSubscriptionPlanScreenState
    extends ConsumerState<CreateSubscriptionPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final _amountController = TextEditingController();
  String _frequency = 'monthly'; // Default frequency
  bool _isLoading = false;

  @override
  void dispose() {
    _planNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _createPlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    final planName = _planNameController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    try {
      await ref.read(subscriptionServiceProvider).createSubscriptionPlan(
            planName: planName,
            amount: amount,
            frequency: _frequency,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan créé avec succès!')),
        );
        // Invalidate provider to refresh the list on the previous screen
        ref.invalidate(merchantSubscriptionPlansProvider);
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
      appBar: const CustomAppBar(title: 'Créer un Plan d\'Abonnement'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _planNameController,
                label: 'Nom du Plan',
                hint: 'Ex: Abonnement Premium',
                validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amountController,
                label: 'Montant (FCFA)',
                hint: 'Ex: 5000',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Ce champ est requis';
                  if (double.tryParse(value) == null) return 'Veuillez entrer un nombre valide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Fréquence',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Hebdomadaire')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensuel')),
                  DropdownMenuItem(value: 'yearly', child: Text('Annuel')),
                ],
                onChanged: (value) {
                  setState(() {
                    _frequency = value!;
                  });
                },
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Créer le Plan',
                onPressed: _createPlan,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
