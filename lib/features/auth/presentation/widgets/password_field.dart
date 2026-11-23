import 'package:flutter/material.dart';

/// خانة كلمة السر مع زر 👁️ لإظهارها وإخفائها.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'كلمة السر',
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  /// الشرط الافتراضي: 6 أحرف على الأقل.
  static String? minSix(String? v) => (v == null || v.length < 6) ? '6 أحرف على الأقل' : null;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted == null ? null : (_) => widget.onSubmitted!(),
      validator: widget.validator ?? PasswordField.minSix,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: _hidden ? 'إظهار كلمة السر' : 'إخفاء كلمة السر',
          icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}
