import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/credit_service.dart';
import '../../../data/providers/user_provider.dart';
import '../../../domain/entities/credit_request.dart';

class CreditScreen extends ConsumerStatefulWidget {
  const CreditScreen({super.key});

  @override
  ConsumerState<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends ConsumerState<CreditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Crédits'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryViolet,
          labelColor: AppColors.primaryViolet,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Mes crédits'),
            Tab(text: 'Nouveau crédit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMyCreditsTab(), _buildNewCreditTab()],
      ),
    );
  }

  Widget _buildMyCreditsTab() {
    final userProfile = ref.watch(userProfileProvider);

    return userProfile.when(
      data: (profile) {
        if (profile == null) {
          return const Center(
            child: Text('Veuillez vous connecter pour voir vos crédits'),
          );
        }

        final creditsAsync = ref.watch(userCreditRequestsProvider(profile.id));

        return creditsAsync.when(
          data: (credits) {
            if (credits.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.credit_card_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun crédit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Faites votre première demande de crédit\npour financer vos projets',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _tabController.animateTo(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Demander un crédit'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: credits.length,
              itemBuilder: (context, index) {
                final credit = credits[index];
                return _buildCreditCard(credit);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(userCreditRequestsProvider(profile.id)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erreur: $error')),
    );
  }

  Widget _buildNewCreditTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nouvelle demande de crédit',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Formulaire avec upload de documents et validation admin.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: AppColors.primaryViolet,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Système de crédit complet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Fonctionnalités disponibles :\n• Simulation de crédit\n• Demande en ligne\n• Suivi de dossier',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _showComingSoonDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Commencer la demande'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(CreditRequest credit) {
    final statusColor = _getStatusColor(credit.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credit.purpose,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${credit.amount.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryViolet,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    credit.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info row
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Durée',
                    '${credit.durationMonths} mois',
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Taux',
                    '${credit.interestRate.toStringAsFixed(1)}%',
                    Icons.percent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getStatusColor(CreditStatus status) {
    switch (status) {
      case CreditStatus.pending:
        return AppColors.warning;
      case CreditStatus.underReview:
        return AppColors.info;
      case CreditStatus.approved:
        return AppColors.success;
      case CreditStatus.rejected:
        return AppColors.error;
      case CreditStatus.active:
        return AppColors.primaryViolet;
      case CreditStatus.completed:
        return AppColors.success;
      case CreditStatus.defaulted:
        return AppColors.error;
    }
  }

  void _showComingSoonDialog() {
    final amountController = TextEditingController();
    final durationController = TextEditingController();
    final purposeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demande de crédit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant souhaité (FCFA)',
                  hintText: '500000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Durée (mois)',
                  hintText: '12',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_month),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: purposeController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Objet du crédit',
                  hintText: 'Décrivez l\'utilisation prévue...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Taux d\'intérêt : 12% - 18% par an'),
                    Text('• Traitement : 24-48h'),
                    Text('• Documents requis après validation'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_validateCreditRequest(
                amountController.text,
                durationController.text,
                purposeController.text,
              )) {
                _processCreditRequest(
                  double.parse(amountController.text),
                  int.parse(durationController.text),
                  purposeController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  bool _validateCreditRequest(String amount, String duration, String purpose) {
    if (amount.isEmpty || duration.isEmpty || purpose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return false;
    }

    final amountValue = double.tryParse(amount);
    final durationValue = int.tryParse(duration);

    if (amountValue == null || amountValue < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le montant minimum est de 50 000 FCFA')),
      );
      return false;
    }

    if (durationValue == null || durationValue < 3 || durationValue > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La durée doit être entre 3 et 60 mois')),
      );
      return false;
    }

    return true;
  }

  Future<void> _processCreditRequest(
    double amount,
    int duration,
    String purpose,
  ) async {
    try {
      // Simulation du traitement de la demande
      await Future.delayed(const Duration(seconds: 2));

      final monthlyPayment = _calculateMonthlyPayment(amount, duration);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Demande soumise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Votre demande a été soumise avec succès !'),
              const SizedBox(height: 16),
              Text('Montant: ${amount.toStringAsFixed(0)} FCFA'),
              Text('Durée: $duration mois'),
              Text(
                'Mensualité estimée: ${monthlyPayment.toStringAsFixed(0)} FCFA',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Un conseiller vous contactera dans les 24h pour finaliser votre dossier.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la soumission: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateMonthlyPayment(double amount, int duration) {
    const double annualRate = 0.15; // 15% par an
    final double monthlyRate = annualRate / 12;
    return (amount * monthlyRate * pow(1 + monthlyRate, duration)) /
        (pow(1 + monthlyRate, duration) - 1);
  }
}
