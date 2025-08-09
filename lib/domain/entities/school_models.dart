import 'package:cloud_firestore/cloud_firestore.dart';

class School {
  final String id;
  final String name;

  School({required this.id, required this.name});
}

class Student {
  final String id;
  final String name;
  final String schoolId;
  final String parentUserId;

  Student({
    required this.id,
    required this.name,
    required this.schoolId,
    required this.parentUserId,
  });
}

enum FeeStatus { unpaid, paid }

class Fee {
  final String id;
  final String studentId;
  final String schoolId;
  final String description;
  final double amount;
  final DateTime dueDate;
  final FeeStatus status;

  Fee({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

   factory Fee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Fee(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      schoolId: data['schoolId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      status: data['status'] == 'paid' ? FeeStatus.paid : FeeStatus.unpaid,
    );
  }
}
