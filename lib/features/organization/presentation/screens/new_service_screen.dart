import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/regions.dart';
import 'package:wasl/features/organization/domain/repositories/org_repository.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';
import 'package:wasl/features/services/presentation/cubit/services_cubit.dart';

/// نشر خدمة مجانية (عيادة، نقطة شحن، دروس...).
class NewServiceScreen extends StatefulWidget {
  const NewServiceScreen({super.key});

  static const categories = ['صحة', 'تعليم', 'دعم نفسي', 'تدريب', 'خدمات عامة'];

  @override
  State<NewServiceScreen> createState() => _NewServiceScreenState();
}

class _NewServiceScreenState extends State<NewServiceScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _beneficiaries = TextEditingController();
  final _schedule = TextEditingController();
  final _how = TextEditingController();
  String _category = NewServiceScreen.categories.first;
  String? _region;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _description, _beneficiaries, _schedule, _how]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final publicList = context.read<ServicesCubit>();
    final error = await context.read<OrgServicesCubit>().create(NewServiceInput(
          name: _name.text,
          category: _category,
          description: _description.text,
          beneficiaries: _beneficiaries.text,
          region: _region!,
          schedule: _schedule.text,
          howToBenefit: _how.text,
        ));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) {
      publicList.refresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انتشرت الخدمة 🎉')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خدمة جديدة')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'اسم الخدمة', hintText: 'مثلاً: عيادة أطفال مجانية'),
              validator: (v) => (v?.trim().length ?? 0) < 4 ? 'اكتبي اسم أوضح' : null,
            ),
            const SizedBox(height: 16),
            const Text('التصنيف', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in NewServiceScreen.categories)
                ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
            ]),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _region,
              decoration: const InputDecoration(labelText: 'المنطقة'),
              items: [for (final r in Regions.all) DropdownMenuItem(value: r, child: Text(r))],
              onChanged: (v) => setState(() => _region = v),
              validator: (v) => v == null ? 'اختاري المنطقة' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'شو بتقدّم الخدمة؟'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _beneficiaries,
              decoration: const InputDecoration(labelText: 'مين بيستفيد؟', hintText: 'مثلاً: الأطفال لعمر 12 سنة'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _schedule,
              decoration: const InputDecoration(labelText: 'المواعيد', hintText: 'مثلاً: السبت – الخميس · 9 ص – 1 م'),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'اكتبي المواعيد' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _how,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'كيف الناس بتستفيد؟', hintText: 'مثلاً: احضري مع الهوية'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.red)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.campaign_outlined),
            label: const Text('انشري الخدمة'),
          ),
        ),
      ),
    );
  }
}
