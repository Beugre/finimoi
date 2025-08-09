import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/card_model.dart';
import '../../core/utils/auth_utils.dart';

class RealCardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtenir les cartes de l'utilisateur
  static Stream<List<CardModel>> getUserCards() {
    final currentUser = AuthUtils.getCurrentUser();
    if (currentUser == null) {
      return Stream.value([]);
    }

    final ownedCardsStream = _firestore
        .collection('cards')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots();

    final sharedCardsStream = _firestore
        .collection('cards')
        .where('sharedWith', arrayContains: currentUser.uid)
        .snapshots();

    // Combine the two streams
    return ownedCardsStream.asyncMap((ownedSnapshot) async {
      final sharedSnapshot = await sharedCardsStream.first;
      final allDocs = [...ownedSnapshot.docs, ...sharedSnapshot.docs];
      final uniqueDocs = { for (var doc in allDocs) doc.id : doc }.values.toList();

      final cards = uniqueDocs.map((doc) {
        try {
          return CardModel.fromFirestore(doc);
        } catch (e) {
          print('Erreur lors du parsing de la carte ${doc.id}: $e');
          return null;
        }
      }).whereType<CardModel>().toList();

      cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return cards;
    });
  }

  // Créer une nouvelle carte
  static Future<String?> createCard({
    required String cardType,
    required String cardName,
    required bool isVirtual,
    double? limit,
  }) async {
    try {
      final currentUser = AuthUtils.getCurrentUser();
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final userData = await AuthUtils.getCurrentUserData();
      if (userData == null) throw Exception('Données utilisateur non trouvées');

      final cardData = {
        'userId': currentUser.uid,
        'userName': userData['firstName'] + ' ' + userData['lastName'],
        'cardType': cardType,
        'cardName': cardName,
        'cardNumber': _generateCardNumber(),
        'expiryDate': _generateExpiryDate(),
        'cvv': _generateCVV(),
        'isVirtual': isVirtual,
        'isActive': true,
        'balance': 0.0,
        'limit': limit ?? (isVirtual ? 100000.0 : 500000.0),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('cards').add(cardData);
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la carte: $e');
      return null;
    }
  }

  // Bloquer/débloquer une carte
  static Future<bool> toggleCardStatus(String cardId, bool isActive) async {
    try {
      await _firestore.collection('cards').doc(cardId).update({
        'isActive': isActive,
        'status': isActive ? 'active' : 'blocked',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors du changement de statut de la carte: $e');
      return false;
    }
  }

  // Obtenir les transactions d'une carte
  static Stream<List<Map<String, dynamic>>> getCardTransactions(String cardId) {
    return _firestore
        .collection('transactions')
        .where('cardId', isEqualTo: cardId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
  }

  // Partager une carte
  static Future<void> shareCard(String cardId, String friendId) async {
    try {
      await _firestore.collection('cards').doc(cardId).update({
        'sharedWith': FieldValue.arrayUnion([friendId]),
      });
    } catch (e) {
      throw Exception('Erreur lors du partage de la carte: $e');
    }
  }

  // Ne plus partager une carte
  static Future<void> unshareCard(String cardId, String friendId) async {
    try {
      await _firestore.collection('cards').doc(cardId).update({
        'sharedWith': FieldValue.arrayRemove([friendId]),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation du partage: $e');
    }
  }

  // Fonctions privées pour générer les données de carte
  static String _generateCardNumber() {
    // Générer un numéro de carte virtuel commençant par 4000 (visa test)
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return '4000 ${random.substring(0, 4)} ${random.substring(4, 8)} ${random.substring(8, 12)}';
  }

  static String _generateExpiryDate() {
    final now = DateTime.now();
    final expiry = DateTime(now.year + 3, now.month);
    return '${expiry.month.toString().padLeft(2, '0')}/${expiry.year.toString().substring(2)}';
  }

  static String _generateCVV() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    return random.toString().padLeft(3, '0');
  }
}
