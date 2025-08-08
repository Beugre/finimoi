import 'package:flutter/material.dart';
import 'package:finimoi/core/config/auth_config.dart';

/// Widget de debug pour vérifier l'état des configurations d'authentification
class AuthConfigDebugWidget extends StatelessWidget {
  const AuthConfigDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Auth - Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('📊 État des Configurations'),
            _buildConfigCard(
              'Google',
              AuthConfig.isGoogleConfigured,
              Colors.red,
              'Client ID: ${AuthConfig.googleClientId.isNotEmpty ? "✅ Configuré" : "❌ Manquant"}',
            ),

            _buildConfigCard(
              'Apple',
              AuthConfig.isAppleConfigured,
              Colors.black,
              'Service ID: ${AuthConfig.appleServiceId}',
            ),

            _buildConfigCard(
              'Facebook',
              AuthConfig.isFacebookConfigured,
              const Color(0xFF1877F2),
              'App ID: ${_maskSecret(AuthConfig.facebookAppId)}\nClient Token: ${_maskSecret(AuthConfig.facebookClientToken)}',
            ),

            _buildConfigCard(
              'LinkedIn',
              AuthConfig.isLinkedInConfigured,
              const Color(0xFF0A66C2),
              'Client ID: ${_maskSecret(AuthConfig.linkedInClientId)}\nClient Secret: ${_maskSecret(AuthConfig.linkedInClientSecret)}',
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('🔧 Actions de Debug'),

            _buildActionButton(
              'Tester Google Auth',
              AuthConfig.isGoogleConfigured,
              () => _showTestDialog(
                context,
                'Google',
                'Test de connexion Google',
              ),
            ),

            _buildActionButton(
              'Tester Apple Auth',
              AuthConfig.isAppleConfigured,
              () =>
                  _showTestDialog(context, 'Apple', 'Test de connexion Apple'),
            ),

            _buildActionButton(
              'Tester Facebook Auth',
              AuthConfig.isFacebookConfigured,
              () => _showTestDialog(
                context,
                'Facebook',
                'Test de connexion Facebook',
              ),
            ),

            _buildActionButton(
              'Tester LinkedIn Auth',
              AuthConfig.isLinkedInConfigured,
              () => _showTestDialog(
                context,
                'LinkedIn',
                'Test de connexion LinkedIn',
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('📋 Guide Configuration'),

            _buildGuideCard('Facebook', [
              '1. Aller sur developers.facebook.com',
              '2. Créer une App "Consumer"',
              '3. Ajouter Facebook Login pour iOS',
              '4. Copier App ID et Client Token',
              '5. Mettre à jour auth_config.dart et Info.plist',
            ], Colors.blue),

            _buildGuideCard('LinkedIn', [
              '1. Aller sur linkedin.com/developers',
              '2. Créer une page entreprise',
              '3. Créer une App LinkedIn',
              '4. Demander accès à "Sign In with LinkedIn"',
              '5. Copier Client ID et Client Secret',
              '6. Mettre à jour auth_config.dart',
            ], Colors.indigo),

            const SizedBox(height: 24),
            _buildSectionTitle('⚠️ Problèmes Courants'),

            _buildProblemCard('Facebook Login ne fonctionne pas', [
              '• Vérifiez que l\'App ID est correct dans Info.plist',
              '• Assurez-vous que fb{AppID} est dans CFBundleURLSchemes',
              '• Vérifiez que l\'app Facebook est en mode "Live" ou que vous êtes testeur',
              '• Validez les URI de redirection OAuth',
            ]),

            _buildProblemCard('LinkedIn Auth échoue', [
              '• Vérifiez que votre app a accès à "Sign In with LinkedIn"',
              '• Assurez-vous que le Client ID est correct',
              '• Validez l\'URL de redirection autorisée',
              '• LinkedIn nécessite un backend pour l\'échange de tokens',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildConfigCard(
    String provider,
    bool isConfigured,
    Color color,
    String details,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            provider[0],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          provider,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(details),
        trailing: Icon(
          isConfigured ? Icons.check_circle : Icons.error,
          color: isConfigured ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    bool isEnabled,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: isEnabled ? Colors.blue : Colors.grey.shade300,
          foregroundColor: isEnabled ? Colors.white : Colors.grey.shade600,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildGuideCard(String provider, List<String> steps, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: color,
                  child: Text(
                    provider[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Configuration $provider',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  step,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemCard(String title, List<String> solutions) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...solutions.map(
              (solution) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  solution,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _maskSecret(String secret) {
    if (secret.length <= 8) return secret;
    if (secret == 'YOUR_FACEBOOK_CLIENT_TOKEN' ||
        secret == 'YOUR_LINKEDIN_CLIENT_SECRET' ||
        secret == '1234567890' ||
        secret == '78rco6wdmj7vwo') {
      return '❌ Non configuré';
    }
    return '${secret.substring(0, 4)}****${secret.substring(secret.length - 4)}';
  }

  void _showTestDialog(BuildContext context, String provider, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test $provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
            const SizedBox(height: 8),
            const Text(
              'Cette fonctionnalité sera disponible dans l\'écran d\'authentification principal.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

/// Extension pour ajouter facilement le widget de debug
extension AuthConfigDebugExtension on BuildContext {
  void showAuthConfigDebug() {
    Navigator.of(this).push(
      MaterialPageRoute(builder: (context) => const AuthConfigDebugWidget()),
    );
  }
}
