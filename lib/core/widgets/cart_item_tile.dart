import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CartItemTile extends StatelessWidget {
  final FoodItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: item.imagePath.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: item.imagePath,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image_outlined),
                  )
                : item.imagePath.trim().isEmpty
                    ? Container(
                        width: 64,
                        height: 64,
                        color: AppColors.muted,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      )
                    : Image.asset(
                        item.imagePath,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(item.subtitle, style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                Text(item.priceLabel, style: AppTextStyles.price),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _qtyButton(Icons.remove, onRemove),
              Text(quantity.toString(), style: AppTextStyles.title),
              _qtyButton(Icons.add, onAdd),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.muted,
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}
