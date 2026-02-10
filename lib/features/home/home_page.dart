import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dine_ease/core/data/sample_data.dart';
import 'package:dine_ease/core/models/food_item.dart';
import 'package:dine_ease/core/state/app_state.dart';
import 'package:dine_ease/core/widgets/app_logo_title.dart';
import 'package:dine_ease/core/widgets/app_dialogs.dart';
import 'package:dine_ease/core/widgets/category_chip.dart';
import 'package:dine_ease/core/widgets/delivery_destination_sheet.dart';
import 'package:dine_ease/core/widgets/food_card.dart';
import 'package:dine_ease/features/food_details/food_details_page.dart';
import 'package:dine_ease/features/home/view_all_page.dart';
import 'package:dine_ease/features/search/filter_search_page.dart';
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
              const AppLogoTitle(),
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
              _sectionHeader('Popular Food'),
              const SizedBox(height: 12),
              _foodsStream(
                context,
                type: 'popularFoods',
                isHorizontal: true,
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

  // Widget _heroBanner() {
  //   return ClipRRect(
  //     borderRadius: BorderRadius.circular(22),
  //     child: CachedNetworkImage(
  //       imageUrl:
  //           'https://static.wixstatic.com/media/a0f741_213388a947a84038a956d91682435f4b~mv2.jpg?dn=LanyardBlack.jpg',
  //       height: 150,
  //       width: double.infinity,
  //       fit: BoxFit.cover,
  //       placeholder: (context, url) => Container(
  //         height: 150,
  //         color: AppColors.muted,
  //         alignment: Alignment.center,
  //         child: const SizedBox(
  //           height: 28,
  //           width: 28,
  //           child: CircularProgressIndicator(strokeWidth: 2),
  //         ),
  //       ),
  //       errorWidget: (context, url, error) => Container(
  //         height: 150,
  //         color: AppColors.muted,
  //         alignment: Alignment.center,
  //         child: const Icon(Icons.broken_image_outlined),
  //       ),
  //       errorListener: (error) {
  //         debugPrint('Home hero image load failed: $error');
  //       },
  //     ),
  //   );
  // }

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
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final category in foodCategories)
            CategoryChip(
              emoji: category['emoji']!,
              label: category['label']!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FilterSearchPage(
                    initialCategory: category['label']!,
                  ),
                ),
              ),
            ),
        ],
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
                for (final item in items) _buildFoodCard(context, item),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final item in items)
              _DeliciousTile(
                item: item,
                onTap: () => _openDetails(context, item),
                onAdd: () => _addToCart(context, item),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFoodCard(BuildContext context, FoodItem item) {
    return FoodCard(
      title: item.title,
      subtitle: item.subtitle,
      imagePath: item.imagePath,
      price: item.priceLabel,
      onAdd: () => _addToCart(context, item),
      onTap: () => _openDetails(context, item),
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
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final categoryController = TextEditingController();
    final priceController = TextEditingController();
    final ratingController = TextEditingController(text: '4.5');
    final timeController = TextEditingController();
    final caloriesController = TextEditingController();
    final descriptionController = TextEditingController();
    final ingredientsController = TextEditingController();
    final imageUrlController = TextEditingController(
      text: 'https://picsum.photos/seed/dineease/800/600',
    );
    bool popular = true;
    bool delicious = true;
    String previewUrl = imageUrlController.text.trim();
    double ratingValue = 4.5;
    const categories = [
      'Heavy Meal',
      'Rice & Bean Meal',
      'Side Dishes & Snacks',
    ];
    String? selectedCategory;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Add Food', style: AppTextStyles.heading),
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _imagePreview(previewUrl),
                      const SizedBox(height: 14),
                      _sheetField(
                        'Image URL',
                        controller: imageUrlController,
                        onChanged: (value) =>
                            setState(() => previewUrl = value.trim()),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Image URL is required';
                          }
                          if (!value.trim().startsWith('http')) {
                            return 'Use a valid https URL';
                          }
                          return null;
                        },
                      ),
                      _sheetField(
                        'Title',
                        controller: titleController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      _sheetField('Subtitle', controller: subtitleController),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          filled: true,
                          fillColor: AppColors.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          for (final category in categories)
                            DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() => selectedCategory = value);
                          categoryController.text = value ?? '';
                        },
                        validator: (value) =>
                            value == null ? 'Category is required' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _sheetField(
                              'Price (GHS)',
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final number =
                                    double.tryParse(value?.trim() ?? '');
                                if (number == null || number <= 0) {
                                  return 'Enter a valid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rating', style: AppTextStyles.subtitle),
                                Slider(
                                  value: ratingValue,
                                  min: 1,
                                  max: 5,
                                  divisions: 8,
                                  label: ratingValue.toStringAsFixed(1),
                                  onChanged: (value) {
                                    setState(() => ratingValue = value);
                                    ratingController.text =
                                        value.toStringAsFixed(1);
                                  },
                                ),
                                Text(
                                  ratingValue.toStringAsFixed(1),
                                  style: AppTextStyles.subtitle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: timeController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Time',
                                filled: true,
                                fillColor: AppColors.card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onTap: () async {
                                final minutes = await _pickDuration(context);
                                if (minutes != null) {
                                  final min = (minutes - 2).clamp(1, 999);
                                  final max = minutes + 2;
                                  setState(() {
                                    timeController.text = '$min-$max min';
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Time is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _sheetField(
                              'Calories',
                              controller: caloriesController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) return null;
                                final number = int.tryParse(value!.trim());
                                if (number == null || number < 0) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      _sheetField(
                        'Description',
                        controller: descriptionController,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                      _sheetField(
                        'Ingredients (comma separated)',
                        controller: ingredientsController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingredients are required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Placement', style: AppTextStyles.title),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: popular,
                                  onChanged: (value) =>
                                      setState(() => popular = value ?? false),
                                ),
                                const Text('Popular Food'),
                                const SizedBox(width: 12),
                                Checkbox(
                                  value: delicious,
                                  onChanged: (value) => setState(
                                      () => delicious = value ?? false),
                                ),
                                const Text('Delicious Foods'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() != true) {
                              return;
                            }
                            _showSavingDialog(context);
                            final price =
                                double.tryParse(priceController.text.trim()) ??
                                    0;
                            final rating = double.tryParse(
                                  ratingController.text.trim(),
                                ) ??
                                0;
                            final calories = int.tryParse(
                                  caloriesController.text.trim(),
                                ) ??
                                0;
                            final types = <String>[];
                            if (popular) types.add('Popular Food');
                            if (delicious) types.add('Delicious Foods');
                            final ingredients = ingredientsController.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();

                            try {
                              await FirebaseFirestore.instance
                                  .collection('foods')
                                  .add({
                                'title': titleController.text.trim(),
                                'subtitle': subtitleController.text.trim(),
                                'category': categoryController.text.trim(),
                                'description':
                                    descriptionController.text.trim(),
                                'imageUrl': imageUrlController.text.trim(),
                                'time': timeController.text.trim(),
                                'price': price,
                                'rating': rating,
                                'calories': calories,
                                'ingredients': ingredients,
                                'foodType': types,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                              if (context.mounted) {
                                Navigator.pop(context); // close loading
                                Navigator.pop(context); // close sheet
                                showInfoDialog(
                                  context,
                                  title: 'Food added',
                                  message:
                                      'Food was added successfully to the menu.',
                                );
                              }
                            } on FirebaseException catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context); // close loading
                                showInfoDialog(
                                  context,
                                  title: 'Add failed',
                                  message: e.message ??
                                      'You do not have permission to add foods.',
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                Navigator.pop(context); // close loading
                                showInfoDialog(
                                  context,
                                  title: 'Add failed',
                                  message: 'Something went wrong. Try again.',
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Save Food',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
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

  Widget _imagePreview(String url) {
    final safeUrl = url.trim();
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: safeUrl.isEmpty
            ? const Center(child: Icon(Icons.image_outlined, size: 40))
            : CachedNetworkImage(
                imageUrl: safeUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }

  void _showSavingDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Row(
            children: [
              const SizedBox(
                height: 36,
                width: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Saving food...',
                  style: AppTextStyles.subtitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int?> _pickDuration(BuildContext context) async {
    int selected = 20;
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Cooking Time', style: AppTextStyles.heading),
                  const SizedBox(height: 6),
                  Text(
                    '$selected min',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: selected.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '$selected min',
                    onChanged: (value) =>
                        setState(() => selected = value.round()),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Set Time',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetField(
    String label, {
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _DeliciousTile extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _DeliciousTile({
    required this.item,
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
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: item.imagePath.startsWith('https')
            ? CachedNetworkImage(
                imageUrl: item.imagePath,
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
                  debugPrint('Home tile image load failed: ${item.imagePath}');
                  debugPrint('Home tile image error: $error');
                },
              )
            : item.imagePath.trim().isEmpty
                ? Container(
                    width: 90,
                    height: 90,
                    color: AppColors.muted,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  )
                : Image.asset(
                    item.imagePath,
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
            ),
          ],
        ),
      ],
    );
  }
}
