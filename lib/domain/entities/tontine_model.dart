import 'package:cloud_firestore/cloud_firestore.dart';

enum TontineStatus { draft, active, completed, cancelled }

enum TontineFrequency { weekly, biweekly, monthly, quarterly }

enum TontineType { classic, rotating, investment, emergency }

class TontineMember {
  final String userId;
  final String name;
  final DateTime joinedAt;
  final bool isActive;
  final int position;
  final bool autoPayEnabled;

  TontineMember({
    required this.userId,
    required this.name,
    required this.joinedAt,
    required this.isActive,
    required this.position,
    this.autoPayEnabled = false,
  });

  factory TontineMember.fromMap(Map<String, dynamic> data) {
    return TontineMember(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      joinedAt: data['joinedAt'] != null
          ? (data['joinedAt'] is Timestamp
                ? (data['joinedAt'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      position: data['position'] ?? 0,
      autoPayEnabled: data['autoPayEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
      'position': position,
      'autoPayEnabled': autoPayEnabled,
    };
  }
}

class TontineModel {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String creatorName;
  final double contributionAmount;
  final TontineFrequency frequency;
  final TontineType type;
  final TontineStatus status;
  final int maxMembers;
  final int currentMembers;
  final int currentCycle;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> memberIds;
  final List<TontineMember> members;
  final List<TontineCycle> cycles;
  final Map<String, dynamic> rules;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final bool isPrivate;
  final String? inviteCode;

  TontineModel({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.contributionAmount,
    required this.frequency,
    required this.type,
    required this.status,
    required this.maxMembers,
    required this.currentMembers,
    required this.currentCycle,
    required this.startDate,
    this.endDate,
    required this.memberIds,
    required this.members,
    required this.cycles,
    required this.rules,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    required this.isPrivate,
    this.inviteCode,
  });

  factory TontineModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TontineModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      contributionAmount: (data['contributionAmount'] ?? 0.0).toDouble(),
      frequency: TontineFrequency.values.firstWhere(
        (e) => e.name == data['frequency'],
        orElse: () => TontineFrequency.monthly,
      ),
      type: TontineType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TontineType.classic,
      ),
      status: TontineStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TontineStatus.draft,
      ),
      maxMembers: data['maxMembers'] ?? 0,
      currentMembers: data['currentMembers'] ?? 0,
      currentCycle: data['currentCycle'] ?? 1,
      startDate: data['startDate'] != null
          ? (data['startDate'] is Timestamp
                ? (data['startDate'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? (data['endDate'] is Timestamp
                ? (data['endDate'] as Timestamp).toDate()
                : null)
          : null,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      members:
          (data['members'] as List<dynamic>?)
              ?.map((member) => TontineMember.fromMap(member))
              .toList() ??
          [],
      cycles:
          (data['cycles'] as List<dynamic>?)
              ?.map((cycle) => TontineCycle.fromMap(cycle))
              .toList() ??
          [],
      rules: Map<String, dynamic>.from(data['rules'] ?? {}),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      imageUrl: data['imageUrl'],
      isPrivate: data['isPrivate'] ?? false,
      inviteCode: data['inviteCode'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'contributionAmount': contributionAmount,
      'frequency': frequency.name,
      'type': type.name,
      'status': status.name,
      'maxMembers': maxMembers,
      'currentMembers': currentMembers,
      'currentCycle': currentCycle,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'memberIds': memberIds,
      'members': members.map((member) => member.toMap()).toList(),
      'cycles': cycles.map((cycle) => cycle.toMap()).toList(),
      'rules': rules,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'imageUrl': imageUrl,
      'isPrivate': isPrivate,
      'inviteCode': inviteCode,
    };
  }

  double get totalPool => contributionAmount * maxMembers;

  String get frequencyText {
    switch (frequency) {
      case TontineFrequency.weekly:
        return 'Hebdomadaire';
      case TontineFrequency.biweekly:
        return 'Bimensuel';
      case TontineFrequency.monthly:
        return 'Mensuel';
      case TontineFrequency.quarterly:
        return 'Trimestriel';
    }
  }

  String get typeText {
    switch (type) {
      case TontineType.classic:
        return 'Classique';
      case TontineType.rotating:
        return 'Rotative';
      case TontineType.investment:
        return 'Investissement';
      case TontineType.emergency:
        return 'Urgence';
    }
  }

  String get statusText {
    switch (status) {
      case TontineStatus.draft:
        return 'Brouillon';
      case TontineStatus.active:
        return 'Active';
      case TontineStatus.completed:
        return 'Terminée';
      case TontineStatus.cancelled:
        return 'Annulée';
    }
  }

  DateTime get nextDueDate {
    if (status != TontineStatus.active) {
      return DateTime.now(); // Or handle appropriately
    }
    switch (frequency) {
      case TontineFrequency.weekly:
        return startDate.add(Duration(days: 7 * currentCycle));
      case TontineFrequency.biweekly:
        return startDate.add(Duration(days: 14 * currentCycle));
      case TontineFrequency.monthly:
        return DateTime(startDate.year, startDate.month + currentCycle, startDate.day);
      case TontineFrequency.quarterly:
        return DateTime(startDate.year, startDate.month + (3 * currentCycle), startDate.day);
    }
  }
}

class TontineCycle {
  final int cycleNumber;
  final String winnerId;
  final String winnerName;
  final String beneficiaryName;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime payoutDate;
  final double amount;
  final double totalAmount;
  final List<TontineContribution> contributions;
  final bool isCompleted;

  TontineCycle({
    required this.cycleNumber,
    required this.winnerId,
    required this.winnerName,
    required this.beneficiaryName,
    required this.startDate,
    this.endDate,
    required this.payoutDate,
    required this.amount,
    required this.totalAmount,
    required this.contributions,
    required this.isCompleted,
  });

  factory TontineCycle.fromMap(Map<String, dynamic> data) {
    return TontineCycle(
      cycleNumber: data['cycleNumber'] ?? 0,
      winnerId: data['winnerId'] ?? '',
      winnerName: data['winnerName'] ?? '',
      beneficiaryName: data['beneficiaryName'] ?? data['winnerName'] ?? '',
      startDate: data['startDate'] != null
          ? (data['startDate'] is Timestamp
                ? (data['startDate'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? (data['endDate'] is Timestamp
                ? (data['endDate'] as Timestamp).toDate()
                : null)
          : null,
      payoutDate: data['payoutDate'] != null
          ? (data['payoutDate'] is Timestamp
                ? (data['payoutDate'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      amount: (data['amount'] ?? 0.0).toDouble(),
      totalAmount: (data['totalAmount'] ?? data['amount'] ?? 0.0).toDouble(),
      contributions:
          (data['contributions'] as List<dynamic>?)
              ?.map((contrib) => TontineContribution.fromMap(contrib))
              .toList() ??
          [],
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cycleNumber': cycleNumber,
      'winnerId': winnerId,
      'winnerName': winnerName,
      'beneficiaryName': beneficiaryName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'payoutDate': Timestamp.fromDate(payoutDate),
      'amount': amount,
      'totalAmount': totalAmount,
      'contributions': contributions.map((contrib) => contrib.toMap()).toList(),
      'isCompleted': isCompleted,
    };
  }
}

class TontineContribution {
  final String memberId;
  final String memberName;
  final double amount;
  final DateTime contributionDate;
  final bool isPaid;
  final String? transactionId;

  TontineContribution({
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.contributionDate,
    required this.isPaid,
    this.transactionId,
  });

  factory TontineContribution.fromMap(Map<String, dynamic> data) {
    return TontineContribution(
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      contributionDate: data['contributionDate'] != null
          ? (data['contributionDate'] is Timestamp
                ? (data['contributionDate'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      isPaid: data['isPaid'] ?? false,
      transactionId: data['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'contributionDate': Timestamp.fromDate(contributionDate),
      'isPaid': isPaid,
      'transactionId': transactionId,
    };
  }
}
