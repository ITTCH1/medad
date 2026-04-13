import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env.development');
    debugPrint('✅ Environment loaded');
  } catch (e) {
    debugPrint('⚠️ Env load failed: $e');
  }

  // Debug info
  debugPrint('🔑 API Key: ${dotenv.env['FIREBASE_API_KEY'] ?? "NOT_FOUND"}');
  debugPrint('📱 Project: ${dotenv.env['FIREBASE_PROJECT_ID'] ?? "NOT_FOUND"}');

  // Initialize Firebase (handle duplicate app case)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized fresh');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('⚠️ Firebase already initialized, using existing instance');
    } else {
      rethrow;
    }
  }

  debugPrint('✅ Firebase ready');

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
        home: const AuthWrapper(),
      ),
    );
  }
}
