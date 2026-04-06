import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../ads/ads_list_screen.dart';
import '../ads/add_ad_screen.dart';
import '../ads/my_ads_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        title: const Text(
          'مدد',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _signOut,
              tooltip: 'تسجيل الخروج',
            ),
          IconButton(
            icon: Icon(
              user != null ? Icons.person : Icons.login,
              color: user != null ? Colors.teal : Colors.orange,
            ),
            onPressed: user != null ? null : _openLogin,
            tooltip: user != null ? 'مسجل' : 'تسجيل الدخول',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user != null ? 'أهلاً بك!' : 'مرحباً',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user != null
                                  ? 'تصفح الإعلانات أو أضف إعلاناً'
                                  : 'سجّل دخولك لتصفح الإعلانات',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stats cards
              _buildSectionTitle('نظرة عامة'),
              const SizedBox(height: 12),
              _buildStatsGrid(),
              const SizedBox(height: 24),

              // Quick actions
              _buildSectionTitle('إجراءات سريعة'),
              const SizedBox(height: 12),
              _buildQuickActions(user),
              const SizedBox(height: 24),

              // Recent ads
              _buildSectionTitle('آخر الإعلانات'),
              const SizedBox(height: 12),
              _buildRecentAds(),
            ],
          ),
        ),
      ),
      floatingActionButton: user != null
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddAdScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('إضافة إعلان'),
              backgroundColor: Colors.teal,
            )
          : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('ads').get(),
      builder: (context, adsSnapshot) {
        int totalAds = 0;
        if (adsSnapshot.hasData) {
          totalAds = adsSnapshot.data!.docs.length;
        }

        int myAds = 0;
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && adsSnapshot.hasData) {
          myAds = adsSnapshot.data!.docs
              .where((doc) =>
                  (doc.data() as Map<String, dynamic>)['userId'] == user.uid)
              .length;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              'الإعلانات',
              totalAds.toString(),
              Icons.campaign_outlined,
              const Color(0xFF667eea),
            ),
            _buildStatCard(
              'إعلاناتي',
              myAds.toString(),
              Icons.my_library_add_outlined,
              const Color(0xFFf093fb),
            ),
            _buildStatCard(
              'الزوار',
              '-',
              Icons.visibility_outlined,
              const Color(0xFF4facfe),
            ),
            _buildStatCard(
              'التقييم',
              '⭐',
              Icons.star_border,
              const Color(0xFF43e97b),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(User? user) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2,
      children: [
        _buildQuickActionCard(
          'تصفح الإعلانات',
          Icons.browse_gallery,
          const Color(0xFF667eea),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdsListScreen()),
          ),
        ),
        if (user != null)
          _buildQuickActionCard(
            'إعلاناتي',
            Icons.person_outline,
            const Color(0xFFf093fb),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyAdsScreen()),
            ),
          ),
        if (user != null)
          _buildQuickActionCard(
            'إضافة إعلان',
            Icons.add_circle_outline,
            const Color(0xFF43e97b),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddAdScreen()),
            ),
          ),
        _buildQuickActionCard(
          user != null ? 'الملف الشخصي' : 'تسجيل الدخول',
          user != null ? Icons.person : Icons.login,
          const Color(0xFF4facfe),
          () => user != null ? null : _openLogin(),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAds() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ads')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final ads = snapshot.data!.docs;
        if (ads.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Text(
                  'لا توجد إعلانات بعد',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ads.length,
          separatorBuilder: (ctx, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = ads[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? 'بدون عنوان';
            final price = '${data['price'] ?? 0} ريال';
            final location = data['location'] ?? '';
            List<dynamic> images = [];
            if (data['images'] != null) images = data['images'] as List;

            return InkWell(
              onTap: () {
                // Navigate to details (import dynamically to avoid cycles)
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[100],
                      ),
                      child: images.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                images.first,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                ),
                              ),
                            )
                          : Icon(
                              Icons.image_outlined,
                              color: Colors.grey[400],
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            price,
                            style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (location.isNotEmpty)
                            Text(
                              location,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
