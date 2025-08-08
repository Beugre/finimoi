import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/cinetpay_config.dart';

// Provider pour le service CinetPay
final cinetPayServiceProvider = Provider<CinetPayService>((ref) {
  return CinetPayService();
});

class CinetPayService {
  // Initier un paiement
  Future<CinetPayTransaction> initiatePayment({
    required double amount,
    required String currency,
    required String paymentMethod,
    required String userId,
    String? description,
  }) async {
    try {
      final transactionId = 'FINIMOI_${DateTime.now().millisecondsSinceEpoch}';

      final requestData = {
        'apikey': CinetPayConfig.apiKey,
        'site_id': CinetPayConfig.siteId,
        'transaction_id': transactionId,
        'amount': amount.toInt(),
        'currency': currency,
        'description': description ?? 'Rechargement FinIMoi',
        'customer_name': 'Utilisateur FinIMoi',
        'customer_surname': 'Test',
        'customer_email': 'user@finimoi.app',
        'customer_phone_number': '+2250748123456',
        'customer_address': 'Abidjan',
        'customer_city': 'Abidjan',
        'customer_country': 'CI',
        'customer_state': 'CI',
        'customer_zip_code': '00225',
        'return_url':
            '${CinetPayConfig.returnUrl}?transaction_id=$transactionId',
        'notify_url': CinetPayConfig.notifyUrl,
        'cancel_url': CinetPayConfig.cancelUrl,
        'custom': userId, // Pour identifier l'utilisateur dans le webhook
        'channels': paymentMethod == 'ALL' ? 'ALL' : paymentMethod,
      };

      final response = await http.post(
        Uri.parse('${CinetPayConfig.baseUrl}/payment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      );

      print('🌐 CinetPay API Response Status: ${response.statusCode}');
      print('🌐 CinetPay API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['code'] == '201') {
          return CinetPayTransaction(
            transactionId: transactionId,
            paymentUrl: responseData['data']['payment_url'],
            status: 'pending',
            amount: amount,
            currency: currency,
            createdAt: DateTime.now(),
            metadata: {'user_id': userId, 'payment_method': paymentMethod},
          );
        } else {
          print('❌ CinetPay Error Code: ${responseData['code']}');
          print('❌ CinetPay Error Message: ${responseData['message']}');
          throw Exception(
            'CinetPay Error ${responseData['code']}: ${responseData['message'] ?? 'Erreur lors de l\'initiation du paiement'}',
          );
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'initiation du paiement: $e');
    }
  }

  // Vérifier le statut d'une transaction
  Future<CinetPayTransaction> checkTransactionStatus(
    String transactionId,
  ) async {
    try {
      final requestData = {
        'apikey': CinetPayConfig.apiKey,
        'site_id': CinetPayConfig.siteId,
        'transaction_id': transactionId,
      };

      print('🔍 Données envoyées à CinetPay:');
      print('   - URL: ${CinetPayConfig.baseUrl}/payment/check');
      print('   - Transaction ID: $transactionId');
      print('   - Site ID: ${CinetPayConfig.siteId}');
      print('   - API Key: ${CinetPayConfig.apiKey.substring(0, 10)}...');
      print('   - Payload JSON: ${json.encode(requestData)}');

      final url = Uri.parse('${CinetPayConfig.baseUrl}/payment/check');
      print('🌐 URL complète: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      );

      print('🌐 Check Status Response: ${response.statusCode}');
      print('🌐 Check Status Headers: ${response.headers}');
      print('🌐 Check Status Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['code'] == '00') {
          final data = responseData['data'];
          return CinetPayTransaction(
            transactionId: transactionId,
            paymentUrl: '',
            status:
                data['status'], // Utiliser 'status' au lieu de 'payment_status'
            amount: _parseAmount(data['amount']),
            currency: data['currency'],
            createdAt: DateTime.parse(data['payment_date']),
            metadata: data['metadata'],
          );
        } else if (responseData['code'] == '600') {
          // Transaction échouée mais API valide - retourner les données quand même
          print(
            '⚠️ Transaction échouée mais données disponibles: ${responseData['message']}',
          );
          final data = responseData['data'];
          return CinetPayTransaction(
            transactionId: transactionId,
            paymentUrl: '',
            status: data['status'], // REFUSED, CANCELLED, etc.
            amount: _parseAmount(data['amount']),
            currency: data['currency'],
            createdAt: DateTime.parse(data['payment_date']),
            metadata: data['metadata'],
          );
        } else {
          throw Exception(responseData['message'] ?? 'Transaction non trouvée');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la vérification du statut: $e');
    }
  }

  // Effectuer un remboursement
  Future<bool> refundTransaction({
    required String transactionId,
    required double amount,
    String? reason,
  }) async {
    try {
      final requestData = {
        'apikey': CinetPayConfig.apiKey,
        'site_id': CinetPayConfig.siteId,
        'transaction_id': transactionId,
        'amount': amount.toInt(),
        'reason': reason ?? 'Remboursement demandé par l\'utilisateur',
      };

      final response = await http.post(
        Uri.parse('${CinetPayConfig.baseUrl}/transaction/refund'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['code'] == '00';
      }

      return false;
    } catch (e) {
      print('Erreur lors du remboursement: $e');
      return false;
    }
  }

  // Convertir une devise
  Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    // Utiliser les taux de change statiques de CinetPayConfig
    if (fromCurrency == 'XOF' && toCurrency == 'EUR') {
      return amount * CinetPayConfig.xofToEurRate;
    } else if (fromCurrency == 'EUR' && toCurrency == 'XOF') {
      return amount * CinetPayConfig.eurToXofRate;
    }
    // Si même devise ou non supportée, retourner le montant original
    return amount;
  }

  // Récupérer les méthodes de paiement disponibles
  Future<List<CinetPayPaymentMethod>> getPaymentMethods() async {
    try {
      // Faire un appel API pour obtenir les méthodes dynamiquement
      final response = await http.post(
        Uri.parse('${CinetPayConfig.baseUrl}/payment-methods'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'apikey': CinetPayConfig.apiKey,
          'site_id': CinetPayConfig.siteId,
          'country': CinetPayConfig.defaultCountry,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['code'] == '201') {
          final methods = responseData['data'] as List;
          return methods
              .map(
                (method) => CinetPayPaymentMethod(
                  code: method['code'],
                  name: method['name'],
                  description: method['description'] ?? method['name'],
                  isAvailable: method['status'] == 'available',
                ),
              )
              .toList();
        }
      }

      // En cas d'erreur API, retourner la liste statique
      return CinetPayPaymentMethod.getAvailableMethods();
    } catch (e) {
      // En cas d'erreur, retourner la liste statique par défaut
      return CinetPayPaymentMethod.getAvailableMethods();
    }
  }

  // Traitement d'un webhook CinetPay
  Future<bool> processWebhook(Map<String, dynamic> webhookData) async {
    try {
      // Vérifier la signature du webhook
      if (!_verifyWebhookSignature(webhookData)) {
        throw Exception('Signature webhook invalide');
      }

      final status = webhookData['cpm_result'];

      // Traiter selon le statut
      switch (status) {
        case '00':
          // Paiement réussi
          await _handleSuccessfulPayment(webhookData);
          break;
        case '01':
          // Paiement échoué
          await _handleFailedPayment(webhookData);
          break;
        default:
          // Statut inconnu
          break;
      }

      return true;
    } catch (e) {
      print('Erreur lors du traitement du webhook: $e');
      return false;
    }
  }

  // Vérifier la signature du webhook
  bool _verifyWebhookSignature(Map<String, dynamic> webhookData) {
    try {
      final signature = webhookData['signature'] as String?;
      if (signature == null) return false;

      // Reconstruire la signature
      final dataToSign =
          '${webhookData['cpm_trans_id']}'
          '${webhookData['cpm_amount']}'
          '${webhookData['cpm_currency']}'
          '${webhookData['cpm_result']}'
          '${CinetPayConfig.secretKey}';

      // Calculer le hash SHA256
      final bytes = utf8.encode(dataToSign);
      final digest = sha256.convert(bytes);
      final calculatedSignature = digest.toString();

      return signature.toLowerCase() == calculatedSignature.toLowerCase();
    } catch (e) {
      print('Erreur vérification signature: $e');
      return false;
    }
  }

  // Traiter un paiement réussi
  Future<void> _handleSuccessfulPayment(
    Map<String, dynamic> webhookData,
  ) async {
    try {
      final transactionId = webhookData['cpm_trans_id'] as String;
      final amount = _parseAmount(webhookData['cpm_amount']);
      final currency = webhookData['cpm_currency'] as String;
      final userId = webhookData['cpm_custom'] as String; // Notre user ID

      // Mettre à jour le solde utilisateur
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDoc);
        if (!userSnapshot.exists) throw Exception('Utilisateur non trouvé');

        final currentBalance = (userSnapshot.data()?['balance'] ?? 0.0)
            .toDouble();
        final newBalance = currentBalance + amount;

        transaction.update(userDoc, {'balance': newBalance});

        // Créer l'historique de transaction
        transaction.set(
          FirebaseFirestore.instance.collection('transactions').doc(),
          {
            'userId': userId,
            'type': 'recharge',
            'amount': amount,
            'currency': currency,
            'status': 'completed',
            'cinetpayTransactionId': transactionId,
            'timestamp': FieldValue.serverTimestamp(),
            'metadata': {'provider': 'cinetpay', 'webhook_data': webhookData},
          },
        );
      });

      print('Paiement traité avec succès: $transactionId');
    } catch (e) {
      print('Erreur traitement paiement réussi: $e');
      rethrow;
    }
  }

