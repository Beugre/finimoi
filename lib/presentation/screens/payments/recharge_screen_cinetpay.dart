import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/services/cinetpay_service.dart';
import '../../../data/services/user_service.dart';
import '../../../data/services/currency_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/recharge_validation_modal.dart';
import 'package:url_launcher/url_launcher.dart';

class RechargeScreenCinetPay extends ConsumerStatefulWidget {
  const RechargeScreenCinetPay({super.key});

  @override
  ConsumerState<RechargeScreenCinetPay> createState() =>
      _RechargeScreenCinetPayState();
}

class _RechargeScreenCinetPayState
    extends ConsumerState<RechargeScreenCinetPay> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedMethod; // Aucune méthode sélectionnée par défaut
  String _selectedCurrency = 'XOF';
  bool _isLoading = false;

  // Montants prédéfinis
  final List<double> _quickAmounts = [1000, 2500, 5000, 10000, 25000, 50000];

  // Méthodes de paiement CinetPay
  final Map<String, Map<String, dynamic>> _paymentMethods = {
    'ALL': {
      'name': 'Toutes les méthodes',
      'icon': Icons.credit_card,
      'color': Colors.purple[700],
      'description': 'Choisir parmi toutes les méthodes disponibles',
    },
    'MOBILE_MONEY': {
      'name': 'Mobile Money',
      'icon': Icons.phone_android,
      'color': Colors.orange[700],
      'description': 'Orange Money, MTN Money, Moov Money',
    },
    'WALLET': {
      'name': 'Portefeuille électronique',
      'icon': Icons.account_balance_wallet,
      'color': Colors.blue[700],
      'description': 'Wave et autres portefeuilles',
    },
    'CREDIT_CARD': {
      'name': 'Carte de crédit',
      'icon': Icons.credit_card,
      'color': Colors.green[700],
      'description': 'Visa, Mastercard',
    },
    'INTERNATIONAL_CARD': {
      'name': 'Carte internationale',
      'icon': Icons.credit_card_outlined,
      'color': Colors.indigo[700],
      'description': 'Cartes bancaires internationales',
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
      appBar: const CustomAppBar(title: 'Recharger mon compte'),
      body: userAsync.when(
        data: (user) => user != null
            ? _buildContent(user.balance)
            : _buildError('Utilisateur non connecté'),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(error.toString()),
      ),
    );
  }

  Widget _buildContent(double balance) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Solde actuel
          _buildCurrentBalance(balance),

          const SizedBox(height: 24),

          // Sélecteur de devise
          _buildCurrencySelector(),

          const SizedBox(height: 24),

          // Montants rapides
          _buildQuickAmountsSection(),

          const SizedBox(height: 24),

          // Montant personnalisé
          _buildCustomAmountSection(),

          const SizedBox(height: 24),

          // Méthodes de paiement
          _buildPaymentMethodSection(),

          const SizedBox(height: 24),

          // Numéro de téléphone
          _buildPhoneNumberSection(),

          const SizedBox(height: 32),

          // Bouton de recharge
          _buildRechargeButton(),

          const SizedBox(height: 16),

          // Bouton de simulation de recharge
          _buildSimulationButton(),

          const SizedBox(height: 24),

          // Informations de sécurité
          _buildSecurityInfo(),
        ],
      ),
    );
  }

  Widget _buildCurrentBalance(double balance) {
    final converter = ref.watch(currencyConverterProvider);
    final preferences = ref.watch(currencyPreferencesProvider);

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
            converter.formatWithPreferences(balance, preferences),
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

  Widget _buildCurrencySelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Devise de paiement',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCurrencyOption(
                    'XOF',
                    'Franc CFA',
                    Icons.monetization_on,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCurrencyOption('EUR', 'Euro', Icons.euro),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String currency, String name, IconData icon) {
    final isSelected = _selectedCurrency == currency;

    return GestureDetector(
      onTap: () => setState(() => _selectedCurrency = currency),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryViolet.withAlpha(25)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryViolet : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryViolet : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              currency,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primaryViolet : Colors.grey[700],
              ),
            ),
            Text(name, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montants rapides',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: _quickAmounts.length,
          itemBuilder: (context, index) {
            final amount = _quickAmounts[index];
            return _buildQuickAmountTile(amount);
          },
        ),
      ],
    );
  }

  Widget _buildQuickAmountTile(double amount) {
    final converter = ref.watch(currencyConverterProvider);
    final isSelected = _amountController.text == amount.toStringAsFixed(0);

    return GestureDetector(
      onTap: () {
        setState(() {
          _amountController.text = amount.toStringAsFixed(0);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryViolet : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryViolet : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            _selectedCurrency == 'EUR'
                ? converter.formatAmount(
                    converter.convertXofToEur(amount),
                    'EUR',
                  )
                : converter.formatAmount(amount, 'XOF'),
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primaryViolet,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAmountSection() {
    final converter = ref.watch(currencyConverterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant personnalisé',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Montant à recharger',
            hintText: _selectedCurrency == 'EUR' ? 'Ex: 15.24' : 'Ex: 10000',
            suffixText: _selectedCurrency,
            prefixIcon: Icon(
              _selectedCurrency == 'EUR' ? Icons.euro : Icons.monetization_on,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),
        if (_selectedCurrency == 'EUR' &&
            _amountController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
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
                    'Équivalent: ${converter.formatAmount(converter.convertEurToXof(double.tryParse(_amountController.text) ?? 0), 'XOF')}',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthode de paiement',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ..._paymentMethods.entries.map((entry) {
          return _buildPaymentMethodTile(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentMethodTile(String method, Map<String, dynamic> data) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
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
                color: isSelected ? data['color'] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(data['icon'], color: Colors.white, size: 24),
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
                  Text(
                    data['description'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
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

  Widget _buildPhoneNumberSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numéro de téléphone',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: _selectedMethod != null
                ? 'Votre numéro ${_paymentMethods[_selectedMethod]!['name']}'
                : 'Votre numéro de téléphone',
            hintText: '+225 0123456789',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildRechargeButton() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final phone = _phoneController.text.trim();
    final isValid = amount > 0 && phone.isNotEmpty && _selectedMethod != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid && !_isLoading ? _showValidationModal : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryViolet,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Recharger ${_amountController.text.isNotEmpty ? _amountController.text : "0"} $_selectedCurrency',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSimulationButton() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final isValid = amount > 0;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isValid && !_isLoading ? _processSimulationRecharge : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: isValid ? AppColors.primaryViolet : Colors.grey,
          ),
        ),
        child: Text(
          'Simulation de recharge ${_amountController.text.isNotEmpty ? _amountController.text : "0"} $_selectedCurrency',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isValid ? AppColors.primaryViolet : Colors.grey,
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
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.green[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement sécurisé par CinetPay',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vos données sont protégées et chiffrées',
                  style: TextStyle(color: Colors.green[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _processSimulationRecharge() async {
    if (_isLoading) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userAsync = ref.read(userProfileProvider);
      final user = userAsync.value;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Simuler un délai de traitement
      await Future.delayed(const Duration(seconds: 2));

      // Mettre à jour directement le solde de l'utilisateur
      await UserService.updateBalance(user.id, user.balance + amount);

      if (mounted) {
        // Rafraîchir les données utilisateur
        ref.invalidate(userProfileProvider);

        // Afficher le message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Simulation réussie ! ${amount.toStringAsFixed(0)} XOF ajoutés à votre compte.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Réinitialiser le formulaire
        _amountController.clear();
        _phoneController.clear();
        setState(() {
          _selectedMethod = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la simulation: $e'),
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

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('Erreur', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showValidationModal() {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une méthode de paiement'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    final phone = _phoneController.text.trim();
    final methodInfo = _paymentMethods[_selectedMethod]!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RechargeValidationModal(
          amount: amount,
          currency: _selectedCurrency,
          paymentMethod: methodInfo['name'],
          methodIcon: methodInfo['icon'],
          methodColor: methodInfo['color'],
          phoneNumber: phone,
          onConfirm: () {
            Navigator.of(context).pop();
            _confirmRecharge();
          },
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _confirmRecharge() async {
    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final userAsync = ref.read(userProfileProvider);

      await userAsync.when(
        data: (user) async {
          if (user == null) throw Exception('Utilisateur non connecté');

          // Validation du numéro de téléphone
          if (_phoneController.text.trim().isEmpty) {
            throw Exception('Veuillez saisir votre numéro de téléphone');
          }

          // Initier le paiement avec CinetPay
          final cinetPayService = ref.read(cinetPayServiceProvider);
          print('🔄 Début initiation paiement CinetPay');

          final transaction = await cinetPayService.initiatePayment(
            amount: amount,
            currency: _selectedCurrency,
            paymentMethod: _selectedMethod!,
            userId: user.id,
            description:
                'Rechargement FinIMoi - ${amount.toStringAsFixed(0)} $_selectedCurrency',
          );

          print('✅ Transaction créée: ${transaction.transactionId}');
          print('🔗 URL de paiement: ${transaction.paymentUrl}');

          // Sauvegarder l'ID de transaction pour la vérification ultérieure
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'pending_transaction_id',
            transaction.transactionId,
          );
          await prefs.setDouble('pending_amount', amount);
          await prefs.setString('pending_currency', _selectedCurrency);

          // Ouvrir l'URL de paiement CinetPay
          final uri = Uri.parse(transaction.paymentUrl);
          print('🔍 Vérification de l\'URL: $uri');

          if (await canLaunchUrl(uri)) {
            print('✅ URL peut être lancée, redirection...');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            print('✅ URL lancée avec succès');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Redirection vers ${_paymentMethods[_selectedMethod!]!['name']} effectuée. Finalisez votre paiement.',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 5),
                ),
              );

              // Invalider le cache pour rafraîchir le solde
              ref.invalidate(userProfileProvider);
            }
          } else {
            print('❌ Impossible de lancer l\'URL: $uri');
            throw Exception(
              'Impossible d\'ouvrir l\'interface de paiement. URL: ${transaction.paymentUrl}',
            );
          }
        },
        loading: () => throw Exception('Chargement des données utilisateur...'),
        error: (error, stack) => throw Exception('Erreur utilisateur: $error'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
