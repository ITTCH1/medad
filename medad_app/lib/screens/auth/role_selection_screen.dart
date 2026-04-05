import 'package:flutter/material.dart';
import '../common/profile_setup_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String uid;
  final String phone;

  const RoleSelectionScreen({
    super.key,
    required this.uid,
    required this.phone,
  });

  final List<Map<String, dynamic>> roles = const [
    {
      'title': 'عميل',
      'icon': Icons.person,
      'role': 'customer',
      'color': Colors.blue,
      'description': 'اطلب الطعام والخدمات'
    },
    {
      'title': 'تاجر',
      'icon': Icons.store,
      'role': 'merchant',
      'color': Colors.green,
      'description': 'أضف منتجاتك وإعلاناتك'
    },
    {
      'title': 'مندوب',
      'icon': Icons.delivery_dining,
      'role': 'delivery',
      'color': Colors.orange,
      'description': 'وصل الطلبات للعملاء'
    },
  ];

  void _selectRole(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSetupScreen(
          uid: uid,
          phone: phone,
          selectedRole: role,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر نوع الحساب'),
        // ✅ السماح بالرجوع (لن يتم تسجيل خروج)
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'كيف ستستخدم تطبيق مدد؟',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            ...roles.map((role) => Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (role['color'] as Color).withOpacity(0.1),
                      child: Icon(role['icon'], color: role['color'], size: 28),
                    ),
                    title: Text(
                      role['title']!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(role['description']!),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _selectRole(context, role['role']!),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}