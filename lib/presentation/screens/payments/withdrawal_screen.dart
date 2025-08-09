import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/stripe_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  String _method = 'mobile_money';
  bool _isLoading = false;
  final StripeService _stripeService = StripeService();

  Future<void> _withdraw() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    if (_method == 'stripe') {
      await _stripeService.transferToBank();
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Virement Stripe simulé initié.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userId = ref.read(currentUserProvider)?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final amount = double.parse(_amountController.text);
      final details = _detailsController.text;

      await PaymentService.withdraw(
        userId: userId,
        amount: amount,
        method: _method,
        details: details,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retrait initié avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retirer de l\'argent')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Effectuer un retrait',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: _method,
                items: const [
                  DropdownMenuItem(
                    value: 'mobile_money',
                    child: Text('Mobile Money'),
                  ),
                  DropdownMenuItem(
                    value: 'bank_account',
                    child: Text('Compte Bancaire'),
                  ),
                  DropdownMenuItem(
                    value: 'stripe',
                    child: Text('Virement Stripe (International)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _method = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Méthode de retrait',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amountController,
                label: 'Montant',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _detailsController,
                label: _method == 'mobile_money'
                    ? 'Numéro de téléphone'
                    : 'IBAN',
                keyboardType: _method == 'mobile_money'
                    ? TextInputType.phone
                    : TextInputType.text,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Effectuer le retrait',
                onPressed: _withdraw,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
