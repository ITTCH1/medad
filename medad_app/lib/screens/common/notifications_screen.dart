import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ad_model.dart';
import '../ads/ad_details_screen.dart';

/// صفحة تعرض حالة الإعلانات للمستخدم
class MyNotificationsScreen extends StatefulWidget {
  const MyNotificationsScreen({super.key});

  @override
  State<MyNotificationsScreen> createState() => _MyNotificationsScreenState();
}

class _MyNotificationsScreenState extends State<MyNotificationsScreen> {
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;
  String _filter = 'all'; // all, pending, approved, rejected

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('إشعاراتي')),
        body: const Center(child: Text('يجب تسجيل الدخول أولاً')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('إشعاراتي'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ads')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ads = snapshot.data!.docs
              .map((doc) => AdModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          // حساب الحالات
          _pendingCount = ads.where((ad) => !ad.isApproved).length;
          _approvedCount = ads.where((ad) => ad.isApproved && ad.status == 'active').length;
          _rejectedCount = ads.where((ad) => ad.status == 'inactive').length;

          if (ads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ملخص الحالة
              _buildSummaryCards(),
              const SizedBox(height: 24),

              // فلترة
              _buildFilterTabs(),
              const SizedBox(height: 12),

              // قائمة الإعلانات
              Text(
                'حالة الإعلانات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              _buildAdsList(ads),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        // إعلان معلق
        if (_pendingCount > 0)
          _buildStatusCard(
            'إعلانات معلقة',
            '$_pendingCount إعلان بانتظار الموافقة',
            Icons.hourglass_empty,
            Colors.orange,
            Colors.orange.shade50,
          ),

        // إعلان موافق
        if (_approvedCount > 0)
          _buildStatusCard(
            'إعلانات موافق عليها',
            '$_approvedCount إعلان نشط',
            Icons.check_circle_outline,
            Colors.green,
            Colors.green.shade50,
          ),

        // إعلان مرفوض
        if (_rejectedCount > 0)
          _buildStatusCard(
            'إعلانات مرفوضة',
            '$_rejectedCount إعلان لم يتم قبوله',
            Icons.cancel_outlined,
            Colors.red,
            Colors.red.shade50,
          ),

        // لا توجد إعلانات معلقة
        if (_pendingCount == 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لا توجد إعلانات معلقة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'جميع إعلاناتك موافقة عليها ونشطة',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildFilterChip('الكل', 'all', Icons.list),
          if (_pendingCount > 0)
            _buildFilterChip('معلقة', 'pending', Icons.hourglass_empty),
          if (_approvedCount > 0)
            _buildFilterChip('موافقة', 'approved', Icons.check_circle),
          if (_rejectedCount > 0)
            _buildFilterChip('مرفوضة', 'rejected', Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filter == value;
    final count = value == 'all'
        ? _pendingCount + _approvedCount + _rejectedCount
        : value == 'pending'
            ? _pendingCount
            : value == 'approved'
                ? _approvedCount
                : _rejectedCount;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text('$label ($count)'),
        ],
      ),
      onSelected: (selected) {
        setState(() => _filter = value);
      },
      selectedColor: Colors.teal.shade100,
      checkmarkColor: Colors.teal,
      labelStyle: TextStyle(
        color: isSelected ? Colors.teal.shade900 : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildAdsList(List<AdModel> ads) {
    // تصفية حسب الحالة
    List<AdModel> filteredAds;
    switch (_filter) {
      case 'pending':
        filteredAds = ads.where((ad) => !ad.isApproved).toList();
        break;
      case 'approved':
        filteredAds = ads.where((ad) => ad.isApproved && ad.status == 'active').toList();
        break;
      case 'rejected':
        filteredAds = ads.where((ad) => ad.status == 'inactive').toList();
        break;
      default:
        filteredAds = ads;
    }

    if (filteredAds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'لا توجد إعلانات',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredAds.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ad = filteredAds[index];
        final isApproved = ad.isApproved && ad.status == 'active';
        final isPending = !ad.isApproved;
        final isRejected = ad.status == 'inactive';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // فتح تفاصيل الإعلان
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdDetailsScreen(adId: ad.id ?? ''),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isApproved
                      ? Colors.green.shade200
                      : isPending
                          ? Colors.orange.shade200
                          : Colors.red.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isApproved
                            ? Colors.green
                            : isPending
                                ? Colors.orange
                                : Colors.red)
                        .withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // حالة الإعلان
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isApproved
                          ? Colors.green
                          : isPending
                              ? Colors.orange
                              : Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isApproved
                              ? '✅ موافق عليه ونشط'
                              : isPending
                                  ? '⏳ بانتظار الموافقة'
                                  : '❌ لم يتم قبوله',
                          style: TextStyle(
                            fontSize: 13,
                            color: isApproved
                                ? Colors.green
                                : isPending
                                    ? Colors.orange
                                    : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(height: 4),
                          Text(
                            'سيتم مراجعة إعلانك من قبل الإدارة',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isApproved
                        ? Icons.check_circle
                        : isPending
                            ? Icons.hourglass_empty
                            : Icons.cancel,
                    color: isApproved
                        ? Colors.green
                        : isPending
                            ? Colors.orange
                            : Colors.red,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
