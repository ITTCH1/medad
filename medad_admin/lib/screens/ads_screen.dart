import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  String _selectedFilter = 'all';

  // ✅ الموافقة على إعلان
  Future<void> _approveAd(String adId) async {
    try {
      // جلب بيانات الإعلان أولاً
      final adDoc = await FirebaseFirestore.instance.collection('ads').doc(adId).get();
      final adData = adDoc.data() as Map<String, dynamic>?;
      final merchantId = adData?['userId'] ?? '';
      final adCategory = adData?['category'] ?? '';
      final adTitle = adData?['title'] ?? '';

      // تحديث حالة الإعلان
      await FirebaseFirestore.instance.collection('ads').doc(adId).update({
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // إنشاء إشعار للتاجر
      if (merchantId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('merchant_notifications').add({
          'merchantId': merchantId,
          'type': 'ad_approved',
          'title': 'تمت الموافقة على إعلانك ✅',
          'message': 'تمت الموافقة على إعلانك وهو متاح الآن للمشاهدة.',
          'adId': adId,
          'isRead': false,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        });
      }

      // إشعار العملاء المهتمين بهذه الفئة
      String resultMessage = '';
      if (adCategory.isNotEmpty) {
        final allUsers = await FirebaseFirestore.instance
            .collection('users')
            .get();
        
        int totalUsers = allUsers.docs.length;
        List<String> userInfos = [];
        for (final userDoc in allUsers.docs) {
          final userData = userDoc.data();
          final favCats = userData['favoriteCategories'] as List<dynamic>?;
          userInfos.add('${userDoc.id.substring(0, 8)} (${userData['role']}): ${favCats?.join(', ') ?? 'لا شيء'}');
        }

        final interestedUsers = await FirebaseFirestore.instance
            .collection('users')
            .where('favoriteCategories', arrayContains: adCategory)
            .get();

        int notificationCount = 0;
        for (final userDoc in interestedUsers.docs) {
          final customerId = userDoc.id;
          if (customerId == merchantId) continue;

          await FirebaseFirestore.instance.collection('customer_notifications').add({
            'customerId': customerId,
            'type': 'new_ad_category',
            'title': 'إعلان جديد في فئة $adCategory 🎉',
            'message': 'تم إضافة إعلان جديد "$adTitle" في الفئة التي تتابعها.',
            'adId': adId,
            'category': adCategory,
            'isRead': false,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          });
          notificationCount++;
        }

        resultMessage = '\n\n📊 نتائج إشعارات العملاء:\n'
            '• الفئة: $adCategory\n'
            '• إجمالي المستخدمين: $totalUsers\n'
            '• المهتمين بـ "$adCategory": ${interestedUsers.docs.length}\n'
            '• الإشعارات المُنشأة: $notificationCount\n'
            '\n👥 تفاصيل المستخدمين:\n${userInfos.join('\n')}';
      } else {
        resultMessage = '\n\n⚠️ الإعلان بدون فئة - لم يتم إرسال إشعارات';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ تمت الموافقة'),
            content: SingleChildScrollView(
              child: SelectableText(
                'تمت الموافقة على الإعلان بنجاح.$resultMessage',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ رفض إعلان
  Future<void> _rejectAd(String adId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الإعلان'),
        content: const Text('هل أنت متأكد من رفض هذا الإعلان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // جلب بيانات الإعلان أولاً
      final adDoc = await FirebaseFirestore.instance.collection('ads').doc(adId).get();
      final adData = adDoc.data() as Map<String, dynamic>?;
      final merchantId = adData?['userId'] ?? '';
      debugPrint('📢 Rejecting ad, Merchant ID: $merchantId');

      // تحديث حالة الإعلان
      await FirebaseFirestore.instance.collection('ads').doc(adId).update({
        'isApproved': false,
        'status': 'inactive',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // إنشاء إشعار للتاجر
      if (merchantId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('merchant_notifications').add({
          'merchantId': merchantId,
          'type': 'ad_rejected',
          'title': 'لم يتم قبول إعلانك ❌',
          'message': 'لم يتم قبول إعلانك. يرجى مراجعة شروط النشر.',
          'adId': adId,
          'isRead': false,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        });
        debugPrint('✅ Rejection notification created for merchant: $merchantId');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفض الإعلان'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error rejecting ad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ حذف إعلان
  Future<void> _deleteAd(String adId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('ads').doc(adId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الإعلان')),
        );
      }
    }
  }

  // ✅ عرض تفاصيل الإعلان
  void _showAdDetails(Map<String, dynamic> ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ad['title'] ?? 'بدون عنوان'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('الفئة', ad['category'] ?? ''),
              _detailRow('السعر', '${ad['price'] ?? 0} ريال'),
              _detailRow('الموقع', ad['location'] ?? ''),
              _detailRow('الهاتف', ad['phone'] ?? ''),
              _detailRow('الحالة', ad['isApproved'] == true ? 'موافق عليه' : 'بانتظار الموافقة'),
              const SizedBox(height: 8),
              const Text(
                'الوصف:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(ad['description'] ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إدارة الإعلانات',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // ✅ شريط الفلترة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('فلترة:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildFilterChip('الكل', 'all'),
                  const SizedBox(width: 4),
                  _buildFilterChip('بانتظار الموافقة', 'pending'),
                  const SizedBox(width: 4),
                  _buildFilterChip('الموافق عليها', 'approved'),
                  const SizedBox(width: 4),
                  _buildFilterChip('المرفوضة', 'rejected'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ✅ قائمة الإعلانات
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ads')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var ads = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {'id': doc.id, ...data};
                }).toList();

                // تطبيق الفلتر
                ads = ads.where((ad) {
                  final isApproved = ad['isApproved'] ?? false;
                  final status = ad['status'] ?? 'active';

                  switch (_selectedFilter) {
                    case 'pending':
                      return !isApproved;
                    case 'approved':
                      return isApproved;
                    case 'rejected':
                      return status == 'inactive' && !isApproved;
                    default:
                      return true;
                  }
                }).toList();

                if (ads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'pending'
                              ? 'لا توجد إعلانات بانتظار الموافقة'
                              : 'لا توجد إعلانات',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index];
                    final isApproved = ad['isApproved'] ?? false;
                    final status = ad['status'] ?? 'active';
                    final isPending = !isApproved;
                    final isRejected = status == 'inactive' && !isApproved;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ad['images'] != null && ad['images'].isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ad['images'][0],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 60),
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                        title: Text(ad['title'] ?? 'بدون عنوان'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${ad['price'] ?? 0} ريال | ${ad['category'] ?? ''}'),
                            if (isPending)
                              const Text(
                                'بانتظار الموافقة',
                                style: TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            if (isRejected)
                              const Text(
                                'تم الرفض',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            if (isApproved)
                              const Text(
                                'موافق عليه',
                                style: TextStyle(color: Colors.green, fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // أزرار الموافقة والرفض
                            if (isPending) ...[
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => _approveAd(ad['id']),
                                tooltip: 'موافقة',
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _rejectAd(ad['id']),
                                tooltip: 'رفض',
                              ),
                            ],
                            // زر إعادة الموافقة (للمرفوض)
                            if (isRejected) ...[
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Colors.orange),
                                onPressed: () => _approveAd(ad['id']),
                                tooltip: 'إعادة الموافقة',
                              ),
                            ],
                            // زر الحذف
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAd(ad['id']),
                              tooltip: 'حذف',
                            ),
                          ],
                        ),
                        onTap: () => _showAdDetails(ad),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: Colors.teal.shade100,
      checkmarkColor: Colors.teal,
    );
  }
}
