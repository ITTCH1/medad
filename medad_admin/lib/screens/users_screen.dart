import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersScreen extends StatefulWidget {
  final String initialFilter;

  const UsersScreen({super.key, this.initialFilter = 'all'});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(UsersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() => _selectedFilter = widget.initialFilter);
    }
  }

  // ✅ دالة الموافقة على مستخدم
  Future<void> _approveUser(String userId, String userType) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isApproved': true,
        'status': 'active',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('📢 Approving user: $userId as $userType');

      // إنشاء إشعار للمستخدم (نستخدم customer_notifications كإشعار نظام)
      await FirebaseFirestore.instance.collection('customer_notifications').add({
        'customerId': userId,
        'type': 'system',
        'title': 'تمت الموافقة على حسابك ✅',
        'message': 'تمت الموافقة على حسابك كـ ${userType == 'merchant' ? 'تاجر' : 'مندوب'}. يمكنك الآن استخدام جميع المزايا.',
        'isRead': false,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint('✅ Approval notification created for user: $userId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('تمت الموافقة على ${userType == 'merchant' ? 'التاجر' : 'المندوب'} بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error approving user: $e');
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

  // ✅ دالة رفض المستخدم (تعطيل الحساب)
  Future<void> _rejectUser(String userId, String userType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: Text(
          'هل أنت متأكد من رفض ${userType == 'merchant' ? 'طلب التاجر' : 'طلب المندوب'}؟ سيتم تعطيل الحساب.',
        ),
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
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': 'rejected',
        'isApproved': false,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('📢 Rejecting user: $userId as $userType');

      // إنشاء إشعار للمستخدم
      await FirebaseFirestore.instance.collection('customer_notifications').add({
        'customerId': userId,
        'type': 'system',
        'title': 'لم يتم قبول طلبك ❌',
        'message': 'لم يتم قبول طلبك كـ ${userType == 'merchant' ? 'تاجر' : 'مندوب'}. يرجى التواصل مع الدعم الفني.',
        'isRead': false,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint('✅ Rejection notification created for user: $userId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رفض طلب ${userType == 'merchant' ? 'التاجر' : 'المندوب'}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error rejecting user: $e');
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

  // ✅ دالة تعطيل/تفعيل المستخدم
  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': !currentStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus ? 'تم تعطيل المستخدم' : 'تم تفعيل المستخدم'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إدارة المستخدمين',
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
                  _buildFilterChip('التجار', 'merchants'),
                  const SizedBox(width: 4),
                  _buildFilterChip('المندوبين', 'delivery'),
                  const SizedBox(width: 4),
                  _buildFilterChip('العملاء', 'customers'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ✅ جدول المستخدمين
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {'id': doc.id, ...data};
                }).toList();

                // تطبيق الفلتر
                users = users.where((user) {
                  switch (_selectedFilter) {
                    case 'pending':
                      return (user['role'] == 'merchant' ||
                              user['role'] == 'delivery') &&
                          user['isApproved'] == false;
                    case 'merchants':
                      return user['role'] == 'merchant';
                    case 'delivery':
                      return user['role'] == 'delivery';
                    case 'customers':
                      return user['role'] == 'customer';
                    default:
                      return true;
                  }
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'pending'
                              ? 'لا يوجد مستخدمين بانتظار الموافقة'
                              : 'لا يوجد مستخدمين',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final role = user['role'];
                    final isApproved = user['isApproved'] ?? false;
                    final isActive = user['isActive'] ?? true;
                    final needsApproval =
                        (role == 'merchant' || role == 'delivery') && !isApproved;
                    final isRejected = user['status'] == 'rejected';

                    Color roleColor;
                    IconData roleIcon;
                    String roleText;

                    switch (role) {
                      case 'merchant':
                        roleText = 'تاجر';
                        roleColor = Colors.green;
                        roleIcon = Icons.store;
                        break;
                      case 'delivery':
                        roleText = 'مندوب';
                        roleColor = Colors.orange;
                        roleIcon = Icons.delivery_dining;
                        break;
                      default:
                        roleText = 'عميل';
                        roleColor = Colors.blue;
                        roleIcon = Icons.person;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: roleColor.withOpacity(0.2),
                          child: Icon(roleIcon, color: roleColor),
                        ),
                        title: Text(user['name'] ?? 'غير مكتمل'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['phone'] ?? ''),
                            Text(
                              roleText,
                              style: TextStyle(fontSize: 12, color: roleColor),
                            ),
                            if (needsApproval)
                              const Text(
                                'بانتظار الموافقة',
                                style: TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            if (isRejected)
                              const Text(
                                'تم الرفض',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ أزرار الموافقة والرفض للتجار والمندوبين
                            if (needsApproval) ...[
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => _approveUser(user['id'], role),
                                tooltip: 'موافقة',
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _rejectUser(user['id'], role),
                                tooltip: 'رفض',
                              ),
                            ],
                            // زر تعطيل/تفعيل للجميع
                            if (!needsApproval)
                              IconButton(
                                icon: Icon(
                                  isActive ? Icons.block : Icons.play_circle,
                                  color: isActive ? Colors.orange : Colors.green,
                                ),
                                onPressed: () => _toggleUserStatus(user['id'], isActive),
                                tooltip: isActive ? 'تعطيل' : 'تفعيل',
                              ),
                          ],
                        ),
                        onTap: () => _showUserDetails(user),
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

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['name'] ?? 'بيانات المستخدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('الدور', user['role'] ?? ''),
            _detailRow('الهاتف', user['phone'] ?? ''),
            if (user['email'] != null && user['email'].toString().isNotEmpty)
              _detailRow('البريد الإلكتروني', user['email']),
            _detailRow(
              'الحالة',
              user['isApproved'] == true ? 'مقبول' : 'بانتظار الموافقة',
            ),
            if (user['status'] != null && user['status'].toString().isNotEmpty)
              _detailRow('الحالة التفصيلية', user['status']),
            if (user['createdAt'] != null)
              _detailRow(
                'تاريخ التسجيل',
                _formatDate(user['createdAt']),
              ),
          ],
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as dynamic).toDate();
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
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
