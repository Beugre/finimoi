import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/user_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/payment_service.dart';

class RechargeScreen extends ConsumerStatefulWidget {
  const RechargeScreen({super.key});

  @override
  ConsumerState<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends ConsumerState<RechargeScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;
  PaymentMethod _selectedMethod = PaymentMethod.card;

  // Montants en FCFA (adaptés au marché ouest-africain)
  final List<double> _predefinedAmounts = [
    1000,
    2500,
    5000,
    10000,
    25000,
    50000,
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processRecharge(double amount) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Initier le paiement via le service professionnel
      final paymentTransaction = await PaymentService.initiateRecharge(
        userId: currentUser.uid,
        amount: amount,
        method: _selectedMethod,
        currency: 'XOF', // Franc CFA
        metadata: {
          'description': 'Recharge compte FinIMoi',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        if (paymentTransaction.status == PaymentStatus.completed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Recharge de ${amount.toInt()} FCFA effectuée avec succès !',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else if (paymentTransaction.status == PaymentStatus.failed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Échec de la recharge: ${paymentTransaction.errorMessage}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement en cours de traitement...'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
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
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Recharger mon compte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: userProfile.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryViolet,
                      AppColors.primaryViolet.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Solde actuel',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(user?.balance ?? 0).toInt()} FCFA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Payment method selection
              Text(
                'Méthode de paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMethodButton(
                        PaymentMethod.card,
                        'Carte bancaire',
                        Icons.credit_card,
                      ),
                    ),
                    Expanded(
                      child: _buildMethodButton(
                        PaymentMethod.mobileMoney,
                        'Mobile Money',
                        Icons.phone_android,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Predefined amounts
              Text(
                'Montants prédéfinis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _predefinedAmounts.length,
                itemBuilder: (context, index) {
                  final amount = _predefinedAmounts[index];
                  return _buildAmountButton(amount);
                },
              ),

              const SizedBox(height: 32),

              // Custom amount
              Text(
                'Montant personnalisé',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixIcon: const Icon(Icons.money),
                        suffixText: 'FCFA',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            final amount = double.tryParse(
                              _amountController.text,
                            );
                            if (amount != null && amount >= 100) {
                              _processRecharge(amount);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Montant minimum: 100 FCFA'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Recharger'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Payment info based on selected method
              _buildPaymentInfo(),

              const SizedBox(height: 24),

              // Security note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: AppColors.success, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Toutes les transactions sont sécurisées et chiffrées',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildMethodButton(PaymentMethod method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountButton(double amount) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _processRecharge(amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryViolet.withOpacity(0.1),
        foregroundColor: AppColors.primaryViolet,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.primaryViolet.withOpacity(0.3)),
        ),
      ),
      child: Text(
        '${amount.toInt()} F',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final info = _getPaymentMethodInfo();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(info['icon'], color: AppColors.info, size: 24),
              const SizedBox(width: 8),
              Text(
                info['title'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(info['description'], style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPaymentMethodInfo() {
    switch (_selectedMethod) {
      case PaymentMethod.card:
        return {
          'icon': Icons.credit_card,
          'title': 'Paiement par carte bancaire',
          'description':
              'Visa, Mastercard et cartes locales acceptées.\n'
              'Transaction sécurisée via CinetPay.\n'
              'Débit immédiat sur votre compte.',
        };
      case PaymentMethod.mobileMoney:
        return {
          'icon': Icons.phone_android,
          'title': 'Paiement Mobile Money',
          'description':
              'Orange Money, MTN Money, Moov Money, Wave, Flooz.\n'
              'Suivez les instructions sur votre téléphone.\n'
              'Confirmation par SMS ou USSD.',
        };
      case PaymentMethod.bankTransfer:
        return {
          'icon': Icons.account_balance,
          'title': 'Virement bancaire',
          'description':
              'Virement SEPA ou local.\n'
              'Traitement sous 1-3 jours ouvrés.\n'
              'RIB disponible après validation.',
        };
    }
  }
}
