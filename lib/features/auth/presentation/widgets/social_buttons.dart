import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/features/auth/domain/entities/app_user.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';

/// "أو" + زر Google
class SocialButtons extends StatelessWidget {
  const SocialButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(child: Divider(color: AppColors.line)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('أو', style: TextStyle(color: AppColors.muted)),
              ),
              Expanded(child: Divider(color: AppColors.line)),
            ],
          ),
        ),
        _SocialButton(
          label: 'المتابعة باستخدام Google',
          // الشعار الرسمي من Google (حمّليه وحطيه بـ assets/images)
          icon: Image.asset(
            'assets/images/google_logo.png',
            width: 22,
            height: 22,
            errorBuilder: (_, __, ___) => const Text(
              'G',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4285F4)),
            ),
          ),
          background: Colors.white,
          foreground: AppColors.ink,
          border: AppColors.line,
          onTap: () => cubit.signInWith(SocialProvider.google),
        ),
        // زر Facebook مخفي لحد ما نفعّله على Supabase (Sign In / Providers)
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(color: border ?? background),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
