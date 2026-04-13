import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../firebase_options.dart';

/// شاشة اختبار Firebase Storage
class FirebaseStorageTest extends StatefulWidget {
  const FirebaseStorageTest({super.key});

  @override
  State<FirebaseStorageTest> createState() => _FirebaseStorageTestState();
}

class _FirebaseStorageTestState extends State<FirebaseStorageTest> {
  String _status = 'جاري التهيئة...';
  String _error = '';
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _initializeAndTest();
  }

  Future<void> _initializeAndTest() async {
    if (_isTesting) return;
    
    setState(() {
      _isTesting = true;
      _status = '1️⃣ تحميل متغيرات البيئة...';
      _error = '';
    });

    try {
      // Load environment
      try {
        await dotenv.load(fileName: '.env.development');
        _status = '✅ بيئة التطوير محملة';
      } catch (e) {
        _status = '⚠️ فشل تحميل .env - استخدام القيم الافتراضية';
      }

      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _status = '2️⃣ تهيئة Firebase...';
      });

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      setState(() {
        _status = '✅ Firebase تم التهيئة بنجاح';
      });

      await Future.delayed(Duration(seconds: 1));

      await _testStorage();
      
    } catch (e) {
      setState(() {
        _status = '❌ فشل في التهيئة';
        _error = e.toString();
        _isTesting = false;
      });
    }
  }

  Future<void> _testStorage() async {
    try {
      setState(() {
        _status = '3️⃣ الاتصال بـ Firebase Storage...';
      });

      final storage = FirebaseStorage.instance;
      
      // التحقق من وجود Storage bucket
      final bucket = storage.bucket;
      setState(() {
        _status = '4️⃣ Bucket: $bucket';
      });

      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _status = '5️⃣ محاولة رفع ملف اختباري...';
      });

      // محاولة رفع ملف بسيط
      final ref = storage.ref('test/connection_${DateTime.now().millisecondsSinceEpoch}.txt');
      await ref.putString('Firebase Storage is working! ${DateTime.now()}');

      setState(() {
        _status = '6️⃣ الحصول على رابط الملف...';
      });

      final url = await ref.getDownloadURL();

      setState(() {
        _status = '✅ Firebase Storage يعمل بنجاح!';
        _error = 'Bucket: $bucket\nURL: $url';
        _isTesting = false;
      });

      // تنظيف - حذف الملف الاختباري
      try {
        await ref.delete();
      } catch (e) {
        // تجاهل خطأ الحذف
      }
      
    } catch (e) {
      setState(() {
        _status = '❌ فشل اختبار Firebase Storage';
        _error = 'Error: $e\n\nالخطوات:\n1. تأكد من تفعيل Storage في Firebase Console\n2. تحقق من اسم Bucket\n3. تأكد من Rules';
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار Firebase Storage'),
        backgroundColor: _error.contains('✅') ? Colors.green : (_isTesting ? Colors.blue : Colors.red),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _error.contains('✅') ? Icons.check_circle : 
                _isTesting ? Icons.hourglass_empty : Icons.error,
                size: 80,
                color: _error.contains('✅') ? Colors.green : 
                       _isTesting ? Colors.blue : Colors.red,
              ),
              SizedBox(height: 24),
              Text(
                _status,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (_error.isNotEmpty) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _error,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isTesting ? null : _initializeAndTest,
                icon: Icon(Icons.refresh),
                label: Text('إعادة الاختبار'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
