import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user_model.dart';
import 'screens/common/home_screen.dart';
import 'screens/common/waiting_approval_screen.dart';
import 'screens/auth/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<UserModel?> _getUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, uid);
      }
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // حالة التحميل الأولية
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // المستخدم غير مسجل → شاشة تسجيل الدخول
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        // المستخدم مسجل → فحص حالة حسابه
        return FutureBuilder<UserModel?>(
          future: _getUserData(authSnapshot.data!.uid),
          builder: (context, userSnapshot) {
            // حالة التحميل
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // بيانات المستخدم غير موجودة → اختيار الدور
            if (!userSnapshot.hasData || userSnapshot.data == null) {
              return LoginScreen();
            }

            final user = userSnapshot.data!;

            // الحساب مرفوض → تسجيل خروج والعودة لتسجيل الدخول
            if (user.status == 'rejected') {
              FirebaseAuth.instance.signOut();
              return const LoginScreen();
            }

            // الحساب غير نشط → تسجيل خروج
            if (!user.isActive) {
              FirebaseAuth.instance.signOut();
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 80, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'تم تعطيل حسابك',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يرجى التواصل مع الدعم الفني',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text('تسجيل الخروج'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // الحساب بانتظار الموافقة → شاشة الانتظار
            if (!user.isApproved) {
              return WaitingApprovalScreen(
                userId: user.uid,
                role: user.role,
              );
            }

            // الحساب موافق عليه ونشط → الشاشة الرئيسية
            return const HomeScreen();
          },
        );
      },
    );
  }
}
