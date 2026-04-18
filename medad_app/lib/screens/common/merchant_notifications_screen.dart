import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../models/merchant_notification_model.dart';
import '../ads/ad_details_screen.dart';

/// صفحة إشعارات التاجر
/// تعرض: موافقة/رفض الإعلانات، استفسارات العملاء، حالة الإعلانات
class MerchantNotificationsScreen extends StatefulWidget {
  const MerchantNotificationsScreen({super.key});

  @override
  State<MerchantNotificationsScreen> createState() =>
      _MerchantNotificationsScreenState();
}

class _MerchantNotificationsScreenState
    extends State<MerchantNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  String _filter = 'all'; // all, unread, ad_approved, ad_rejected, ad_pending, new_inquiry

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('إشعارات التاجر')),
        body: const Center(child: Text('يجب تسجيل الدخول أولاً')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('إشعارات التاجر'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.teal,
        actions: [
          // زر إضافة إشعارات تجريبية (للاختبار)
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _addTestNotifications(),
            tooltip: 'إضافة إشعارات تجريبية',
          ),
          // زر تحديد الكل كمقروء
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllAsRead(),
            tooltip: 'تحديد الكل كمقروء',
          ),
          // زر مسح الكل
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _clearAllNotifications(),
            tooltip: 'مسح الكل',
          ),
        ],
      ),
      body: StreamBuilder<List<MerchantNotificationModel>>(
        stream: _notificationService.getMerchantNotifications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ستصلك إشعارات عند تحديث حالة إعلاناتك',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ملخص الإشعارات
              _buildSummaryCards(notifications),
              const SizedBox(height: 24),

              // فلترة
              _buildFilterTabs(notifications),
              const SizedBox(height: 12),

              // قائمة الإشعارات
              _buildNotificationsList(notifications),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(List<MerchantNotificationModel> notifications) {
    final unread = notifications.where((n) => !n.isRead).length;
    final approved = notifications.where((n) => n.type == 'ad_approved').length;
    final rejected = notifications.where((n) => n.type == 'ad_rejected').length;
    final pending = notifications.where((n) => n.type == 'ad_pending').length;
    final inquiries = notifications.where((n) => n.type == 'new_inquiry').length;

    return Column(
      children: [
        // بطاقات غير مقروءة
        if (unread > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إشعارات غير مقروءة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '$unread إشعار',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // بطاقات الحالة
        Row(
          children: [
            if (approved > 0)
              Expanded(
                child: _buildStatCard(
                  'موافقة',
                  approved,
                  Icons.check_circle,
                  Colors.green,
                  Colors.green.shade50,
                ),
              ),
            if (approved > 0 && rejected > 0) const SizedBox(width: 8),
            if (rejected > 0)
              Expanded(
                child: _buildStatCard(
                  'مرفوضة',
                  rejected,
                  Icons.cancel,
                  Colors.red,
                  Colors.red.shade50,
                ),
              ),
            if (pending > 0 && (approved > 0 || rejected > 0))
              const SizedBox(width: 8),
            if (pending > 0)
              Expanded(
                child: _buildStatCard(
                  'معلقة',
                  pending,
                  Icons.hourglass_empty,
                  Colors.orange,
                  Colors.orange.shade50,
                ),
              ),
            if (inquiries > 0 && (approved > 0 || rejected > 0 || pending > 0))
              const SizedBox(width: 8),
            if (inquiries > 0)
              Expanded(
                child: _buildStatCard(
                  'استفسارات',
                  inquiries,
                  Icons.question_answer,
                  Colors.blue,
                  Colors.blue.shade50,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(List<MerchantNotificationModel> notifications) {
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final approvedCount = notifications.where((n) => n.type == 'ad_approved').length;
    final rejectedCount = notifications.where((n) => n.type == 'ad_rejected').length;
    final pendingCount = notifications.where((n) => n.type == 'ad_pending').length;
    final inquiryCount = notifications.where((n) => n.type == 'new_inquiry').length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildFilterChip('الكل', 'all', notifications.length),
          if (unreadCount > 0)
            _buildFilterChip('غير مقروءة', 'unread', unreadCount),
          if (approvedCount > 0)
            _buildFilterChip('موافقة', 'ad_approved', approvedCount),
          if (rejectedCount > 0)
            _buildFilterChip('مرفوضة', 'ad_rejected', rejectedCount),
          if (pendingCount > 0)
            _buildFilterChip('معلقة', 'ad_pending', pendingCount),
          if (inquiryCount > 0)
            _buildFilterChip('استفسارات', 'new_inquiry', inquiryCount),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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

  Widget _buildNotificationsList(List<MerchantNotificationModel> notifications) {
    List<MerchantNotificationModel> filtered;
    switch (_filter) {
      case 'unread':
        filtered = notifications.where((n) => !n.isRead).toList();
        break;
      case 'ad_approved':
        filtered = notifications.where((n) => n.type == 'ad_approved').toList();
        break;
      case 'ad_rejected':
        filtered = notifications.where((n) => n.type == 'ad_rejected').toList();
        break;
      case 'ad_pending':
        filtered = notifications.where((n) => n.type == 'ad_pending').toList();
        break;
      case 'new_inquiry':
        filtered = notifications.where((n) => n.type == 'new_inquiry').toList();
        break;
      default:
        filtered = notifications;
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'لا توجد إشعارات',
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
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notification = filtered[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(MerchantNotificationModel notification) {
    Color color;
    IconData icon;
    String statusText;

    switch (notification.type) {
      case 'ad_approved':
        color = Colors.green;
        icon = Icons.check_circle;
        statusText = 'تمت الموافقة';
        break;
      case 'ad_rejected':
        color = Colors.red;
        icon = Icons.cancel;
        statusText = 'لم يتم القبول';
        break;
      case 'ad_pending':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        statusText = 'بانتظار الموافقة';
        break;
      case 'new_inquiry':
        color = Colors.blue;
        icon = Icons.question_answer;
        statusText = 'استفسار جديد';
        break;
      default:
        color = Colors.grey;
        icon = Icons.notifications;
        statusText = 'إشعار';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // تحديد كمقروء
          if (!notification.isRead) {
            await _notificationService.markMerchantNotificationAsRead(
              notification.id,
            );
          }
          // الانتقال لتفاصيل الإعلان إذا موجود
          if (notification.adId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdDetailsScreen(adId: notification.adId!),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade200
                  : color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الأيقونة
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              // المحتوى
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // زر الحذف
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[500]),
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _notificationService.deleteMerchantNotification(
                      notification.id,
                    );
                  } else if (value == 'mark_read') {
                    await _notificationService.markMerchantNotificationAsRead(
                      notification.id,
                    );
                  }
                },
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Text('تحديد كمقروء'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('حذف'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllMerchantNotificationsAsRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديد جميع الإشعارات كمقروءة'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _addTestNotifications() async {
    await _notificationService.createTestMerchantNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إضافة إشعارات تجريبية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح جميع الإشعارات'),
        content: const Text('هل أنت متأكد من حذف جميع الإشعارات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('مسح الكل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _notificationService.clearAllMerchantNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم مسح جميع الإشعارات'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
