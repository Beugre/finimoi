import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/merchant_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../domain/entities/transfer_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class MerchantPaymentScreen extends ConsumerStatefulWidget {
  final String merchantId;
  const MerchantPaymentScreen({super.key, required this.merchantId});

  @override
  ConsumerState<MerchantPaymentScreen> createState() =>
      _MerchantPaymentScreenState();
}

class _MerchantPaymentScreenState extends ConsumerState<MerchantPaymentScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _submitPayment(String merchantName) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final amount = double.parse(_amountController.text);
        final result = await ref.read(transferServiceProvider).performTransfer(
              TransferRequest(
                recipientId: widget.merchantId,
                recipientName: merchantName,
                amount: amount,
                type: TransferType.qrCode,
                description: 'Paiement à $merchantName',
              ),
            );

        if (mounted) {
          if (result.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Paiement effectué avec succès!'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/home');
          } else {
            throw Exception(result.error);
          }
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
  }

  @override
  Widget build(BuildContext context) {
    final merchantProfileAsync = ref.watch(merchantProfileProvider(widget.merchantId));

    return Scaffold(
      appBar: AppBar(title: const Text('Payer le Marchand')),
      body: merchantProfileAsync.when(
        data: (merchant) {
          if (merchant == null) {
            return const Center(child: Text('Marchand non trouvé.'));
          }
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    child: Text(
                      merchant.businessName.substring(0, 2).toUpperCase(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Paiement à ${merchant.businessName}',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _amountController,
                    label: 'Montant',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.money,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le montant est requis';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Montant invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Payer',
                    onPressed: () => _submitPayment(merchant.businessName),
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
