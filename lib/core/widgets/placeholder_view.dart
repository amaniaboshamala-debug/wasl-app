import 'package:flutter/material.dart';
import 'package:wasl/core/theme/app_colors.dart';

/// شاشة مؤقتة لحد ما نبني الشاشة الحقيقية.
class PlaceholderView extends StatelessWidget {
  final String title;
  const PlaceholderView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text('قيد البناء 🛠️', style: TextStyle(color: AppColors.muted, fontSize: 16)),
      ),
    );
  }
}
