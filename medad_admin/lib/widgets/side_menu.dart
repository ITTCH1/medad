import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final void Function(int, {String? filter}) onItemSelected;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: const Color(0xFF2C3E50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: const Text(
              'مدد - لوحة التحكم',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white24),
          _buildMenuItem(
            index: 0,
            icon: Icons.dashboard,
            title: 'لوحة التحكم',
          ),
          _buildMenuItem(
            index: 1,
            icon: Icons.people,
            title: 'المستخدمين',
          ),
          _buildMenuItem(
            index: 2,
            icon: Icons.image,
            title: 'الإعلانات',
          ),
          const Spacer(),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const Scaffold()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final isSelected = selectedIndex == index;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.teal : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.teal : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.white10 : null,
      onTap: () => onItemSelected(index),
    );
  }
}