import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: '.env.development');
  } catch (e) {
    print('Env load failed: $e');
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const StorageTestApp());
}

class StorageTestApp extends StatelessWidget {
  const StorageTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const StorageTestScreen(),
    );
  }
}

class StorageTestScreen extends StatefulWidget {
  const StorageTestScreen({super.key});

  @override
  State<StorageTestScreen> createState() => _StorageTestScreenState();
}

class _StorageTestScreenState extends State<StorageTestScreen> {
  String message = 'Press button to test';
  
  Future<void> testStorage() async {
    setState(() {
      message = 'Testing...';
    });
    
    try {
      final storage = FirebaseStorage.instance;
      final bucket = storage.bucket;
      final ref = storage.ref('test/test.txt');
      
      await ref.putString('test');
      final url = await ref.getDownloadURL();
      
      setState(() {
        message = 'SUCCESS!\nBucket: $bucket\nURL: $url';
      });
    } catch (e) {
      setState(() {
        message = 'ERROR: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(message, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: testStorage,
              child: const Text('Test Storage'),
            ),
          ],
        ),
      ),
    );
  }
}
