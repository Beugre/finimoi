import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/presentation/widgets/common/custom_text_field.dart';
import 'package:finimoi/presentation/widgets/common/custom_button.dart';
import 'package:finimoi/data/providers/donation_provider.dart';
import 'package:go_router/go_router.dart';

class DonationScreen extends ConsumerStatefulWidget {
  final String orphanageId;
  final String orphanageName;
  const DonationScreen({super.key, required this.orphanageId, required this.orphanageName});

  @override
  ConsumerState<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends ConsumerState<DonationScreen> {
  final _amountController = TextEditingController();
  bool _isRecurring = false;
  bool _isLoading = false;

  void _makeDonation() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(donationServiceProvider).makeDonation(
        orphanageId: widget.orphanageId,
        amount: amount,
        isRecurring: _isRecurring,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merci pour votre don!')),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Don à ${widget.orphanageName}'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: _amountController,
              label: 'Montant du don (FCFA)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Faire de ce don un don mensuel'),
              value: _isRecurring,
              onChanged: (value) => setState(() => _isRecurring = value),
            ),
            const Spacer(),
            CustomButton(
              text: 'Faire un don',
              onPressed: _makeDonation,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
