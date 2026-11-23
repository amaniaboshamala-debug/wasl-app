import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_state.dart';
import 'package:wasl/features/auth/presentation/widgets/password_field.dart';

/// بتفتح لحالها لما المستخدم يضغط رابط "نسيت كلمة السر" من الإيميل.
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    context.read<AuthCubit>().updatePassword(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كلمة سر جديدة'), automaticallyImplyLeading: false),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is PasswordRecovery && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
          if (state is Authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تغيير كلمة السر ✅')),
            );
          }
        },
        builder: (context, state) {
          final saving = state is PasswordRecovery && state.saving;
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'اكتبي كلمة سر جديدة لحسابك.',
                  style: TextStyle(color: AppColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 24),
                PasswordField(
                  controller: _password,
                  label: 'كلمة السر الجديدة',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirm,
                  label: 'تأكيد كلمة السر',
                  textInputAction: TextInputAction.done,
                  onSubmitted: _submit,
                  validator: (v) => v != _password.text ? 'كلمتين السر مش متطابقات' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: saving ? null : _submit,
                  child: saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('حفظ كلمة السر'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
