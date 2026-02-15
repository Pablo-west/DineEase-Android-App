// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dine_ease/core/data/food_categories.dart';
import 'package:dine_ease/global.dart';
import 'package:flutter/material.dart';
import '../../core/models/food_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/app_logo_title.dart';
import 'widgets/food_editor_sheet.dart';

class AdminFoodsPage extends StatefulWidget {
  const AdminFoodsPage({super.key});

  @override
  State<AdminFoodsPage> createState() => _AdminFoodsPageState();
}

class _AdminFoodsPageState extends State<AdminFoodsPage> {
  final _searchController = TextEditingController();
  String _query = '';

  CollectionReference<Map<String, dynamic>> get _foodsCollection =>
      FirebaseFirestore.instance.collection('foods');

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      FirebaseFirestore.instance.collection('food_categories');

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
                Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Manage Categories',
                      onPressed: () => _showManageCategoriesSheet(context),
                      icon: const Icon(Icons.category_outlined),
                    ),
                    IconButton(
                      tooltip: 'Add Food',
                      onPressed: () => _openFoodSheet(context),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _searchBar(),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _foodsCollection.orderBy('title').snapshots(),
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
                      _foodsSummaryCard(foods),
                      const SizedBox(height: 12),
                      for (final food in foods)
                        _FoodAdminCard(
                          food: food,
                          onEdit: () => _openFoodSheet(context, existing: food),
                          onDelete: () => _confirmDeleteFood(context, food),
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

  Widget _foodsSummaryCard(List<FoodItem> foods) {
    final total = foods.length;
    final categoryCount = <String, int>{};
    for (final food in foods) {
      categoryCount.update(food.category, (value) => value + 1, ifAbsent: () => 1);
    }
    final sortedFoods = foods
        .map((food) => '${food.title} (${food.category})')
        .toList(growable: false)
      ..sort();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.muted),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text('Foods Summary ($total)', style: AppTextStyles.title),
        subtitle: Text(
          '${categoryCount.length} categories',
          style: AppTextStyles.subtitle,
        ),
        children: [
          for (final entry in categoryCount.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${entry.key}: ${entry.value} food(s)',
                style: AppTextStyles.subtitle,
              ),
            ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text('All foods:', style: AppTextStyles.title),
          const SizedBox(height: 6),
          for (final foodLabel in sortedFoods)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                foodLabel,
                style: AppTextStyles.subtitle,
              ),
            ),
        ],
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

  Future<List<String>> _loadCategoryLabels() async {
    try {
      final snapshot = await _categoriesCollection.orderBy('label').get();
      final labels = snapshot.docs
          .map((doc) => (doc.data()['label'] ?? '').toString())
          .toList(growable: false);
      return normalizeCategoryLabels(labels);
    } catch (_) {
      return List<String>.from(defaultFoodCategoryLabels);
    }
  }

  Future<void> _openFoodSheet(
    BuildContext context, {
    FoodItem? existing,
  }) async {
    final categories = await _loadCategoryLabels();
    if (!context.mounted) return;

    await showFoodEditorSheet(
      context,
      existing: existing,
      categories: categories,
      onSave: (data, foodId) async {
        if (foodId == null) {
          await _foodsCollection.add(data);
        } else {
          await _foodsCollection.doc(foodId).update(data);
        }
      },
    );
  }

  Future<void> _confirmDeleteFood(BuildContext context, FoodItem food) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Food', style: AppTextStyles.title),
        content: Text(
          'Delete "${food.title}" from the menu?',
          style: AppTextStyles.subtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    _showProgressDialog(context, 'Deleting food...');
    try {
      await _foodsCollection.doc(food.id).delete();
      if (context.mounted) {
        Navigator.pop(context);
        showInfoDialog(
          context,
          title: 'Food deleted',
          message: '"${food.title}" was removed from the menu.',
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showInfoDialog(
          context,
          title: 'Delete failed',
          message: e.message ?? 'You do not have permission.',
        );
      }
    }
  }

  Future<void> _showManageCategoriesSheet(BuildContext context) async {
    final newCategoryController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Manage Categories', style: AppTextStyles.heading),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              TextField(
                controller: newCategoryController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'New category',
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _createCategory(context, newCategoryController),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _createCategory(context, newCategoryController),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Create Category',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _categoriesCollection.orderBy('label').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          'No categories yet. Add one to get started.',
                          style: AppTextStyles.subtitle,
                        ),
                      );
                    }
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        for (final doc in snapshot.data!.docs)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              (doc.data()['label'] ?? '').toString(),
                              style: AppTextStyles.title,
                            ),
                            subtitle: Text(
                              'Tap edit to rename this category',
                              style: AppTextStyles.subtitle,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _renameCategory(
                                    context,
                                    categoryDocId: doc.id,
                                    oldLabel:
                                        (doc.data()['label'] ?? '').toString(),
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () => _confirmDeleteCategory(
                                    context,
                                    categoryDocId: doc.id,
                                    label:
                                        (doc.data()['label'] ?? '').toString(),
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createCategory(
    BuildContext context,
    TextEditingController controller,
  ) async {
    try {
      final label = controller.text.trim();
      if (label.isEmpty) {
        showInfoDialog(
          context,
          title: 'Category required',
          message: 'Enter a category name.',
        );
        return;
      }

      final docId = _normalizeCategoryDocId(label);
      await _categoriesCollection.doc(docId).set({
        'label': label,
        'labelLower': label.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      controller.clear();
    } on FirebaseException catch (e) {
      if (context.mounted) {
        showInfoDialog(
          context,
          title: 'Create failed',
          message: e.message ?? 'You do not have permission.',
        );
      }
    }
  }

  Future<void> _renameCategory(
    BuildContext context, {
    required String categoryDocId,
    required String oldLabel,
  }) async {
    final controller = TextEditingController(text: oldLabel);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Rename Category', style: AppTextStyles.title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newLabel == null || newLabel.isEmpty || newLabel == oldLabel) return;

    try {
      if (!context.mounted) return;
      _showProgressDialog(context, 'Updating category...');
      await _categoriesCollection.doc(categoryDocId).update({
        'label': newLabel,
        'labelLower': newLabel.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _renameCategoryInFoods(oldLabel: oldLabel, newLabel: newLabel);
      if (context.mounted) {
        Navigator.pop(context);
        showInfoDialog(
          context,
          title: 'Category updated',
          message: 'Category renamed and related foods were updated.',
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.pop(context);
        }
        showInfoDialog(
          context,
          title: 'Update failed',
          message: e.message ?? 'You do not have permission.',
        );
      }
    }
  }

  String _normalizeCategoryDocId(String label) {
    final normalized = label.trim().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '-',
        );
    return normalized.isEmpty ? 'category' : normalized;
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context, {
    required String categoryDocId,
    required String label,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Category', style: AppTextStyles.title),
        content: Text(
          'Delete "$label"?',
          style: AppTextStyles.subtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final inUse = await _foodsCollection
          .where('category', isEqualTo: label)
          .limit(1)
          .get();
      if (inUse.docs.isNotEmpty) {
        if (context.mounted) {
          showInfoDialog(
            context,
            title: 'Category in use',
            message:
                'This category is still assigned to foods. Reassign foods before deleting.',
          );
        }
        return;
      }

      if (!context.mounted) return;
      _showProgressDialog(context, 'Deleting category...');
      await _categoriesCollection.doc(categoryDocId).delete();
      if (context.mounted) {
        Navigator.pop(context);
        showInfoDialog(
          context,
          title: 'Category deleted',
          message: '"$label" was deleted.',
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.pop(context);
        }
        showInfoDialog(
          context,
          title: 'Delete failed',
          message: e.message ?? 'You do not have permission.',
        );
      }
    }
  }

  Future<void> _renameCategoryInFoods({
    required String oldLabel,
    required String newLabel,
  }) async {
    final matchingFoods = await _foodsCollection
        .where('category', isEqualTo: oldLabel)
        .get();
    if (matchingFoods.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final foodDoc in matchingFoods.docs) {
      batch.update(foodDoc.reference, {
        'category': newLabel,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  void _showProgressDialog(BuildContext context, String message) {
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
                  message,
                  style: AppTextStyles.subtitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodAdminCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FoodAdminCard({
    required this.food,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final safeImagePath = food.imagePath.trim();
    final isSpecialScaled = safeImagePath == kSpecialScaledImageUrl;
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
            child: safeImagePath.startsWith('http')
                ? Transform.scale(
                    scale: isSpecialScaled ? 0.9 : 1.0,
                    child: CachedNetworkImage(
                      imageUrl: safeImagePath,
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
                    ),
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
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
