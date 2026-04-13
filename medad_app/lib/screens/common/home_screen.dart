import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../ads/ads_list_screen.dart';
import '../ads/add_ad_screen.dart';
import '../ads/ad_details_screen.dart';
import '../ads/my_ads_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await AuthService().getCurrentUserData();
      if (mounted) {
        if (data == null) {
          await AuthService().signOut();
          if (!mounted) return;
          _showDeletedAccountMessage();
          return;
        }
        setState(() => _userModel = data);
      }
    }
  }

  void _showDeletedAccountMessage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.account_circle_outlined, color: Colors.blue[700], size: 28),
            const SizedBox(width: 8),
            const Text('إنشاء حساب جديد'),
          ],
        ),
        content: const Text('لم يتم العثور على بيانات حسابك. يرجى إنشاء حساب جديد.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    _userModel = null;
    await _loadUserData();
    if (mounted) setState(() {});
  }

  bool get _isMerchant {
    return _userModel?.role == 'merchant' && _userModel?.isApproved == true;
  }

  Future<void> _openLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    if (mounted) {
      await _loadUserData();
      setState(() {});
    }
  }

  Future<void> _signOut() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().signOut();
              if (mounted) setState(() => _userModel = null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // App Bar مخصص
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade600, Colors.teal.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront, color: Colors.white, size: 32),
                          const SizedBox(width: 8),
                          Text(
                            'مدد',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (user != null && _userModel != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  _isMerchant ? Icons.store : Icons.person,
                                  color: Colors.teal,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _userModel!.name != null && _userModel!.name!.isNotEmpty
                                    ? _userModel!.name!.trim().split(' ')[0]
                                    : 'مستخدم',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white.withValues(alpha: 0.8)),
                onPressed: user != null ? _signOut : _openLogin,
                tooltip: user != null ? 'تسجيل الخروج' : 'تسجيل الدخول',
              ),
            ],
          ),

          // المحتوى
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // بطاقات الإحصائيات
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    // الإجراءات السريعة
                    _buildSectionTitle('إجراءات سريعة'),
                    const SizedBox(height: 12),
                    _buildQuickActions(user),
                    const SizedBox(height: 24),

                    // آخر الإعلانات
                    _buildSectionTitle('آخر الإعلانات'),
                    const SizedBox(height: 12),
                    _buildRecentAds(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isMerchant
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddAdScreen()),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'إضافة إعلان',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.teal,
                elevation: 0,
              ),
            )
          : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('ads').get(),
      builder: (context, adsSnapshot) {
        int totalAds = 0;
        if (adsSnapshot.hasData) {
          totalAds = adsSnapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isApproved'] == true;
          }).length;
        }

        int myAds = 0;
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && adsSnapshot.hasData) {
          myAds = adsSnapshot.data!.docs
              .where((doc) => (doc.data() as Map<String, dynamic>)['userId'] == user.uid)
              .length;
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'الإعلانات',
                totalAds.toString(),
                Icons.campaign_outlined,
                const Color(0xFF667eea),
                const Color(0xFFE8EAF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'الزوار',
                '-',
                Icons.visibility_outlined,
                const Color(0xFF4facfe),
                const Color(0xFFE3F2FD),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
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
      childAspectRatio: 2.2,
      children: [
        _buildQuickActionCard(
          'تصفح الإعلانات',
          Icons.browse_gallery,
          const Color(0xFF667eea),
          const Color(0xFFE8EAF6),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdsListScreen()),
          ),
        ),
        if (_isMerchant)
          _buildQuickActionCard(
            'إعلاناتي',
            Icons.my_library_books,
            const Color(0xFFf093fb),
            const Color(0xFFFCE4EC),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyAdsScreen()),
            ),
          ),
        if (_isMerchant)
          _buildQuickActionCard(
            'إضافة إعلان',
            Icons.add_circle,
            const Color(0xFF43e97b),
            const Color(0xFFE8F5E9),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddAdScreen()),
            ),
          ),
        _buildQuickActionCard(
          user != null ? 'الملف الشخصي' : 'تسجيل الدخول',
          user != null ? Icons.person : Icons.login,
          const Color(0xFF4facfe),
          const Color(0xFFE3F2FD),
          () => user != null ? null : _openLogin(),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String label,
    IconData icon,
    Color color,
    Color bgColor,
    VoidCallback? onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAds() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ads')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 8),
                  Text(
                    'حدث خطأ في تحميل الإعلانات',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final approvedAds = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['status'] == 'active') && (data['isApproved'] == true);
        }).take(5).toList();

        if (approvedAds.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.campaign_outlined, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'لا توجد إعلانات بعد',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: approvedAds.length,
          separatorBuilder: (ctx, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final ads = approvedAds;
            final data = ads[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? 'بدون عنوان';
            final price = '${data['price'] ?? 0} ريال';
            final location = data['location'] ?? '';
            final category = data['category'] ?? '';
            List<dynamic> images = [];
            if (data['images'] != null) images = data['images'] as List;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final doc = ads[index];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdDetailsScreen(adId: doc.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey[100],
                          child: images.isNotEmpty
                              ? Image.network(
                                  images.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Icon(
                                    Icons.image_outlined,
                                    color: Colors.grey[400],
                                    size: 32,
                                  ),
                                )
                              : Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey[400],
                                  size: 32,
                                ),
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
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  location.isNotEmpty ? location : 'غير محدد',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    price,
                                    style: const TextStyle(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (category.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
