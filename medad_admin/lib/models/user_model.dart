import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String phone;
  String? name;
  String? email;
  String? profileImage;
  String role;
  bool isApproved;
  bool isActive;
  DateTime createdAt;

  UserModel({
    required this.uid,
    required this.phone,
    this.name,
    this.email,
    this.profileImage,
    required this.role,
    this.isApproved = false,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'phone': phone,
        'name': name,
        'email': email,
        'profileImage': profileImage,
        'role': role,
        'isApproved': isApproved,
        'isActive': isActive,
        'createdAt': createdAt,
      };

  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      phone: json['phone'] ?? '',
      name: json['name'],
      email: json['email'],
      profileImage: json['profileImage'],
      role: json['role'] ?? 'customer',
      isApproved: json['isApproved'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }
}