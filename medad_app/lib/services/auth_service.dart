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
  Future<void> sendOTP(String phoneNumber, Function(String) onCodeSent) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
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

  // حفظ بيانات المستخدم
  Future<void> saveUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toJson());
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