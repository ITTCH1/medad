import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/ad_service.dart';
import '../../services/auth_service.dart';
import '../../models/ad_model.dart';

class AddAdScreen extends StatefulWidget {
  @override
  _AddAdScreenState createState() => _AddAdScreenState();
}

class _AddAdScreenState extends State<AddAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String? _selectedCategory;
  List<File> _images = [];
  bool _isLoading = false;
  
  List<String> _categories = [
    'إلكترونيات',
    'أثاث',
    'عقارات',
    'سيارات',
    'خدمات',
    'ملابس',
    'أخرى',
  ];

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء إضافة صورة واحدة على الأقل')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // إنشاء الإعلان أولاً للحصول على ID
      AdModel ad = AdModel(
        userId: AuthService().getCurrentUser()!.uid,
        title: _titleController.text,
        description: _descController.text,
        price: double.parse(_priceController.text),
        category: _selectedCategory!,
        location: _locationController.text,
        images: [], // سنضيف الصور لاحقاً
        phone: _phoneController.text,
        createdAt: DateTime.now(),
      );
      
      String adId = await AdService().addAd(ad);
      
      // رفع الصور
      List<String> imageUrls = await AdService().uploadImages(_images, adId);
      
      // تحديث الإعلان بصوره
      await AdService().updateAd(adId, {'images': imageUrls});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم نشر الإعلان بنجاح')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إضافة إعلان جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // اختيار الصور
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _images.isEmpty
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40),
                          Text('اضغط لإضافة صور'),
                        ],
                      ))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.file(_images[index], width: 80, fit: BoxFit.cover),
                          );
                        },
                      ),
              ),
            ),
            SizedBox(height: 15),
            
            // عنوان
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'عنوان الإعلان'),
              validator: (v) => v!.isEmpty ? 'الرجاء إدخال العنوان' : null,
            ),
            SizedBox(height: 15),
            
            // وصف
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(labelText: 'الوصف'),
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'الرجاء إدخال الوصف' : null,
            ),
            SizedBox(height: 15),
            
            // السعر
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'السعر (ريال)'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'الرجاء إدخال السعر' : null,
            ),
            SizedBox(height: 15),
            
            // التصنيف
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(labelText: 'التصنيف'),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
              validator: (v) => v == null ? 'الرجاء اختيار التصنيف' : null,
            ),
            SizedBox(height: 15),
            
            // الموقع
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'الموقع'),
              validator: (v) => v!.isEmpty ? 'الرجاء إدخال الموقع' : null,
            ),
            SizedBox(height: 15),
            
            // رقم الهاتف
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'رقم الهاتف للتواصل'),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'الرجاء إدخال رقم الهاتف' : null,
            ),
            SizedBox(height: 30),
            
            // زر النشر
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitAd,
                    child: Text('نشر الإعلان'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}