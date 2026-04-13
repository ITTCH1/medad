import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'role_selection_screen.dart';
import '../common/waiting_approval_screen.dart';
import '../common/home_screen.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phone;

  const OTPScreen({super.key, required this.verificationId, required this.phone});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _countdown = 60;

  @override
  void initState() { super.initState(); _startCountdown(); }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) { setState(() => _countdown--); _startCountdown(); }
      else if (mounted) setState(() => _canResend = true);
    });
  }

  @override
  void dispose() { _otpController.dispose(); super.dispose(); }

  Future<void> _resendOTP() async {
    if (!_canResend || _isLoading) return;
    setState(() { _isLoading = true; _canResend = false; _countdown = 60; });
    try {
      await Provider.of<AuthService>(context, listen: false).sendOTP(widget.phone, (_) {});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رمز التحقق بنجاح'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) { setState(() => _canResend = true); _showError('فشل إعادة الإرسال: $e'); }
    } finally {
      if (mounted) { setState(() => _isLoading = false); _startCountdown(); }
    }
  }

  Future<void> _verifyOTP() async {
    final String otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) { _showError('الرجاء إدخال رمز التحقق المكون من 6 أرقام'); return; }
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userCredential = await authService.verifyOTP(widget.verificationId, otp);
      await authService.refreshUserToken();
      if (!mounted) return;

      final userData = await authService.getCurrentUserData();
      if (!mounted) return;

      if (userData == null) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => RoleSelectionScreen(uid: userCredential.user!.uid, phone: widget.phone)), (_) => false);
        return;
      }

      if (!userData.isActive) {
        await authService.signOut();
        if (!mounted) return;
        _showStatusDialog('تم تعطيل حسابك', 'تم تعطيل حسابك من قبل الإدارة. يرجى مراجعة الدعم الفني.', Colors.red);
        return;
      }
      if (userData.status == 'rejected') {
        await authService.signOut();
        if (!mounted) return;
        _showStatusDialog('تم رفض حسابك', 'تم رفض طلبك من قبل الإدارة. يرجى مراجعة الدعم الفني.', Colors.orange);
        return;
      }

      if (userData.role == 'customer' || userData.isApproved) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
      } else {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => WaitingApprovalScreen(userId: userCredential.user!.uid, role: userData.role)), (_) => false);
      }
    } catch (error) {
      debugPrint('❌ خطأ في التحقق: $error');
      if (mounted) _showError('رمز غير صحيح أو حدث خطأ');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
  }

  void _showStatusDialog(String title, String message, Color color) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [Icon(Icons.info_outline, color: color, size: 28), const SizedBox(width: 8), Text(title)]),
      content: Text(message),
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
              // أيقونة OTP
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade700]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
                child: const Icon(Icons.sms, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('تأكيد الرمز', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text('تم إرسال رمز إلى', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              Text(widget.phone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal)),
              const SizedBox(height: 32),

              // حقل OTP
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                child: TextField(
                  controller: _otpController, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '000000', hintStyle: TextStyle(color: Colors.grey[300], fontSize: 24, letterSpacing: 8),
                    border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                ),
              ),
              const SizedBox(height: 24),

              // زر التحقق
              _isLoading ? const CircularProgressIndicator(color: Colors.teal) : Container(
                width: double.infinity, height: 54,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade600, Colors.teal.shade800]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))]),
                child: ElevatedButton(onPressed: _verifyOTP, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('تحقق', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
              const SizedBox(height: 16),

              // إعادة الإرسال
              TextButton(
                onPressed: _canResend && !_isLoading ? _resendOTP : null,
                child: Text(_canResend ? 'إعادة إرسال الرمز' : 'إعادة إرسال الرمز ($_countdown ث)', style: TextStyle(color: _canResend ? Colors.teal : Colors.grey[400], fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
