import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/data/services/gift_card_service.dart';
import 'package:finimoi/domain/entities/partner_store_model.dart';
import 'package:finimoi/domain/entities/gift_card_model.dart';

final giftCardServiceProvider = Provider<GiftCardService>((ref) {
  return GiftCardService();
});

final partnerStoresProvider = StreamProvider<List<PartnerStore>>((ref) {
  return ref.watch(giftCardServiceProvider).getPartnerStores();
});

final myGiftCardsProvider = StreamProvider<List<GiftCard>>((ref) {
  return ref.watch(giftCardServiceProvider).getMyGiftCards();
});
