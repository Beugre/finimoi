class BillParticipant {
  final String userId;
  final String name;
  double amountOwed;

  BillParticipant({
    required this.userId,
    required this.name,
    this.amountOwed = 0.0,
  });
}

class BillItem {
  String description;
  double price;
  List<String> assignedParticipantIds;

  BillItem({
    required this.description,
    required this.price,
    this.assignedParticipantIds = const [],
  });
}

class SplitBill {
  final String id;
  final String hostId;
  final String imageUrl;
  final List<BillItem> items;
  final List<BillParticipant> participants;
  final DateTime createdAt;

  SplitBill({
    required this.id,
    required this.hostId,
    required this.imageUrl,
    required this.items,
    required this.participants,
    required this.createdAt,
  });
}
