import 'package:flutter/material.dart';
import 'package:wasl/core/theme/app_colors.dart';

/// لون وأيقونة لكل تصنيف (تعليمية، صحية، نفسية...) زي التصميم.
class CategoryStyle {
  final IconData icon;
  final Color color;
  final Color soft;
  const CategoryStyle(this.icon, this.color, this.soft);

  static const _purple = Color(0xFF5B3F8C);
  static const _purpleSoft = Color(0xFFF3ECF8);

  static CategoryStyle of(String? category) {
    final c = category ?? '';
    if (c.contains('صح') || c.contains('طب')) {
      return const CategoryStyle(Icons.favorite_outline, AppColors.red, AppColors.redSoft);
    }
    if (c.contains('تعل') || c.contains('تدري')) {
      return const CategoryStyle(Icons.menu_book_outlined, AppColors.primary, AppColors.primarySoft);
    }
    if (c.contains('نفس')) {
      return const CategoryStyle(Icons.psychology_outlined, _purple, _purpleSoft);
    }
    if (c.contains('بيئ')) {
      return const CategoryStyle(Icons.eco_outlined, AppColors.primaryDark, AppColors.primarySoft);
    }
    if (c.contains('مهن')) {
      return const CategoryStyle(Icons.handyman_outlined, AppColors.blue, AppColors.blueSoft);
    }
    return const CategoryStyle(Icons.bolt_outlined, AppColors.orange, AppColors.orangeSoft);
  }
}
