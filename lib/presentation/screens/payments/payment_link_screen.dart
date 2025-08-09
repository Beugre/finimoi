import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class PaymentLinkScreen extends ConsumerStatefulWidget {
  const PaymentLinkScreen({super.key});

  @override
  ConsumerState<PaymentLinkScreen> createState() => _PaymentLinkScreenState();
}

class _PaymentLinkScreenState extends ConsumerState<PaymentLinkScreen> {
  final _amountController = TextEditingController();
  String _generatedLink = '';

  void _generateLink() {
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) return;

    final amount = _amountController.text;
    String link = 'finimoi://pay?userId=$userId';
    if (amount.isNotEmpty) {
      link += '&amount=$amount';
    }

    setState(() {
      _generatedLink = link;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Générer un lien de paiement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Créer un lien de paiement',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _amountController,
              label: 'Montant (optionnel)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Générer le lien',
              onPressed: _generateLink,
            ),
            if (_generatedLink.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Lien généré:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _generatedLink,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _generatedLink));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lien copié!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
