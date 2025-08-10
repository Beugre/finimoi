import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StripePaymentTestWidget extends ConsumerStatefulWidget {
  const StripePaymentTestWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<StripePaymentTestWidget> createState() => _StripePaymentTestWidgetState();
}

class _StripePaymentTestWidgetState extends ConsumerState<StripePaymentTestWidget> {
  final TextEditingController _amountController = TextEditingController(text: '1000');
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _testCardPayment() async {
    if (_amountController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      
      // Simuler la création d'un PaymentIntent
      // Dans une vraie app, ceci se ferait via votre backend
      final paymentIntentData = await _createTestPaymentIntent(amount);
      
      // Initialiser la feuille de paiement
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'FinIMoi',
          style: ThemeMode.system,
          billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
            name: CollectionMode.always,
            email: CollectionMode.always,
            phone: CollectionMode.always,
          ),
        ),
      );

      // Présenter la feuille de paiement
      await Stripe.instance.presentPaymentSheet();
      
      // Si on arrive ici, le paiement a réussi
      _showSuccessDialog();
      
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _createTestPaymentIntent(double amount) async {
    // ⚠️ ATTENTION: Ceci est un exemple POUR LES TESTS UNIQUEMENT
    // Dans une vraie application, cette logique doit être sur votre backend sécurisé
    
    // Pour les tests, nous simulons la réponse d'un PaymentIntent
    // En réalité, vous devez appeler votre backend qui utilisera la clé secrète
    
    throw Exception(
      'Configuration backend requise!\n\n'
      'Pour utiliser Stripe en production, vous devez:\n'
      '1. Créer un backend sécurisé\n'
      '2. Créer un endpoint qui utilise la clé secrète\n'
      '3. Retourner le client_secret du PaymentIntent\n\n'
      'Consultez la documentation Stripe pour plus d\'infos.'
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Paiement réussi!'),
        content: const Text('Le paiement a été traité avec succès.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Erreur de paiement'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Paiement Stripe'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '💳 Test des paiements Stripe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            const Text(
              'Montant (en FCFA):',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: 1000',
                prefixText: 'FCFA ',
                suffixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 30),
            
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber),
              ),
              child: const Text(
                '⚠️ Pour utiliser cette fonctionnalité:\n'
                '1. Configurez votre backend\n'
                '2. Créez les endpoints PaymentIntent\n'
                '3. Utilisez la clé secrète côté serveur uniquement',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testCardPayment,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payment),
              label: Text(_isLoading ? 'Traitement...' : 'Tester le paiement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            
            const Divider(),
            
            const Text(
              '📋 Informations Stripe:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ Clé publique configurée'),
                  const Text('⚠️ Backend requis pour les PaymentIntents'),
                  const Text('🔒 Clé secrète dans .env (sécurisée)'),
                  const Text('🚫 Clé secrète NOT dans le code mobile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
