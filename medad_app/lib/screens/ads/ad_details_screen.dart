import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/ad_service.dart';
import '../../services/notification_service.dart';
import '../../models/ad_model.dart';

class AdDetailsScreen extends StatelessWidget {
  final String adId;

  const AdDetailsScreen({super.key, required this.adId});

  Future<void> _callPhone(String phone) async {
    Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'لا يمكن الاتصال بهذا الرقم';
    }
  }

  Future<void> _editPrice(BuildContext context, AdModel ad) async {
    final controller = TextEditingController(text: ad.price.toString());
    final oldPrice = ad.price;

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل السعر'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'السعر الجديد (ريال)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice > 0) {
                Navigator.pop(context, newPrice);
              }
            },
            child: const Text('تحديث'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      // تحديث السعر
      await FirebaseFirestore.instance
          .collection('ads')
          .doc(adId)
          .update({'price': result});

      // إذا انخفض السعر → إشعار المتابعين
      if (result < oldPrice) {
        debugPrint('📢 Price dropped from $oldPrice to $result, notifying followers...');

        // جلب المستخدمين المهتمين بهذه الفئة
        final interestedUsers = await FirebaseFirestore.instance
            .collection('users')
            .where('favoriteCategories', arrayContains: ad.category)
            .get();

        debugPrint('📢 Found ${interestedUsers.docs.length} interested customers');

        for (final userDoc in interestedUsers.docs) {
          final customerId = userDoc.id;
          // لا تُرسل إشعار لصاحب الإعلان
          if (customerId == ad.userId) continue;

          await FirebaseFirestore.instance.collection('customer_notifications').add({
            'customerId': customerId,
            'type': 'price_drop',
            'title': 'انخفاض السعر 📉',
            'message': 'تم تخفيض سعر "${ad.title}" من $oldPrice إلى $result ريال.',
            'adId': adId,
            'category': ad.category,
            'oldPrice': oldPrice,
            'newPrice': result,
            'isRead': false,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          });
        }
        debugPrint('✅ Price drop notifications sent');
      }
    } catch (e) {
      debugPrint('❌ Error updating price: $e');
    }
  }

  Future<void> _markAsSold(BuildContext context, AdModel ad) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تم بيع الإعلان؟'),
        content: Text('هل أنت متأكد من تعليم "${ad.title}" كـ "مباع"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('تم البيع'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // تحديث الحالة
      await FirebaseFirestore.instance
          .collection('ads')
          .doc(adId)
          .update({'status': 'sold'});

      // إشعار المتابعين بأن الإعلان تم بيعه
      debugPrint('📢 Ad marked as sold, notifying followers...');

      final interestedUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('favoriteCategories', arrayContains: ad.category)
          .get();

      for (final userDoc in interestedUsers.docs) {
        final customerId = userDoc.id;
        if (customerId == ad.userId) continue;

        await FirebaseFirestore.instance.collection('customer_notifications').add({
          'customerId': customerId,
          'type': 'ad_sold',
          'title': 'الإعلان تم بيعه 🏷️',
          'message': 'الإعلان "${ad.title}" الذي في فئة ${ad.category} تم بيعه.',
          'adId': adId,
          'category': ad.category,
          'isRead': false,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        });
      }
      debugPrint('✅ Ad sold notifications sent');
    } catch (e) {
      debugPrint('❌ Error marking as sold: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الإعلان'),
        actions: [
          // زر تعديل السعر (لصاحب الإعلان فقط)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('ads').doc(adId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final adData = snapshot.data!.data() as Map<String, dynamic>?;
              final ad = adData != null ? AdModel.fromJson(adData, adId) : null;

              if (ad == null || currentUser?.uid != ad.userId) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit_price' && ad != null) {
                    _editPrice(context, ad);
                  } else if (value == 'mark_sold' && ad != null) {
                    _markAsSold(context, ad);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit_price',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('تعديل السعر'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'mark_sold',
                    child: Row(
                      children: [
                        Icon(Icons.sell, size: 20),
                        SizedBox(width: 8),
                        Text('تم البيع'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<AdModel?>(
        future: AdService().getAd(adId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          AdModel ad = snapshot.data!;
          final isOwner = currentUser?.uid == ad.userId;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صور الإعلان
                SizedBox(
                  height: 250,
                  child: ad.images.isEmpty
                      ? Center(child: Icon(Icons.image, size: 100))
                      : PageView.builder(
                          itemCount: ad.images.length,
                          itemBuilder: (context, index) {
                            return Image.network(ad.images[index], fit: BoxFit.cover);
                          },
                        ),
                ),
                SizedBox(height: 15),

                // العنوان
                Text(ad.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),

                // الحالة (تم البيع)
                if (ad.status == 'sold')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sell, color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'تم البيع',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // السعر والتصنيف
                Row(
                  children: [
                    Text(
                      '${ad.price} ريال',
                      style: TextStyle(fontSize: 18, color: Colors.green),
                    ),
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editPrice(context, ad),
                        tooltip: 'تعديل السعر',
                      ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(ad.category),
                    ),
                  ],
                ),
                SizedBox(height: 15),

                // الموقع
                Row(
                  children: [
                    Icon(Icons.location_on, size: 20),
                    SizedBox(width: 5),
                    Text(ad.location),
                  ],
                ),
                SizedBox(height: 10),

                // الوصف
                Text('الوصف:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text(ad.description),
                SizedBox(height: 20),

                Divider(),
                SizedBox(height: 15),

                // زر الاتصال
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.phone),
                    label: Text('اتصل بصاحب الإعلان'),
                    onPressed: () => _callPhone(ad.phone),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}