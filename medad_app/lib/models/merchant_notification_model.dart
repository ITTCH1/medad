import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج إشعارات التاجر
/// الأنواع: ad_approved, ad_rejected, ad_pending, new_inquiry
class MerchantNotificationModel {
  String id;
  String merchantId;
  String type; // ad_approved, ad_rejected, ad_pending, new_inquiry
  String title;
  String message;
  String? adId; // مرتبط بالإعلان
  String? inquiryId; // مرتبط بالاستفسار
  bool isRead;
  DateTime createdAt;

  MerchantNotificationModel({
    required this.id,
    required this.merchantId,
    required this.type,
    required this.title,
    required this.message,
    this.adId,
    this.inquiryId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchantId': merchantId,
        'type': type,
        'title': title,
        'message': message,
        if (adId != null) 'adId': adId,
        if (inquiryId != null) 'inquiryId': inquiryId,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory MerchantNotificationModel.fromJson(
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

    return MerchantNotificationModel(
      id: id,
      merchantId: json['merchantId'] ?? '',
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      adId: json['adId'],
      inquiryId: json['inquiryId'],
      isRead: json['isRead'] ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  // أيقونة حسب النوع
  String get icon {
    switch (type) {
      case 'ad_approved':
        return 'check_circle';
      case 'ad_rejected':
        return 'cancel';
      case 'ad_pending':
        return 'hourglass_empty';
      case 'new_inquiry':
        return 'question_answer';
      default:
        return 'notifications';
    }
  }

  // لون حسب النوع
  String get colorHex {
    switch (type) {
      case 'ad_approved':
        return '#4CAF50'; // green
      case 'ad_rejected':
        return '#F44336'; // red
      case 'ad_pending':
        return '#FF9800'; // orange
      case 'new_inquiry':
        return '#2196F3'; // blue
      default:
        return '#9E9E9E'; // grey
    }
  }
}
