import 'package:flutter/material.dart';
import '../common/profile_setup_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String uid;
  final String phone;

  const RoleSelectionScreen({super.key, required this.uid, required this.phone});

  final List<Map<String, dynamic>> roles = const [
    {'title': 'عميل', 'icon': Icons.person_outline, 'role': 'customer', 'color': Color(0xFF667eea), 'bgColor': Color(0xFFE8EAF6), 'description': 'تصفح الإعلانات والخدمات'},
    {'title': 'تاجر', 'icon': Icons.storefront_outlined, 'role': 'merchant', 'color': Color(0xFF43e97b), 'bgColor': Color(0xFFE8F5E9), 'description': 'أضف منتجاتك وإعلاناتك'},
    {'title': 'مندوب توصيل', 'icon': Icons.delivery_dining_outlined, 'role': 'delivery', 'color': Color(0xFFf093fb), 'bgColor': Color(0xFFFCE4EC), 'description': 'وصل الطلبات للعملاء'},
  ];

  void _selectRole(BuildContext context, String role) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileSetupScreen(uid: uid, phone: phone, selectedRole: role)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // الأيقونة
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade700]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
                child: const Icon(Icons.group_add, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('اختر نوع الحساب', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text('كيف ستستخدم تطبيق مدد؟', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              const SizedBox(height: 32),

              // الأدوار
              Expanded(
                child: ListView.separated(
                  itemCount: roles.length,
                  separatorBuilder: (ctx, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final role = roles[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectRole(context, role['role']!),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: role['bgColor'], borderRadius: BorderRadius.circular(14)),
                                child: Icon(role['icon'], color: role['color'], size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(role['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(role['description']!, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
