import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/ads/ad_details_screen.dart';
import '../models/ad_model.dart';
import '../utils/constants.dart';

/// شريط أخباري متحرك لآخر الإعلانات
/// يمكن سحبه أفقياً مع تأثير auto-scroll
class AdsNewsTicker extends StatefulWidget {
  final int limit;
  final bool autoScroll;
  final Duration scrollDuration;

  const AdsNewsTicker({
    super.key,
    this.limit = 10,
    this.autoScroll = true,
    this.scrollDuration = const Duration(seconds: 3),
  });

  @override
  State<AdsNewsTicker> createState() => _AdsNewsTickerState();
}

class _AdsNewsTickerState extends State<AdsNewsTicker>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (widget.autoScroll) {
      _startAutoScroll();
    }

    _scrollController.addListener(_onScroll);
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _scrollController.hasClients) {
        _autoScrollLoop();
      }
    });
  }

  Future<void> _autoScrollLoop() async {
    while (mounted) {
      await Future.delayed(widget.scrollDuration);
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        // Scroll to end smoothly
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(seconds: 8),
          curve: Curves.linear,
        );
        
        // Wait and go back
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted && _scrollController.hasClients) {
          await _scrollController.animateTo(
            0,
            duration: const Duration(seconds: 8),
            curve: Curves.linear,
          );
        }
      }
    }
  }

  void _onScroll() {
    final showLeft = _scrollController.offset > 50;
    final showRight = _scrollController.offset < _scrollController.position.maxScrollExtent - 50;

    if (showLeft != _showLeftArrow || showRight != _showRightArrow) {
      setState(() {
        _showLeftArrow = showLeft;
        _showRightArrow = showRight;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [AppShadows.small],
      ),
      child: Stack(
        children: [
          // Title bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade600, Colors.teal.shade800],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppBorderRadius.lg),
                  topRight: Radius.circular(AppBorderRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'آخر الإعلانات',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'اضغط للتفاصيل',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable ads
          Positioned(
            top: 38,
            left: 0,
            right: 0,
            bottom: 0,
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('ads')
                  .orderBy('createdAt', descending: true)
                  .limit(20)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('❌ Ads ticker error: ${snapshot.error}');
                  
                  // عرض رسالة بسيطة عند الخطأ
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_outlined, size: 32, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(
                          'لا توجد إعلانات بعد',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                // Filter ads locally
                final ads = snapshot.data!.docs
                    .map((doc) => AdModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
                    .where((ad) => ad.isApproved && ad.status == 'active')
                    .take(widget.limit)
                    .toList();

                if (ads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_outlined, size: 32, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(
                          'لا توجد إعلانات بعد',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    _onScroll();
                    return true;
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: ads.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final ad = ads[index];
                      return _buildAdCard(ad);
                    },
                  ),
                );
              },
            ),
          ),

          // Left arrow indicator
          if (_showLeftArrow)
            Positioned(
              left: 0,
              top: 38,
              bottom: 0,
              child: Container(
                width: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Icon(Icons.chevron_left, color: Colors.grey[400]),
              ),
            ),

          // Right arrow indicator
          if (_showRightArrow)
            Positioned(
              right: 0,
              top: 38,
              bottom: 0,
              child: Container(
                width: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Icon(Icons.chevron_right, color: Colors.grey[400]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdCard(AdModel ad) {
    List<String> images = ad.images.isNotEmpty ? ad.images : [];
    String? imageUrl = images.isNotEmpty ? images.first : null;

    return Material(
      color: const Color(0xFFF8F9FB),
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdDetailsScreen(adId: ad.id ?? ''),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image or placeholder
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppBorderRadius.md),
                  topRight: Radius.circular(AppBorderRadius.md),
                ),
                child: Container(
                  height: 60,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Icon(
                            Icons.image_outlined,
                            color: Colors.grey[400],
                            size: 28,
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.grey[400],
                            size: 28,
                          ),
                        ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    SizedBox(
                      height: 14,
                      child: Text(
                        ad.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Price
                    SizedBox(
                      height: 13,
                      child: Text(
                        '${ad.price} ريال',
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Location
                    SizedBox(
                      height: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 10, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              ad.location.isNotEmpty ? ad.location : 'غير محدد',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 9,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
