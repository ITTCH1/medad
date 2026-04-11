import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';
import 'create_account_screen.dart';
import 'role_selection_screen.dart';
import '../common/waiting_approval_screen.dart';
import '../common/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signInWithPassword() async {
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم الجوال')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال كلمة المرور')),
      );
      return;
    }

    // إضافة +967 إذا لم يكن موجوداً
    if (!phone.startsWith('+')) {
      phone = '+967$phone';
    }

    setState(() => _isLoading = true);

    try {
      await Provider.of<AuthService>(context, listen: false)
          .signInWithPhoneAndPassword(phone, password);

      if (!mounted) return;

      // فحص حالة الحساب بعد تسجيل الدخول
      final userData = await Provider.of<AuthService>(context, listen: false).getCurrentUserData();

      if (!mounted) return;

      // المستخدم غير موجود في Firestore (محذوف)
      if (userData == null) {
        await Provider.of<AuthService>(context, listen: false).signOut();
        if (!mounted) return;
        _showDeletedAccountDialog();
        setState(() => _isLoading = false);
        return;
      }

      // الحساب معطل
      if (!userData.isActive) {
        await Provider.of<AuthService>(context, listen: false).signOut();
        if (!mounted) return;
        _showDisabledAccountDialog();
        setState(() => _isLoading = false);
        return;
      }

      // الحساب مرفوض
      if (userData.status == 'rejected') {
        await Provider.of<AuthService>(context, listen: false).signOut();
        if (!mounted) return;
        _showRejectedAccountDialog();
        setState(() => _isLoading = false);
        return;
      }

      // الحساب بانتظار الموافقة
      if (!userData.isApproved) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => WaitingApprovalScreen(
              userId: Provider.of<AuthService>(context, listen: false).currentUser!.uid,
              role: userData.role,
            ),
          ),
          (route) => false,
        );
        setState(() => _isLoading = false);
        return;
      }

      // نجاح تسجيل الدخول - التوجه إلى الشاشة الرئيسية
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'فشل تسجيل الدخول';
      if (e.toString().contains('user-not-found') ||
          e.toString().contains('wrong-password') ||
          e.toString().contains('credential is incorrect')) {
        errorMsg = 'رقم الجوال أو كلمة المرور غير صحيحة';
      } else if (e.toString().contains('account-exists-with-different-credential')) {
        errorMsg = 'هذا الحساب موجود بالفعل. استخدم تسجيل الدخول برمز التحقق';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDisabledAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red[700], size: 28),
            const SizedBox(width: 8),
            const Text('تم تعطيل حسابك'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تم تعطيل حسابك من قبل الإدارة.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يرجى مراجعة الدعم الفني لمعرفة السبب.',
                      style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showRejectedAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.orange[700], size: 28),
            const SizedBox(width: 8),
            const Text('تم رفض حسابك'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تم رفض طلبك من قبل الإدارة.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يرجى مراجعة الدعم الفني.',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showDeletedAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.account_circle, color: Colors.blue[700], size: 28),
            const SizedBox(width: 8),
            const Text('إنشاء حساب جديد'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لم يتم العثور على بيانات حسابك. يرجى إنشاء حساب جديد.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم حذف بياناتك من النظام. يمكنك إنشاء حساب جديد بسهولة.',
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateAccountScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ),
            child: const Text('إنشاء حساب جديد'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOTP() async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم الجوال')),
      );
      return;
    }

    // فقط الأرقام
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الجوال يجب أن يحتوي على أرقام فقط')),
      );
      return;
    }

    // تحقق من طول الرقم (لليمن: 7-9 أرقام)
    if (phone.length < 7 || phone.length > 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الجوال يجب أن يكون بين 7 و 9 أرقام')),
      );
      return;
    }

    if (!phone.startsWith('+')) {
      phone = '+967$phone';
    }

    setState(() => _isLoading = true);

    try {
      await Provider.of<AuthService>(context, listen: false).sendOTP(
        phone,
        (verificationId) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                verificationId: verificationId,
                phone: phone,
              ),
            ),
          );
        },
        onAutoVerified: (userCredential) async {
          // التحقق التلقائي (Android) - الانتقال مباشرة للتطبيق
          if (!mounted) return;

          final authService = Provider.of<AuthService>(context, listen: false);
          final userData = await authService.getCurrentUserData();

          if (!mounted) return;

          Widget targetScreen;
          if (userData == null) {
            // مستخدم جديد → اختيار الدور
            targetScreen = RoleSelectionScreen(
              uid: userCredential.user!.uid,
              phone: phone,
            );
          } else if (userData.status == 'rejected' || !userData.isActive) {
            // مرفوض أو معطل → تسجيل خروج
            await authService.signOut();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  userData.status == 'rejected'
                      ? 'تم رفض طلبك. يرجى التواصل مع الدعم الفني.'
                      : 'تم تعطيل حسابك.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
            return;
          } else if (!userData.isApproved) {
            // بانتظار الموافقة (تاجر/مندوب)
            targetScreen = WaitingApprovalScreen(
              userId: userCredential.user!.uid,
              role: userData.role,
            );
          } else {
            // موافق عليه → الشاشة الرئيسية
            targetScreen = const HomeScreen();
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
            (route) => false,
          );
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // شعار التطبيق
              Image.asset(
                'assets/logo.png',
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Color(0xFF0D47A1),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              
              // نص الترحيب
              const Text(
                'أهلاً بك',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // حقل رقم الموبايل
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFB0BEC5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'اكتب رقم الموبايل',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    labelText: 'رقم الموبايل *',
                    labelStyle: const TextStyle(color: Color(0xFF0D47A1)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: const Icon(Icons.phone_android, color: Color(0xFF0D47A1)),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // حقل كلمة المرور
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFB0BEC5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'اكتب كلمة المرور',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    labelText: 'كلمة المرور *',
                    labelStyle: const TextStyle(color: Color(0xFF0D47A1)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0D47A1)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  keyboardType: TextInputType.visiblePassword,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // نسيت كلمة المرور
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: إرسال رمز التحقق لإعادة تعيين كلمة المرور
                    _sendOTP();
                  },
                  child: const Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(
                      color: Color(0xFF0D47A1),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // زر تسجيل الدخول
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D47A1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: _signInWithPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'تسجيل دخول',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
              
              const SizedBox(height: 30),
              
              // إنشاء حساب جديد
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ليس لديك حساب؟',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF616161),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateAccountScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'انشاء حساب جديد',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Divider
              Divider(color: Colors.grey[300], thickness: 1),
              
              const SizedBox(height: 20),
              
              // روابط الدعم
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSupportIcon(Icons.chat_bubble_outline, 'الدعم الفني'),
                  _buildSupportIcon(Icons.headset_mic, 'خدمة العملاء'),
                  _buildSupportIcon(Icons.info_outline, 'عن التطبيق'),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0D47A1), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF616161),
          ),
        ),
      ],
    );
  }
}
