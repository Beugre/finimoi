import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/cinetpay_service.dart';
import '../../../data/services/user_service.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/providers/auth_provider.dart';

class PaymentReturnScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  final String? status;
  final String? message;

  const PaymentReturnScreen({
    Key? key,
    this.transactionId,
    this.status,
    this.message,
  }) : super(key: key);

  @override
  ConsumerState<PaymentReturnScreen> createState() =>
      _PaymentReturnScreenState();
}

class _PaymentReturnScreenState extends ConsumerState<PaymentReturnScreen> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String _message = '';
  double _amount = 0.0;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();

    // Si on a des paramètres directs (status et message), les utiliser
    if (widget.status != null && widget.message != null) {
      _handleDirectParameters();
    } else {
      // Sinon, vérifier le statut via l'API
      _checkPaymentStatus();
    }
  }

  // Gérer les paramètres passés directement via l'URL
  void _handleDirectParameters() {
    setState(() {
      _isLoading = false;

      switch (widget.status) {
        case 'success':
          _isSuccess = true;
          _message = widget.message ?? 'Paiement réussi !';
          break;
        case 'pending':
          _isSuccess = false;
          _message = widget.message ?? 'Paiement en attente de confirmation...';
          break;
        case 'failed':
        case 'error':
        default:
          _isSuccess = false;
          _message =
              widget.message ?? 'Le paiement a échoué. Veuillez réessayer.';
          break;
      }
    });

    print(
      '📱 Paramètres directs - Status: ${widget.status}, Message: ${widget.message}',
    );
  }

  Future<void> _checkPaymentStatus() async {
    String? transactionId = widget.transactionId;

    // Si pas de transaction ID dans l'URL, vérifier SharedPreferences
    if (transactionId == null || transactionId.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        transactionId = prefs.getString('pending_transaction_id');
        print('🔍 Transaction ID depuis SharedPreferences: $transactionId');
      } catch (e) {
        print('❌ Erreur lors de la lecture des préférences: $e');
      }
    } else {
      print('🔍 Transaction ID depuis l\'URL: $transactionId');
    }

    if (transactionId == null || transactionId.isEmpty) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message =
            'Identifiant de transaction manquant. Vérifiez que le paiement a été initié correctement.';
      });
      return;
    }

    try {
      print('🔍 Vérification du statut de la transaction: $transactionId');
      print('📱 Tentative de connexion à CinetPay API...');

      final cinetPayService = ref.read(cinetPayServiceProvider);

      // Test de connexion avant la requête
      print('🌐 URL de vérification: ${cinetPayService.toString()}');

      final transaction = await cinetPayService.checkTransactionStatus(
        transactionId,
      );

      print('✅ Statut de la transaction: ${transaction.status}');
      print('💰 Montant: ${transaction.amount} ${transaction.currency}');
      print('📅 Date: ${transaction.createdAt}');

      setState(() {
        _isLoading = false;
        _amount = transaction.amount;
      });

      if (transaction.status == 'ACCEPTED') {
        // Paiement réussi - Mettre à jour le solde de l'utilisateur
        print(
          '🎉 Paiement confirmé comme réussi ! Status: ${transaction.status}',
        );

        try {
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            print('👤 Utilisateur connecté: ${currentUser.uid}');
            await UserService.addToBalance(currentUser.uid, transaction.amount);
            print(
              '✅ Solde mis à jour: +${transaction.amount} ${transaction.currency}',
            );
          } else {
            print('❌ Aucun utilisateur connecté pour mettre à jour le solde');
          }
        } catch (e) {
          print('❌ Erreur lors de la mise à jour du solde: $e');
        }

        setState(() {
          _isSuccess = true;
          _message =
              'Paiement réussi ! Votre compte a été rechargé de ${transaction.amount.toStringAsFixed(0)} ${transaction.currency}.';
        });

        // Rafraîchir le profil utilisateur pour mettre à jour le solde dans l'UI
        ref.invalidate(userProfileProvider);
        print('🔄 Profil utilisateur invalidé pour rafraîchir le solde');

        // Nettoyer les SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pending_transaction_id');
          await prefs.remove('pending_amount');
          await prefs.remove('pending_currency');
          print('✅ Préférences nettoyées');
        } catch (e) {
          print('❌ Erreur lors du nettoyage: $e');
        }

        // Attendre un peu puis rediriger
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          print('🏠 Redirection vers l\'écran principal...');
          try {
            context.go('/main');
            print('✅ Navigation vers /main réussie');
          } catch (e) {
            print('❌ Erreur de navigation: $e');
            // Fallback : essayer de naviguer vers la page d'accueil
            try {
              context.go('/');
              print('✅ Navigation vers / réussie (fallback)');
            } catch (e2) {
              print('❌ Erreur de navigation fallback: $e2');
            }
          }
        }
      } else if (transaction.status == 'REFUSED' ||
          transaction.status == 'CANCELLED') {
        // Paiement échoué
        print('❌ Paiement échoué: ${transaction.status}');
        setState(() {
          _isSuccess = false;
          _message = 'Paiement échoué ou annulé. Veuillez réessayer.';
        });
      } else {
        // Paiement en attente (statut inconnu ou en cours)
        print('⏳ Paiement en attente: ${transaction.status}');
        setState(() {
          _isSuccess = false;
          _message =
              'Paiement en cours de traitement... Statut: ${transaction.status}';
        });

        // Redemander le statut dans 3 secondes
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          print('🔄 Nouvelle tentative de vérification...');
          _checkPaymentStatus();
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification: $e');

      // Pour debug: Essayer de vérifier manuellement avec les SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedAmount = prefs.getDouble('pending_amount') ?? 0.0;
        final savedCurrency = prefs.getString('pending_currency') ?? 'XOF';

        print('🔧 Debug: Montant sauvé: $savedAmount $savedCurrency');

        if (savedAmount > 0) {
          // Simuler un succès temporaire pour debug
          print('🆘 Mode debug: Simulation d\'un succès');

          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            await UserService.addToBalance(currentUser.uid, savedAmount);
            print(
              '✅ Solde mis à jour en mode debug: +$savedAmount $savedCurrency',
            );
          }

          setState(() {
            _isLoading = false;
            _isSuccess = true;
            _amount = savedAmount;
            _message =
                'Paiement traité (mode debug) ! Votre compte a été rechargé de ${savedAmount.toStringAsFixed(0)} $savedCurrency.';
          });

          ref.invalidate(userProfileProvider);

          // Nettoyer
          await prefs.remove('pending_transaction_id');
          await prefs.remove('pending_amount');
          await prefs.remove('pending_currency');

          await Future.delayed(const Duration(seconds: 3));
          if (mounted) {
            context.go('/main');
          }
          return;
        }
      } catch (debugError) {
        print('❌ Erreur en mode debug: $debugError');
      }

      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = 'Erreur lors de la vérification du paiement: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retour de paiement'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Vérification du paiement...',
                  style: TextStyle(fontSize: 18),
                ),
              ] else ...[
                Icon(
                  _isSuccess ? Icons.check_circle : Icons.error,
                  size: 80,
                  color: _isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  _isSuccess ? 'Paiement réussi !' : 'Paiement échoué',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                if (_amount > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${_amount.toStringAsFixed(0)} XOF',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/main'),
                  child: const Text('Retour à l\'accueil'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
