import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/regions.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/profile/presentation/cubit/profile_cubit.dart';

/// تعديل الملف الشخصي: الاسم، المنطقة، رقم الجوال، نبذة، والمهارات.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  /// مهارات جاهزة للاختيار السريع (وبتقدري تضيفي غيرها)
  static const suggested = [
    'تدريس', 'إسعاف أولي', 'دعم نفسي', 'تصميم', 'تنظيم فعاليات', 'إكسل',
    'إنجليزي', 'تصوير', 'عمل ميداني', 'رسم', 'برمجة', 'كتابة',
  ];

  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _bio;
  final _newSkill = TextEditingController();
  String? _region;
  late final List<String> _skills;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileCubit>().profile;
    _name = TextEditingController(text: p?.name ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _bio = TextEditingController(text: p?.bio ?? '');
    final region = p?.region ?? '';
    _region = Regions.all.contains(region) ? region : null;
    _skills = [...?p?.skills];
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _bio, _newSkill]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggle(String s) => setState(() => _skills.contains(s) ? _skills.remove(s) : _skills.add(s));

  void _addSkill() {
    final s = _newSkill.text.trim();
    if (s.isEmpty || _skills.contains(s)) return;
    setState(() {
      _skills.add(s);
      _newSkill.clear();
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = context.read<AuthCubit>();
    final error = await context.read<ProfileCubit>().save(
          name: _name.text,
          region: _region ?? '',
          skills: _skills,
          phone: _phone.text,
          bio: _bio.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'انحفظت التعديلات ✓')));
    if (error == null) {
      auth.checkSession(); // عشان الاسم الجديد يبين بكل التطبيق
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = {...suggested, ..._skills}.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل ملفي')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'الاسم'),
              validator: (v) => (v?.trim().length ?? 0) < 2 ? 'اكتبي اسمك' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _region,
              decoration: const InputDecoration(labelText: 'المنطقة'),
              items: [for (final r in Regions.all) DropdownMenuItem(value: r, child: Text(r))],
              onChanged: (v) => setState(() => _region = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'رقم الجوال', hintText: '059xxxxxxx'),
              validator: (v) {
                final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                return digits.isNotEmpty && digits.length < 9 ? 'الرقم قصير' : null;
              },
            ),
            const SizedBox(height: 4),
            const Text('بيتعبّى لحاله لما تقدّمي على فرصة', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bio,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'نبذة عنك (اختياري)'),
            ),
            const SizedBox(height: 8),
            const Text('مهاراتي', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in options)
                FilterChip(
                  label: Text(s),
                  selected: _skills.contains(s),
                  onSelected: (_) => _toggle(s),
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: _skills.contains(s) ? Colors.white : AppColors.ink),
                ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _newSkill,
                  decoration: const InputDecoration(hintText: 'مهارة تانية...'),
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(tooltip: 'إضافة', onPressed: _addSkill, icon: const Icon(Icons.add)),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('حفظ'),
          ),
        ),
      ),
    );
  }
}
