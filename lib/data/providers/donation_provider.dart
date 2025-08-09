import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/data/services/donation_service.dart';
import 'package:finimoi/domain/entities/partner_orphanage_model.dart';

final donationServiceProvider = Provider<DonationService>((ref) {
  return DonationService();
});

final partnerOrphanagesProvider = StreamProvider<List<PartnerOrphanage>>((ref) {
  return ref.watch(donationServiceProvider).getPartnerOrphanages();
});
