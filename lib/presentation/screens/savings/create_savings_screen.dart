import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/real_savings_service.dart';
import '../../../domain/entities/savings_model.dart';

class CreateSavingsScreen extends ConsumerStatefulWidget {
  const CreateSavingsScreen({super.key});

  @override
  ConsumerState<CreateSavingsScreen> createState() =>
      _CreateSavingsScreenState();
}

class _CreateSavingsScreenState extends ConsumerState<CreateSavingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalNameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _monthlyAmountController = TextEditingController();

  DateTime? _deadline;
  bool _isLocked = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvel Objectif d\'Épargne'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.info, AppColors.info.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.savings, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    'Nouvel Objectif',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Form fields
            TextFormField(
              controller: _goalNameController,
              decoration: InputDecoration(
                labelText: 'Nom de l\'objectif',
                hintText: 'Ex: Vacances d\'été, Nouvelle voiture...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.flag),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant objectif',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.euro),
                suffixText: 'EUR',
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _monthlyAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Épargne mensuelle',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.calendar_month),
                suffixText: 'EUR/mois',
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
            ),

            const SizedBox(height: 16),

            // Deadline picker
            InkWell(
              onTap: _selectDeadline,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      _deadline != null
                          ? 'Échéance: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                          : 'Sélectionner une échéance',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Locked savings option
            SwitchListTile(
              title: Text('Épargne bloquée'),
              subtitle: Text('Impossible de retirer avant l\'échéance'),
              value: _isLocked,
              onChanged: (value) => setState(() => _isLocked = value),
              activeColor: AppColors.info,
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createSavingsGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Créer l\'Objectif',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _deadline = date);
    }
  }

  Future<void> _createSavingsGoal() async {
    if (!_formKey.currentState!.validate() || _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userId = ref.read(authProvider).currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter.')),
      );
      return;
    }

    try {
      final newGoal = SavingsModel(
        id: '',
        userId: userId,
        goalName: _goalNameController.text,
        targetAmount: double.parse(_targetAmountController.text),
        monthlyContribution: double.parse(_monthlyAmountController.text),
        deadline: _deadline!,
        isLocked: _isLocked,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentAmount: 0,
        isCompleted: false,
      );

      await ref.read(realSavingsServiceProvider).createSavings(newGoal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Objectif d\'épargne créé !'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
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

  @override
  void dispose() {
    _goalNameController.dispose();
    _targetAmountController.dispose();
    _monthlyAmountController.dispose();
    super.dispose();
  }
}
