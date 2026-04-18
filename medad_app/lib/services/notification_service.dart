import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/merchant_notification_model.dart';
import '../models/customer_notification_model.dart';

/// خدمة الإشعارات المنفصلة حسب الدور
/// - MerchantNotifications: إشعارات التاجر (حالة الإعلانات، استفسارات العملاء)
/// - CustomerNotifications: إشعارات العميل (إعلانات جديدة، انخفاض الأسعار)
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== MERCHANT NOTIFICATIONS ====================

  /// إنشاء إشعار جديد للتاجر
  Future<void> createMerchantNotification({
    required String merchantId,
    required String type,
    required String title,
    required String message,
    String? adId,
    String? inquiryId,
  }) async {
    final notification = MerchantNotificationModel(
      id: '', // Firestore سيولّد المعرّف
      merchantId: merchantId,
      type: type,
      title: title,
      message: message,
      adId: adId,
      inquiryId: inquiryId,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('merchant_notifications')
        .add(notification.toJson());
  }

  /// جلب إشعارات التاجر (Stream)
  Stream<List<MerchantNotificationModel>> getMerchantNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('merchant_notifications')
        .where('merchantId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) =>
              MerchantNotificationModel.fromJson(doc.data(), doc.id))
          .toList();
      // ترتيب محلي لتجنب مشاكل Firestore index
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    }).handleError((error) {
      print('❌ Error fetching merchant notifications: $error');
      return <MerchantNotificationModel>[];
    });
  }

  /// جلب إشعارات التاجر غير المقروءة
  Stream<int> getMerchantUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('merchant_notifications')
        .where('merchantId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      print('❌ Error fetching merchant unread count: $error');
      return 0;
    });
  }

  /// تحديد إشعار كمقروء
  Future<void> markMerchantNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('merchant_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// تحديد جميع الإشعارات كمقروءة
  Future<void> markAllMerchantNotificationsAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final snapshot = await _firestore
        .collection('merchant_notifications')
        .where('merchantId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// حذف إشعار تاجر
  Future<void> deleteMerchantNotification(String notificationId) async {
    await _firestore
        .collection('merchant_notifications')
        .doc(notificationId)
        .delete();
  }

  /// حذف جميع إشعارات التاجر
  Future<void> clearAllMerchantNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final snapshot = await _firestore
        .collection('merchant_notifications')
        .where('merchantId', isEqualTo: currentUser.uid)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ==================== CUSTOMER NOTIFICATIONS ====================

  /// إنشاء إشعار جديد للعميل
  Future<void> createCustomerNotification({
    required String customerId,
    required String type,
    required String title,
    required String message,
    String? adId,
    String? category,
    double? oldPrice,
    double? newPrice,
  }) async {
    final notification = CustomerNotificationModel(
      id: '',
      customerId: customerId,
      type: type,
      title: title,
      message: message,
      adId: adId,
      category: category,
      oldPrice: oldPrice,
      newPrice: newPrice,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('customer_notifications')
        .add(notification.toJson());
  }

  /// جلب إشعارات العميل (Stream)
  Stream<List<CustomerNotificationModel>> getCustomerNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('⚠️ No current user for customer notifications');
      return Stream.value([]);
    }

    print('📢 Fetching customer notifications for: ${currentUser.uid}');

    return _firestore
        .collection('customer_notifications')
        .where('customerId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      print('📢 Found ${snapshot.docs.length} customer notifications');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('   - ${data['type']}: ${data['title']}');
      }
      final notifications = snapshot.docs
          .map((doc) =>
              CustomerNotificationModel.fromJson(doc.data(), doc.id))
          .toList();
      // ترتيب محلي لتجنب مشاكل Firestore index
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    }).handleError((error) {
      print('❌ Error fetching customer notifications: $error');
      return <CustomerNotificationModel>[];
    });
  }

  /// جلب إشعارات العميل غير المقروءة
  Stream<int> getCustomerUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('customer_notifications')
        .where('customerId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      print('❌ Error fetching customer unread count: $error');
      return 0;
    });
  }

  /// تحديد إشعار كمقروء
  Future<void> markCustomerNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('customer_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// تحديد جميع الإشعارات كمقروءة
  Future<void> markAllCustomerNotificationsAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final snapshot = await _firestore
        .collection('customer_notifications')
        .where('customerId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// حذف إشعار عميل
  Future<void> deleteCustomerNotification(String notificationId) async {
    await _firestore
        .collection('customer_notifications')
        .doc(notificationId)
        .delete();
  }

  /// حذف جميع إشعارات العميل
  Future<void> clearAllCustomerNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final snapshot = await _firestore
        .collection('customer_notifications')
        .where('customerId', isEqualTo: currentUser.uid)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ==================== HELPER METHODS ====================

  /// إشعار التاجر عند موافقة الإعلان
  Future<void> notifyAdApproved(String merchantId, String adId) async {
    await createMerchantNotification(
      merchantId: merchantId,
      type: 'ad_approved',
      title: 'تمت الموافقة على إعلانك ✅',
      message: 'تمت الموافقة على إعلانك وهو متاح الآن للمشاهدة.',
      adId: adId,
    );
  }

  /// إشعار التاجر عند رفض الإعلان
  Future<void> notifyAdRejected(String merchantId, String adId) async {
    await createMerchantNotification(
      merchantId: merchantId,
      type: 'ad_rejected',
      title: 'لم يتم قبول إعلانك ❌',
      message: 'لم يتم قبول إعلانك. يرجى مراجعة شروط النشر.',
      adId: adId,
    );
  }

  /// إشعار التاجر عند وجود استفسار من عميل
  Future<void> notifyNewInquiry(String merchantId, String adId, String inquiryId) async {
    await createMerchantNotification(
      merchantId: merchantId,
      type: 'new_inquiry',
      title: 'استفسار جديد على إعلانك 💬',
      message: 'لديك استفسار جديد من عميل محتم.',
      adId: adId,
      inquiryId: inquiryId,
    );
  }

  /// إشعار العميل بإعلان جديد في فئة مهتم بها
  Future<void> notifyNewAdInCategory(String customerId, String category, String adId) async {
    await createCustomerNotification(
      customerId: customerId,
      type: 'new_ad_category',
      title: 'إعلان جديد في فئة $category 🎉',
      message: 'تم إضافة إعلان جديد في الفئة التي تتابعها.',
      adId: adId,
      category: category,
    );
  }

  /// إشعار العميل بانخفاض سعر
  Future<void> notifyPriceDrop(String customerId, String adId, double oldPrice, double newPrice) async {
    await createCustomerNotification(
      customerId: customerId,
      type: 'price_drop',
      title: 'انخفاض السعر 📉',
      message: 'تم تخفيض السعر من $oldPrice إلى $newPrice ريال.',
      adId: adId,
      oldPrice: oldPrice,
      newPrice: newPrice,
    );
  }

  /// إشعار العميل ببيع إعلان مفضل
  Future<void> notifyAdSold(String customerId, String adId) async {
    await createCustomerNotification(
      customerId: customerId,
      type: 'ad_sold',
      title: 'الإعلان تم بيعه 🏷️',
      message: 'الإعلان الذي كنت تتابعه تم بيعه.',
      adId: adId,
    );
  }

  // ==================== TEST NOTIFICATIONS ====================

  /// إنشاء إشعارات تجريبية للتاجر (للاختبار فقط)
  Future<void> createTestMerchantNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // إشعار موافقة
    await createMerchantNotification(
      merchantId: currentUser.uid,
      type: 'ad_approved',
      title: 'تمت الموافقة على إعلانك ✅',
      message: 'تمت الموافقة على إعلان "سيارة للبيع" وهو متاح الآن للمشاهدة.',
      adId: 'test_ad_1',
    );

    // إشعار رفض
    await createMerchantNotification(
      merchantId: currentUser.uid,
      type: 'ad_rejected',
      title: 'لم يتم قبول إعلانك ❌',
      message: 'لم يتم قبول إعلان "عقار للإيجار". يرجى مراجعة شروط النشر.',
      adId: 'test_ad_2',
    );

    // إشعار معلق
    await createMerchantNotification(
      merchantId: currentUser.uid,
      type: 'ad_pending',
      title: 'إعلانك بانتظار الموافقة ⏳',
      message: 'إعلان "هاتف للبيع" بانتظار مراجعة الإدارة.',
      adId: 'test_ad_3',
    );

    // إشعار استفسار
    await createMerchantNotification(
      merchantId: currentUser.uid,
      type: 'new_inquiry',
      title: 'استفسار جديد على إعلانك 💬',
      message: 'لديك استفسار جديد من عميل محتم على إعلان "سيارة للبيع".',
      adId: 'test_ad_1',
      inquiryId: 'test_inquiry_1',
    );
  }

  /// إنشاء إشعارات تجريبية للعميل (للاختبار فقط)
  Future<void> createTestCustomerNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // إشعار إعلان جديد
    await createCustomerNotification(
      customerId: currentUser.uid,
      type: 'new_ad_category',
      title: 'إعلان جديد في فئة سيارات 🎉',
      message: 'تم إضافة إعلان جديد "Toyota Camry 2024" في الفئة التي تتابعها.',
      adId: 'test_ad_4',
      category: 'سيارات',
    );

    // إشعار انخفاض السعر
    await createCustomerNotification(
      customerId: currentUser.uid,
      type: 'price_drop',
      title: 'انخفاض السعر 📉',
      message: 'تم تخفيض سعر الإعلان الذي تتابعه.',
      adId: 'test_ad_5',
      oldPrice: 50000,
      newPrice: 45000,
    );

    // إشعار تم البيع
    await createCustomerNotification(
      customerId: currentUser.uid,
      type: 'ad_sold',
      title: 'الإعلان تم بيعه 🏷️',
      message: 'الإعلان "هاتف iPhone 15" الذي كنت تتابعه تم بيعه.',
      adId: 'test_ad_6',
    );

    // إشعار نظام
    await createCustomerNotification(
      customerId: currentUser.uid,
      type: 'system',
      title: 'مرحباً بك في مدد 👋',
      message: 'تم تفعيل حسابك بنجاح. يمكنك الآن تصصفح الإعلانات.',
    );
  }
}
