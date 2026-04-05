import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';  // ✅ أضف هذا السطر
import 'screens/auth/login_screen.dart';
import 'screens/common/home_screen.dart';
import 'screens/common/waiting_approval_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // تعطيل App Check للتطوير (يمنع مشكلة sign-out التلقائي)
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'مدد',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          fontFamily: 'Cairo',
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError) {
              debugPrint('❌ Auth error: ${snapshot.error}');
              return const LoginScreen();
            }
            
            final user = snapshot.data;
            
            if (user == null) {
              return const LoginScreen();
            }
            
            // المستخدم موجود، تحقق من حالته
            return FutureBuilder<UserModel?>(
              future: Provider.of<AuthService>(context, listen: false).getCurrentUserData(),
              builder: (context, userDataSnapshot) {
                if (userDataSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (userDataSnapshot.hasError || userDataSnapshot.data == null) {
                  // لا يوجد بيانات للمستخدم، سجل خروج
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<AuthService>(context, listen: false).signOut();
                  });
                  return const LoginScreen();
                }
                
                final userData = userDataSnapshot.data!;
                
                if (userData.role == 'customer' || userData.isApproved) {
                  return const HomeScreen();
                } else {
                  return WaitingApprovalScreen(
                    userId: user.uid,
                    role: userData.role,
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}