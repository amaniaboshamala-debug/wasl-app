import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/utils/regions.dart';
import 'package:wasl/features/initiatives/presentation/cubit/initiatives_cubit.dart';
import 'package:wasl/features/organization/domain/repositories/org_repository.dart';
import 'package:wasl/features/organization/presentation/cubit/my_org_cubit.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';

/// نشر مبادرة جديدة.
class NewInitiativeScreen extends StatefulWidget {
  const NewInitiativeScreen({super.key});

  static const categories = ['تعليمية', 'صحية', 'نفسية', 'بيئية', 'إغاثية', 'مهنية', 'ثقافية'];

  @override
  State<NewInitiativeScreen> createState() => _NewInitiativeScreenState();
}

class _NewInitiativeScreenState extends State<NewInitiativeScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _skill = TextEditingController();
  final _issuer = TextEditingController();
  String _category = NewInitiativeScreen.categories.first;
  String? _region;
  DateTimeRange? _dates;
  int _volunteers = 5;
  final _skills = <String>[];
  bool _certificate = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_title, _description, _skill, _issuer]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDates() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final r = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _dates,
    );
    if (r != null) setState(() => _dates = r);
  }

  void _addSkill() {
    final s = _skill.text.trim();
    if (s.isEmpty || _skills.contains(s)) return;
    setState(() {
      _skills.add(s);
      _skill.clear();
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final verified = context.read<MyOrgCubit>().org?.isVerified ?? false;
    final publicList = context.read<InitiativesCubit>();
    final error = await context.read<OrgInitiativesCubit>().create(NewInitiativeInput(
          title: _title.text,
          description: _description.text,
          category: _category,
          region: _region!,
          startDate: _dates?.start,
          endDate: _dates?.end,
          volunteersNeeded: _volunteers,
          skills: _skills,
          offersCertificate: _certificate,
          certificateIssuer: _issuer.text,
        ));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) {
      publicList.refresh();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(verified ? 'انتشرت المبادرة 🎉' : 'انبعتت المبادرة لفريق وَصْل للمراجعة، وبتنتشر بعد الموافقة.'),
      ));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = context.watch<MyOrgCubit>().org?.isVerified ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('مبادرة جديدة')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            if (!verified)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  'مؤسستك لسا قيد التوثيق، فالمبادرة رح تستنى موافقة فريق وَصْل قبل ما تطلع للناس.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7A3E00)),
                ),
              ),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'اسم المبادرة', hintText: 'مثلاً: تعلّم وارتقِ'),
              validator: (v) => (v?.trim().length ?? 0) < 4 ? 'اكتبي اسم أوضح' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'عن المبادرة', hintText: 'شو بتعملوا، ولمين، وليش؟'),
              validator: (v) => (v?.trim().length ?? 0) < 20 ? 'اكتبي وصف من جملتين على الأقل' : null,
            ),
            const SizedBox(height: 16),
            const Text('التصنيف', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in NewInitiativeScreen.categories)
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range, color: AppColors.primary),
              title: const Text('الموعد (اختياري)'),
              subtitle: Text(_dates == null ? 'اختاري من لـ' : DateAr.range(_dates!.start, _dates!.end)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDates,
            ),
            const SizedBox(height: 8),
            const Text('كم متطوع بتحتاج المبادرة تقريباً؟', style: TextStyle(fontWeight: FontWeight.w700)),
            Row(children: [
              IconButton.outlined(
                tooltip: 'أقل',
                onPressed: _volunteers > 0 ? () => setState(() => _volunteers--) : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text('$_volunteers', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              IconButton.outlined(
                tooltip: 'أكتر',
                onPressed: () => setState(() => _volunteers++),
                icon: const Icon(Icons.add),
              ),
            ]),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('📜 بنعطي شهادة تطوع مصدّقة', style: TextStyle(fontWeight: FontWeight.w700)),
              value: _certificate,
              onChanged: (v) => setState(() => _certificate = v),
            ),
            if (_certificate)
              TextFormField(
                controller: _issuer,
                decoration: const InputDecoration(labelText: 'مين بيصدّق الشهادة؟ (اختياري)'),
              ),
            const SizedBox(height: 16),
            const Text('مهارات مفيدة (اختياري)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _skill,
                  decoration: const InputDecoration(hintText: 'مثلاً: تدريس'),
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(tooltip: 'إضافة', onPressed: _addSkill, icon: const Icon(Icons.add)),
            ]),
            if (_skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in _skills) InputChip(label: Text(s), onDeleted: () => setState(() => _skills.remove(s))),
              ]),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.red)),
            ],
            const SizedBox(height: 8),
            const Text(
              'بعد ما تنشري المبادرة، بتقدري تضيفي احتياجاتها (أغراض، مكان...) من صفحتها.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
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
            label: const Text('انشري المبادرة'),
          ),
        ),
      ),
    );
  }
}
