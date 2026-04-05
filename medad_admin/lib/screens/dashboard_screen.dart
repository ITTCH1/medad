import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/side_menu.dart';
import 'users_screen.dart';
import 'ads_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardContent(),
    const UsersScreen(),
    const AdsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لوحة التحكم',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // عرض الإحصائيات باستخدام StreamBuilder
          _buildStatsSection(),
          const SizedBox(height: 32),
          const Text(
            'آخر المستخدمين المسجلين',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildRecentUsers(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        if (!usersSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = usersSnapshot.data!.docs;
        final totalUsers = users.length;
        
        // حساب عدد التجار والمندوبين بانتظار الموافقة
        final pendingUsers = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final role = data['role'];
          final isApproved = data['isApproved'] ?? false;
          return (role == 'merchant' || role == 'delivery') && !isApproved;
        }).length;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('ads').snapshots(),
          builder: (context, adsSnapshot) {
            final totalAds = adsSnapshot.hasData ? adsSnapshot.data!.docs.length : 0;

            return GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  title: 'المستخدمين',
                  count: totalUsers.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                  onTap: () {
                    // تغيير القائمة المختارة إلى المستخدمين
                    _changeToUsersScreen(context);
                  },
                ),
                _buildStatCard(
                  title: 'الإعلانات',
                  count: totalAds.toString(),
                  icon: Icons.image,
                  color: Colors.green,
                  onTap: () {
                    _changeToAdsScreen(context);
                  },
                ),
                _buildStatCard(
                  title: 'بانتظار الموافقة',
                  count: pendingUsers.toString(),
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                  onTap: () {
                    // تغيير القائمة المختارة إلى المستخدمين مع فلتر للمنتظرين
                    _changeToUsersScreenWithPendingFilter(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                count,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(title, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentUsers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        if (users.isEmpty) {
          return const Center(child: Text('لا يوجد مستخدمين بعد'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            final role = data['role'] ?? 'customer';
            final isApproved = data['isApproved'] ?? false;
            final name = data['name'] ?? 'مستخدم جديد';
            final phone = data['phone'] ?? '';

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
                title: Text(name),
                subtitle: Text(phone),
                trailing: (role == 'merchant' || role == 'delivery') && !isApproved
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'بانتظار الموافقة',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  void _changeToUsersScreen(BuildContext context) {
    // العثور على SideMenu وتغيير الفهرس
    final state = context.findAncestorStateOfType<_DashboardScreenState>();
    if (state != null) {
      state.setState(() {
        state._selectedIndex = 1;
      });
    }
  }

  void _changeToAdsScreen(BuildContext context) {
    final state = context.findAncestorStateOfType<_DashboardScreenState>();
    if (state != null) {
      state.setState(() {
        state._selectedIndex = 2;
      });
    }
  }

  void _changeToUsersScreenWithPendingFilter(BuildContext context) {
    final state = context.findAncestorStateOfType<_DashboardScreenState>();
    if (state != null) {
      state.setState(() {
        state._selectedIndex = 1;
      });
      // إرسال إشارة لشاشة المستخدمين لتطبيق فلتر المنتظرين
      // يمكن استخدام Provider أو Notification
      Future.delayed(const Duration(milliseconds: 100), () {
        UsersScreen.applyPendingFilter = true;
      });
    }
  }
}