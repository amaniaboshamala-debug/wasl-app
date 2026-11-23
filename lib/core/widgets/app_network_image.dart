import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wasl/core/theme/app_colors.dart';

/// صورة من النت بتنحفظ على الجوال (Cache):
/// أول مرة بتنزل، وبعدها بتطلع فوراً حتى بدون نت.
/// استخدميها بكل مكان بدل Image.network.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: AppColors.line,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.muted),
    );

    if (url == null || url!.isEmpty) {
      return ClipRRect(borderRadius: borderRadius, child: fallback);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        // بنصغّر الصورة بالذاكرة على قد حجمها بالشاشة عشان ما تثقّل الجوال
        memCacheWidth: width == null ? null : (width! * 2).round(),
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, __) => Container(width: width, height: height, color: AppColors.line),
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
