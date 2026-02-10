import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/food_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../food_details/food_details_page.dart';

class ViewAllDeliciousPage extends StatelessWidget {
  const ViewAllDeliciousPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(context),
              const SizedBox(height: 16),
              Text('Delicious Items', style: AppTextStyles.heading),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseFirestore.instance.collection('foods').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Text(
                          'Loading meals...',
                          style: AppTextStyles.subtitle,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No meals available',
                          style: AppTextStyles.subtitle,
                        ),
                      );
                    }
                    final items = snapshot.data!.docs
                        .map(_foodFromDoc)
                        .where((item) => item.foodTypes.contains('deliciousFoods'))
                        .toList(growable: false);
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'No meals available',
                          style: AppTextStyles.subtitle,
                        ),
                      );
                    }
                    return GridView.builder(
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _FoodGridCard(
                          title: item.title,
                          price: item.priceLabel,
                          imagePath: item.imagePath,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FoodDetailsPage(item: item),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.arrow_back),
          ),
        ),
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.search),
        ),
      ],
    );
  }

  FoodItem _foodFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawImage = FoodItem.readStringField(
      data,
      const ['imageUrl', 'imageUrl ', 'imageURL'],
    );
    return FoodItem(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      imagePath: FoodItem.normalizeImagePath(rawImage),
      description: (data['description'] ?? '').toString(),
      ingredients: (data['ingredients'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      foodTypes: FoodItem.normalizeFoodTypes(data['foodType'] as List?),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      time: (data['time'] ?? '').toString(),
      calories: (data['calories'] as num?)?.toInt() ?? 0,
    );
  }
}

class _FoodGridCard extends StatelessWidget {
  final String title;
  final String price;
  final String imagePath;
  final VoidCallback onTap;

  const _FoodGridCard({
    required this.title,
    required this.price,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: imagePath.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: imagePath,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image_outlined),
                      errorListener: (error) {
                        debugPrint(
                          'ViewAll image load failed: $imagePath',
                        );
                        debugPrint('ViewAll image error: $error');
                      },
                    )
                  : imagePath.trim().isEmpty
                      ? Container(
                          height: 120,
                          width: double.infinity,
                          color: AppColors.muted,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        )
                      : Image.asset(
                          imagePath,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(price, style: AppTextStyles.price),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
