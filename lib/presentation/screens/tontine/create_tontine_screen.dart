import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/tontine_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/tontine_provider.dart';

class CreateTontineScreen extends ConsumerStatefulWidget {
  const CreateTontineScreen({super.key});

  @override
  ConsumerState<CreateTontineScreen> createState() =>
      _CreateTontineScreenState();
}

class _CreateTontineScreenState extends ConsumerState<CreateTontineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _maxMembersController = TextEditingController();
  final _pageController = PageController();

  TontineFrequency _frequency = TontineFrequency.monthly;
  TontineType _type = TontineType.classic;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  bool _isPrivate = false;
  bool _allowEarlyWithdrawal = false;
  bool _requireApproval = true;
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _maxMembersController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _createTontine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Utilisateur non connecté');

      final rules = {
        'allowEarlyWithdrawal': _allowEarlyWithdrawal,
        'requireApproval': _requireApproval,
        'penaltyRate': 0.05, // 5% de pénalité pour retard
        'maxDelayDays': 7,
      };

      final tontineService = ref.read(tontineServiceProvider);
      final tontineId = await tontineService.createTontine(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        creatorId: user.uid,
        creatorName: user.displayName ?? 'Utilisateur',
        contributionAmount: double.parse(_amountController.text),
        frequency: _frequency,
        type: _type,
        maxMembers: int.parse(_maxMembersController.text),
        startDate: _startDate,
        rules: rules,
        isPrivate: _isPrivate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tontine créée avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/tontine/$tontineId');
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createTontine();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Créer une Tontine',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: index <= _currentPage
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Form pages
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildBasicInfoPage(),
                  _buildDetailsPage(),
                  _buildRulesPage(),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Précédent'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _currentPage < 2 ? 'Suivant' : 'Créer la Tontine',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.accent.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.group_add, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Informations de base',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Donnez vie à votre projet financier collectif',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Nom de la tontine
          Text(
            'Nom de la tontine *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Ex: Tontine Famille Kouassi',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom est obligatoire';
              }
              if (value.length < 3) {
                return 'Le nom doit faire au moins 3 caractères';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Décrivez l\'objectif de votre tontine...',
              prefixIcon: const Icon(Icons.description),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Type de tontine
          Text(
            'Type de tontine *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: TontineType.values.map((type) {
              final isSelected = _type == type;
              return GestureDetector(
                onTap: () => setState(() => _type = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(type),
                        color: isSelected ? AppColors.primary : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTypeText(type),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey[600],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Visibilité
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tontine privée',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Seules les personnes avec le code peuvent rejoindre',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPrivate,
                  onChanged: (value) => setState(() => _isPrivate = value),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.settings, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Configuration financière',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Définissez les paramètres financiers',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Montant de contribution
          Text(
            'Montant de contribution *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '50000',
              prefixIcon: const Icon(Icons.monetization_on),
              suffixText: 'FCFA',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le montant est obligatoire';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Montant invalide';
              }
              if (amount < 1000) {
                return 'Le montant minimum est de 1000 FCFA';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Nombre de participants
          Text(
            'Nombre maximum de participants *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _maxMembersController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '10',
              prefixIcon: const Icon(Icons.people),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nombre de participants est obligatoire';
              }
              final number = int.tryParse(value);
              if (number == null || number < 2) {
                return 'Il faut au moins 2 participants';
              }
              if (number > 100) {
                return 'Maximum 100 participants';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Fréquence
          Text(
            'Fréquence des contributions *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Column(
            children: TontineFrequency.values.map((freq) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _frequency == freq
                        ? AppColors.primary
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: RadioListTile<TontineFrequency>(
                  value: freq,
                  groupValue: _frequency,
                  onChanged: (value) => setState(() => _frequency = value!),
                  title: Text(_getFrequencyText(freq)),
                  subtitle: Text(_getFrequencyDescription(freq)),
                  activeColor: AppColors.primary,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Date de début
          Text(
            'Date de début *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _startDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 12),
                  Text(
                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Calcul automatique
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.accent.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Récapitulatif',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Montant par cycle',
                  '${_getTotalPool()} FCFA',
                ),
                _buildSummaryRow('Durée estimée', '${_getDuration()}'),
                _buildSummaryRow('Total des gains', '${_getTotalPool()} FCFA'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warning, AppColors.warning.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.rule, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Règles et conditions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Définissez les règles de fonctionnement',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Règles
          _buildRuleItem(
            title: 'Retrait anticipé',
            subtitle: 'Autoriser les membres à se retirer avant la fin',
            value: _allowEarlyWithdrawal,
            onChanged: (value) => setState(() => _allowEarlyWithdrawal = value),
            icon: Icons.exit_to_app,
          ),

          const SizedBox(height: 16),

          _buildRuleItem(
            title: 'Approbation requise',
            subtitle: 'Les nouveaux membres doivent être approuvés',
            value: _requireApproval,
            onChanged: (value) => setState(() => _requireApproval = value),
            icon: Icons.approval,
          ),

          const SizedBox(height: 32),

          // Conditions importantes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'Conditions importantes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('• Pénalité de 5% en cas de retard de paiement'),
                const Text('• Délai maximum de 7 jours après l\'échéance'),
                const Text('• Exclusion automatique après 2 retards'),
                const Text('• Les fonds sont sécurisés par FinIMoi'),
                const Text('• Remboursement garanti en cas de litige'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Acceptation des conditions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.verified_user, color: AppColors.success, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Sécurité garantie',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vos tontines sont sécurisées par la technologie blockchain et garanties par notre assurance partenaire.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(TontineType type) {
    switch (type) {
      case TontineType.classic:
        return Icons.group;
      case TontineType.rotating:
        return Icons.rotate_right;
      case TontineType.investment:
        return Icons.trending_up;
      case TontineType.emergency:
        return Icons.emergency;
    }
  }

  String _getTypeText(TontineType type) {
    switch (type) {
      case TontineType.classic:
        return 'Classique';
      case TontineType.rotating:
        return 'Rotative';
      case TontineType.investment:
        return 'Investissement';
      case TontineType.emergency:
        return 'Urgence';
    }
  }

  String _getFrequencyText(TontineFrequency frequency) {
    switch (frequency) {
      case TontineFrequency.weekly:
        return 'Hebdomadaire';
      case TontineFrequency.biweekly:
        return 'Bimensuel';
      case TontineFrequency.monthly:
        return 'Mensuel';
      case TontineFrequency.quarterly:
        return 'Trimestriel';
    }
  }

  String _getFrequencyDescription(TontineFrequency frequency) {
    switch (frequency) {
      case TontineFrequency.weekly:
        return 'Contribution chaque semaine';
      case TontineFrequency.biweekly:
        return 'Contribution toutes les 2 semaines';
      case TontineFrequency.monthly:
        return 'Contribution chaque mois';
      case TontineFrequency.quarterly:
        return 'Contribution chaque trimestre';
    }
  }

  String _getTotalPool() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final members = int.tryParse(_maxMembersController.text) ?? 0;
    return (amount * members).toStringAsFixed(0);
  }

  String _getDuration() {
    final members = int.tryParse(_maxMembersController.text) ?? 0;
    switch (_frequency) {
      case TontineFrequency.weekly:
        return '$members semaines';
      case TontineFrequency.biweekly:
        return '${members * 2} semaines';
      case TontineFrequency.monthly:
        return '$members mois';
      case TontineFrequency.quarterly:
        return '${members * 3} mois';
    }
  }
}
