import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// صفحة اختيار الفئات المفضلة
/// العميل يختار الفئات التي يهتم بها → يصله إشعار عند إضافة إعلان جديد
class FavoriteCategoriesScreen extends StatefulWidget {
  const FavoriteCategoriesScreen({super.key});

  @override
  State<FavoriteCategoriesScreen> createState() =>
      _FavoriteCategoriesScreenState();
}

class _FavoriteCategoriesScreenState extends State<FavoriteCategoriesScreen> {
  final List<String> _allCategories = [
    'إلكترونيات',
    'أثاث',
    'عقارات',
    'سيارات',
    'خدمات',
    'ملابس',
    'أخرى',
  ];

  Set<String> _selectedCategories = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteCategories();
  }

  Future<void> _loadFavoriteCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final favorites = List<String>.from(data['favoriteCategories'] ?? []);
        setState(() {
          _selectedCategories = favorites.toSet();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading favorite categories: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFavoriteCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    debugPrint('💾 Saving favorite categories for user ${user.uid}: ${_selectedCategories.toList()}');

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'favoriteCategories': _selectedCategories.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Favorite categories saved successfully');

      // Verify by reading back
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() as Map<String, dynamic>?;
      debugPrint('📖 Verified - stored categories: ${data?['favoriteCategories']}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ تم حفظ الفئات المفضلة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving favorite categories: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ أثناء الحفظ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('الفئات المفضلة'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // معلومات
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'اختر الفئات التي تهتم بها. سنرسل لك إشعارات عند إضافة إعلانات جديدة في هذه الفئات.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // عداد
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'المختار: ${_selectedCategories.length} من ${_allCategories.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // قائمة الفئات
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allCategories.length,
              itemBuilder: (context, index) {
                final category = _allCategories[index];
                final isSelected = _selectedCategories.contains(category);
                final icon = _getCategoryIcon(category);
                final color = _getCategoryColor(category);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedCategories.remove(category);
                          } else {
                            _selectedCategories.add(category);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.2)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? color : Colors.grey[600],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected ? color : Colors.grey[800],
                                ),
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected ? color : Colors.grey[400],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // زر الحفظ
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _saveFavoriteCategories();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'حفظ (${_selectedCategories.length} فئة)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'إلكترونيات':
        return Icons.devices;
      case 'أثاث':
        return Icons.chair;
      case 'عقارات':
        return Icons.apartment;
      case 'سيارات':
        return Icons.directions_car;
      case 'خدمات':
        return Icons.build;
      case 'ملابس':
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'إلكترونيات':
        return Colors.blue;
      case 'أثاث':
        return Colors.brown;
      case 'عقارات':
        return Colors.purple;
      case 'سيارات':
        return Colors.teal;
      case 'خدمات':
        return Colors.orange;
      case 'ملابس':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
