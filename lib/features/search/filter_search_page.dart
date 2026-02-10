import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/sample_data.dart';
import '../../core/models/food_item.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/food_card.dart';
import '../food_details/food_details_page.dart';

class FilterSearchPage extends StatefulWidget {
  final String? initialCategory;

  const FilterSearchPage({super.key, this.initialCategory});

  @override
  State<FilterSearchPage> createState() => _FilterSearchPageState();
}

class _FilterSearchPageState extends State<FilterSearchPage> {
  late final TextEditingController _controller;
  String _query = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final items = _filteredItems();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(context),
              const SizedBox(height: 12),
              _searchBar(),
              const SizedBox(height: 14),
              _categoryChips(),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('foods')
                      .snapshots(),
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
                          'No meals match your search.',
                          style: AppTextStyles.subtitle,
                        ),
                      );
                    }
                    final items = snapshot.data!.docs
                        .map(_foodFromDoc)
                        .where(_matchesFilters)
                        .toList(growable: false);
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'No meals match your search.',
                          style: AppTextStyles.subtitle,
                        ),
                      );
                    }
                    return ListView(
                      children: [
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: SizedBox(
                              height: 260,
                              child: FoodCard(
                                title: item.title,
                                subtitle: item.subtitle,
                                imagePath: item.imagePath,
                                price: item.priceLabel,
                                onAdd: () {
                                  AppScope.of(context).addToCart(item);
                                  showInfoDialog(
                                    context,
                                    title: 'Added to Cart',
                                    message: '${item.title} added to cart.',
                                  );
                                },
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FoodDetailsPage(item: item),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
        Text('Search', style: AppTextStyles.title),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _controller,
      onChanged: (value) => setState(() => _query = value.trim()),
      decoration: InputDecoration(
        hintText: 'Search meals',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final category in foodCategories)
            CategoryChip(
              emoji: category['emoji']!,
              label: category['label']!,
              selected: _selectedCategory == category['label'],
              onTap: () {
                setState(() {
                  final label = category['label']!;
                  _selectedCategory = _selectedCategory == label ? null : label;
                });
              },
            ),
        ],
      ),
    );
  }

  bool _matchesFilters(FoodItem item) {
    if (_selectedCategory != null && item.category != _selectedCategory) {
      return false;
    }
    final query = _query.toLowerCase();
    if (query.isEmpty) return true;
    final haystack = [
      item.title,
      item.subtitle,
      item.description,
      ...item.ingredients,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
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
