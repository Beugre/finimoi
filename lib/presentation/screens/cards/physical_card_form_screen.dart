import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/card_providers.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class PhysicalCardFormScreen extends ConsumerStatefulWidget {
  const PhysicalCardFormScreen({super.key});

  @override
  ConsumerState<PhysicalCardFormScreen> createState() =>
      _PhysicalCardFormScreenState();
}

class _PhysicalCardFormScreenState
    extends ConsumerState<PhysicalCardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  bool _isLoading = false;

  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final cardId = await ref.read(createCardProvider({
          'cardType': 'debit',
          'cardName': 'Carte Physique',
          'isVirtual': false,
          'limit': 1000000.0,
        }).future);

        if (cardId != null) {
          // In a real app, you would save the address with the order
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Demande de carte physique envoyée!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/cards');
        } else {
          throw Exception('Impossible de commander la carte');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Commander une carte physique')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adresse de livraison',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _addressController,
                label: 'Adresse',
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _cityController,
                label: 'Ville',
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _zipController,
                label: 'Code Postal',
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Commander',
                onPressed: _submitRequest,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
