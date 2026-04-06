import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/ad_service.dart';
import '../../models/ad_model.dart';

class AdDetailsScreen extends StatelessWidget {
  final String adId;

  const AdDetailsScreen({super.key, required this.adId});

  Future<void> _callPhone(String phone) async {
    Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'لا يمكن الاتصال بهذا الرقم';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل الإعلان')),
      body: FutureBuilder<AdModel?>(
        future: AdService().getAd(adId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          AdModel ad = snapshot.data!;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صور الإعلان
                SizedBox(
                  height: 250,
                  child: ad.images.isEmpty
                      ? Center(child: Icon(Icons.image, size: 100))
                      : PageView.builder(
                          itemCount: ad.images.length,
                          itemBuilder: (context, index) {
                            return Image.network(ad.images[index], fit: BoxFit.cover);
                          },
                        ),
                ),
                SizedBox(height: 15),
                
                // العنوان
                Text(ad.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                
                // السعر والتصنيف
                Row(
                  children: [
                    Text('${ad.price} ريال', style: TextStyle(fontSize: 18, color: Colors.green)),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(ad.category),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                
                // الموقع
                Row(
                  children: [
                    Icon(Icons.location_on, size: 20),
                    SizedBox(width: 5),
                    Text(ad.location),
                  ],
                ),
                SizedBox(height: 10),
                
                // الوصف
                Text('الوصف:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text(ad.description),
                SizedBox(height: 20),
                
                Divider(),
                SizedBox(height: 15),
                
                // زر الاتصال
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.phone),
                    label: Text('اتصل بصاحب الإعلان'),
                    onPressed: () => _callPhone(ad.phone),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}