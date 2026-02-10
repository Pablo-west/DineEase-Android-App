class FoodItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String imagePath;
  final String description;
  final List<String> ingredients;
  final List<String> foodTypes;
  final double price;
  final double rating;
  final String time;
  final int calories;

  const FoodItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.imagePath,
    required this.description,
    required this.ingredients,
    this.foodTypes = const [],
    required this.price,
    required this.rating,
    required this.time,
    required this.calories,
  });

  String get priceLabel => 'GHS${price.toStringAsFixed(2)}';

  static List<String> normalizeFoodTypes(List<dynamic>? raw) {
    if (raw == null) return const [];
    final normalized = <String>[];
    for (final value in raw) {
      final text = value.toString().trim();
      if (text.isEmpty) continue;
      final lower = text.toLowerCase();
      if (lower == 'popularfoods' ||
          lower == 'popular food' ||
          lower == 'popular foods') {
        normalized.add('popularFoods');
        continue;
      }
      if (lower == 'deliciousfoods' ||
          lower == 'delicious food' ||
          lower == 'delicious foods' ||
          lower == 'delicious items' ||
          lower == 'delicious item') {
        normalized.add('deliciousFoods');
        continue;
      }
      normalized.add(text);
    }
    return normalized.toSet().toList(growable: false);
  }

  static String normalizeImagePath(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Uri.encodeFull(value);
    }
    return value;
  }

  static String readStringField(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString();
      if (text.trim().isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
