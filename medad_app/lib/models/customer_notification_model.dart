import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج إشعارات العميل
/// الأنواع: new_ad_category, price_drop, ad_sold, system
class CustomerNotificationModel {
  String id;
  String customerId;
  String type; // new_ad_category, price_drop, ad_sold, system
  String title;
  String message;
  String? adId; // مرتبط بالإعلان
  String? category; // الفئة المهتم بها
  double? oldPrice;
  double? newPrice;
  bool isRead;
  DateTime createdAt;

  CustomerNotificationModel({
    required this.id,
    required this.customerId,
    required this.type,
    required this.title,
    required this.message,
    this.adId,
    this.category,
    this.oldPrice,
    this.newPrice,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'type': type,
        'title': title,
        'message': message,
        if (adId != null) 'adId': adId,
        if (category != null) 'category': category,
        if (oldPrice != null) 'oldPrice': oldPrice,
        if (newPrice != null) 'newPrice': newPrice,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory CustomerNotificationModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    DateTime parsedCreatedAt;
    if (json['createdAt'] is Timestamp) {
      parsedCreatedAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] != null) {
      final rawDate = json['createdAt'];
      // Handle both String and DateTime
      if (rawDate is String) {
        try {
          parsedCreatedAt = DateTime.parse(rawDate);
        } catch (e) {
          parsedCreatedAt = DateTime.now();
        }
      } else {
        parsedCreatedAt = DateTime.now();
      }
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return CustomerNotificationModel(
      id: id,
      customerId: json['customerId'] ?? '',
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      adId: json['adId'],
      category: json['category'],
      oldPrice: json['oldPrice']?.toDouble(),
      newPrice: json['newPrice']?.toDouble(),
      isRead: json['isRead'] ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  // أيقونة حسب النوع
  String get icon {
    switch (type) {
      case 'new_ad_category':
        return 'new_releases';
      case 'price_drop':
        return 'trending_down';
      case 'ad_sold':
        return 'sell';
      case 'system':
        return 'info';
      default:
        return 'notifications';
    }
  }

  // لون حسب النوع
  String get colorHex {
    switch (type) {
      case 'new_ad_category':
        return '#4CAF50'; // green
      case 'price_drop':
        return '#FF9800'; // orange
      case 'ad_sold':
        return '#9E9E9E'; // grey
      case 'system':
        return '#2196F3'; // blue
      default:
        return '#9E9E9E'; // grey
    }
  }
}
