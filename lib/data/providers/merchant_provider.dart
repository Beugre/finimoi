import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/merchant_service.dart';

final merchantServiceProvider = Provider<MerchantService>((ref) {
  return MerchantService();
});

import 'package:finimoi/domain/entities/merchant_model.dart';
import 'auth_provider.dart';

final isMerchantProvider = StreamProvider<bool>((ref) {
  final merchantService = ref.watch(merchantServiceProvider);
  return merchantService.isCurrentUserMerchant();
});

final merchantProfileProvider =
    FutureProvider.family<MerchantModel?, String>((ref, merchantId) async {
  final merchantService = ref.read(merchantServiceProvider);
  return await merchantService.getMerchantProfile(merchantId);
});
