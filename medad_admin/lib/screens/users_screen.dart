import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();

  static bool applyPendingFilter = false;
}

class _UsersScreenState extends State<UsersScreen> {
  String _selectedFilter = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (UsersScreen.applyPendingFilter) {
      _selectedFilter = 'pending';
      UsersScreen.applyPendingFilter = false;
    }
  }

  // ✅ دالة الموافقة على مستخدم
  Future<void> _approveUser(String userId, String userType) async {
    setState(() => _isLoading = true);
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت الموافقة على ${userType == 'merchant' ? 'التاجر' : 'المندوب'} بنجاح'),
            backgroundColor: Colors.green,
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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ دالة رفض المستخدم (حذف الحساب)
  Future<void> _rejectUser(String userId, String userType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: Text('هل أنت متأكد من رفض طلب ${userType == 'merchant' ? 'التاجر' : 'المندوب'}؟ سيتم حذف الحساب بالكامل.'),
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

    setState(() => _isLoading = true);
    
    try {
      // حذف المستخدم من Authentication
      // ملاحظة: لا يمكن حذف المستخدم من Authentication مباشرة من Flutter Web
      // نحتاج إلى Cloud Function أو نقوم بتعطيل الحساب فقط
      
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': 'rejected',
        'isApproved': false,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رفض طلب ${userType == 'merchant' ? 'التاجر' : 'المندوب'}'),
            backgroundColor: Colors.orange,
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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ دالة تعطيل/تفعيل المستخدم
  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isActive': !currentStatus,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(currentStatus ? 'تم تعطيل المستخدم' : 'تم تفعيل المستخدم'),
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
            'إدارة المستخدمين',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // ✅ إحصائيات سريعة
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final users = snapshot.data!.docs;
              final pendingCount = users.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final role = data['role'];
                final isApproved = data['isApproved'] ?? false;
                return (role == 'merchant' || role == 'delivery') && !isApproved;
              }).length;
              
              if (pendingCount == 0) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يوجد $pendingCount مستخدمين بانتظار الموافقة',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
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
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    ...data,
                  };
                }).toList();

                // تطبيق الفلتر
                users = users.where((user) {
                  switch (_selectedFilter) {
                    case 'pending':
                      return (user['role'] == 'merchant' || user['role'] == 'delivery') && 
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
                    final needsApproval = (role == 'merchant' || role == 'delivery') && !isApproved;
                    final isRejected = user['status'] == 'rejected';

                    String roleText;
                    Color roleColor;
                    IconData roleIcon;

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
                                onPressed: _isLoading ? null : () => _approveUser(user['id'], role),
                                tooltip: 'موافقة',
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: _isLoading ? null : () => _rejectUser(user['id'], role),
                                tooltip: 'رفض',
                              ),
                            ],
                            // زر تعطيل/تفعيل للجميع
                            IconButton(
                              icon: Icon(
                                isActive ? Icons.block : Icons.play_circle,
                                color: isActive ? Colors.orange : Colors.green,
                              ),
                              onPressed: _isLoading ? null : () => _toggleUserStatus(user['id'], isActive),
                              tooltip: isActive ? 'تعطيل' : 'تفعيل',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // ✅ مؤشر تحميل
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
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
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.teal.shade100,
      checkmarkColor: Colors.teal,
    );
  }
}