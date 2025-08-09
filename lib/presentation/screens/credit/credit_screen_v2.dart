import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/real_credit_provider.dart';
import '../../../data/providers/gamification_provider.dart';

class CreditScreen extends ConsumerStatefulWidget {
  const CreditScreen({super.key});

  @override
  ConsumerState<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends ConsumerState<CreditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Formulaire de demande de crédit
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  final _purposeController = TextEditingController();
  final _incomeController = TextEditingController();
  final _employerController = TextEditingController();

  String _selectedCreditType = 'personnel';
  double _requestedAmount = 50000;
  int _durationMonths = 12;
  List<String> _documentUrls = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _amountController.text = _requestedAmount.toStringAsFixed(0);
    _durationController.text = _durationMonths.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    _purposeController.dispose();
    _incomeController.dispose();
    _employerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Crédit'),
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
            Tab(text: 'Nouvelle demande'),
            Tab(text: 'Offres'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyCreditsTab(),
          _buildNewRequestTab(),
          _buildOffersTab(),
        ],
      ),
    );
  }

  Widget _buildMyCreditsTab() {
    final userId = ref.watch(authProvider).currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Veuillez vous connecter.'));
    }

    final creditsAsync = ref.watch(userCreditsProvider(userId));
    final statsAsync = ref.watch(creditStatsProvider(userId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        statsAsync.when(
          data: (stats) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryViolet, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mes crédits en cours',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total emprunté',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          '${stats['totalBorrowed']?.toStringAsFixed(0) ?? '0'} FCFA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Reste à payer',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          '${stats['totalRemaining']?.toStringAsFixed(0) ?? '0'} FCFA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Erreur: $err'),
        ),
        const SizedBox(height: 24),
        creditsAsync.when(
          data: (credits) {
            if (credits.isEmpty) {
              return const Center(child: Text('Aucun crédit trouvé.'));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: credits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final credit = credits[index];
          return GestureDetector(
            onTap: () => context.push('/credit/${credit.id}/schedule', extra: credit),
            child: _buildCreditCard(
              title: credit.purpose,
              amount: '${credit.amount.toStringAsFixed(0)} FCFA',
              remaining: '${credit.remainingAmount.toStringAsFixed(0)} FCFA',
              nextPayment:
                  '${credit.monthlyPayment.toStringAsFixed(0)} FCFA',
              dueDate: credit.nextPaymentDate?.toString() ?? 'N/A',
              progress: credit.progressPercentage / 100,
              status: credit.statusText,
            ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Erreur: $err'),
        ),
      ],
    );
  }

  Widget _buildNewRequestTab() {
    final gamificationProfileAsync = ref.watch(gamificationProfileProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Credit Score Badge
          gamificationProfileAsync.when(
            data: (profile) {
              final score = profile?.points ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.blue[800]),
                    const SizedBox(width: 8),
                    Text(
                      'Votre score de fiabilité: $score',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Indicateur d'étapes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Montant', _currentStep >= 0),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep >= 1
                        ? AppColors.primaryViolet
                        : Colors.grey[300],
                  ),
                ),
                _buildStepIndicator(1, 'Détails', _currentStep >= 1),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep >= 2
                        ? AppColors.primaryViolet
                        : Colors.grey[300],
                  ),
                ),
                _buildStepIndicator(2, 'Confirmation', _currentStep >= 2),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contenu des étapes
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildAmountStep(),
                _buildDetailsStep(),
                _buildConfirmationStep(),
              ],
            ),
          ),

          // Boutons de navigation
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primaryViolet),
                      ),
                      child: const Text('Précédent'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep == 2 ? _submitRequest : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_currentStep == 2 ? 'Soumettre' : 'Suivant'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Offres disponibles',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _buildCreditOffer(
          title: 'Crédit Express',
          description: 'Crédit rapide sans garantie',
          amount: 'Jusqu\'à 500 000 FCFA',
          rate: '12% / an',
          duration: '3 à 24 mois',
          features: ['Réponse immédiate', 'Sans garantie', 'Flexible'],
          color: AppColors.primaryViolet,
        ),
        const SizedBox(height: 16),

        _buildCreditOffer(
          title: 'Crédit Personnel',
          description: 'Pour vos projets personnels',
          amount: 'Jusqu\'à 2 000 000 FCFA',
          rate: '10% / an',
          duration: '6 à 60 mois',
          features: [
            'Taux avantageux',
            'Remboursement flexible',
            'Accompagnement',
          ],
          color: AppColors.success,
        ),
        const SizedBox(height: 16),

        _buildCreditOffer(
          title: 'Crédit Équipement',
          description: 'Financez vos équipements',
          amount: 'Jusqu\'à 5 000 000 FCFA',
          rate: '8% / an',
          duration: '12 à 84 mois',
          features: [
            'Taux préférentiel',
            'Financement 100%',
            'Suivi personnalisé',
          ],
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryViolet : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primaryViolet : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'De combien avez-vous besoin ?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Sélecteur de type de crédit
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _buildCreditTypeOption(
                    'personnel',
                    'Crédit Personnel',
                    Icons.person,
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  _buildCreditTypeOption(
                    'equipement',
                    'Crédit Équipement',
                    Icons.business,
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  _buildCreditTypeOption(
                    'express',
                    'Crédit Express',
                    Icons.flash_on,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Montant
            const Text(
              'Montant souhaité',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _requestedAmount,
              min: 10000,
              max: 1000000,
              divisions: 99,
              activeColor: AppColors.primaryViolet,
              label: '${_requestedAmount.toStringAsFixed(0)} FCFA',
              onChanged: (value) {
                setState(() {
                  _requestedAmount = value;
                  _amountController.text = value.toStringAsFixed(0);
                });
              },
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = double.tryParse(value);
                if (amount != null && amount >= 10000 && amount <= 1000000) {
                  setState(() => _requestedAmount = amount);
                }
              },
            ),
            const SizedBox(height: 16),

            // Durée
            const Text(
              'Durée de remboursement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _durationMonths.toDouble(),
              min: 3,
              max: 60,
              divisions: 57,
              activeColor: AppColors.primaryViolet,
              label: '$_durationMonths mois',
              onChanged: (value) {
                setState(() {
                  _durationMonths = value.toInt();
                  _durationController.text = value.toInt().toString();
                });
              },
            ),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Durée (mois)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final duration = int.tryParse(value);
                if (duration != null && duration >= 3 && duration <= 60) {
                  setState(() => _durationMonths = duration);
                }
              },
            ),

            const SizedBox(height: 24),

            // Simulation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryViolet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Simulation de remboursement',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mensualité :'),
                      Text(
                        '${(_requestedAmount * 1.12 / _durationMonths).toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total à rembourser :'),
                      Text(
                        '${(_requestedAmount * 1.12).toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations complémentaires',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _purposeController,
                  decoration: const InputDecoration(
                    labelText: 'Objet du crédit',
                    hintText: 'Décrivez l\'utilisation prévue des fonds',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _incomeController,
                  decoration: const InputDecoration(
                    labelText: 'Revenus mensuels (FCFA)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _employerController,
                  decoration: const InputDecoration(
                    labelText: 'Employeur / Activité',
                    hintText: 'Nom de votre employeur ou type d\'activité',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Documents requis
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documents requis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentItem('Pièce d\'identité', true),
                      _buildDocumentItem('Justificatif de revenus', false),
                      _buildDocumentItem('Relevé bancaire', false),
                      _buildDocumentItem('Justificatif de domicile', false),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _uploadDocuments,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Télécharger des documents'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Récapitulatif de votre demande',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Type de crédit', _getCreditTypeName()),
                      _buildSummaryRow(
                        'Montant demandé',
                        '${_requestedAmount.toStringAsFixed(0)} FCFA',
                      ),
                      _buildSummaryRow('Durée', '$_durationMonths mois'),
                      _buildSummaryRow(
                        'Mensualité estimée',
                        '${(_requestedAmount * 1.12 / _durationMonths).toStringAsFixed(0)} FCFA',
                      ),
                      _buildSummaryRow(
                        'Total à rembourser',
                        '${(_requestedAmount * 1.12).toStringAsFixed(0)} FCFA',
                      ),
                      _buildSummaryRow('Taux d\'intérêt', '12% / an'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.warning,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Informations importantes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Cette demande sera étudiée sous 48h\\n'
                        '• Vous recevrez une réponse par SMS et email\\n'
                        '• Les conditions peuvent varier selon votre profil\\n'
                        '• Un crédit vous engage et doit être remboursé',
                        style: TextStyle(color: Colors.grey[700], height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: (value) {},
                      activeColor: AppColors.primaryViolet,
                    ),
                    const Expanded(
                      child: Text(
                        'J\'accepte les conditions générales et j\'autorise le traitement de mes données personnelles.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditTypeOption(String value, String title, IconData icon) {
    final isSelected = _selectedCreditType == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primaryViolet : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primaryViolet : Colors.black,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primaryViolet)
          : null,
      onTap: () => setState(() => _selectedCreditType = value),
    );
  }

  Widget _buildDocumentItem(String title, bool isUploaded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isUploaded ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isUploaded ? AppColors.success : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          if (isUploaded)
            const Icon(Icons.cloud_done, color: AppColors.success, size: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCreditCard({
    required String title,
    required String amount,
    required String remaining,
    required String nextPayment,
    required String dueDate,
    required double progress,
    required String status,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'Soldé'
                        ? AppColors.success
                        : AppColors.info,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montant initial',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      amount,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Reste à payer',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      remaining,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                status == 'Soldé' ? AppColors.success : AppColors.primaryViolet,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prochain paiement',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      nextPayment,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Échéance',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      dueDate,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditOffer({
    required String title,
    required String description,
    required String amount,
    required String rate,
    required String duration,
    required List<String> features,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Montant',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          amount,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Taux',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          rate,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Durée: ', style: TextStyle(color: Colors.grey[600])),
                    Text(
                      duration,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 16),
                        const SizedBox(width: 8),
                        Text(feature, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _selectOffer(title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Choisir cette offre'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCreditTypeName() {
    switch (_selectedCreditType) {
      case 'personnel':
        return 'Crédit Personnel';
      case 'equipement':
        return 'Crédit Équipement';
      case 'express':
        return 'Crédit Express';
      default:
        return 'Crédit Personnel';
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitRequest() async {
    final userId = ref.read(authProvider).currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter.')),
      );
      return;
    }

    try {
      // This is not ideal, I should add documentUrls to the requestCredit method
      // For now, I will just create the request and then update it with the urls
      final creditId = await ref.read(realCreditServiceProvider).requestCredit(
            userId: userId,
            amount: _requestedAmount,
            purpose: _purposeController.text,
            duration: _durationMonths,
          );

      await FirebaseFirestore.instance.collection('credits').doc(creditId).update({
        'documentUrls': _documentUrls,
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Demande soumise'),
            content: const Text(
              'Votre demande de crédit a été soumise avec succès. '
              'Vous recevrez une réponse sous 48h.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentStep = 0;
                    _tabController.index = 0;
                  });
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _uploadDocuments() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final userId = ref.read(authProvider).currentUser?.uid;
      if (userId == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('credit_documents/$userId/${DateTime.now().millisecondsSinceEpoch}');

      try {
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _documentUrls.add(downloadUrl);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document téléchargé avec succès!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de téléchargement: $e')),
        );
      }
    }
  }

  void _selectOffer(String offerTitle) {
    setState(() => _tabController.index = 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Offre "$offerTitle" sélectionnée'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
