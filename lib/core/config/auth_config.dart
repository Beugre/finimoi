/// Configuration des providers d'authentification pour FinIMoi
///
/// Ce fichier contient les identifiants et configurations pour tous les
/// providers d'authentification sociale de l'application.

class AuthConfig {
  // Configuration Google (déjà fonctionnelle)
  static const String googleClientId =
      '363043806234-p64tmb8334e61m503adsj9pu6ktg1afb.apps.googleusercontent.com';

  // Configuration Facebook (configuré ✅)
  static const String facebookAppId = '1113446920734040';
  static const String facebookClientToken = '82b0c369fd4fbde78e3a3016c3f166fd';

  // Configuration LinkedIn (nécessite création d'une app LinkedIn)
  static const String linkedInClientId =
      '78rco6wdmj7vwo'; // À remplacer par le vrai Client ID
  static const String linkedInClientSecret =
      'YOUR_LINKEDIN_CLIENT_SECRET'; // À remplacer
  static const String linkedInRedirectUri =
      'https://finimoi.app/auth/linkedin/callback';

  // Configuration Apple (déjà fonctionnelle nativement sur iOS)
  static const String appleServiceId = 'com.finimoi.app.finimoi';

  // URLs de redirection
  static const String baseRedirectUrl = 'https://finimoi.app/auth';

  // Scopes pour chaque provider
  static const List<String> googleScopes = ['email', 'profile'];
  static const List<String> facebookPermissions = [
    'email',
    'public_profile',
    'user_friends',
  ];
  static const String linkedInScope = 'openid profile email';
  static const List<String> appleScopes = ['email', 'fullName'];

  // Configuration des couleurs pour les boutons
  static const Map<String, Map<String, dynamic>> providerColors = {
    'google': {
      'background': 0xFFFFFFFF,
      'text': 0xFF000000,
      'border': 0xFFE0E0E0,
    },
    'facebook': {
      'background': 0xFF1877F2,
      'text': 0xFFFFFFFF,
      'border': 0xFF1877F2,
    },
    'apple': {
      'background': 0xFF000000,
      'text': 0xFFFFFFFF,
      'border': 0xFF000000,
    },
    'linkedin': {
      'background': 0xFF0A66C2,
      'text': 0xFFFFFFFF,
      'border': 0xFF0A66C2,
    },
  };

  // Configuration des erreurs communes
  static const Map<String, String> errorMessages = {
    'network_error': 'Erreur de réseau. Vérifiez votre connexion internet.',
    'configuration_error':
        'Erreur de configuration. Veuillez réessayer plus tard.',
    'user_cancelled': 'Connexion annulée par l\'utilisateur.',
    'invalid_credentials': 'Identifiants invalides.',
    'account_disabled': 'Ce compte a été désactivé.',
    'too_many_requests': 'Trop de tentatives. Veuillez patienter.',
  };

  // Méthodes utilitaires
  static bool get isGoogleConfigured => googleClientId.isNotEmpty;
  static bool get isFacebookConfigured =>
      facebookAppId != '1234567890' &&
      facebookClientToken != 'YOUR_FACEBOOK_CLIENT_TOKEN';
  static bool get isLinkedInConfigured =>
      linkedInClientId != '78rco6wdmj7vwo' &&
      linkedInClientSecret != 'YOUR_LINKEDIN_CLIENT_SECRET';
  static bool get isAppleConfigured => true; // Toujours disponible sur iOS

  /// Génère un state unique pour OAuth
  static String generateState(String provider) {
    return '${provider}_auth_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Valide si un provider est configuré correctement
  static bool isProviderConfigured(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return isGoogleConfigured;
      case 'facebook':
        return isFacebookConfigured;
      case 'linkedin':
        return isLinkedInConfigured;
      case 'apple':
        return isAppleConfigured;
      default:
        return false;
    }
  }

  /// Retourne les couleurs pour un provider
  static Map<String, dynamic>? getProviderColors(String provider) {
    return providerColors[provider.toLowerCase()];
  }

  /// Retourne le message d'erreur approprié
  static String getErrorMessage(String errorKey) {
    return errorMessages[errorKey] ?? 'Une erreur inattendue s\'est produite.';
  }
}
