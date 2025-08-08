import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/real_card_service.dart';
import '../../domain/entities/card_model.dart';

// Provider pour les cartes de l'utilisateur
final userCardsProvider = StreamProvider<List<CardModel>>((ref) {
  return RealCardService.getUserCards();
});

// Provider pour les transactions d'une carte
final cardTransactionsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, cardId) {
      return RealCardService.getCardTransactions(cardId);
    });

// Provider pour créer une carte
final createCardProvider = FutureProvider.family<String?, Map<String, dynamic>>(
  (ref, cardData) async {
    return RealCardService.createCard(
      cardType: cardData['cardType'],
      cardName: cardData['cardName'],
      isVirtual: cardData['isVirtual'],
      limit: cardData['limit'],
    );
  },
);

// Provider pour changer le statut d'une carte
final toggleCardStatusProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
      return RealCardService.toggleCardStatus(data['cardId'], data['isActive']);
    });
