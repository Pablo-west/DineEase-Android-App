import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_dialogs.dart';

class UserPromotionPage extends StatelessWidget {
  final PromotionAd promotion;

  const UserPromotionPage({
    super.key,
    required this.promotion,
  });

  static Future<void> showIfActive(BuildContext context) async {
    final promotion = await _loadActivePromotion();
    if (!context.mounted || promotion == null || !promotion.active) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Close promotion',
      pageBuilder: (context, animation, secondaryAnimation) {
        return UserPromotionPage(promotion: promotion);
      },
    );
  }

  static Future<PromotionAd?> _loadActivePromotion() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .where('active', isEqualTo: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      final title = _readString(
        data,
        const ['promoTitle', 'title', 'promo_title'],
      );
      final description = _readString(
        data,
        const ['description', 'desc', 'promoDescription'],
      );
      final imageUrl = _cleanUrl(
        _readString(
          data,
          const [
            'imageUrl',
            'imageURL',
            'imageUrl ',
            'imageURL ',
            'image_url',
            'promoImageUrl',
            'bannerUrl',
            'image',
          ],
        ),
      );
      final targetUrl = _cleanUrl(
        _readString(
          data,
          const [
            'targetUrl',
            'targetURL',
            'target_url',
            'link',
            'url',
          ],
        ),
      );

      return PromotionAd(
        title: title,
        description: description,
        imageUrl: imageUrl,
        targetUrl: targetUrl.isEmpty ? null : targetUrl,
        active: _readBool(data['active']),
      );
    } catch (_) {
      return null;
    }
  }

  static String _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value == null) return false;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  static String _cleanUrl(String value) {
    if (value.isEmpty) return value;
    return value.trim().replaceAll('"', '').replaceAll("'", '');
  }

  static bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return false;
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  Future<void> _openTargetUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      showInfoDialog(
        context,
        title: 'Link unavailable',
        message: 'Could not open this promotion link.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidImageUrl = _isHttpUrl(promotion.imageUrl);
    return Material(
      color: Colors.black.withOpacity(0.81),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: hasValidImageUrl
                  ? CachedNetworkImage(
                      imageUrl: promotion.imageUrl,
                      fit: BoxFit.fill,
                      placeholder: (context, url) => Container(
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _PromotionFallbackBackground(),
                    )
                  : _PromotionFallbackBackground(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.28),
                      Colors.black.withOpacity(0.68),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Material(
                    color: Colors.black.withOpacity(0.25),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111).withOpacity(0.52),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PROMOTION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          promotion.title.isEmpty
                              ? 'Special Offer'
                              : promotion.title,
                          style: AppTextStyles.heading.copyWith(
                            color: Colors.white,
                            fontSize: 29,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (promotion.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            promotion.description,
                            style: AppTextStyles.subtitle.copyWith(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (promotion.targetUrl != null) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 44,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _openTargetUrl(context, promotion.targetUrl!),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const Text('Find out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF151515),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionFallbackBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF131313),
            const Color(0xFF202020),
            AppColors.primary.withOpacity(0.72),
          ],
        ),
      ),
    );
  }
}

class PromotionAd {
  final String title;
  final String description;
  final String imageUrl;
  final String? targetUrl;
  final bool active;

  const PromotionAd({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.targetUrl,
    required this.active,
  });
}
