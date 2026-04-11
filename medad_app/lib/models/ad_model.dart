import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  String? id;
  String userId;
  String title;
  String description;
  double price;
  String category;
  String location;
  List<String> images;
  String phone;
  bool isFeatured;
  bool isApproved;
  DateTime createdAt;
  String status; // 'active', 'inactive', 'sold'

  AdModel({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.location,
    required this.images,
    required this.phone,
    this.isFeatured = false,
    this.isApproved = false,
    required this.createdAt,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'title': title,
    'description': description,
    'price': price,
    'category': category,
    'location': location,
    'images': images,
    'phone': phone,
    'isFeatured': isFeatured,
    'isApproved': isApproved,
    'createdAt': createdAt,
    'status': status,
  };

  factory AdModel.fromJson(Map<String, dynamic> json, String id) {
    return AdModel(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      location: json['location'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      phone: json['phone'] ?? '',
      isFeatured: json['isFeatured'] ?? false,
      isApproved: json['isApproved'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      status: json['status'] ?? 'active',
    );
  }
}
