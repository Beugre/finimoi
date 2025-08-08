import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/services/cinetpay_service.dart';
import '../../../data/providers/auth_provider.dart';

class CinetPayPaymentScreen extends ConsumerStatefulWidget {
  final double amount;
  final String currency; // XOF ou EUR
  final String type; // 'recharge', 'payment', etc.
  final Map<String, dynamic>? metadata;

  const CinetPayPaymentScreen({
    super.key,
    required this.amount,
    this.currency = 'XOF',
    required this.type,
    this.metadata,
  });

  @override
  ConsumerState<CinetPayPaymentScreen> createState() =>
      _CinetPayPaymentScreenState();
}

class _CinetPayPaymentScreenState extends ConsumerState<CinetPayPaymentScreen> {
  bool _isLoading = false;
  String? _selectedPaymentMethod;
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'recharge' ? 'Recharge CinetPay' : 'Paiement CinetPay',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: userAsync.when(
        data: (currentUser) => currentUser != null
            ? _buildPaymentForm(currentUser)
            : const Center(child: Text('Utilisateur non connecté')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildPaymentForm(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Résumé du montant
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Montant à payer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.currency == 'EUR'
                        ? '${widget.amount.toStringAsFixed(2)} €'
                        : '${widget.amount.toStringAsFixed(0)} XOF',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Méthodes de paiement
          Text(
            'Choisir une méthode de paiement',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Orange Money
          _buildPaymentMethodTile(
            'ORANGE_MONEY_CI',
            'Orange Money',
            'assets/images/orange_money.png',
            Colors.orange,
          ),

          // MTN Money
          _buildPaymentMethodTile(
            'MOOV_MONEY_CI',
            'Moov Money',
            'assets/images/moov_money.png',
            Colors.blue,
          ),

          // Wave
          _buildPaymentMethodTile(
            'WAVE_CI',
            'Wave',
            'assets/images/wave.png',
            Colors.blue[800]!,
          ),

          // Visa/Mastercard
          _buildPaymentMethodTile(
            'CARD',
            'Carte bancaire',
            'assets/images/cards.png',
            Colors.grey[700]!,
          ),

          const SizedBox(height: 24),

          // Champ numéro de téléphone pour mobile money
          if (_selectedPaymentMethod != null &&
              _selectedPaymentMethod != 'CARD')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Numéro de téléphone',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Ex: +225 0123456789',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),

          // Bouton de paiement
          ElevatedButton(
            onPressed: _selectedPaymentMethod != null && !_isLoading
                ? _processPayment
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.currency == 'EUR'
                        ? 'Payer ${widget.amount.toStringAsFixed(2)} €'
                        : 'Payer ${widget.amount.toStringAsFixed(0)} XOF',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // Information sécurisée
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paiement sécurisé par CinetPay',
                    style: TextStyle(color: Colors.green[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    String methodId,
    String title,
    String iconPath,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod == methodId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = methodId;
          if (methodId == 'CARD') {
            _phoneController.clear();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPaymentMethodIcon(methodId),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.black87,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String methodId) {
    switch (methodId) {
      case 'ORANGE_MONEY_CI':
        return Icons.phone_android;
      case 'MOOV_MONEY_CI':
        return Icons.smartphone;
      case 'WAVE_CI':
        return Icons.waves;
      case 'CARD':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) return;

    // Validation du numéro pour mobile money
    if (_selectedPaymentMethod != 'CARD' &&
        _phoneController.text.trim().isEmpty) {
      _showErrorDialog('Veuillez saisir votre numéro de téléphone');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userAsync = ref.read(authStateProvider);
      final user = userAsync.value;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Initier le paiement avec CinetPay
      final cinetPayService = ref.read(cinetPayServiceProvider);
      final transaction = await cinetPayService.initiatePayment(
        amount: widget.amount,
        currency: widget.currency,
        paymentMethod: _selectedPaymentMethod ?? 'ORANGE_MONEY_CI',
        userId: user.uid,
        description:
            'Paiement FinIMoi - ${widget.amount.toStringAsFixed(0)} ${widget.currency}',
      );

      // Ouvrir l'URL de paiement
      final uri = Uri.parse(transaction.paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Retourner à l'écran précédent après le lancement
        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessDialog('Redirection vers CinetPay effectuée');
        }
      } else {
        throw Exception('Impossible d\'ouvrir l\'URL de paiement');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erreur lors du paiement: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Succès'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
