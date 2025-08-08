import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/transfer_service.dart';

class BankTransferDialog extends ConsumerStatefulWidget {
  final VoidCallback? onTransferComplete;

  const BankTransferDialog({super.key, this.onTransferComplete});

  @override
  ConsumerState<BankTransferDialog> createState() => _BankTransferDialogState();
}

class _BankTransferDialogState extends ConsumerState<BankTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  String _selectedBank = 'SGBCI';

  final List<Map<String, String>> _banks = [
    {'code': 'SGBCI', 'name': 'Société Générale'},
    {'code': 'BICICI', 'name': 'BICICI'},
    {'code': 'BACI', 'name': 'Banque Atlantique'},
    {'code': 'ECOBANK', 'name': 'Ecobank'},
    {'code': 'BOA', 'name': 'Bank of Africa'},
    {'code': 'UBA', 'name': 'UBA'},
    {'code': 'NSIA', 'name': 'NSIA Banque'},
    {'code': 'VERSUS', 'name': 'Versus Bank'},
  ];

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _executeTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final accountNumber = _accountNumberController.text.trim();
      final accountName = _accountNameController.text.trim();
      final amount = double.parse(_amountController.text);
      final message = _messageController.text.trim();

      await TransferService.transferToBank(
        senderId: currentUser.uid,
        bankCode: _selectedBank,
        accountNumber: accountNumber,
        accountName: accountName,
        amount: amount,
        description: message.isEmpty
            ? 'Virement bancaire via FinIMoi'
            : message,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Virement bancaire initié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onTransferComplete?.call();
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
    return AlertDialog(
      title: const Text('Virement Bancaire'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sélection de la banque
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: const InputDecoration(
                  labelText: 'Banque',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(),
                ),
                items: _banks.map((bank) {
                  return DropdownMenuItem(
                    value: bank['code'],
                    child: Text(bank['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedBank = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Numéro de compte
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Numéro de compte',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir le numéro de compte';
                  }
                  if (value.length < 10) {
                    return 'Numéro de compte invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Nom du compte
              TextFormField(
                controller: _accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du titulaire',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir le nom du titulaire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Montant
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Montant (XOF)',
                  prefixIcon: Icon(Icons.monetization_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un montant';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide';
                  }
                  if (amount < 500) {
                    return 'Montant minimum: 500 XOF';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Message (optionnel)
              TextFormField(
                controller: _messageController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motif du virement (optionnel)',
                  prefixIcon: Icon(Icons.message),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Avertissement
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les virements bancaires peuvent prendre 1-3 jours ouvrables',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _executeTransfer,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Effectuer'),
        ),
      ],
    );
  }
}
