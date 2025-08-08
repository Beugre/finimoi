import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service pour créer des utilisateurs de test avec des données réelles
class TestDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer des utilisateurs de test avec des soldes
  static Future<void> createTestUsers() async {
    final testUsers = [
      {
        'email': 'jean.dupont@test.com',
        'firstName': 'Jean',
        'lastName': 'Dupont',
        'balance': 50000.0,
        'finimoimtag': 'jeandupont',
      },
      {
        'email': 'marie.martin@test.com',
        'firstName': 'Marie',
        'lastName': 'Martin',
        'balance': 75000.0,
        'finimoimtag': 'mariemartin',
      },
      {
        'email': 'paul.bernard@test.com',
        'firstName': 'Paul',
        'lastName': 'Bernard',
        'balance': 30000.0,
        'finimoimtag': 'paulbernard',
      },
      {
        'email': 'sophie.michel@test.com',
        'firstName': 'Sophie',
        'lastName': 'Michel',
        'balance': 60000.0,
        'finimoimtag': 'sophiemichel',
      },
    ];

    for (final userData in testUsers) {
      // Vérifier si l'utilisateur existe déjà
      final existing = await _firestore
          .collection('users')
          .where('email', isEqualTo: userData['email'])
          .get();

      if (existing.docs.isEmpty) {
        // Créer l'utilisateur test
        final docRef = _firestore.collection('users').doc();
        await docRef.set({
          ...userData,
          'fullName': '${userData['firstName']} ${userData['lastName']}',
          'isEmailVerified': true,
          'isPhoneVerified': false,
          'createdAt': Timestamp.now(),
          'lastLoginAt': Timestamp.now(),
          'profilePicture': null,
          'phoneNumber': null,
          'dateOfBirth': null,
          'address': null,
        });
        print('✅ Utilisateur test créé: ${userData['email']}');
      } else {
        print('ℹ️ Utilisateur test existe déjà: ${userData['email']}');
      }
    }
  }

  /// Ajouter du solde à l'utilisateur connecté pour les tests
  static Future<void> addTestBalance({double amount = 100000.0}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    await _firestore.collection('users').doc(currentUser.uid).update({
      'balance': FieldValue.increment(amount),
    });

    print('✅ Solde de test ajouté: ${amount.toStringAsFixed(0)} FCFA');
  }

  /// Créer des tontines de test
  static Future<void> createTestTontines() async {
    final testTontines = [
      {
        'title': 'Tontine Famille',
        'description': 'Épargne familiale pour les fêtes',
        'targetAmount': 500000.0,
        'monthlyContribution': 25000.0,
        'duration': 20, // 20 mois
        'type': 'family',
        'isActive': true,
        'memberCount': 5,
        'currentRound': 3,
      },
      {
        'title': 'Tontine Entreprise',
        'description': 'Projet d\'investissement commun',
        'targetAmount': 1000000.0,
        'monthlyContribution': 50000.0,
        'duration': 20,
        'type': 'business',
        'isActive': true,
        'memberCount': 8,
        'currentRound': 1,
      },
      {
        'title': 'Tontine Étudiants',
        'description': 'Épargne pour les études',
        'targetAmount': 200000.0,
        'monthlyContribution': 10000.0,
        'duration': 20,
        'type': 'education',
        'isActive': true,
        'memberCount': 12,
        'currentRound': 7,
      },
    ];

    for (final tontineData in testTontines) {
      final docRef = _firestore.collection('tontines').doc();
      await docRef.set({
        ...tontineData,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'creatorId': FirebaseAuth.instance.currentUser?.uid ?? 'system',
        'members': [],
        'rounds': [],
        'nextDrawDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      });
      print('✅ Tontine test créée: ${tontineData['title']}');
    }
  }

  /// Créer des épargnes de test
  static Future<void> createTestSavings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final testSavings = [
      {
        'title': 'Vacances d\'été',
        'description': 'Épargne pour les vacances en famille',
        'targetAmount': 300000.0,
        'currentAmount': 120000.0,
        'targetDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 180)),
        ),
        'isActive': true,
        'autoSave': true,
        'autoSaveAmount': 15000.0,
      },
      {
        'title': 'Nouveau téléphone',
        'description': 'iPhone 15 Pro Max',
        'targetAmount': 800000.0,
        'currentAmount': 350000.0,
        'targetDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 120)),
        ),
        'isActive': true,
        'autoSave': false,
        'autoSaveAmount': 0.0,
      },
      {
        'title': 'Urgences',
        'description': 'Fonds d\'urgence',
        'targetAmount': 500000.0,
        'currentAmount': 75000.0,
        'targetDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 365)),
        ),
        'isActive': true,
        'autoSave': true,
        'autoSaveAmount': 25000.0,
      },
    ];

    for (final savingData in testSavings) {
      final docRef = _firestore.collection('savings').doc();
      await docRef.set({
        ...savingData,
        'userId': currentUser.uid,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      print('✅ Épargne test créée: ${savingData['title']}');
    }
  }

  /// Créer des crédits de test
  static Future<void> createTestCredits() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final testCredits = [
      {
        'amount': 150000.0,
        'purpose': 'Équipement professionnel',
        'duration': 12, // 12 mois
        'interestRate': 0.15, // 15%
        'status': 'approved',
        'monthlyPayment': 14000.0,
        'remainingAmount': 98000.0,
        'nextPaymentDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      },
      {
        'amount': 300000.0,
        'purpose': 'Rénovation maison',
        'duration': 24,
        'interestRate': 0.12,
        'status': 'pending',
        'monthlyPayment': 0.0,
        'remainingAmount': 300000.0,
        'nextPaymentDate': null,
      },
    ];

    for (final creditData in testCredits) {
      final docRef = _firestore.collection('credits').doc();
      await docRef.set({
        ...creditData,
        'userId': currentUser.uid,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'applicationDate': Timestamp.now(),
      });
      print('✅ Crédit test créé: ${creditData['purpose']}');
    }
  }

  /// Créer des messages de test
  static Future<void> createTestMessages() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Récupérer un utilisateur test pour les conversations
    final testUsers = await _firestore
        .collection('users')
        .where('email', isEqualTo: 'jean.dupont@test.com')
        .get();

    if (testUsers.docs.isEmpty) return;
    final testUserId = testUsers.docs.first.id;

    final conversationId = '${currentUser.uid}_$testUserId';

    final testMessages = [
      {
        'text': 'Salut ! Comment ça va ?',
        'senderId': testUserId,
        'timestamp': Timestamp.now(),
        'type': 'text',
      },
      {
        'text': 'Ça va bien merci ! Et toi ?',
        'senderId': currentUser.uid,
        'timestamp': Timestamp.now(),
        'type': 'text',
      },
      {
        'text': 'Parfait ! Au fait, peux-tu me renvoyer les 5000 FCFA ?',
        'senderId': testUserId,
        'timestamp': Timestamp.now(),
        'type': 'text',
      },
      {
        'text': 'Bien sûr, je t\'envoie ça maintenant',
        'senderId': currentUser.uid,
        'timestamp': Timestamp.now(),
        'type': 'text',
      },
    ];

    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);

    await conversationRef.set({
      'participants': [currentUser.uid, testUserId],
      'lastMessage': testMessages.last['text'],
      'lastMessageTime': testMessages.last['timestamp'],
      'createdAt': Timestamp.now(),
    });

    for (final messageData in testMessages) {
      await conversationRef.collection('messages').add(messageData);
    }

    print('✅ Messages test créés');
  }

  /// Créer des transferts de test
  static Future<void> createTestTransfers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final testTransfers = [
      {
        'senderId': currentUser.uid,
        'recipientId': 'user_test_1',
        'recipientName': 'Amadou Traoré',
        'recipientPhone': '+225 07 XX XX XX 89',
        'amount': 25000.0,
        'fees': 500.0,
        'totalAmount': 25500.0,
        'currency': 'XOF',
        'type': 0, // TransferType.internal
        'status': 2, // TransferStatus.completed
        'reference': 'TRF_${DateTime.now().millisecondsSinceEpoch}_001',
        'description': 'Transfert pour achat',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
        'completedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        ),
      },
      {
        'senderId': currentUser.uid,
        'recipientPhone': '+225 05 XX XX XX 45',
        'recipientName': 'Fatou Koné',
        'amount': 15000.0,
        'fees': 300.0,
        'totalAmount': 15300.0,
        'currency': 'XOF',
        'type': 1, // TransferType.mobileMoney
        'provider': 'Orange Money',
        'status': 2, // TransferStatus.completed
        'reference': 'TRF_${DateTime.now().millisecondsSinceEpoch}_002',
        'description': 'Remboursement',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 5)),
        ),
        'completedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 4, minutes: 45)),
        ),
      },
      {
        'senderId': currentUser.uid,
        'recipientPhone': '+225 01 XX XX XX 23',
        'recipientName': 'Kofi Asante',
        'amount': 50000.0,
        'fees': 1000.0,
        'totalAmount': 51000.0,
        'currency': 'XOF',
        'type': 2, // TransferType.bankTransfer
        'recipientBank': 'Ecobank',
        'recipientAccountNumber': '1234567890',
        'status': 0, // TransferStatus.pending
        'reference': 'TRF_${DateTime.now().millisecondsSinceEpoch}_003',
        'description': 'Virement bancaire',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      },
      {
        'senderId': currentUser.uid,
        'recipientPhone': '+225 09 XX XX XX 67',
        'recipientName': 'Aïsha Diallo',
        'amount': 8000.0,
        'fees': 200.0,
        'totalAmount': 8200.0,
        'currency': 'XOF',
        'type': 1, // TransferType.mobileMoney
        'provider': 'MTN Money',
        'status': 2, // TransferStatus.completed
        'reference': 'TRF_${DateTime.now().millisecondsSinceEpoch}_004',
        'description': 'Paiement taxi',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1)),
        ),
        'completedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 45)),
        ),
      },
    ];

    for (final transferData in testTransfers) {
      await _firestore.collection('transactions').add(transferData);
      print('✅ Transfert test créé: ${transferData['recipientName']}');
    }
  }

  /// Créer des contacts de test
  static Future<void> createTestContacts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final testContacts = [
      {
        'name': 'Amadou Traoré',
        'phone': '+225 07 XX XX XX 89',
        'avatar': 'https://i.pravatar.cc/150?img=1',
        'lastTransferDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
      },
      {
        'name': 'Fatou Koné',
        'phone': '+225 05 XX XX XX 45',
        'avatar': 'https://i.pravatar.cc/150?img=2',
        'lastTransferDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 5)),
        ),
      },
      {
        'name': 'Kofi Asante',
        'phone': '+225 01 XX XX XX 23',
        'avatar': 'https://i.pravatar.cc/150?img=3',
        'lastTransferDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      },
      {
        'name': 'Aïsha Diallo',
        'phone': '+225 09 XX XX XX 67',
        'avatar': 'https://i.pravatar.cc/150?img=4',
        'lastTransferDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1)),
        ),
      },
      {
        'name': 'Ibrahim Sanogo',
        'phone': '+225 03 XX XX XX 12',
        'avatar': 'https://i.pravatar.cc/150?img=5',
        'lastTransferDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 2)),
        ),
      },
    ];

    for (final contactData in testContacts) {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('contacts')
          .add(contactData);
      print('✅ Contact test créé: ${contactData['name']}');
    }
  }

  /// Initialiser toutes les données de test
  /// Initialiser toutes les données de test
  static Future<void> initializeAllTestData() async {
    try {
      print('🚀 Initialisation des données de test...');

      await createTestUsers();
      await addTestBalance();
      await createTestTontines();
      await createTestSavings();
      await createTestCredits();
      await createTestMessages();
      await createTestTransfers();
      await createTestContacts();

      print('✅ Toutes les données de test ont été créées avec succès !');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des données de test: $e');
    }
  }

  /// Effacer toutes les données de test
  static Future<void> clearAllTestData() async {
    try {
      print('🗑️ Effacement des données de test...');

      // Récupérer tous les utilisateurs test
      final testUsersQuery = await _firestore
          .collection('users')
          .where('email', arrayContains: 'test.com')
          .get();

      final testUserIds = testUsersQuery.docs.map((doc) => doc.id).toList();

      // Effacer en batch pour optimiser
      final batch = _firestore.batch();

      // Supprimer tous les transferts liés aux utilisateurs test
      final transfersQuery = await _firestore
          .collection('transactions')
          .where(
            'senderId',
            whereIn: testUserIds.isNotEmpty ? testUserIds : ['non-existent'],
          )
          .get();

      for (final doc in transfersQuery.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer toutes les tontines de test
      final tontinesQuery = await _firestore
          .collection('tontines')
          .where('title', arrayContains: 'Test')
          .get();

      for (final doc in tontinesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer toutes les épargnes de test
      final savingsQuery = await _firestore
          .collection('savings')
          .where('title', arrayContains: 'Test')
          .get();

      for (final doc in savingsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer tous les crédits de test
      final creditsQuery = await _firestore
          .collection('credits')
          .where(
            'userId',
            whereIn: testUserIds.isNotEmpty ? testUserIds : ['non-existent'],
          )
          .get();

      for (final doc in creditsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer tous les messages de test
      final messagesQuery = await _firestore
          .collection('conversations')
          .where(
            'participants',
            arrayContainsAny: testUserIds.isNotEmpty
                ? testUserIds
                : ['non-existent'],
          )
          .get();

      for (final doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer tous les contacts de test
      final contactsQuery = await _firestore
          .collection('contacts')
          .where('name', arrayContains: 'Test')
          .get();

      for (final doc in contactsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer les utilisateurs test (en dernier)
      for (final doc in testUsersQuery.docs) {
        batch.delete(doc.reference);
      }

      // Exécuter le batch
      await batch.commit();

      print('✅ Toutes les données de test ont été effacées avec succès !');
    } catch (e) {
      print('❌ Erreur lors de l\'effacement des données de test: $e');
      rethrow;
    }
  }
}
