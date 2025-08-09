import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? finimoiTag;
  final double balance;
  final double cashbackBalance;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String? address;
  final String? city;
  final String? country;
  final DateTime? updatedAt;
  final bool roundUpSavingsEnabled;
  final String? roundUpSavingsGoalId;
  final String? referralCode;
  final String? referredBy;
  final bool isJuniorAccount;
  final String? parentAccountId;
  final List<String>? homeScreenLayout;
  final String? gender;
  final DateTime? dateOfBirth;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    this.finimoiTag,
    required this.balance,
    this.cashbackBalance = 0.0,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    this.address,
    this.city,
    this.country,
    this.updatedAt,
    this.roundUpSavingsEnabled = false,
    this.roundUpSavingsGoalId,
    this.referralCode,
    this.referredBy,
    this.isJuniorAccount = false,
    this.parentAccountId,
    this.homeScreenLayout,
    this.gender,
    this.dateOfBirth,
  });

  String get fullName => '$firstName $lastName';
  String get initials {
    final first = (firstName.trim().isNotEmpty) ? firstName.trim()[0] : '';
    final last = (lastName.trim().isNotEmpty) ? lastName.trim()[0] : '';
    if (first.isEmpty && last.isEmpty) return '?';
    return '$first$last'.toUpperCase();
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      finimoiTag: data['finimoiTag'],
      balance: (data['balance'] ?? 0.0).toDouble(),
      cashbackBalance: (data['cashbackBalance'] ?? 0.0).toDouble(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] is Timestamp
                ? (data['lastLoginAt'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      address: data['address'],
      city: data['city'],
      country: data['country'],
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      roundUpSavingsEnabled: data['roundUpSavingsEnabled'] ?? false,
      roundUpSavingsGoalId: data['roundUpSavingsGoalId'],
      referralCode: data['referralCode'],
      referredBy: data['referredBy'],
      isJuniorAccount: data['isJuniorAccount'] ?? false,
      parentAccountId: data['parentAccountId'],
      homeScreenLayout: List<String>.from(data['homeScreenLayout'] ?? []),
      gender: data['gender'],
      dateOfBirth: data['dateOfBirth'] != null ? (data['dateOfBirth'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'finimoiTag': finimoiTag,
      'balance': balance,
      'cashbackBalance': cashbackBalance,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'address': address,
      'city': city,
      'country': country,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'roundUpSavingsEnabled': roundUpSavingsEnabled,
      'roundUpSavingsGoalId': roundUpSavingsGoalId,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'isJuniorAccount': isJuniorAccount,
      'parentAccountId': parentAccountId,
      'homeScreenLayout': homeScreenLayout,
      'gender': gender,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    String? finimoiTag,
    double? balance,
    double? cashbackBalance,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? address,
    String? city,
    String? country,
    DateTime? updatedAt,
    bool? roundUpSavingsEnabled,
    String? roundUpSavingsGoalId,
    String? referralCode,
    String? referredBy,
    bool? isJuniorAccount,
    String? parentAccountId,
    List<String>? homeScreenLayout,
    String? gender,
    DateTime? dateOfBirth,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      finimoiTag: finimoiTag ?? this.finimoiTag,
      balance: balance ?? this.balance,
      cashbackBalance: cashbackBalance ?? this.cashbackBalance,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      updatedAt: updatedAt ?? this.updatedAt,
      roundUpSavingsEnabled: roundUpSavingsEnabled ?? this.roundUpSavingsEnabled,
      roundUpSavingsGoalId: roundUpSavingsGoalId ?? this.roundUpSavingsGoalId,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      isJuniorAccount: isJuniorAccount ?? this.isJuniorAccount,
      parentAccountId: parentAccountId ?? this.parentAccountId,
      homeScreenLayout: homeScreenLayout ?? this.homeScreenLayout,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }
}
