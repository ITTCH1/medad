import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/ad_model.dart';

class AdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // إضافة إعلان
  Future<String> addAd(AdModel ad) async {
    DocumentReference docRef = await _firestore.collection('ads').add(ad.toJson());
    return docRef.id;
  }

  // رفع الصور
  Future<List<String>> uploadImages(List<File> images, String adId) async {
    List<String> urls = [];
    for (int i = 0; i < images.length; i++) {
      String fileName = 'ads/$adId/${DateTime.now().millisecondsSinceEpoch + i}_$i.jpg';
      Reference ref = _storage.ref().child(fileName);
      await ref.putFile(images[i]);
      String url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // الحصول على جميع الإعلانات النشطة
  Stream<List<AdModel>> getAllAds() {
    return _firestore
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // الحصول على إعلانات المستخدم
  Future<List<AdModel>> getUserAds(String userId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('ads')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => AdModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // الحصول على إعلان واحد
  Future<AdModel?> getAd(String adId) async {
    DocumentSnapshot doc = await _firestore.collection('ads').doc(adId).get();
    if (doc.exists) {
      return AdModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // تحديث إعلان
  Future<void> updateAd(String adId, Map<String, dynamic> data) async {
    await _firestore.collection('ads').doc(adId).update(data);
  }

  // حذف إعلان
  Future<void> deleteAd(String adId) async {
    await _firestore.collection('ads').doc(adId).delete();
  }

  // البحث عن إعلانات
  Stream<List<AdModel>> searchAds(String keyword) {
    // Firestore لا يدعم البحث النصي الكامل مباشرة
    // حل بسيط: البحث في العنوان
    return _firestore
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .where((ad) => ad.title.contains(keyword) || ad.description.contains(keyword))
            .toList());
  }
}