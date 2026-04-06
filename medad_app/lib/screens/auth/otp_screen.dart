import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'role_selection_screen.dart';
import '../common/waiting_approval_screen.dart';
import '../common/home_screen.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phone;

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phone,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    final String otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رمز التحقق المكون من 6 أرقام')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final UserCredential userCredential = await authService.verifyOTP(
        widget.verificationId,
        otp,
      );

      await authService.refreshUserToken();

      if (!mounted) return;

      final userData = await authService.getCurrentUserData();

      if (!mounted) return;

      if (userData == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoleSelectionScreen(
              uid: userCredential.user!.uid,
              phone: widget.phone,
            ),
          ),
        );
        return;
      }

      if (userData.role == 'customer' || userData.isApproved) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingApprovalScreen(
              userId: userCredential.user!.uid,
              role: userData.role,
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('❌ خطأ في التحقق: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('رمز غير صحيح أو حدث خطأ: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد الرمز'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(  // ✅ إضافة SingleChildScrollView لمنع التجاوز
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.sms,
                size: 80,
                color: Colors.teal.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                'تم إرسال رمز إلى',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.phone,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'رمز التحقق',
                  hintText: '000000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.pin),
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'تحقق',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: const Text('إعادة إرسال الرمز'),
              ),
              const SizedBox(height: 20), // ✅ مسافة إضافية في الأسفل
            ],
          ),
        ),
      ),
    );
  }
}