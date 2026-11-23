import 'package:flutter/material.dart';
import 'package:wasl/core/theme/app_colors.dart';

/// شريط التنقل السفلي "عائم": زوايا مدوّرة وظل خفيف.
class FloatingNav extends StatelessWidget {
  final Widget child;
  const FloatingNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), boxShadow: AppColors.shadow),
            child: ClipRRect(borderRadius: BorderRadius.circular(26), child: child),
          ),
        ),
      );
}
