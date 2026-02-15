const List<String> defaultFoodCategoryLabels = [
  'Heavy Meal',
  'Rice & Bean Meal',
  'Side Dishes & Snacks',
];

const List<String> _categoryEmojiPool = [
  '🍛',
  '🍟',
  '🥗',
  '🍱',
  '🍔',
  '🍲',
  // '🍖',
];

List<String> normalizeCategoryLabels(Iterable<String> labels) {
  final normalized = <String>[];
  for (final raw in labels) {
    final value = raw.trim();
    if (value.isEmpty) continue;
    if (!normalized.any((item) => item.toLowerCase() == value.toLowerCase())) {
      normalized.add(value);
    }
  }
  if (normalized.isEmpty) {
    return List<String>.from(defaultFoodCategoryLabels);
  }
  return normalized;
}

String categoryEmojiForLabel(String label) {
  final normalized = label.trim();
  if (normalized.isEmpty) return '🍽️';
  final defaultIndex = defaultFoodCategoryLabels.indexWhere(
    (item) => item.toLowerCase() == normalized.toLowerCase(),
  );
  if (defaultIndex >= 0) {
    return _categoryEmojiPool[defaultIndex % _categoryEmojiPool.length];
  }

  int hash = 0;
  for (final unit in normalized.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _categoryEmojiPool[hash % _categoryEmojiPool.length];
}
