import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/data/services/lottery_service.dart';
import 'package:finimoi/domain/entities/lottery_models.dart';

final lotteryServiceProvider = Provider<LotteryService>((ref) {
  return LotteryService();
});

final activeLotteryDrawsProvider = StreamProvider<List<LotteryDraw>>((ref) {
  return ref.watch(lotteryServiceProvider).getActiveLotteryDraws();
});
