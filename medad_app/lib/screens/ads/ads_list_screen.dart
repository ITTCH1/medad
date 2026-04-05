import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ad_service.dart';
import '../../models/ad_model.dart';
import 'ad_details_screen.dart';

class AdsListScreen extends StatelessWidget {
  final String? category;
  
  AdsListScreen({this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category ?? 'جميع الإعلانات'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<AdModel>>(
        stream: Provider.of<AdService>(context).getAllAds(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          List<AdModel> ads = snapshot.data!;
          
          if (category != null) {
            ads = ads.where((ad) => ad.category == category).toList();
          }
          
          if (ads.isEmpty) {
            return Center(child: Text('لا توجد إعلانات'));
          }
          
          return ListView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) {
              AdModel ad = ads[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: ad.images.isNotEmpty
                      ? Image.network(ad.images.first, width: 60, height: 60, fit: BoxFit.cover)
                      : Icon(Icons.image, size: 60),
                  title: Text(ad.title, maxLines: 1),
                  subtitle: Text('${ad.price} ريال | ${ad.location}'),
                  trailing: Text(ad.category),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdDetailsScreen(adId: ad.id!),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/add_ad');
        },
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('بحث'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'أدخل كلمة البحث'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchResultsScreen(keyword: controller.text),
                ),
              );
            },
            child: Text('بحث'),
          ),
        ],
      ),
    );
  }
}