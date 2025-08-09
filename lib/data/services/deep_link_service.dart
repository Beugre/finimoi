import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cinetpay_service.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

// Provider pour le service de deep links
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService(ref);
});

// Variable globale pour la navigation
GoRouter? _globalRouter;

// Setter pour le router global
void setGlobalRouter(GoRouter router) {
  _globalRouter = router;
}

class DeepLinkService {
  final Ref _ref;
  static const platform = MethodChannel('finimoi.app/deeplink');

  DeepLinkService(this._ref);

  // Initialiser la gestion des deep links
  void initialize() {
    platform.setMethodCallHandler(_handleDeepLink);
    _checkPendingTransaction();
  }

  // Gérer les deep links entrants
  Future<void> _handleDeepLink(MethodCall call) async {
    if (call.method == 'handleDeepLink') {
      final String url = call.arguments;
      final uri = Uri.parse(url);

      print('🔗 Deep link reçu: $url');
      print('📋 Scheme: ${uri.scheme}, Path: ${uri.path}');
      print('📝 Paramètres: ${uri.queryParameters}');

      // Accepter à la fois /return et /payment/return pour la compatibilité
      if (uri.scheme == 'finimoi' &&
          (uri.path == '/payment/return' || uri.path == '/return')) {
        final transactionId = uri.queryParameters['transaction_id'];
        final status = uri.queryParameters['status'];

        print('💳 Transaction ID: $transactionId, Status: $status');

        if (transactionId != null) {
          await _handlePaymentReturn(transactionId);
        } else {
          // Si pas de transaction_id, naviguer vers l'écran de retour avec les paramètres disponibles
          print(
            '⚠️ Pas de transaction_id, navigation directe vers /payment/return',
          );

          // Utiliser le router global pour naviguer
          if (_globalRouter != null) {
            _globalRouter!.go('/payment/return?status=$status');
            print('✅ Navigation via router global vers /payment/return');
          } else {
            print('❌ Router global non disponible');
          }
        }
      } else if (uri.scheme == 'finimoi' && uri.path == '/pay') {
        final merchantId = uri.queryParameters['merchantId'];
        final userId = uri.queryParameters['userId'];
        if (merchantId != null && _globalRouter != null) {
          _globalRouter!.push('/merchant/pay', extra: merchantId);
        } else if (userId != null && _globalRouter != null) {
          // We can reuse the merchant payment screen for user payments
          _globalRouter!.push('/merchant/pay', extra: userId);
        }
      }
    }
  }

  // Gérer le retour de paiement
  Future<void> _handlePaymentReturn(String transactionId) async {
    try {
      print('🔄 Traitement du retour de paiement: $transactionId');

      final cinetPayService = _ref.read(cinetPayServiceProvider);
      final transaction = await cinetPayService.checkTransactionStatus(
        transactionId,
      );

      // Naviguer vers l'écran de retour avec le résultat
      String resultStatus = 'failed';
      String message = 'Échec du paiement';

      if (transaction.status == 'ACCEPTED' ||
          transaction.status == 'completed') {
        // Paiement réussi - Mettre à jour le solde
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser != null) {
          await UserService.addToBalance(currentUser.uid, transaction.amount);
          print(
            '✅ Solde mis à jour: +${transaction.amount} ${transaction.currency}',
          );

          // Nettoyer les préférences
          await _clearPendingTransaction();

          // Invalider le cache utilisateur
          _ref.invalidate(userProfileProvider);

          resultStatus = 'success';
          message = 'Paiement réussi! Votre solde a été mis à jour.';
        }
      } else if (transaction.status == 'PENDING') {
        resultStatus = 'pending';
        message = 'Paiement en attente de confirmation...';
        print('⏳ Paiement en attente: $transactionId');
      } else {
        resultStatus = 'failed';
        message = 'Le paiement a échoué. Veuillez réessayer.';
        print('❌ Paiement échoué: ${transaction.status}');
      }

      // Navigation vers l'écran de retour avec le résultat
      if (_globalRouter != null) {
        _globalRouter!.go(
          '/payment/return?transaction_id=$transactionId&status=$resultStatus&message=${Uri.encodeComponent(message)}',
        );
        print('✅ Navigation vers /payment/return avec status: $resultStatus');
      } else {
        print('❌ Router global non disponible pour la navigation');
      }
    } catch (e) {
      print('❌ Erreur lors du traitement du retour: $e');

      // Navigation vers l'écran d'erreur
      if (_globalRouter != null) {
        _globalRouter!.go(
          '/payment/return?transaction_id=$transactionId&status=error&message=${Uri.encodeComponent('Erreur lors de la vérification du paiement')}',
        );
        print('✅ Navigation vers /payment/return avec erreur');
      }
    }
  }

  // Vérifier les transactions en attente au démarrage
  Future<void> _checkPendingTransaction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingTransactionId = prefs.getString('pending_transaction_id');

      if (pendingTransactionId != null) {
        print(
          '🔍 Vérification de transaction en attente: $pendingTransactionId',
        );
        await _handlePaymentReturn(pendingTransactionId);
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification des transactions: $e');
    }
  }

  // Nettoyer les transactions en attente
  Future<void> _clearPendingTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_transaction_id');
    await prefs.remove('pending_amount');
    await prefs.remove('pending_currency');
  }
}
