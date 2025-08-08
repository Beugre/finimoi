import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/services/cinetpay_service.dart';
import '../../../data/services/currency_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RechargeScreen extends ConsumerStatefulWidget {
  const RechargeScreen({super.key});

  @override
  ConsumerState<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends ConsumerState<RechargeScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedMethod; // Aucune méthode sélectionnée par défaut
  String _selectedCurrency = 'XOF'; // Devise par défaut
  String _selectedOperator = 'ORANGE_MONEY_CI'; // Opérateur par défaut
  bool _isLoading = false;

  // Montants prédéfinis
  final List<double> _quickAmounts = [1000, 2500, 5000, 10000, 25000, 50000];

  // Méthodes de paiement CinetPay
  final Map<String, Map<String, dynamic>> _paymentMethods = {
    'ORANGE_MONEY_CI': {
      'name': 'Orange Money',
      'icon': Icons.phone_android,
      'color': Colors.orange[700],
      'description': 'Paiement via Orange Money Côte d\'Ivoire',
    },
    'MTN_MONEY_CI': {
      'name': 'MTN Money',
      'icon': Icons.smartphone,
      'color': Colors.yellow[700],
      'description': 'Paiement via MTN Mobile Money',
    },
    'MOOV_MONEY_CI': {
      'name': 'Moov Money',
      'icon': Icons.phone_android,
      'color': Colors.blue[700],
      'description': 'Paiement via Moov Money',
    },
    'WAVE_CI': {
      'name': 'Wave',
      'icon': Icons.waves,
      'color': Colors.blue[900],
      'description': 'Paiement via Wave',
    },
  };

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Recharger mon compte',
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance actuelle
            userAsync.when(
              data: (user) => _buildCurrentBalance(user?.balance ?? 0),
              loading: () => _buildCurrentBalanceLoading(),
              error: (error, stack) => _buildCurrentBalanceError(),
            ),

            const SizedBox(height: 32),

            // Montant à recharger
            _buildAmountSection(),

            const SizedBox(height: 32),

            // Méthode de paiement
            _buildPaymentMethodSection(),

            const SizedBox(height: 32),

            // Informations supplémentaires selon la méthode
            _buildAdditionalInfoSection(),

            const SizedBox(height: 32),

            // Bouton de recharge
            _buildRechargeButton(),

            const SizedBox(height: 24),

            // Informations de sécurité
            _buildSecurityInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBalance(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryViolet,
            AppColors.primaryViolet.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryViolet.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde actuel',
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${NumberFormat('#,###').format(balance)} FCFA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBalanceLoading() {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCurrentBalanceError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 32),
          const SizedBox(height: 8),
          Text(
            'Erreur de chargement du solde',
            style: TextStyle(color: Colors.red[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant à recharger',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Montants rapides
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((amount) {
            return _buildQuickAmountChip(amount);
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Saisie personnalisée
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Montant personnalisé',
            hintText: '0',
            suffixText: 'FCFA',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandsSeparatorInputFormatter(),
          ],
          onChanged: (value) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildQuickAmountChip(double amount) {
    final isSelected =
        _amountController.text == NumberFormat('#,###').format(amount);

    return GestureDetector(
      onTap: () {
        setState(() {
          _amountController.text = NumberFormat('#,###').format(amount);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryViolet : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryViolet : Colors.grey[300]!,
          ),
        ),
        child: Text(
          '${NumberFormat('#,###').format(amount)} F',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    final converter = CurrencyConverterService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Méthode de paiement',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            // Sélecteur de devise
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCurrency,
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 'XOF', child: Text('XOF')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCurrency = value!);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Afficher la conversion si EUR est sélectionné
        if (_selectedCurrency == 'EUR' &&
            _amountController.text.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conversion: ${_amountController.text} EUR = ${converter.convertEurToXof(double.tryParse(_amountController.text) ?? 0).toStringAsFixed(0)} XOF',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        ..._paymentMethods.entries.map((entry) {
          return _buildPaymentMethodTile(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentMethodTile(String method, Map<String, dynamic> data) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryViolet.withAlpha(25)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryViolet : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? data['color'] ?? AppColors.primaryViolet
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                data['icon'],
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isSelected
                          ? AppColors.primaryViolet
                          : Colors.black87,
                    ),
                  ),
                  if (data['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      data['description'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primaryViolet,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    if (_selectedMethod == 'mobile_money') {
      return _buildMobileMoneySection();
    } else if (_selectedMethod == 'bank_card') {
      return _buildBankCardSection();
    } else if (_selectedMethod == 'bank_transfer') {
      return _buildBankTransferSection();
    }
    return const SizedBox.shrink();
  }

  Widget _buildMobileMoneySection() {
    final operators =
        _paymentMethods['mobile_money']!['operators'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opérateur Mobile Money',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Sélection d'opérateur
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: operators.entries.map((entry) {
            return _buildOperatorChip(entry.key, entry.value);
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Numéro de téléphone
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Numéro de téléphone',
            hintText: '+225 XX XX XX XX XX',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildOperatorChip(String operator, Map<String, dynamic> data) {
    final isSelected = _selectedOperator == operator;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOperator = operator;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? data['color'] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? data['color'] : Colors.grey[300]!,
          ),
        ),
        child: Text(
          data['name'],
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBankCardSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vous serez redirigé vers une page sécurisée pour saisir vos informations bancaires.',
              style: TextStyle(color: Colors.blue[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankTransferSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: Colors.orange[600]),
              const SizedBox(width: 12),
              Text(
                'Informations de virement',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Effectuez un virement vers:\nIBAN: CI05 CI001 XXXXXXXXXX\nBénéficiaire: FinIMoi SAS\nRéférence: Votre ID utilisateur',
            style: TextStyle(color: Colors.orange[700], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeButton() {
    final amount = _getSelectedAmount();
    final isValid = _isFormValid();

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isValid && !_isLoading ? _processRecharge : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryViolet,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                amount > 0
                    ? 'Recharger ${NumberFormat('#,###').format(amount)} FCFA'
                    : 'Recharger',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Paiement 100% sécurisé',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vos données sont protégées par un chiffrement SSL et nous ne stockons jamais vos informations bancaires.',
            style: TextStyle(color: Colors.green[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  double _getSelectedAmount() {
    final text = _amountController.text.replaceAll(',', '');
    return double.tryParse(text) ?? 0;
  }

  bool _isFormValid() {
    final amount = _getSelectedAmount();
    if (amount <= 0) return false;
    if (_selectedMethod == null) return false;

    if (_selectedMethod == 'mobile_money') {
      return _phoneController.text.trim().isNotEmpty;
    }

    return true;
  }

  void _processRecharge() async {
    if (!_isFormValid() || _isLoading) return;

    // Afficher la modale de confirmation
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Intégrer CinetPay ici
      await _processPaymentWithCinetPay();

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showConfirmationDialog() async {
    final amount = _getSelectedAmount();
    final methodName = _paymentMethods[_selectedMethod]!['name'];

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmer la recharge'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Montant: ${NumberFormat('#,###').format(amount)} FCFA'),
                Text('Méthode: $methodName'),
                Text('Téléphone: ${_phoneController.text}'),
                const SizedBox(height: 16),
                const Text(
                  'Confirmez-vous cette recharge ?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _processPaymentWithCinetPay() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final cinetPayService = ref.read(cinetPayServiceProvider);
      final amount = _getSelectedAmount();

      // Validation du numéro de téléphone pour mobile money
      if (_phoneController.text.trim().isEmpty) {
        throw Exception('Veuillez saisir votre numéro de téléphone');
      }

      // Initier le paiement avec CinetPay
      final transaction = await cinetPayService.initiatePayment(
        amount: amount,
        currency: _selectedCurrency,
        paymentMethod: _selectedMethod!,
        userId: currentUser.uid,
        description: 'Rechargement FinIMoi - ${amount.toStringAsFixed(0)} XOF',
      );

      // Ouvrir l'URL de paiement dans le navigateur
      if (await canLaunchUrl(Uri.parse(transaction.paymentUrl))) {
        await launchUrl(
          Uri.parse(transaction.paymentUrl),
          mode: LaunchMode.externalApplication,
        );

        // Afficher un message de confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Redirection vers ${_paymentMethods[_selectedMethod]!['name']} effectuée. Finalisez votre paiement.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );

          // Surveiller le statut du paiement
          await _monitorPaymentStatus(transaction.transactionId);
        }
      } else {
        throw Exception('Impossible d\'ouvrir l\'URL de paiement');
      }
    } catch (e) {
      throw Exception('Erreur CinetPay: $e');
    }
  }

  Future<void> _monitorPaymentStatus(String transactionId) async {
    final cinetPayService = ref.read(cinetPayServiceProvider);
    int attempts = 0;
    const maxAttempts = 60; // 5 minutes maximum (5s * 60)

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 5));

      try {
        final transaction = await cinetPayService.checkTransactionStatus(
          transactionId,
        );

        if (transaction.status == 'completed') {
          // Paiement réussi - invalider le cache pour rafraîchir le solde
          if (mounted) {
            ref.invalidate(userProfileProvider);
          }
          return;
        } else if (transaction.status == 'failed' ||
            transaction.status == 'cancelled') {
          throw Exception('Paiement ${transaction.status}');
        }
      } catch (e) {
        // Continuer à surveiller
      }

      attempts++;
    }

    throw Exception('Timeout - Vérifiez votre paiement');
  }

  void _showSuccessDialog() {
    final amount = _getSelectedAmount();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 64),
            const SizedBox(height: 16),
            const Text(
              'Recharge réussie !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat('#,###').format(amount)} FCFA ont été ajoutés à votre compte.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              // Refresh user data
              ref.invalidate(userProfileProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryViolet,
              foregroundColor: Colors.white,
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Erreur de paiement'),
          ],
        ),
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
}

// Formateur pour les milliers
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) {
      return oldValue;
    }

    final formatted = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
