// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/food_item.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_dialogs.dart';

class FoodDetailsPage extends StatefulWidget {
  final FoodItem item;

  const FoodDetailsPage({
    super.key,
    required this.item,
  });

  @override
  State<FoodDetailsPage> createState() => _FoodDetailsPageState();
}

class _FoodDetailsPageState extends State<FoodDetailsPage> {
  int _quantity = 1;
  String _customNote = '';

  void _increment() {
    setState(() => _quantity += 1);
  }

  void _decrement() {
    if (_quantity == 1) return;
    setState(() => _quantity -= 1);
  }

  // Dialog to capture user customization text
  void _showCustomizationDialog() {
    final TextEditingController controller =
        TextEditingController(text: _customNote);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Customize Order', style: AppTextStyles.heading),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Extra spicy, no onions...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            contentPadding: EdgeInsets.all(16),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() {
                _customNote = controller.text;
              });
              Navigator.pop(context);
            },
            child:
                const Text('Save Note', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final size = MediaQuery.of(context).size;
    // Image takes up 45% of the screen height
    final double imageHeight = size.height * 0.45;
    // Content starts 40 pixels before the image ends to create the overlay effect
    final double contentTopOffset = imageHeight - 40;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Background Image (Covers status bar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: item.imagePath.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: item.imagePath,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image_outlined),
                    errorListener: (error) {
                      debugPrint(
                        'FoodDetails image load failed: ${item.imagePath}',
                      );
                      debugPrint('FoodDetails image error: $error');
                    },
                  )
                : item.imagePath.trim().isEmpty
                    ? Container(
                        color: AppColors.muted,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      )
                    : Image.asset(
                        item.imagePath,
                        fit: BoxFit.cover,
                      ),
          ),

          // 2. White Overlay Container containing details
          Positioned(
            top: contentTopOffset,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      children: [
                        // Title and Heart Icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: AppTextStyles.heading
                                    .copyWith(fontSize: 22),
                              ),
                            ),
                            Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.muted),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child:
                                  const Icon(Icons.favorite_border, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'From: ${item.priceLabel}',
                          style: AppTextStyles.subtitle.copyWith(
                            color: const Color(0xFFFF6600),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _infoRow(item),
                        const SizedBox(height: 18),
                        Text('Description', style: AppTextStyles.title),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: AppTextStyles.body.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 18),
                        Text('Ingredients', style: AppTextStyles.title),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final ingredient in item.ingredients)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.muted,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  ingredient,
                                  style: AppTextStyles.subtitle
                                      .copyWith(color: AppColors.textPrimary),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Customize Label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Customize', style: AppTextStyles.title),
                            Row(
                              children: [
                                Text(
                                  'More Details',
                                  style: AppTextStyles.subtitle.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.expand_more,
                                    size: 18, color: AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Quantity Selector AND Chat Button
                        Row(
                          children: [
                            _quantitySelector(),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: _showCustomizationDialog,
                                child: Container(
                                  height:
                                      48, // Match approximate height of qty selector
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: _customNote.isNotEmpty
                                        ? AppColors.primary.withOpacity(0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: _customNote.isNotEmpty
                                            ? AppColors.primary
                                            : AppColors.muted),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 20,
                                        color: _customNote.isNotEmpty
                                            ? AppColors.primary
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _customNote.isNotEmpty
                                              ? 'Note Added'
                                              : 'Add Note',
                                          style:
                                              AppTextStyles.subtitle.copyWith(
                                            color: _customNote.isNotEmpty
                                                ? AppColors.primary
                                                : Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (_customNote.isNotEmpty) ...[
                                        const SizedBox(width: 4),
                                        Icon(Icons.check,
                                            size: 16, color: AppColors.primary),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Add to Cart Button Area
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: _addToCartButton(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Custom App Bar / Header (Overlays the Image)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                    Text(
                      'Details',
                      style: AppTextStyles.title.copyWith(
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3.0,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    _circleButton(
                      icon: Icons.ios_share_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
    );
  }

  Widget _infoRow(FoodItem item) {
    return Row(
      children: [
        _infoMetric(Icons.star, item.rating.toStringAsFixed(1)),
        _divider(),
        _infoMetric(Icons.timer, item.time),
        _divider(),
        _infoMetric(Icons.local_fire_department, '${item.calories} Kcal'),
      ],
    );
  }

  Widget _infoMetric(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.subtitle),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 16,
        width: 1,
        color: AppColors.muted,
      ),
    );
  }

  Widget _quantitySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.muted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyButton(Icons.remove, _decrement, isPrimary: false),
          const SizedBox(width: 10),
          Text(
            _quantity.toString().padLeft(2, '0'),
            style: AppTextStyles.title,
          ),
          const SizedBox(width: 10),
          _qtyButton(Icons.add, _increment, isPrimary: true),
        ],
      ),
    );
  }

  Widget _addToCartButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final item = widget.item;
        // In a real app, you would also pass _customNote here
        AppScope.of(context).addToCartWithQuantity(item, _quantity);

        showInfoDialog(
          context,
          title: 'Added to Cart',
          message: '${item.title} added ($_quantity) to cart.',
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6600), // hot orange
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 2,
      ),
      child: const Text(
        'Add to Cart',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap,
      {required bool isPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: isPrimary ? Colors.black : Colors.white,
        child: Icon(
          icon,
          size: 16,
          color: isPrimary ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}
