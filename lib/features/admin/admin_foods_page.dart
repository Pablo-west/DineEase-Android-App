// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/models/food_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_logo_title.dart';
import '../../core/widgets/app_dialogs.dart';

class AdminFoodsPage extends StatefulWidget {
  const AdminFoodsPage({super.key});

  @override
  State<AdminFoodsPage> createState() => _AdminFoodsPageState();
}

class _AdminFoodsPageState extends State<AdminFoodsPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLogoTitle(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Foods', style: AppTextStyles.heading),
                IconButton(
                  onPressed: () => _showFoodSheet(context),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _searchBar(),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('foods')
                    .orderBy('title')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Text(
                        'Loading foods...',
                        style: AppTextStyles.subtitle,
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No foods yet',
                        style: AppTextStyles.subtitle,
                      ),
                    );
                  }
                  final foods = snapshot.data!.docs
                      .map(_foodFromDoc)
                      .where(_matchesSearch)
                      .toList(growable: false);
                  if (foods.isEmpty) {
                    return Center(
                      child: Text(
                        'No foods match your search',
                        style: AppTextStyles.subtitle,
                      ),
                    );
                  }
                  return ListView(
                    children: [
                      for (final food in foods)
                        _FoodAdminCard(
                          food: food,
                          onEdit: () => _showFoodSheet(
                            context,
                            existing: food,
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
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search foods',
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

  bool _matchesSearch(FoodItem item) {
    if (_query.isEmpty) return true;
    final haystack = [
      item.title,
      item.subtitle,
      item.category,
    ].join(' ').toLowerCase();
    return haystack.contains(_query);
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

  Future<void> _showFoodSheet(
    BuildContext context, {
    FoodItem? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final subtitleController =
        TextEditingController(text: existing?.subtitle ?? '');
    final categoryController =
        TextEditingController(text: existing?.category ?? '');
    final priceController = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(2) : '',
    );
    final ratingController = TextEditingController(
      text: existing != null ? existing.rating.toStringAsFixed(1) : '4.5',
    );
    final timeController = TextEditingController(text: existing?.time ?? '');
    final caloriesController = TextEditingController(
      text: existing?.calories.toString() ?? '',
    );
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final ingredientsController = TextEditingController(
      text: existing?.ingredients.join(', ') ?? '',
    );
    final imageUrlController = TextEditingController(
      text: existing?.imagePath.isNotEmpty == true
          ? existing!.imagePath
          : 'https://picsum.photos/seed/dineease/800/600',
    );
    bool popular = existing?.foodTypes.contains('popularFoods') ?? true;
    bool delicious = existing?.foodTypes.contains('deliciousFoods') ?? true;
    double ratingValue = existing?.rating ?? 4.5;
    String previewUrl = imageUrlController.text.trim();
    const categories = [
      'Heavy Meal',
      'Rice & Bean Meal',
      'Side Dishes & Snacks',
    ];
    String? selectedCategory = existing?.category;

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
                          Text(
                            existing == null ? 'Add Food' : 'Edit Food',
                            style: AppTextStyles.heading,
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _imagePreview(previewUrl),
                      const SizedBox(height: 14),
                      _sheetField(
                        'Image URL',
                        controller: imageUrlController,
                        maxLines: 2,
                        onChanged: (value) =>
                            setState(() => previewUrl = value.trim()),
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
                      const SizedBox(height: 12),
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
                                final number =
                                    int.tryParse(value!.trim());
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
                                  onChanged: (value) =>
                                      setState(() => delicious = value ?? false),
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
                            final data = {
                              'title': titleController.text.trim(),
                              'subtitle': subtitleController.text.trim(),
                              'category': categoryController.text.trim(),
                              'description': descriptionController.text.trim(),
                              'imageUrl': imageUrlController.text.trim(),
                              'time': timeController.text.trim(),
                              'price': price,
                              'rating': rating,
                              'calories': calories,
                              'ingredients': ingredients,
                              'foodType': types,
                              'updatedAt': FieldValue.serverTimestamp(),
                            };
                            await _saveFood(
                              context,
                              existing?.id,
                              data,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            existing == null ? 'Save Food' : 'Update Food',
                            style: const TextStyle(color: Colors.white),
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

  Future<void> _saveFood(
    BuildContext context,
    String? foodId,
    Map<String, dynamic> data,
  ) async {
    _showSavingDialog(context);
    try {
      if (foodId == null) {
        await FirebaseFirestore.instance.collection('foods').add(data);
      } else {
        await FirebaseFirestore.instance.collection('foods').doc(foodId).update(data);
      }
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        showInfoDialog(
          context,
          title: 'Food saved',
          message: 'Food details saved successfully.',
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showInfoDialog(
          context,
          title: 'Save failed',
          message: e.message ?? 'You do not have permission.',
        );
      }
    }
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

class _FoodAdminCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onEdit;

  const _FoodAdminCard({
    required this.food,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: food.imagePath.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: food.imagePath,
                    width: 72,
                    height: 72,
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
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: AppColors.muted,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.title, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(food.category, style: AppTextStyles.subtitle),
                const SizedBox(height: 6),
                Text(
                  food.priceLabel,
                  style: AppTextStyles.price.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}
