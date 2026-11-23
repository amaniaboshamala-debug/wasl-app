import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/utils/regions.dart';
import 'package:wasl/features/organization/presentation/cubit/my_org_cubit.dart';

/// تعديل معلومات المؤسسة (الاسم، النبذة، المنطقة، رقم التواصل). التوثيق ما بيتغيّر من هون.
class EditOrgScreen extends StatefulWidget {
  const EditOrgScreen({super.key});

  @override
  State<EditOrgScreen> createState() => _EditOrgScreenState();
}

class _EditOrgScreenState extends State<EditOrgScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _contact;
  String? _region;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final o = context.read<MyOrgCubit>().org;
    _name = TextEditingController(text: o?.name ?? '');
    _bio = TextEditingController(text: o?.bio ?? '');
    _contact = TextEditingController(text: o?.contact ?? '');
    final region = o?.region ?? '';
    _region = Regions.all.contains(region) ? region : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await context.read<MyOrgCubit>().update(
          name: _name.text,
          bio: _bio.text,
          region: _region ?? '',
          contact: _contact.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'انحفظت معلومات المؤسسة ✓')));
    if (error == null) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معلومات المؤسسة')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
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
              decoration: const InputDecoration(labelText: 'نبذة قصيرة'),
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
