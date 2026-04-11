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
  String _usersFilter = 'all';

  void selectNavItem(int index, {String? filter}) {
    setState(() {
      _selectedIndex = index;
      if (filter != null) _usersFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            selectedIndex: _selectedIndex,
            onItemSelected: selectNavItem,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                DashboardContent(onNavigate: selectNavItem),
                UsersScreen(initialFilter: _usersFilter),
                const AdsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

typedef NavCallback = void Function(int index, {String? filter});

class DashboardContent extends StatefulWidget {
  final NavCallback onNavigate;

  const DashboardContent({super.key, required this.onNavigate});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(),
                  const SizedBox(height: 32),
                  const Text(
                    'آخر المستخدمين المسجلين',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 400,
                    child: _buildRecentUsers(),
                  ),
                ],
              ),
            ),
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

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('ads').snapshots(),
          builder: (context, adsSnapshot) {
            final totalAds = adsSnapshot.hasData ? adsSnapshot.data!.docs.length : 0;
            final pendingAds = adsSnapshot.hasData ? adsSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['isApproved'] ?? false) == false;
            }).length : 0;

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
                  onTap: () => widget.onNavigate(1),
                ),
                _buildStatCard(
                  title: 'الإعلانات',
                  count: totalAds.toString(),
                  icon: Icons.image,
                  color: Colors.green,
                  onTap: () => widget.onNavigate(2),
                ),
                _buildStatCard(
                  title: 'إعلانات بانتظار الموافقة',
                  count: pendingAds.toString(),
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                  onTap: () => widget.onNavigate(2),
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

            Color roleColor;
            IconData roleIcon;

            switch (role) {
              case 'merchant':
                roleColor = Colors.green;
                roleIcon = Icons.store;
                break;
              case 'delivery':
                roleColor = Colors.orange;
                roleIcon = Icons.delivery_dining;
                break;
              default:
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
}