import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/services/test_data_service.dart';
import '../../../debug/transaction_debugger.dart';
import '../../providers/real_savings_provider.dart';
import '../../providers/card_providers.dart';
import '../../providers/chat_providers.dart';
import '../../../domain/entities/savings_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Paramètres'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profil Section
            _buildSection(
              title: 'Profil',
              children: [
                _buildProfileTile(),
                _buildSettingsTile(
                  icon: Icons.edit,
                  title: 'Modifier le profil',
                  subtitle: 'Informations personnelles',
                  onTap: () => context.push('/profile/edit'),
                ),
                _buildSettingsTile(
                  icon: Icons.security,
                  title: 'Sécurité',
                  subtitle: 'Mot de passe et authentification',
                  onTap: () => _showSecurityDialog(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Notifications Section
            _buildSection(
              title: 'Notifications',
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: 'Notifications push',
                  subtitle: 'Recevoir des notifications mobiles',
                  value: _pushNotifications,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                ),
                _buildSwitchTile(
                  icon: Icons.email,
                  title: 'Notifications email',
                  subtitle: 'Recevoir des emails de notification',
                  value: _emailNotifications,
                  onChanged: (value) =>
                      setState(() => _emailNotifications = value),
                ),
                _buildSwitchTile(
                  icon: Icons.sms,
                  title: 'Notifications SMS',
                  subtitle: 'Recevoir des SMS importants',
                  value: _smsNotifications,
                  onChanged: (value) =>
                      setState(() => _smsNotifications = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sécurité Section
            _buildSection(
              title: 'Sécurité',
              children: [
                _buildSwitchTile(
                  icon: Icons.fingerprint,
                  title: 'Authentification biométrique',
                  subtitle: 'TouchID / FaceID pour l\'accès',
                  value: _biometricEnabled,
                  onChanged: (value) =>
                      setState(() => _biometricEnabled = value),
                ),
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: 'Code PIN',
                  subtitle: 'Définir un code PIN',
                  onTap: () => _showPinDialog(),
                ),
                _buildSettingsTile(
                  icon: Icons.history,
                  title: 'Sessions actives',
                  subtitle: 'Gérer les appareils connectés',
                  onTap: () => _showSessionsDialog(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Apparence Section
            _buildSection(
              title: 'Épargne',
              children: [
                _buildSwitchTile(
                  icon: Icons.add_circle_outline,
                  title: 'Arrondi automatique',
                  subtitle: 'Épargnez la petite monnaie de vos transactions',
                  value: ref.watch(userProfileProvider).value?.roundUpSavingsEnabled ?? false,
                  onChanged: (value) {
                    final userId = ref.read(currentUserProvider)?.uid;
                    if (userId != null) {
                      ref.read(userServiceProvider).updateUserProfile(userId, {'roundUpSavingsEnabled': value});
                    }
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.savings,
                  title: 'Objectif pour l\'arrondi',
                  subtitle: 'Choisir un objectif pour recevoir l\'arrondi',
                  onTap: () => _showRoundUpGoalDialog(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSection(
              title: 'Apparence',
              children: [
                _buildSwitchTile(
                  icon: Icons.dark_mode,
                  title: 'Mode sombre',
                  subtitle: 'Activer le thème sombre',
                  value: _darkMode,
                  onChanged: (value) => setState(() => _darkMode = value),
                ),
                _buildSettingsTile(
                  icon: Icons.language,
                  title: 'Langue',
                  subtitle: 'Français',
                  onTap: () => _showLanguageDialog(),
                ),
                 _buildSettingsTile(
                  icon: Icons.view_quilt,
                  title: 'Personnaliser l\'accueil',
                  subtitle: 'Réorganiser les sections de l\'accueil',
                  onTap: () => context.push('/settings/customize-home'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Debug Section (mode développement)
            _buildSection(
              title: 'Debug (Développement)',
              children: [
                 _buildSettingsTile(
                  icon: Icons.settings_applications,
                  title: 'Debug Menu',
                  subtitle: 'Actions spéciales de débogage',
                  onTap: () => context.push('/settings/debug'),
                ),
                _buildSettingsTile(
                  icon: Icons.data_object,
                  title: 'Initialiser données de test',
                  subtitle: 'Créer des données de test pour développement',
                  onTap: () => _initializeTestData(),
                ),
                _buildSettingsTile(
                  icon: Icons.bug_report,
                  title: 'Debug Transactions',
                  subtitle: 'Analyser le flux des données de transactions',
                  onTap: () => _debugTransactions(),
                ),
                _buildSettingsTile(
                  icon: Icons.speed,
                  title: 'Test Rapide Data',
                  subtitle: 'Vérification rapide des données Firestore',
                  onTap: () => _quickDataTest(),
                ),
                _buildSettingsTile(
                  icon: Icons.delete_sweep,
                  title: 'Effacer données de test',
                  subtitle: 'Supprimer toutes les données de test',
                  onTap: () => _clearTestData(),
                ),
                _buildSettingsTile(
                  icon: Icons.refresh,
                  title: 'Recharger providers',
                  subtitle: 'Forcer la mise à jour des données',
                  onTap: () => _refreshProviders(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Support Section
            _buildSection(
              title: 'Support',
              children: [
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Centre d\'aide',
                  subtitle: 'FAQ et guides d\'utilisation',
                  onTap: () => _openHelpCenter(),
                ),
                _buildSettingsTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Contacter le support',
                  subtitle: 'Assistance en ligne',
                  onTap: () => context.push('/chat'),
                ),
                _buildSettingsTile(
                  icon: Icons.bug_report,
                  title: 'Signaler un problème',
                  subtitle: 'Rapporter un bug',
                  onTap: () => _reportBug(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Legal Section
            _buildSection(
              title: 'Légal',
              children: [
                _buildSettingsTile(
                  icon: Icons.privacy_tip,
                  title: 'Politique de confidentialité',
                  subtitle: 'Comment nous protégeons vos données',
                  onTap: () => _openPrivacyPolicy(),
                ),
                _buildSettingsTile(
                  icon: Icons.description,
                  title: 'Conditions d\'utilisation',
                  subtitle: 'Termes et conditions',
                  onTap: () => _openTermsOfService(),
                ),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'À propos',
                  subtitle: 'Version ${_getAppVersion()}',
                  onTap: () => _showAboutDialog(),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Logout Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(
                      Icons.delete_forever,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Supprimer le compte',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryViolet,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileTile() {
    final currentUser = ref.watch(currentUserProvider);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primaryViolet,
        backgroundImage: currentUser?.photoURL != null
            ? NetworkImage(currentUser!.photoURL!)
            : null,
        child: currentUser?.photoURL == null
            ? Text(
                currentUser?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        currentUser?.displayName ?? 'Utilisateur',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(currentUser?.email ?? ''),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => context.push('/profile'),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryViolet.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryViolet, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryViolet.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryViolet, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryViolet,
      ),
    );
  }

  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sécurité'),
        content: const Text(
          'Options de sécurité avancées disponibles bientôt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code PIN'),
        content: const Text('Configuration du code PIN disponible bientôt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showSessionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sessions actives'),
        content: const Text('Gestion des sessions disponible bientôt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Français'),
              leading: Radio<String>(
                value: 'fr',
                groupValue: 'fr',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: 'fr',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _openHelpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Centre d\'aide disponible ! Nous sommes là pour vous aider.',
        ),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rapport de bug envoyé ! Merci pour votre retour.'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _openPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Politique de confidentialité consultable dans l\'application.',
        ),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _openTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Conditions d\'utilisation disponibles dans l\'application.',
        ),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'FinIMoi',
      applicationVersion: _getAppVersion(),
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryViolet, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.account_balance_wallet,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text('Application de fintech révolutionnaire pour l\'Afrique.'),
        const SizedBox(height: 16),
        const Text(
          'Développé avec ❤️ pour simplifier vos finances.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  String _getAppVersion() {
    return '1.0.0'; // À récupérer depuis package_info_plus
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authController = ref.read(authControllerProvider);
      await authController.signOut();
      if (mounted) {
        context.go('/auth/login');
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront supprimées définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Suppression de compte activée. Contactez le support pour procéder.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Initialiser les données de test
  Future<void> _initializeTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialiser données de test'),
        content: const Text(
          'Cette action va créer des données de test pour toutes les fonctionnalités (transferts, épargnes, cartes, etc.). Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Afficher un indicateur de chargement
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Création des données de test...'),
              ],
            ),
          ),
        );

        await TestDataService.initializeAllTestData();

        // Fermer l'indicateur de chargement
        if (mounted) Navigator.pop(context);

        // Afficher le succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Données de test créées avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Fermer l'indicateur de chargement en cas d'erreur
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  /// Effacer les données de test
  Future<void> _clearTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer données de test'),
        content: const Text(
          'Cette action va supprimer toutes les données de test. Cette action est irréversible. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Effacer toutes les données de test
        await TestDataService.clearAllTestData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données de test effacées avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Rafraîchir les providers après effacement
        _refreshProviders();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'effacement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Recharger tous les providers
  void _refreshProviders() {
    // Invalider tous les providers pour forcer le rechargement
    ref.invalidate(userTransactionsProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(userSavingsProvider);
    ref.invalidate(userCardsProvider);
    ref.invalidate(userConversationsProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Providers rechargés'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Debug des transactions - analyse le flux des données
  Future<void> _debugTransactions() async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Analyse en cours...'),
            ],
          ),
        ),
      );

      // Exécuter le debug
      await TransactionDebugger.debugTransactionFlow();

      // Fermer l'indicateur de chargement
      if (mounted) Navigator.pop(context);

      // Afficher le résultat
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Debug terminé - Vérifiez la console'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur debug: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Test rapide des données Firestore
  Future<void> _quickDataTest() async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Test rapide en cours...'),
            ],
          ),
        ),
      );

      // Exécuter le test rapide
      await TransactionDebugger.quickDataCheck();

      // Fermer l'indicateur de chargement
      if (mounted) Navigator.pop(context);

      // Afficher le résultat
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Test rapide terminé - Vérifiez la console'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur test: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showRoundUpGoalDialog() {
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) return;

    final savingsAsync = ref.watch(userSavingsProvider(userId));

    showDialog(
      context: context,
      builder: (context) {
        return savingsAsync.when(
          data: (savings) {
            return AlertDialog(
              title: const Text('Choisir un objectif'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: savings.length,
                  itemBuilder: (context, index) {
                    final goal = savings[index];
                    return ListTile(
                      title: Text(goal.goalName),
                      onTap: () {
                        ref.read(userServiceProvider).updateUserProfile(userId, {'roundUpSavingsGoalId': goal.id});
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Erreur: $e'),
        );
      },
    );
  }
}
