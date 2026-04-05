import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'waiting_approval_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isChecking = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _checkUserApproval();
  }

  Future<void> _checkUserApproval() async {
    final authService = AuthService();
    final userData = await authService.getCurrentUserData();

    if (!mounted) return;

    if (userData == null) {
      _forceSignOut();
      return;
    }

    if (userData.role != 'customer' && !userData.isApproved) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingApprovalScreen(
              userId: userData.uid,
              role: userData.role,
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isChecking = false);
  }

  // ✅ دالة تسجيل الخروج القسرية
  void _forceSignOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // ✅ دالة تسجيل الخروج الرئيسية مع حوار التأكيد
  Future<void> _signOut() async {
    // ✅ عرض حوار تأكيد قبل تسجيل الخروج
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'تسجيل الخروج',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // إذا لم يؤكد المستخدم، نخرج من الدالة
    if (shouldLogout != true) return;

    if (_isLoggingOut) return;
    
    setState(() => _isLoggingOut = true);
    
    try {
      // تسجيل الخروج من Firebase
      await FirebaseAuth.instance.signOut();
      
      // الانتقال إلى شاشة تسجيل الدخول مع إزالة جميع الشاشات السابقة
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
      // حتى لو حدث خطأ، حاول الانتقال إلى شاشة تسجيل الدخول
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدد'),
        actions: [
          _isLoggingOut
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _signOut,
                  tooltip: 'تسجيل الخروج',
                ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'تم تسجيل الدخول بنجاح!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'هذه هي الشاشة الرئيسية للتطبيق',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('قريباً: قسم الإعلانات')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('إضافة إعلان جديد'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}