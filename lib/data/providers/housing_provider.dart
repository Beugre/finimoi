import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/data/services/housing_service.dart';
import 'package:finimoi/domain/entities/housing_models.dart';

final housingServiceProvider = Provider<HousingService>((ref) {
  return HousingService();
});

final myTenancyProvider = StreamProvider<Tenancy?>((ref) {
  return ref.watch(housingServiceProvider).getMyTenancy();
});

final myPropertyDetailsProvider = FutureProvider<Property?>((ref) {
  final tenancy = ref.watch(myTenancyProvider).value;
  if (tenancy == null) return null;
  return ref.watch(housingServiceProvider).getPropertyDetails(tenancy.propertyId);
});
