import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'home_screen.dart';
import 'waiting_approval_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String uid;
  final String phone;
  final String selectedRole;

  const ProfileSetupScreen({
    super.key,
    required this.uid,
    required this.phone,
    required this.selectedRole,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    final fileName = '${widget.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('profile_images/$fileName');
    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الاسم')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _uploadImage();

      final user = UserModel(
        uid: widget.uid,
        phone: widget.phone,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        profileImage: imageUrl,
        role: widget.selectedRole,
        isApproved: widget.selectedRole == 'customer',
        createdAt: DateTime.now(),
      );

      await AuthService().saveUser(user);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.selectedRole == 'customer'
                ? 'تم إنشاء حسابك بنجاح!'
                : 'تم إرسال طلبك للمراجعة. سيتم إعلامك عند الموافقة.',
          ),
          backgroundColor: widget.selectedRole == 'customer' ? Colors.green : Colors.orange,
        ),
      );

      if (widget.selectedRole == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingApprovalScreen(
              userId: widget.uid,
              role: widget.selectedRole,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إكمال الملف الشخصي'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(  // ✅ إضافة SingleChildScrollView
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اضغط لإضافة صورة (اختياري)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم كاملاً *',
                  hintText: 'مثال: أحمد محمد',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني (اختياري)',
                  hintText: 'example@email.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إنشاء الحساب'),
                    ),
              const SizedBox(height: 40), // ✅ مسافة إضافية في الأسفل
            ],
          ),
        ),
      ),
    );
  }
}