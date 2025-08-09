import 'package:cloud_firestore/cloud_firestore.dart';

class MerchantModel {
  final String id;
  final String userId;
  final String businessName;
  final String businessCategory;
  final Map<String, String> address;
  final String phoneNumber;
  final String email;
  final String qrCodeData;
  final bool isActive;
  final Timestamp createdAt;

  MerchantModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessCategory,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.qrCodeData,
    this.isActive = true,
    required this.createdAt,
  });

  factory MerchantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MerchantModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      businessName: data['businessName'] ?? '',
      businessCategory: data['businessCategory'] ?? 'Other',
      address: data['address'] != null
          ? Map<String, String>.from(data['address'])
          : {},
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      qrCodeData: data['qrCodeData'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessName': businessName,
      'businessCategory': businessCategory,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'qrCodeData': qrCodeData,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
