import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppLogoTitle extends StatelessWidget {
  final double logoSize;
  final double fontSize;

  const AppLogoTitle({
    super.key,
    this.logoSize = 36,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: logoSize,
          width: logoSize,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset(
            'assets/logo/logo-icon.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'DineEase',
          style: AppTextStyles.title.copyWith(fontSize: fontSize),
        ),
      ],
    );
  }
}
