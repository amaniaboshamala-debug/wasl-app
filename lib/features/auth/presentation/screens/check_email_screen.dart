import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_state.dart';

/// بعد إنشاء الحساب: "تفقدي إيميلك" + زر إعادة الإرسال.
/// لما يضغط الرابط بالإيميل، التطبيق بينفتح وبيدخل لحاله.
class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({super.key});

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  static const _wait = 60;
  int _seconds = _wait;
  bool _sending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = _wait);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) t.cancel();
      if (mounted) setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend(String email) async {
    setState(() => _sending = true);
    final error = await context.read<AuthCubit>().resendConfirmation(email);
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'بعتنالك الرابط مرة تانية 📩')),
    );
    if (error == null) _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;
    final email = state is AwaitingEmailConfirmation ? state.email : '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: const Icon(Icons.mark_email_unread_outlined, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('تفقدي إيميلك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text(
                'بعتنا رابط تأكيد على:',
                style: TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'افتحي الرسالة من نفس الجوال واضغطي "تأكيد الحساب"، والتطبيق بيفتح وبيدخلك لحاله.\nإذا ما لقيتيها، شوفي مجلد الرسائل غير المرغوب فيها (Spam).',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.6),
              ),
              const Spacer(),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: (_seconds > 0 || _sending || email.isEmpty) ? null : () => _resend(email),
                child: Text(_seconds > 0 ? 'إعادة الإرسال بعد $_seconds ثانية' : 'إعادة إرسال الرابط'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.read<AuthCubit>().backToLogin(),
                child: const Text('رجوع لتسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
