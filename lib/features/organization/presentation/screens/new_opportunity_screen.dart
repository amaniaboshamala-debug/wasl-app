import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/utils/regions.dart';
import 'package:wasl/features/opportunities/presentation/cubit/opportunities_cubit.dart';
import 'package:wasl/features/organization/domain/repositories/org_repository.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';

/// نشر فرصة جديدة: العنوان والمهام، النوع (تطوع / بأجر)، المكان، المواعيد، العدد، والمهارات.
class NewOpportunityScreen extends StatefulWidget {
  const NewOpportunityScreen({super.key});

  @override
  State<NewOpportunityScreen> createState() => _NewOpportunityScreenState();
}

class _NewOpportunityScreenState extends State<NewOpportunityScreen> {
  static const _types = {
    'volunteer': 'تطوع بدون مقابل',
    'volunteer_allowance': 'تطوع مع بدل',
    'paid': 'عمل مؤقت بأجر',
  };

  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _tasks = TextEditingController();
  final _compensation = TextEditingController();
  final _location = TextEditingController();
  final _duration = TextEditingController();
  final _skill = TextEditingController();
  final _issuer = TextEditingController();
  bool _certificate = false;
  String _type = 'volunteer';
  bool _remote = false;
  String? _region;
  DateTime? _date;
  DateTime? _deadline;
  int _count = 3;
  final _skills = <String>[];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_title, _tasks, _compensation, _location, _duration, _skill, _issuer]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? current) => showDatePicker(
        context: context,
        initialDate: current ?? DateTime.now().add(const Duration(days: 1)),
        firstDate: DateUtils.dateOnly(DateTime.now()),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );

  void _addSkill() {
    final s = _skill.text.trim();
    if (s.isEmpty || _skills.contains(s)) return;
    setState(() {
      _skills.add(s);
      _skill.clear();
    });
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (_deadline == null) {
      setState(() => _error = 'اختاري آخر موعد للتقديم.');
      return;
    }
    if (_date != null && _deadline!.isAfter(_date!)) {
      setState(() => _error = 'آخر موعد للتقديم لازم يكون قبل موعد الفرصة.');
      return;
    }
    setState(() => _saving = true);
    final cubit = context.read<OrgOpportunitiesCubit>();
    final publicList = context.read<OpportunitiesCubit>();
    final error = await cubit.create(NewOpportunityInput(
      title: _title.text,
      tasks: _tasks.text,
      type: _type,
      compensation: _compensation.text,
      isRemote: _remote,
      region: _region,
      location: _location.text,
      date: _date,
      duration: _duration.text,
      applyDeadline: _deadline,
      volunteersNeeded: _count,
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انتشرت الفرصة 🎉')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فرصة جديدة')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'عنوان الفرصة', hintText: 'مثلاً: مساعدة في دروس تقوية'),
              validator: (v) => (v?.trim().length ?? 0) < 4 ? 'اكتبي عنوان أوضح' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tasks,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'شو المطلوب من المتطوع؟'),
              validator: (v) => (v?.trim().length ?? 0) < 10 ? 'اشرحي المهام بجملة أو جملتين' : null,
            ),
            const SizedBox(height: 18),
            const _Label('نوع الفرصة'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in _types.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _type == e.key,
                  onSelected: (_) => setState(() => _type = e.key),
                ),
            ]),
            if (_type != 'volunteer') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _compensation,
                decoration: InputDecoration(
                  labelText: _type == 'paid' ? 'الأجر' : 'البدل',
                  hintText: _type == 'paid' ? 'مثلاً: 50 ₪ يومياً' : 'مثلاً: بدل مواصلات',
                ),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'اكتبي قيمة الأجر أو نوع البدل' : null,
              ),
              const SizedBox(height: 6),
              const Text(
                'الدفع بيصير بينك وبين المتطوع مباشرة. وَصْل ما بيستقبل ولا بيحوّل أموال.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('عن بُعد', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('المتطوع بيشتغل من بيته'),
              value: _remote,
              onChanged: (v) => setState(() => _remote = v),
            ),
            if (!_remote) ...[
              DropdownButtonFormField<String>(
                initialValue: _region,
                decoration: const InputDecoration(labelText: 'المنطقة'),
                items: [for (final r in Regions.all) DropdownMenuItem(value: r, child: Text(r))],
                onChanged: (v) => setState(() => _region = v),
                validator: (v) => !_remote && v == null ? 'اختاري المنطقة' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'المكان بالتفصيل', hintText: 'مثلاً: مدرسة الرمال'),
              ),
            ],
            const SizedBox(height: 18),
            const _Label('المواعيد'),
            _DateTile(
              icon: Icons.calendar_today_outlined,
              label: 'موعد الفرصة (اختياري)',
              value: _date,
              onTap: () async {
                final d = await _pickDate(_date);
                if (d != null) setState(() => _date = d);
              },
            ),
            _DateTile(
              icon: Icons.schedule,
              label: 'آخر موعد للتقديم',
              value: _deadline,
              onTap: () async {
                final d = await _pickDate(_deadline);
                if (d != null) setState(() => _deadline = d);
              },
            ),
            TextFormField(
              controller: _duration,
              decoration: const InputDecoration(labelText: 'المدة (اختياري)', hintText: 'مثلاً: 3 ساعات، أسبوع'),
            ),
            const SizedBox(height: 18),
            const _Label('كم متطوع بدك؟'),
            Row(children: [
              IconButton.outlined(
                tooltip: 'أقل',
                onPressed: _count > 1 ? () => setState(() => _count--) : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text('$_count', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              IconButton.outlined(
                tooltip: 'أكتر',
                onPressed: _count < 200 ? () => setState(() => _count++) : null,
                icon: const Icon(Icons.add),
              ),
            ]),
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('📜 بنعطي شهادة تطوع مصدّقة', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('بتطلع شارة على الفرصة، والمتطوعين بيلاقوها بتبويب "شهادة"'),
              value: _certificate,
              onChanged: (v) => setState(() => _certificate = v),
            ),
            if (_certificate)
              TextFormField(
                controller: _issuer,
                decoration: const InputDecoration(
                  labelText: 'مين بيصدّق الشهادة؟ (اختياري)',
                  hintText: 'مثلاً: وزارة التنمية الاجتماعية',
                ),
              ),
            const SizedBox(height: 18),
            const _Label('مهارات مفيدة (اختياري)'),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _skill,
                  decoration: const InputDecoration(hintText: 'مثلاً: تدريس، إسعاف أولي'),
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: const TextStyle(color: AppColors.red)),
              ),
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
            label: const Text('انشري الفرصة'),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      );
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateTile({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(label)),
                Text(
                  value == null ? 'اختاري' : DateAr.day(value!),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: value == null ? AppColors.muted : AppColors.ink,
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}
