import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  User? getCurrentUser() => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // إرسال رمز التحقق
  Future<void> sendOTP(
    String phoneNumber,
    Function(String) onCodeSent, {
    Function(UserCredential)? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCredential = await _auth.signInWithCredential(credential);
        // استدعاء دالة التحقق التلقائي إذا تم تمريرها
        if (onAutoVerified != null) {
          onAutoVerified(userCredential);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        throw Exception('فشل إرسال الرمز: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // التحقق من الرمز
  Future<UserCredential> verifyOTP(String verificationId, String otp) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await _auth.signInWithCredential(credential);
  }

  // تحديث التوكن (يمنع مشاكل sign-out)
  Future<void> refreshUserToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.getIdToken(true);
      if (kDebugMode) {
        print('✅ Token refreshed for user: ${user.uid}');
      }
    }
  }

  // ربط الحساب بكلمة مرور (بعد إنشاء الحساب بـ OTP)
  Future<void> linkPasswordToAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل');

    // فحص الـ providers المرتبطة بالفعل
    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) throw Exception('المستخدم غير مسجل');

    // التحقق إذا كان الحساب مرتبط بالفعل بـ Email/Password
    final providerData = refreshedUser.providerData;
    final hasEmailProvider = providerData.any(
      (info) => info.providerId == 'password',
    );

    if (hasEmailProvider) {
      // الحساب مرتبط بالفعل - نكتفي بالتحديث بدون ربط
      debugPrint('✅ الحساب مرتبط بالفعل بـ Email/Password');
      return;
    }

    // إنشاء بريد إلكتروني افتراضي من رقم الهاتف
    final email = '${user.phoneNumber}@medad.app';

    // إنشاء بيانات اعتماد البريد/كلمة المرور
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    // ربط الحساب الحالي بالبريد/كلمة المرور
    await user.linkWithCredential(credential);
    debugPrint('✅ تم ربط الحساب بكلمة المرور بنجاح');
  }

  // تسجيل الدخول بالهاتف وكلمة المرور
  Future<UserCredential> signInWithPhoneAndPassword(
    String phone,
    String password,
  ) async {
    // إنشاء بريد إلكتروني افتراضي من رقم الهاتف
    final email = '$phone@medad.app';

    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // حفظ بيانات المستخدم (مع merge لتجنب الكتابة الكاملة)
  Future<void> saveUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(
      user.toJson(),
      SetOptions(merge: true),
    );
  }

  // جلب بيانات المستخدم الحالي
  Future<UserModel?> getCurrentUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, user.uid);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user data: $e');
      }
    }
    return null;
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }
}