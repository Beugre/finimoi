import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finimoi/core/utils/auth_utils.dart';
import 'package:finimoi/domain/entities/lottery_models.dart';

class LotteryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<LotteryDraw>> getActiveLotteryDraws() {
    return _firestore
        .collection('lottery_draws')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LotteryDraw.fromFirestore(doc))
            .toList());
  }

  Future<void> buyTicket(String drawId) async {
    final userId = AuthUtils.getCurrentUser()?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté.');

    final drawRef = _firestore.collection('lottery_draws').doc(drawId);

    await _firestore.runTransaction((transaction) async {
      final drawDoc = await transaction.get(drawRef);
      if (!drawDoc.exists) throw Exception('Tirage non trouvé.');
      final draw = LotteryDraw.fromFirestore(drawDoc);

      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await transaction.get(userRef);
      final balance = (userDoc.data()!['balance'] ?? 0.0).toDouble();

      if (balance < draw.ticketPrice) throw Exception('Solde insuffisant.');

      // 1. Deduct ticket price from user
      transaction.update(userRef, {'balance': FieldValue.increment(-draw.ticketPrice)});
      // 2. Add price to prize pool
      transaction.update(drawRef, {'prizePool': FieldValue.increment(draw.ticketPrice)});
      // 3. Create ticket
      final ticketRef = _firestore.collection('lottery_tickets').doc();
      transaction.set(ticketRef, {'drawId': drawId, 'userId': userId});
    });
  }

  Future<void> runDraw(String drawId) async {
    final drawRef = _firestore.collection('lottery_draws').doc(drawId);

    // 1. Close the draw
    await drawRef.update({'status': 'closed'});

    // 2. Get all tickets
    final ticketsSnapshot = await _firestore
        .collection('lottery_tickets')
        .where('drawId', isEqualTo: drawId)
        .get();

    if (ticketsSnapshot.docs.isEmpty) {
        await drawRef.update({'status': 'finished', 'winningTicketId': 'none'});
        return; // No participants
    }

    // 3. Select a winner
    final winningTicketDoc = ticketsSnapshot.docs[Random().nextInt(ticketsSnapshot.docs.length)];
    final winningUserId = winningTicketDoc['userId'];

    // 4. Award prize
    final draw = LotteryDraw.fromFirestore(await drawRef.get());
    final winnerRef = _firestore.collection('users').doc(winningUserId);
    await winnerRef.update({'balance': FieldValue.increment(draw.prizePool)});

    // 5. Update draw status
    await drawRef.update({'status': 'finished', 'winningTicketId': winningTicketDoc.id});

    // 6. Notify winner
    // await NotificationService().createNotification(...)
  }
}
