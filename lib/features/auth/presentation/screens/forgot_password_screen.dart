import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';

/// "نسيت كلمة السر": بنبعت رابط على الإيميل، ولما يفتحه بيوصل لشاشة كلمة السر الجديدة.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    final error = await context.read<AuthCubit>().sendPasswordReset(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = error == null;
    });
    if (error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نسيت كلمة السر')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _sent
                  ? 'بعتنالك رابط على ${_email.text.trim()} 📩\nافتحيه من نفس الجوال، وبيفتحلك التطبيق على شاشة كلمة السر الجديدة.'
                  : 'اكتبي إيميلك، وبنبعتلك رابط تغيّري فيه كلمة السر.',
              style: const TextStyle(color: AppColors.muted, height: 1.6, fontSize: 15),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _email,
              enabled: !_sent,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              validator: (v) => (v == null || !v.contains('@')) ? 'أدخلي بريد صحيح' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sending ? null : (_sent ? () => setState(() => _sent = false) : _submit),
              child: _sending
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(_sent ? 'ما وصلني، ابعت مرة تانية' : 'إرسال الرابط'),
            ),
          ],
        ),
      ),
    );
  }
}
