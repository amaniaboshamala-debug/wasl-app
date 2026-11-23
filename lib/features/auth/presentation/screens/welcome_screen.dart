import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/theme/app_theme.dart';
import 'package:wasl/core/widgets/illustrations.dart';
import 'package:wasl/features/auth/presentation/widgets/social_buttons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // دوائر ناعمة بالخلفية
        const PositionedDirectional(
          top: -80,
          end: -60,
          child: _Blob(300, AppColors.orangeSoft),
        ),
        const PositionedDirectional(
          top: 260,
          start: -90,
          child: _Blob(240, Color(0xFFE7EFE9)),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.link, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text('وَصْل', style: AppTheme.heading(size: 22, weight: FontWeight.w700, color: AppColors.primaryDark)),
                ]),
                const Spacer(),
                const Illustration(Illustration.hero, label: 'متطوعتين ماسكين قلب', height: 210),
                const SizedBox(height: 24),
                Text('بنوصل الخير\nلأصحابه',
                    textAlign: TextAlign.center, style: AppTheme.heading(size: 28, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                const Text(
                  'مبادرات وخدمات وفرص تطوع حواليكِ بغزة، بمكان واحد وبأمان.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.8, color: Color(0xFF4E5A55)),
                ),
                const Spacer(),
                FilledButton(onPressed: () => context.push(Routes.signUp), child: const Text('يلا نبلّش')),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  onPressed: () => context.push(Routes.login),
                  child: const Text('عندي حساب'),
                ),
                const SocialButtons(),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
