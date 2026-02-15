// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dine_ease/core/data/food_categories.dart';
import 'package:dine_ease/core/models/food_item.dart';
import 'package:dine_ease/core/theme/app_colors.dart';
import 'package:dine_ease/core/theme/app_text_styles.dart';
import 'package:dine_ease/core/widgets/app_dialogs.dart';
import 'package:dine_ease/global.dart';
import 'package:flutter/material.dart';

Future<void> showFoodEditorSheet(
  BuildContext context, {
  FoodItem? existing,
  required List<String> categories,
  required Future<void> Function(
    Map<String, dynamic> data,
    String? foodId,
  ) onSave,
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
        : kSpecialScaledImageUrl,
  );
  bool popular = existing?.foodTypes.contains('popularFoods') ?? true;
  bool delicious = existing?.foodTypes.contains('deliciousFoods') ?? true;
  double ratingValue = existing?.rating ?? 4.5;
  String previewUrl = imageUrlController.text.trim();

  final availableCategories = normalizeCategoryLabels([
    ...categories,
    if ((existing?.category ?? '').trim().isNotEmpty) existing!.category,
  ]);
  String? selectedCategory =
      (existing?.category ?? '').trim().isEmpty ? null : existing!.category;

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
                      textInputAction: TextInputAction.next,
                      'Image URL',
                      controller: imageUrlController,
                      maxLines: 1,
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
                      textInputAction: TextInputAction.next,
                      'Title',
                      controller: titleController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    _sheetField(
                      textInputAction: TextInputAction.next,
                      'Subtitle',
                      controller: subtitleController,
                    ),
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
                        for (final category in availableCategories)
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
                            textInputAction: TextInputAction.next,
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Rating', style: AppTextStyles.subtitle),
                                  Text(
                                    ratingValue.toStringAsFixed(1),
                                    style: AppTextStyles.subtitle,
                                  ),
                                ],
                              ),
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
                            textInputAction: TextInputAction.next,
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
                      textInputAction: TextInputAction.next,
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
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
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
                          _showSavingDialog(context);
                          final price =
                              double.tryParse(priceController.text.trim()) ?? 0;
                          final rating =
                              double.tryParse(ratingController.text.trim()) ??
                                  0;
                          final calories =
                              int.tryParse(caloriesController.text.trim()) ?? 0;
                          final types = <String>[];
                          if (popular) types.add('popularFoods');
                          if (delicious) types.add('deliciousFoods');
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
                            if (existing == null)
                              'createdAt': FieldValue.serverTimestamp()
                            else
                              'updatedAt': FieldValue.serverTimestamp(),
                          };
                          try {
                            await onSave(data, existing?.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                              showInfoDialog(
                                context,
                                title: existing == null
                                    ? 'Food added'
                                    : 'Food updated',
                                message: existing == null
                                    ? 'Food was added successfully to the menu.'
                                    : 'Food details updated successfully.',
                              );
                            }
                          } on FirebaseException catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              showInfoDialog(
                                context,
                                title: existing == null
                                    ? 'Add failed'
                                    : 'Update failed',
                                message:
                                    e.message ?? 'You do not have permission.',
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              showInfoDialog(
                                context,
                                title: existing == null
                                    ? 'Add failed'
                                    : 'Update failed',
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
  final isSpecialScaled = safeUrl == kSpecialScaledImageUrl;
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
          : Transform.scale(
              scale: isSpecialScaled ? 0.3 : 1.0,
              child: CachedNetworkImage(
                imageUrl: safeUrl,
                fit: isSpecialScaled ? BoxFit.contain : BoxFit.cover,
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
    ),
  );
}

Widget _sheetField(
  String label, {
  required TextEditingController controller,
  TextInputAction? textInputAction,
  String? hint,
  int maxLines = 1,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  void Function(String)? onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      textInputAction: textInputAction,
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
