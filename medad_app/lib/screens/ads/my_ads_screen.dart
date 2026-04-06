import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ad_service.dart';
import '../../models/ad_model.dart';
import 'ad_details_screen.dart';
import 'add_ad_screen.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  bool _isLoading = true;
  List<AdModel> _myAds = [];

  @override
  void initState() {
    super.initState();
    _loadMyAds();
  }

  Future<void> _loadMyAds() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final ads = await AdService().getUserAds(userId);
    if (mounted) {
      setState(() {
        _myAds = ads;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAd(String adId) async {
    await AdService().deleteAd(adId);
    if (mounted) {
      _loadMyAds();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الإعلان'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعلاناتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddAdScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyAds,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _myAds.isEmpty
                ? const Center(child: Text('لا توجد إعلانات'))
                : ListView.builder(
                    itemCount: _myAds.length,
                    itemBuilder: (context, index) {
                      final ad = _myAds[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: ad.images.isNotEmpty
                              ? Image.network(ad.images.first, width: 60, height: 60, fit: BoxFit.cover)
                              : const Icon(Icons.image, size: 60),
                          title: Text(ad.title, maxLines: 1),
                          subtitle: Text('${ad.price} ريال | ${ad.location}'),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: ad.status == 'active' ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              ad.status == 'active' ? 'نشط' : 'غير نشط',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          onTap: ad.id != null
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdDetailsScreen(adId: ad.id!),
                                    ),
                                  )
                              : null,
                          onLongPress: () => _confirmDelete(context, ad),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdModel ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: Text('هل أنت متأكد من حذف "${ad.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (ad.id != null) _deleteAd(ad.id!);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