  // Traiter un paiement échoué
  Future<void> _handleFailedPayment(Map<String, dynamic> webhookData) async {
    try {
      final transactionId = webhookData['cpm_trans_id'] as String;
      final amount = (webhookData['cpm_amount'] as num).toDouble();
      final currency = webhookData['cpm_currency'] as String;
      final userId = webhookData['cpm_custom'] as String;
      final errorMessage = webhookData['cpm_message'] as String?;

      // Créer l'historique de transaction échouée
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': userId,
        'type': 'recharge_failed',
        'amount': amount,
        'currency': currency,
        'status': 'failed',
        'cinetpayTransactionId': transactionId,
        'errorMessage': errorMessage ?? 'Paiement échoué',
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': {'provider': 'cinetpay', 'webhook_data': webhookData},
      });

      // Envoyer une notification d'échec (optionnel)
      print('Paiement échoué: $transactionId - $errorMessage');
    } catch (e) {
      print('Erreur traitement paiement échoué: $e');
    }
  }

  /// Parse le montant qui peut être une chaîne ou un nombre
  static double _parseAmount(dynamic amount) {
    if (amount is num) {
      return amount.toDouble();
    } else if (amount is String) {
      return double.parse(amount);
    } else {
      throw Exception('Format de montant invalide: $amount');
    }
  }
}
