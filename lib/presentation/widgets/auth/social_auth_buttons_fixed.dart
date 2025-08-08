import 'package:flutter/material.dart';

class SocialAuthButtons extends StatelessWidget {
  final bool isLogin;
  final VoidCallback? onGooglePressed;
  final VoidCallback? onApplePressed;
  final VoidCallback? onFacebookPressed;
  final VoidCallback? onLinkedInPressed;

  const SocialAuthButtons({
    super.key,
    this.isLogin = true,
    this.onGooglePressed,
    this.onApplePressed,
    this.onFacebookPressed,
    this.onLinkedInPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Sign In
        _SocialButton(
          icon: Icons.g_mobiledata,
          label: isLogin ? 'Continuer avec Google' : 'S\'inscrire avec Google',
          onPressed: onGooglePressed ?? () => _handleGoogleAuth(context),
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          borderColor: Colors.grey.shade300,
        ),

        const SizedBox(height: 12),

        // Apple Sign In
        _SocialButton(
          icon: Icons.apple,
          label: isLogin ? 'Continuer avec Apple' : 'S\'inscrire avec Apple',
          onPressed: onApplePressed ?? () => _handleAppleAuth(context),
          backgroundColor: Colors.black,
          textColor: Colors.white,
        ),

        const SizedBox(height: 12),

        // Facebook Sign In
        _SocialButton(
          icon: Icons.facebook,
          label: isLogin
              ? 'Continuer avec Facebook'
              : 'S\'inscrire avec Facebook',
          onPressed: onFacebookPressed ?? () => _handleFacebookAuth(context),
          backgroundColor: const Color(0xFF1877F2),
          textColor: Colors.white,
        ),

        const SizedBox(height: 12),

        // LinkedIn Sign In
        _SocialButton(
          icon: Icons.business,
          label: isLogin
              ? 'Continuer avec LinkedIn'
              : 'S\'inscrire avec LinkedIn',
          onPressed: onLinkedInPressed ?? () => _handleLinkedInAuth(context),
          backgroundColor: const Color(0xFF0A66C2),
          textColor: Colors.white,
        ),
      ],
    );
  }

  // Méthodes spécifiques pour chaque provider
  Future<void> _handleGoogleAuth(BuildContext context) async {
    await _performSocialAuth(context, 'Google', _googleAuthFlow);
  }

  Future<void> _handleAppleAuth(BuildContext context) async {
    await _performSocialAuth(context, 'Apple', _appleAuthFlow);
  }

  Future<void> _handleFacebookAuth(BuildContext context) async {
    await _performSocialAuth(context, 'Facebook', _facebookAuthFlow);
  }

  Future<void> _handleLinkedInAuth(BuildContext context) async {
    await _performSocialAuth(context, 'LinkedIn', _linkedInAuthFlow);
  }

  Future<void> _performSocialAuth(
    BuildContext context,
    String provider,
    Future<Map<String, dynamic>> Function() authFlow,
  ) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Connexion $provider en cours...'),
              const SizedBox(height: 8),
              const Text(
                'Redirection vers le service d\'authentification...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Exécuter le flux d'authentification
      final result = await authFlow();

      // Fermer le dialog de chargement
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Connexion $provider réussie !'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Simulation de sauvegarde des données utilisateur
        await _saveUserData(result['userData']);

        // Redirection vers l'écran principal
        _navigateToHome(context);
      } else {
        _showAuthError(context, provider, result['error']);
      }
    } catch (e) {
      // Fermer le dialog de chargement en cas d'erreur
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showAuthError(context, provider, e.toString());
    }
  }

  // Flux d'authentification simulés pour chaque provider
  Future<Map<String, dynamic>> _googleAuthFlow() async {
    await Future.delayed(const Duration(seconds: 2));

    // Simulation du succès (80% de chance)
    if (DateTime.now().millisecond % 10 < 8) {
      return {
        'success': true,
        'userData': {
          'provider': 'google',
          'id': 'google_${DateTime.now().millisecondsSinceEpoch}',
          'email': 'user@gmail.com',
          'name': 'Utilisateur Google',
          'avatar': 'https://lh3.googleusercontent.com/a/default-user',
        },
      };
    } else {
      return {'success': false, 'error': 'Connexion Google annulée ou échouée'};
    }
  }

  Future<Map<String, dynamic>> _appleAuthFlow() async {
    await Future.delayed(const Duration(seconds: 2));

    if (DateTime.now().millisecond % 10 < 8) {
      return {
        'success': true,
        'userData': {
          'provider': 'apple',
          'id': 'apple_${DateTime.now().millisecondsSinceEpoch}',
          'email': 'user@privaterelay.appleid.com',
          'name': 'Utilisateur Apple',
          'avatar': null,
        },
      };
    } else {
      return {'success': false, 'error': 'Connexion Apple ID annulée'};
    }
  }

  Future<Map<String, dynamic>> _facebookAuthFlow() async {
    await Future.delayed(const Duration(seconds: 2));

    if (DateTime.now().millisecond % 10 < 8) {
      return {
        'success': true,
        'userData': {
          'provider': 'facebook',
          'id': 'fb_${DateTime.now().millisecondsSinceEpoch}',
          'email': 'user@facebook.com',
          'name': 'Utilisateur Facebook',
          'avatar': 'https://graph.facebook.com/v12.0/me/picture',
        },
      };
    } else {
      return {'success': false, 'error': 'Connexion Facebook refusée'};
    }
  }

  Future<Map<String, dynamic>> _linkedInAuthFlow() async {
    await Future.delayed(const Duration(seconds: 2));

    if (DateTime.now().millisecond % 10 < 8) {
      return {
        'success': true,
        'userData': {
          'provider': 'linkedin',
          'id': 'linkedin_${DateTime.now().millisecondsSinceEpoch}',
          'email': 'user@company.com',
          'name': 'Utilisateur LinkedIn',
          'avatar': 'https://media.licdn.com/dms/image/profile-photo',
        },
      };
    } else {
      return {'success': false, 'error': 'Autorisation LinkedIn requise'};
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    // Simulation de sauvegarde des données utilisateur
    await Future.delayed(const Duration(milliseconds: 500));
    // En production, ici on sauvegarderait en base de données
    print('Données utilisateur sauvegardées: $userData');
  }

  void _showAuthError(
    BuildContext context,
    String provider, [
    String? customError,
  ]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur $provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(customError ?? 'La connexion $provider a échoué.'),
            const SizedBox(height: 8),
            const Text(
              'Vérifiez votre connexion internet et réessayez.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Relancer l'authentification selon le provider
              switch (provider) {
                case 'Google':
                  _handleGoogleAuth(context);
                  break;
                case 'Apple':
                  _handleAppleAuth(context);
                  break;
                case 'Facebook':
                  _handleFacebookAuth(context);
                  break;
                case 'LinkedIn':
                  _handleLinkedInAuth(context);
                  break;
              }
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    // Redirection vers l'écran principal
    Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 1,
          shadowColor: Colors.black26,
          side: borderColor != null ? BorderSide(color: borderColor!) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
