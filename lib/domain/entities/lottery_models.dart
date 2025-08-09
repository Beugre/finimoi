import 'package:cloud_firestore/cloud_firestore.dart';

enum LotteryStatus { open, closed, finished }

class LotteryDraw {
  final String id;
  final String name;
  final double ticketPrice;
  final double prizePool;
  final DateTime drawDate;
  final LotteryStatus status;
  final String? winningTicketId;

  LotteryDraw({
    required this.id,
    required this.name,
    required this.ticketPrice,
    required this.prizePool,
    required this.drawDate,
    required this.status,
    this.winningTicketId,
  });

  factory LotteryDraw.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LotteryDraw(
      id: doc.id,
      name: data['name'] ?? '',
      ticketPrice: (data['ticketPrice'] ?? 0.0).toDouble(),
      prizePool: (data['prizePool'] ?? 0.0).toDouble(),
      drawDate: (data['drawDate'] as Timestamp).toDate(),
      status: LotteryStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => LotteryStatus.open),
      winningTicketId: data['winningTicketId'],
    );
  }
}

class LotteryTicket {
  final String id;
  final String drawId;
  final String userId;

  LotteryTicket({required this.id, required this.drawId, required this.userId});
}
