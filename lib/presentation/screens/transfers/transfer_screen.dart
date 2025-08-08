import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/services/user_search_service.dart';
import '../../../data/services/transfer_service.dart';
import '../../../data/services/user_service.dart';
import '../../../domain/entities/user_model.dart';
import '../../../domain/entities/transfer_model.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  UserModel? _selectedUser;

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Méthode temporaire pour ajouter des fonds de test
  void _addTestFunds() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('💰 Ajout de 1000 FCFA au solde...');

        // Ajouter réellement les fonds dans Firebase
        await UserService.addTestFunds(currentUser.uid, 1000.0);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('1000 FCFA ajoutés au solde avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        print('✅ Fonds ajoutés avec succès');

        // Rafraîchir le provider pour recharger les données
        ref.invalidate(userProfileProvider);
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ajout des fonds: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Envoyer de l\'argent',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Section solde
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final userProfileAsync = ref.watch(userProfileProvider);
                  return userProfileAsync.when(
                    data: (userProfile) {
                      final balance = userProfile?.balance ?? 0.0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Solde disponible',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  CurrencyFormatter.formatCFA(balance),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Bouton temporaire pour ajouter des fonds de test
                              SizedBox(
                                width: 80,
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: () => _addTestFunds(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: const Text(
                                    '+ 1000',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solde disponible',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: 150,
                          height: 28,
                          child: LinearProgressIndicator(),
                        ),
                      ],
                    ),
                    error: (error, stack) => const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solde disponible',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Barre de recherche
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher par @finimoi, nom ou email...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Résultats de recherche ou état initial
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      // Force la reconstruction pour déclencher la recherche
    });
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState();
    }

    if (_searchController.text.length < 2) {
      return const Center(
        child: Text(
          'Tapez au moins 2 caractères pour rechercher',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final searchResultsAsync = ref.watch(
          userSearchProvider(_searchController.text),
        );

        print('🔍 Recherche pour: "${_searchController.text}"');

        return searchResultsAsync.when(
          data: (users) {
            print('📝 Résultats trouvés: ${users.length} utilisateurs');
            for (final user in users) {
              print(
                '   - ${user.fullName} (@${user.finimoiTag}) - ${user.email}',
              );
            }

            if (users.isEmpty) {
              return _buildNoResults();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserItem(user);
              },
            );
          },
          loading: () {
            print('⏳ Recherche en cours...');
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stack) {
            print('❌ Erreur de recherche: $error');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de recherche: $error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Rechercher un utilisateur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tapez un @finimoi, nom ou email pour commencer',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Aucun utilisateur trouvé',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Vérifiez l\'orthographe ou essayez un autre terme',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _selectUser(user),
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? Text(
                  user.initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.finimoiTag != null)
              Text(
                '@${user.finimoiTag}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              user.email,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _selectUser(UserModel user) {
    setState(() {
      _selectedUser = user;
    });
    _showAmountDialog();
  }

  void _showAmountDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Info utilisateur sélectionné
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: _selectedUser!.profileImageUrl != null
                        ? NetworkImage(_selectedUser!.profileImageUrl!)
                        : null,
                    child: _selectedUser!.profileImageUrl == null
                        ? Text(
                            _selectedUser!.initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedUser!.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (_selectedUser!.finimoiTag != null)
                          Text(
                            '@${_selectedUser!.finimoiTag}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Champ montant
            const Text(
              'Montant à envoyer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0 FCFA',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Champ message (optionnel)
            const Text(
              'Message (optionnel)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ajouter un message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Bouton envoyer
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _sendMoney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Envoyer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMoney() async {
    print('💰 _sendMoney() appelée');
    print('💰 Montant saisi: "${_amountController.text}"');
    print('💰 Utilisateur sélectionné: ${_selectedUser?.fullName ?? "null"}');

    if (_amountController.text.isEmpty) {
      print('❌ Montant vide');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un montant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    print('💰 Montant parsé: $amount');
    if (amount == null || amount <= 0) {
      print('❌ Montant invalide');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un montant valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérification du solde
    final userProfile = ref.read(userProfileProvider).value;
    final balance = userProfile?.balance ?? 0.0;
    print('💰 Solde disponible: $balance');

    // Calculer les frais (frais internes = 0 pour l'instant)
    const fees = 0.0;
    final totalAmount = amount + fees;
    print('💰 Montant total à débiter: $totalAmount');

    if (totalAmount > balance) {
      print('❌ Solde insuffisant');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solde insuffisant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ Validation réussie, début du transfert...');

    // Fermer le dialog d'entrée
    Navigator.of(context).pop();

    // Afficher le dialog de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Envoi de ${CurrencyFormatter.formatCFA(amount)} à ${_selectedUser!.fullName}...',
            ),
          ],
        ),
      ),
    );

    try {
      print('💰 Création de la requête de transfert...');
      // Créer la requête de transfert
      final transferRequest = TransferRequest.internal(
        recipientId: _selectedUser!.id,
        recipientName: _selectedUser!.fullName,
        amount: amount,
        description: _messageController.text.isEmpty
            ? 'Transfert vers ${_selectedUser!.fullName}'
            : _messageController.text,
      );

      print('💰 Appel du service de transfert...');
      // Effectuer le transfert
      final transferService = TransferService();
      final result = await transferService.performTransfer(transferRequest);

      print('💰 Résultat du transfert: ${result.isSuccess}');
      // Fermer le dialog de chargement
      Navigator.of(context).pop();

      if (result.isSuccess) {
        print('✅ Transfert réussi !');
        // Sauvegarder le nom avant réinitialisation
        final recipientName = _selectedUser!.fullName;

        // Réinitialiser les champs
        _amountController.clear();
        _messageController.clear();
        _selectedUser = null;
        _searchController.clear();
        setState(() {});

        // Rafraîchir le solde
        ref.invalidate(userProfileProvider);

        // Afficher confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${CurrencyFormatter.formatCFA(amount)} envoyé avec succès à $recipientName !',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ Erreur transfert: ${result.error}');
        // Afficher l'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Erreur lors du transfert'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Exception during transfer: $e');
      // Fermer le dialog de chargement si encore ouvert
      Navigator.of(context).pop();

      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
