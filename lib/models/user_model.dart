import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { client, admin }

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;
  final String? profileImageUrl;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
    this.isActive = true,
    this.profileImageUrl,
    this.preferences = const {},
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime safeDate(dynamic value, String fieldName) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is DateTime) {
        return value;
      } else {
        print(
            'Warning: Firestore user field "$fieldName" is missing or not a Timestamp. Using DateTime.now().');
        return DateTime.now();
      }
    }

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'],
      role: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${data['role'] ?? 'client'}',
        orElse: () => UserRole.client,
      ),
      createdAt: safeDate(data['createdAt'], 'createdAt'),
      lastLoginAt: safeDate(data['lastLoginAt'], 'lastLoginAt'),
      isActive: data['isActive'] ?? true,
      profileImageUrl: data['profileImageUrl'],
      preferences: data['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, role: $role)';
  }
}
