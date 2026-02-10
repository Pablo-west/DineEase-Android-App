import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title, style: AppTextStyles.title),
        content: Text(message, style: AppTextStyles.subtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
