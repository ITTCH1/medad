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
      _showError('الرجاء إدخال رقم الجوال');
      return;
    }
    if (password.isEmpty) {
      _showError('الرجاء إدخال كلمة المرور');
      return;
    }
    if (!phone.startsWith('+')) phone = '+967$phone';

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthService>(context, listen: false)
          .signInWithPhoneAndPassword(phone, password);
      if (!mounted) return;

      final userData = await Provider.of<AuthService>(context, listen: false).getCurrentUserData();
      if (!mounted) return;

      if (userData == null) {
        await Provider.of<AuthService>(context, listen: false).signOut();
        if (!mounted) return;
        _showDeletedAccountDialog();
        setState(() => _isLoading = false);
        return;
      }
      if (!userData.isActive) {
        await Provider.of<AuthService>(context, listen: false).signOut();
        if (!mounted) return;
        _showDisabledAccountDialog();
        setState(() => _isLoading = false);
        return;
      }
      if (userData.status == 'rejected') {
        await Provider.of<AuthService>(context, listen: false).signOut();
        if (!mounted) return;
        _showRejectedAccountDialog();
        setState(() => _isLoading = false);
        return;
      }
      if (!userData.isApproved) {
        Navigator.pushAndRemoveUntil(
          context,
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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'رقم الجوال أو كلمة المرور غير صحيحة';
      if (e.toString().contains('account-exists-with-different-credential')) {
        errorMsg = 'هذا الحساب موجود بالفعل. استخدم تسجيل الدخول برمز التحقق';
      }
      _showError(errorMsg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOTP() async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) { _showError('الرجاء إدخال رقم الجوال'); return; }
    if (!RegExp(r'^\d+$').hasMatch(phone)) { _showError('رقم الجوال يجب أن يحتوي على أرقام فقط'); return; }
    if (phone.length < 7 || phone.length > 9) { _showError('رقم الجوال يجب أن يكون بين 7 و 9 أرقام'); return; }
    if (!phone.startsWith('+')) phone = '+967$phone';

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthService>(context, listen: false).sendOTP(
        phone,
        (verificationId) {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => OTPScreen(verificationId: verificationId, phone: phone),
          ));
        },
        onAutoVerified: (userCredential) async {
          if (!mounted) return;
          final authService = Provider.of<AuthService>(context, listen: false);
          final userData = await authService.getCurrentUserData();
          if (!mounted) return;

          Widget targetScreen;
          if (userData == null) {
            targetScreen = RoleSelectionScreen(uid: userCredential.user!.uid, phone: phone);
          } else if (userData.status == 'rejected' || !userData.isActive) {
            await authService.signOut();
            if (!mounted) return;
            _showError(userData.status == 'rejected' ? 'تم رفض طلبك' : 'تم تعطيل حسابك');
            setState(() => _isLoading = false);
            return;
          } else if (!userData.isApproved) {
            targetScreen = WaitingApprovalScreen(userId: userCredential.user!.uid, role: userData.role);
          } else {
            targetScreen = const HomeScreen();
          }
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => targetScreen), (route) => false);
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _showDeletedAccountDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [Icon(Icons.account_circle_outlined, color: Colors.blue[700], size: 28), const SizedBox(width: 8), const Text('إنشاء حساب جديد')]),
      content: const Text('لم يتم العثور على بيانات حسابك. يرجى إنشاء حساب جديد.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً')),
        ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAccountScreen())); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white), child: const Text('إنشاء حساب جديد')),
      ],
    ));
  }

  void _showDisabledAccountDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [Icon(Icons.block, color: Colors.red[700], size: 28), const SizedBox(width: 8), const Text('تم تعطيل حسابك')]),
      content: const Text('تم تعطيل حسابك من قبل الإدارة. يرجى مراجعة الدعم الفني.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
    ));
  }

  void _showRejectedAccountDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [Icon(Icons.cancel, color: Colors.orange[700], size: 28), const SizedBox(width: 8), const Text('تم رفض حسابك')]),
      content: const Text('تم رفض طلبك من قبل الإدارة. يرجى مراجعة الدعم الفني.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // الشعار
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade700]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: const Icon(Icons.storefront, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('مرحباً بك', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text('سجّل دخولك للمتابعة', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
              const SizedBox(height: 40),

              // حقل رقم الموبايل
              _buildTextField(_phoneController, 'رقم الموبايل', 'اكتب رقم الموبايل', Icons.phone_android, TextInputType.phone),
              const SizedBox(height: 16),

              // حقل كلمة المرور
              _buildTextField(
                _passwordController, 'كلمة المرور', 'اكتب كلمة المرور', Icons.lock_outline, TextInputType.visiblePassword,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
              ),

              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _sendOTP, child: Text('نسيت كلمة المرور؟', style: TextStyle(color: Colors.teal, fontSize: 14, fontWeight: FontWeight.w500)))),
              const SizedBox(height: 24),

              // زر تسجيل الدخول
              _isLoading ? const CircularProgressIndicator(color: Colors.teal) : Container(
                width: double.infinity, height: 54,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade600, Colors.teal.shade800]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))]),
                child: ElevatedButton(onPressed: _signInWithPassword, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('تسجيل دخول', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
              const SizedBox(height: 24),

              // إنشاء حساب
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('ليس لديك حساب؟', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAccountScreen())), child: const Text('انشاء حساب جديد', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal))),
              ]),
              const SizedBox(height: 40),

              Divider(color: Colors.grey[200]),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _buildSupportItem(Icons.chat_bubble_outline, 'الدعم الفني'),
                _buildSupportItem(Icons.headset_mic, 'خدمة العملاء'),
                _buildSupportItem(Icons.info_outline, 'عن التطبيق'),
              ]),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, TextInputType keyboardType, {bool obscureText = false, Widget? suffixIcon}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: controller, keyboardType: keyboardType, obscureText: obscureText, textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label, labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
          hintText: hint, hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.teal), suffixIcon: suffixIcon,
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSupportItem(IconData icon, String label) {
    return Column(children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: Colors.teal, size: 24)),
      const SizedBox(height: 8), Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }
}
