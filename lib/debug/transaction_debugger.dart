import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/services/transfer_service.dart';
import '../../../data/services/test_data_service.dart';

/// Script de debugging pour vérifier les données de transactions
class TransactionDebugger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final TransferService _transferService = TransferService();

  /// Teste la création et récupération des données de test
  static Future<void> debugTransactionFlow() async {
    print('🔍 === DEBUG TRANSACTION FLOW ===');

    try {
      // 1. Nettoyer les anciennes données
      print('1️⃣ Nettoyage des anciennes données...');
      await TestDataService.clearAllTestData();
      print('✅ Données nettoyées');

      // 2. Attendre un peu pour que le nettoyage soit effectif
      await Future.delayed(const Duration(seconds: 2));

      // 3. Créer des nouvelles données de test
      print('2️⃣ Création de nouvelles données de test...');
      await TestDataService.createTestTransfers();
      print('✅ Données de test créées');

      // 4. Attendre que Firestore synchronise
      await Future.delayed(const Duration(seconds: 3));

      // 5. Vérifier dans la collection 'transactions'
      print('3️⃣ Vérification de la collection "transactions"...');
      final transactionSnapshot = await _firestore
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      print(
        '📊 Nombre de documents dans "transactions": ${transactionSnapshot.docs.length}',
      );

      for (var doc in transactionSnapshot.docs) {
        final data = doc.data();
        print('  - ID: ${doc.id}');
        print('    Sender: ${data['senderId']}');
        print('    Recipient: ${data['recipientId']}');
        print('    Amount: ${data['amount']}');
        print('    Status: ${data['status']}');
        print('    Date: ${data['createdAt']}');
        print('    ---');
      }

      // 6. Tester les streams du TransferService
      print('4️⃣ Test des streams TransferService...');

      // Simuler un utilisateur avec des données de test
      final testUserId = 'test_user_1'; // Utilisé dans TestDataService

      print('   Testing getUserTransfers pour $testUserId...');
      final sentTransfers = await _transferService
          .getUserTransfers(testUserId)
          .first;
      print('   📤 Transferts envoyés: ${sentTransfers.length}');

      print('   Testing getReceivedTransfers pour $testUserId...');
      final receivedTransfers = await _transferService
          .getReceivedTransfers(testUserId)
          .first;
      print('   📥 Transferts reçus: ${receivedTransfers.length}');

      // 7. Tester la combinaison des streams comme dans le provider
      print('5️⃣ Test de la combinaison des streams...');
      final allTransfers = [...sentTransfers, ...receivedTransfers];
      allTransfers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('   📋 Total combiné: ${allTransfers.length}');

      final recentTransfers = allTransfers.take(10).toList();
      print('   🕒 Récents (10 max): ${recentTransfers.length}');

      // 8. Afficher le détail des transferts récents
      print('6️⃣ Détail des transferts récents:');
      for (var transfer in recentTransfers) {
        print('  - ${transfer.amount} ${transfer.currency} ${transfer.status}');
        print('    De: ${transfer.senderId} -> À: ${transfer.recipientId}');
        print('    Date: ${transfer.createdAt.toDate()}');
        print('    ---');
      }
    } catch (e, stackTrace) {
      print('❌ Erreur pendant le debug: $e');
      print('Stack trace: $stackTrace');
    }

    print('🔍 === FIN DEBUG ===');
  }

  /// Teste uniquement la lecture des données existantes
  static Future<void> quickDataCheck() async {
    print('🔍 === QUICK DATA CHECK ===');

    try {
      final snapshot = await _firestore
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      print('📊 Transactions trouvées: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('  ${data['amount']} ${data['currency']} - ${data['status']}');
        print('  SenderId: ${data['senderId']}');
        print('  RecipientId: ${data['recipientId'] ?? 'null'}');
        print('  Date: ${data['createdAt']}');
        print('  ---');
      }

      // Tester le transferService directement
      print('🔧 Test TransferService...');
      final userId = 'test_user_example'; // ID fictif pour test
      final stream = _transferService.getUserTransfers(userId);
      final transfers = await stream.first;
      print('📋 Transferts depuis service: ${transfers.length}');
    } catch (e) {
      print('❌ Erreur: $e');
    }

    print('🔍 === FIN CHECK ===');
  }
}
