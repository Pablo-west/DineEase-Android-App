import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dine_ease/core/data/food_categories.dart';
import 'package:dine_ease/core/models/food_item.dart';
import 'package:dine_ease/core/state/app_state.dart';
import 'package:dine_ease/core/widgets/app_logo_title.dart';
import 'package:dine_ease/core/widgets/app_dialogs.dart';
import 'package:dine_ease/core/widgets/category_chip.dart';
import 'package:dine_ease/core/widgets/delivery_destination_sheet.dart';
import 'package:dine_ease/core/widgets/food_card.dart';
import 'package:dine_ease/features/food_details/food_details_page.dart';
import 'package:dine_ease/features/home/view_all_page.dart';
import 'package:dine_ease/features/home/user_notices_page.dart';
import 'package:dine_ease/features/search/filter_search_page.dart';
import 'package:dine_ease/features/admin/widgets/food_editor_sheet.dart';
import 'package:dine_ease/global.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              _homeHeader(context),
              const SizedBox(height: 14),
              // _heroBanner(),
              // const SizedBox(height: 14),
              _destinationBanner(context),
              // const SizedBox(height: 14),
              // _topBar(),
              const SizedBox(height: 16),
              _searchBar(context),
              const SizedBox(height: 20),
              _categories(context),
              const SizedBox(height: 22),
              _sectionHeader(
                'Popular Food',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ViewAllPopularPage(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _foodsStream(
                context,
                type: 'popularFoods',
                isHorizontal: true,
                isAdmin: state.isAdmin,
              ),
              const SizedBox(height: 24),
              _sectionHeader(
                'Delicious Foods',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ViewAllDeliciousPage(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _foodsStream(
                context,
                type: 'deliciousFoods',
                isHorizontal: false,
                isAdmin: state.isAdmin,
              ),
              const SizedBox(height: 80),
            ],
          ),
          if (state.isAdmin)
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: () => _showAddFoodSheet(context),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add),
                label: const Text('Add Food'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _homeHeader(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return Row(
      children: [
        const Expanded(child: AppLogoTitle()),
        const SizedBox(width: 10),
        if (userId != null)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('notices')
                .where('userId', isEqualTo: userId)
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserNoticesPage(userId: userId),
                  ),
                ),
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.muted),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Center(
                        child: Icon(Icons.notifications_none_outlined),
                      ),
                      if (count > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _destinationBanner(BuildContext context) {
    final state = AppScope.of(context);
    final destination = state.destination;
    return GestureDetector(
      onTap: () async {
        final selected = await showDeliveryDestinationSheet(
          context,
          initial: destination,
        );
        if (selected != null) {
          state.setDestination(selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.muted),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.place_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery destination', style: AppTextStyles.subtitle),
                  const SizedBox(height: 4),
                  Text(
                    destination?.summary ??
                        'Set doorstep address or table number',
                    style: AppTextStyles.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.icon),
          ],
        ),
      ),
    );
  }

  // Widget _topBar() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Row(
  //         children: [
  //           Container(
  //             height: 40,
  //             width: 40,
  //             decoration: BoxDecoration(
  //               color: AppColors.card,
  //               borderRadius: BorderRadius.circular(14),
  //             ),
  //             child: const Icon(Icons.location_on_outlined, size: 20),
  //           ),
  //           const SizedBox(width: 10),
  //           Text('New York', style: AppTextStyles.title),
  //         ],
  //       ),
  //       Container(
  //         height: 40,
  //         width: 40,
  //         decoration: BoxDecoration(
  //           color: AppColors.card,
  //           borderRadius: BorderRadius.circular(14),
  //         ),
  //         child: const Icon(Icons.favorite_border, size: 20),
  //       ),
  //     ],
  //   );
  // }

  Widget _searchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FilterSearchPage()),
      ),
      child: AbsorbPointer(
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Type to search',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categories(BuildContext context) {
    return SizedBox(
      height: 50,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('food_categories')
            .orderBy('label')
            .snapshots(),
        builder: (context, snapshot) {
          final labels = snapshot.hasData
              ? snapshot.data!.docs
                  .map((doc) => (doc.data()['label'] ?? '').toString())
                  .toList(growable: false)
              : defaultFoodCategoryLabels;
          final categories = normalizeCategoryLabels(labels);

          return ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final label in categories)
                CategoryChip(
                  emoji: categoryEmojiForLabel(label),
                  label: label,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FilterSearchPage(
                        initialCategory: label,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.heading),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'See All',
            style: AppTextStyles.subtitle.copyWith(
              color:
                  onTap != null ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _foodsStream(
    BuildContext context, {
    required String type,
    required bool isHorizontal,
    required bool isAdmin,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('foods').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('Loading...', style: AppTextStyles.subtitle);
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No meals yet', style: AppTextStyles.subtitle);
        }
        final items = snapshot.data!.docs
            .map(_foodFromDoc)
            .where((item) => item.foodTypes.contains(type))
            .toList(growable: false);
        if (items.isEmpty) {
          return Text('No meals yet', style: AppTextStyles.subtitle);
        }
        if (isHorizontal) {
          return SizedBox(
            height: 270,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final item in items)
                  _buildFoodCard(
                    context,
                    item,
                    isAdmin: isAdmin,
                  ),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final item in items)
              GestureDetector(
                onTap: () => _openDetails(context, item),
                child: _DeliciousTile(
                  item: item,
                  isAdmin: isAdmin,
                  onTap: () => _openDetails(context, item),
                  onAdd: () => isAdmin
                      ? _openDetails(context, item)
                      : _addToCart(context, item),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFoodCard(
    BuildContext context,
    FoodItem item, {
    required bool isAdmin,
  }) {
    if (isAdmin) {
      return _buildAdminFoodCard(context, item);
    }
    return FoodCard(
      title: item.title,
      subtitle: item.subtitle,
      imagePath: item.imagePath,
      price: item.priceLabel,
      onAdd: () => _addToCart(context, item),
      onTap: () => _openDetails(context, item),
    );
  }

  Widget _buildAdminFoodCard(BuildContext context, FoodItem item) {
    final safeImagePath = item.imagePath.trim();
    final isSpecialScaled = safeImagePath == kSpecialScaledImageUrl;
    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: safeImagePath.startsWith('http')
                  ? Transform.scale(
                      scale: isSpecialScaled ? 0.9 : 1.0,
                      child: CachedNetworkImage(
                        imageUrl: safeImagePath,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    )
                  : safeImagePath.isEmpty
                      ? Container(
                          color: AppColors.muted,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        )
                      : Image.asset(
                          safeImagePath,
                          fit: BoxFit.cover,
                        ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.title.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.priceLabel,
                    style: AppTextStyles.price.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () => _openDetails(context, item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                      ),
                      child: const Text(
                        'View Food',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, FoodItem item) {
    AppScope.of(context).addToCart(item);
    showInfoDialog(
      context,
      title: 'Added to Cart',
      message: '${item.title} added to cart.',
    );
  }

  void _openDetails(BuildContext context, FoodItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDetailsPage(item: item),
      ),
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

  Future<void> _showAddFoodSheet(BuildContext context) async {
    final categories = await _loadCategoryLabels();
    if (!context.mounted) return;

    await showFoodEditorSheet(
      context,
      categories: categories,
      onSave: (data, _) async {
        await FirebaseFirestore.instance.collection('foods').add(data);
      },
    );
  }

  Future<List<String>> _loadCategoryLabels() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('food_categories')
          .orderBy('label')
          .get();
      final labels = snapshot.docs
          .map((doc) => (doc.data()['label'] ?? '').toString())
          .toList(growable: false);
      return normalizeCategoryLabels(labels);
    } catch (_) {
      return List<String>.from(defaultFoodCategoryLabels);
    }
  }
}

class _DeliciousTile extends StatelessWidget {
  final FoodItem item;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _DeliciousTile({
    required this.item,
    required this.isAdmin,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child:
              // isNarrow
              //     ? Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           _image(),
              //           const SizedBox(height: 12),
              //           _content(isNarrow),
              //         ],
              //       )
              //     :
              Row(
            children: [
              _image(),
              const SizedBox(width: 14),
              Expanded(child: _content(isNarrow)),
            ],
          ),
        );
      },
    );
  }

  Widget _image() {
    final safeImagePath = item.imagePath.trim();
    final isSpecialScaled = safeImagePath == kSpecialScaledImageUrl;
    return GestureDetector(
      onTap: isAdmin ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: safeImagePath.startsWith('https')
            ? Transform.scale(
                scale: isSpecialScaled ? 0.9 : 1.0,
                child: CachedNetworkImage(
                  imageUrl: safeImagePath,
                  width: 90,
                  height: 90,
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
                    debugPrint('Home tile image load failed: $safeImagePath');
                    debugPrint('Home tile image error: $error');
                  },
                ),
              )
            : safeImagePath.isEmpty
                ? Container(
                    width: 90,
                    height: 90,
                    color: AppColors.muted,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  )
                : Image.asset(
                    safeImagePath,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
      ),
    );
  }

  Widget _content(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.title, style: AppTextStyles.title),
        const SizedBox(height: 6),
        Text(item.subtitle, style: AppTextStyles.subtitle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 52,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(item.priceLabel, style: AppTextStyles.price),
            if (!isAdmin)
              ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            else
              ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'View Food',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
