import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:finimoi/core/debug/auth_config_debug.dart';
import 'package:finimoi/core/config/auth_config.dart';

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

        // Phone Sign In
        _SocialButton(
          icon: Icons.phone_outlined,
          label: isLogin
              ? 'Continuer avec le téléphone'
              : 'S\'inscrire avec le téléphone',
          onPressed: () => context.push('/auth/phone'),
          backgroundColor: Colors.green,
          textColor: Colors.white,
        ),

        // Apple Sign In (temporairement désactivé - problème entitlements)
        // _SocialButton(
        //   icon: Icons.apple,
        //   label: isLogin ? 'Continuer avec Apple' : 'S\'inscrire avec Apple',
        //   onPressed: onApplePressed ?? () => _handleAppleAuth(context),
        //   backgroundColor: Colors.black,
        //   textColor: Colors.white,
        // ),

        // const SizedBox(height: 12),

        // Facebook Sign In (configuré avec vrais IDs)
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

        // LinkedIn Sign In (masqué temporairement)
        // _SocialButton(
        //   icon: Icons.business,
        //   label: isLogin
        //       ? 'Continuer avec LinkedIn'
        //       : 'S\'inscrire avec LinkedIn',
        //   onPressed: onLinkedInPressed ?? () => _handleLinkedInAuth(context),
        //   backgroundColor: const Color(0xFF0A66C2),
        //   textColor: Colors.white,
        // ),
        const SizedBox(height: 24),

        // Bouton Debug (temporaire)
        Container(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.showAuthConfigDebug(),
            icon: const Icon(Icons.bug_report, size: 18),
            label: const Text('🔧 Debug Configuration Auth'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // AUTHENTIFICATION GOOGLE RÉELLE
  Future<void> _handleGoogleAuth(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Google');

      // Configuration depuis GoogleService-Info.plist
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Vérifier si l'utilisateur est déjà connecté
      GoogleSignInAccount? currentUser = googleSignIn.currentUser;

      if (currentUser == null) {
        // Essayer de se connecter silencieusement d'abord
        currentUser = await googleSignIn.signInSilently();
      }

      // Si pas de connexion silencieuse, demander une connexion interactive
      if (currentUser == null) {
        currentUser = await googleSignIn.signIn();
      }

      if (currentUser == null) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Fermer le loading
        }
        _showError(context, 'Connexion Google annulée par l\'utilisateur');
        return;
      }

      // Obtenir les tokens d'authentification
      final GoogleSignInAuthentication googleAuth =
          await currentUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _showError(context, 'Erreur lors de la récupération des tokens Google');
        return;
      }

      // Créer les credentials Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Connexion Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Fermer le loading
      }

      if (user != null) {
        // Sauvegarder les informations utilisateur
        await _saveUserToFirestore(user, 'google');

        _showSuccess(context, 'Connexion Google réussie !');
        _navigateToHome(context);
      } else {
        _showError(context, 'Erreur lors de la connexion Google');
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Fermer le loading
      }
      debugPrint('Erreur Google Auth: $e');

      // Messages d'erreur plus spécifiques
      String errorMessage = 'Erreur Google: ';
      if (e.toString().contains('sign_in_canceled')) {
        errorMessage += 'Connexion annulée par l\'utilisateur';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage +=
            'Échec de la connexion. Vérifiez votre configuration Google.';
      } else if (e.toString().contains('network_error')) {
        errorMessage += 'Erreur réseau. Vérifiez votre connexion internet.';
      } else {
        errorMessage += e.toString();
      }

      _showError(context, errorMessage);
    }
  }

  // AUTHENTIFICATION APPLE RÉELLE
  Future<void> _handleAppleAuth(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Apple');

      // Vérifier si Apple Sign In est disponible
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _showError(
          context,
          'Apple Sign In n\'est pas disponible sur cet appareil',
        );
        return;
      }

      // Connexion Apple
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Créer les credentials Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Connexion Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(oauthCredential);
      final User? user = userCredential.user;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Fermer le loading
      }

      if (user != null) {
        // Mise à jour du nom si fourni par Apple
        if (credential.givenName != null || credential.familyName != null) {
          final displayName =
              '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                  .trim();
          if (displayName.isNotEmpty) {
            await user.updateDisplayName(displayName);
          }
        }

        await _saveUserToFirestore(user, 'apple');

        _showSuccess(context, 'Connexion Apple réussie !');
        _navigateToHome(context);
      } else {
        _showError(context, 'Erreur lors de la connexion Apple');
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Fermer le loading
      }
      _showError(context, 'Erreur Apple: ${e.toString()}');
    }
  }

  // AUTHENTIFICATION FACEBOOK RÉELLE
  Future<void> _handleFacebookAuth(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Facebook');

      debugPrint('🔵 Facebook: Début de l\'authentification');
      debugPrint('🔵 Facebook: App ID configuré: 1113446920734040');

      // Connexion Facebook avec permissions de base uniquement
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'], // Permissions simplifiées
        loginBehavior: LoginBehavior.nativeWithFallback,
      );

      debugPrint('🔵 Facebook: Statut de connexion: ${result.status}');

      if (result.status != LoginStatus.success) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        String errorMessage = 'Connexion Facebook échouée';
        String debugInfo = '';

        if (result.status == LoginStatus.failed) {
          errorMessage = 'Échec de la connexion Facebook';
          debugInfo = 'Message: ${result.message}';
          debugPrint('🔴 Facebook: Échec - ${result.message}');
        } else if (result.status == LoginStatus.cancelled) {
          errorMessage = 'Connexion Facebook annulée par l\'utilisateur';
          debugPrint('🟡 Facebook: Annulée par l\'utilisateur');
        } else if (result.status == LoginStatus.operationInProgress) {
          errorMessage = 'Opération Facebook en cours...';
          debugPrint('🟡 Facebook: Opération en cours');
        }

        _showError(
          context,
          '$errorMessage\n\nDébug: $debugInfo\n\nVérifiez:\n• App Facebook en mode Development\n• Vous êtes testeur de l\'app\n• Bundle ID correct dans Facebook Console',
        );
        return;
      }

      debugPrint('🟢 Facebook: Connexion réussie');

      // Obtenir le token d'accès
      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        debugPrint('🔴 Facebook: Token d\'accès non disponible');
        _showError(
          context,
          'Token Facebook non disponible\n\nL\'authentification Facebook a réussi mais le token n\'est pas accessible.',
        );
        return;
      }

      debugPrint(
        '🟢 Facebook: Token obtenu, longueur: ${accessToken.tokenString.length}',
      );

      // Vérifier les données utilisateur Facebook
      try {
        final userData = await FacebookAuth.instance.getUserData(
          fields:
              "name,email,picture.width(200).height(200),first_name,last_name",
        );
        debugPrint(
          '🟢 Facebook: Données utilisateur récupérées: ${userData.keys}',
        );
      } catch (e) {
        debugPrint(
          '🟡 Facebook: Impossible de récupérer les données utilisateur: $e',
        );
      }

      // Créer les credentials Firebase
      debugPrint('🔵 Facebook: Création des credentials Firebase...');
      final credential = FacebookAuthProvider.credential(
        accessToken.tokenString,
      );

      // Connexion Firebase
      debugPrint('🔵 Facebook: Connexion Firebase...');
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Fermer le loading
      }

      if (user != null) {
        debugPrint('🟢 Facebook: Utilisateur Firebase créé: ${user.uid}');

        // Récupérer les données utilisateur pour la sauvegarde
        Map<String, dynamic>? userData;
        try {
          userData = await FacebookAuth.instance.getUserData(
            fields:
                "name,email,picture.width(200).height(200),first_name,last_name",
          );

          // Mettre à jour les informations utilisateur avec les données Facebook
          if (userData['name'] != null &&
              user.displayName != userData['name']) {
            await user.updateDisplayName(userData['name']);
          }
          if (userData['picture']?['data']?['url'] != null) {
            await user.updatePhotoURL(userData['picture']['data']['url']);
          }
        } catch (e) {
          debugPrint(
            '🟡 Facebook: Erreur lors de la récupération des données: $e',
          );
        }

        await _saveUserToFirestore(user, 'facebook', additionalData: userData);
        _showSuccess(
          context,
          'Connexion Facebook réussie !\n\nProfil: ${user.displayName ?? "Sans nom"}\nEmail: ${user.email ?? "Pas d\'email"}',
        );
        _navigateToHome(context);
      } else {
        debugPrint('🔴 Facebook: Utilisateur Firebase null');
        _showError(
          context,
          'Erreur lors de la connexion Facebook\n\nFirebase n\'a pas pu créer l\'utilisateur.',
        );
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      debugPrint('🔴 Facebook Auth Exception: $e');

      String errorMessage = 'Erreur Facebook: ';
      if (e.toString().contains('network')) {
        errorMessage += 'Problème de réseau. Vérifiez votre connexion.';
      } else if (e.toString().contains('configuration')) {
        errorMessage += 'Configuration Facebook incorrecte.';
      } else if (e.toString().contains('PlatformException')) {
        errorMessage += 'Erreur plateforme iOS.';
      } else {
        errorMessage += e.toString();
      }

      _showError(
        context,
        '$errorMessage\n\nVérifications:\n• App Facebook: 1113446920734040\n• Mode Development activé\n• Vous êtes testeur\n• iOS Bundle ID correct',
      );
    }
  } // AUTHENTIFICATION LINKEDIN RÉELLE

  Future<void> _handleLinkedInAuth(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'LinkedIn');

      // Configuration LinkedIn OAuth
      const String clientId = '78rco6wdmj7vwo'; // Exemple client ID
      const String redirectUri = 'https://finimoi.app/auth/linkedin/callback';
      const String scope = 'openid profile email';
      final String state =
          'linkedin_auth_${DateTime.now().millisecondsSinceEpoch}';

      final String authUrl =
          'https://www.linkedin.com/oauth/v2/authorization'
          '?response_type=code'
          '&client_id=$clientId'
          '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
          '&scope=${Uri.encodeComponent(scope)}'
          '&state=$state';

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Fermer le loading
      }

      // Afficher WebView pour LinkedIn OAuth
      final Map<String, String>? authResult = await Navigator.of(context)
          .push<Map<String, String>>(
            MaterialPageRoute(
              builder: (context) =>
                  _LinkedInWebView(authUrl: authUrl, redirectUri: redirectUri),
            ),
          );

      if (authResult == null || authResult['code'] == null) {
        _showError(context, 'Connexion LinkedIn annulée');
        return;
      }

      _showLoadingDialog(context, 'LinkedIn');

      // Simuler l'échange de token (en production, ceci se ferait côté serveur)
      await Future.delayed(const Duration(seconds: 2));

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Pour la démonstration, nous créons un utilisateur fictif LinkedIn
      await _createLinkedInDemoUser(context, authResult);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      debugPrint('Erreur LinkedIn Auth: $e');
      _showError(context, 'Erreur LinkedIn: ${e.toString()}');
    }
  }

  // Créer un utilisateur démo LinkedIn (en attendant l'implémentation backend)
  Future<void> _createLinkedInDemoUser(
    BuildContext context,
    Map<String, String> authResult,
  ) async {
    try {
      // Données utilisateur LinkedIn simulées
      final linkedInUserData = {
        'id': 'linkedin_demo_${DateTime.now().millisecondsSinceEpoch}',
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john.doe@example.com',
        'profilePicture':
            'https://via.placeholder.com/200x200/0A66C2/FFFFFF?text=LI',
        'headline': 'Développeur chez FinIMoi',
        'location': 'Abidjan, Côte d\'Ivoire',
      };

      // Créer un utilisateur Firebase personnalisé pour LinkedIn
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        // Si pas d'utilisateur connecté, créer un compte anonyme temporaire
        final UserCredential anonymousCredential = await FirebaseAuth.instance
            .signInAnonymously();
        final User? anonymousUser = anonymousCredential.user;

        if (anonymousUser != null) {
          // Mettre à jour le profil avec les données LinkedIn
          await anonymousUser.updateDisplayName(
            '${linkedInUserData['firstName']} ${linkedInUserData['lastName']}',
          );
          await anonymousUser.updatePhotoURL(
            linkedInUserData['profilePicture'],
          );

          // Sauvegarder dans Firestore avec les données LinkedIn
          await _saveUserToFirestore(
            anonymousUser,
            'linkedin',
            additionalData: linkedInUserData,
          );

          _showSuccess(context, 'Connexion LinkedIn réussie ! (Mode Démo)');
          _navigateToHome(context);
        }
      } else {
        // Lier les données LinkedIn au compte existant
        await _saveUserToFirestore(
          currentUser,
          'linkedin',
          additionalData: linkedInUserData,
        );
        _showSuccess(context, 'Compte LinkedIn lié avec succès ! (Mode Démo)');
        _navigateToHome(context);
      }
    } catch (e) {
      debugPrint('Erreur création utilisateur LinkedIn démo: $e');
      _showError(context, 'Erreur lors de la création du profil LinkedIn');
    }
  }

  // SAUVEGARDE UTILISATEUR DANS FIRESTORE
  Future<void> _saveUserToFirestore(
    User user,
    String provider, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userDoc = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'provider': provider,
        'createdAt': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
        'isEmailVerified': user.emailVerified,
        'phoneNumber': user.phoneNumber,
        'providerData': user.providerData
            .map(
              (info) => {
                'providerId': info.providerId,
                'uid': info.uid,
                'displayName': info.displayName,
                'email': info.email,
                'photoURL': info.photoURL,
              },
            )
            .toList(),
      };

      // Ajouter les données additionnelles si fournies
      if (additionalData != null) {
        userDoc['additionalProviderData'] = additionalData;
      }

      // Sauvegarder dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userDoc, SetOptions(merge: true));

      // Créer le profil utilisateur dans l'app
      await _createUserProfile(user);
    } catch (e) {
      debugPrint('Erreur sauvegarde Firestore: $e');
    }
  }

  // CRÉER PROFIL UTILISATEUR COMPLET
  Future<void> _createUserProfile(User user) async {
    try {
      // Créer un solde initial
      await FirebaseFirestore.instance
          .collection('balances')
          .doc(user.uid)
          .set({
            'balance': 0.0,
            'currency': 'XOF',
            'lastUpdated': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));

      // Créer les préférences utilisateur
      await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(user.uid)
          .set({
            'notifications': true,
            'biometricAuth': false,
            'language': 'fr',
            'theme': 'light',
            'currency': 'XOF',
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erreur création profil: $e');
    }
  }

  // INTERFACES UTILISATEUR
  void _showLoadingDialog(BuildContext context, String provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Authentification $provider...'),
            const SizedBox(height: 8),
            const Text(
              'Redirection en cours...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Erreur d\'authentification'),
          ],
        ),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    context.go('/main');
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
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor ?? backgroundColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// WebView pour LinkedIn OAuth
class _LinkedInWebView extends StatefulWidget {
  final String authUrl;
  final String redirectUri;

  const _LinkedInWebView({required this.authUrl, required this.redirectUri});

  @override
  State<_LinkedInWebView> createState() => _LinkedInWebViewState();
}

class _LinkedInWebViewState extends State<_LinkedInWebView> {
  late final WebViewController controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(widget.redirectUri)) {
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];
              final state = uri.queryParameters['state'];
              final error = uri.queryParameters['error'];

              if (error != null) {
                Navigator.of(context).pop({'error': error});
              } else if (code != null) {
                Navigator.of(context).pop({'code': code, 'state': state ?? ''});
              } else {
                Navigator.of(context).pop(null);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion LinkedIn'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: const Color(0xFF0A66C2),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF0A66C2),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement de LinkedIn...',
                    style: TextStyle(fontSize: 16, color: Color(0xFF0A66C2)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
