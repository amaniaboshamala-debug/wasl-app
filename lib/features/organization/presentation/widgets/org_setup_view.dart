import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/regions.dart';
import 'package:wasl/features/organization/presentation/cubit/my_org_cubit.dart';

/// أول مرة بيدخل حساب المؤسسة: بيعبّي معلومات المؤسسة أو الفريق.
class OrgSetupView extends StatefulWidget {
  final MyOrgMissing state;
  const OrgSetupView(this.state, {super.key});

  @override
  State<OrgSetupView> createState() => _OrgSetupViewState();
}

class _OrgSetupViewState extends State<OrgSetupView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _contact = TextEditingController();
  String? _region;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    context.read<MyOrgCubit>().create(
          name: _name.text,
          bio: _bio.text,
          region: _region ?? '',
          contact: _contact.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final saving = widget.state.saving;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        children: [
          const Text('أهلاً بمؤسستك في وَصْل 🤝', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'عبّي معلومات المؤسسة أو الفريق، وبعدها بتقدري تنشري فرص وتستقبلي متطوعين.',
            style: TextStyle(color: AppColors.muted, height: 1.6),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'اسم المؤسسة أو الفريق'),
            validator: (v) => (v?.trim().length ?? 0) < 3 ? 'اكتبي اسم من 3 أحرف أو أكتر' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bio,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(labelText: 'نبذة قصيرة (شو بتعملوا؟)'),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _region,
            decoration: const InputDecoration(labelText: 'المنطقة'),
            items: [for (final r in Regions.all) DropdownMenuItem(value: r, child: Text(r))],
            onChanged: (v) => setState(() => _region = v),
            validator: (v) => v == null ? 'اختاري المنطقة' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contact,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'رقم للتواصل'),
            validator: (v) => (v?.replaceAll(RegExp(r'\D'), '').length ?? 0) < 9 ? 'اكتبي رقم صحيح' : null,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(14)),
            child: const Text(
              'حسابك رح يكون "قيد التوثيق" لحد ما فريق وَصْل يتأكد من المؤسسة. العلامة الخضرا ✓ بتطلع بعد التوثيق.',
              style: TextStyle(fontSize: 13, color: Color(0xFF0B4A61), height: 1.6),
            ),
          ),
          if (widget.state.error != null) ...[
            const SizedBox(height: 12),
            Text(widget.state.error!, style: const TextStyle(color: AppColors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : _submit,
            child: saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('إنشاء المؤسسة'),
          ),
        ],
      ),
    );
  }
}
