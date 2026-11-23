import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/applications/presentation/cubit/my_applications_cubit.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';
import 'package:wasl/features/opportunities/presentation/cubit/opportunities_cubit.dart';
import 'package:wasl/features/profile/presentation/cubit/profile_cubit.dart';

/// نموذج التقديم: ليش حابة تتطوعي (اختياري) · الأيام المتاحة · المهارات · الموافقة على المشاركة.
class ApplyScreen extends StatefulWidget {
  final Opportunity opportunity;
  const ApplyScreen({super.key, required this.opportunity});

  static const days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _bio = TextEditingController();
  final _phone = TextEditingController();
  final _days = <String>{};
  late final _skills = <String>{...widget.opportunity.skills};
  bool _consent = false;
  bool _sending = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // رقم الجوال من ملفك الشخصي (إذا موجود)
    final cubit = context.read<ProfileCubit?>();
    _phone.text = cubit?.profile?.phone ?? '';
  }

  @override
  void dispose() {
    _bio.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// رقم جوال فيه 9 أرقام أو أكتر (059xxxxxxx أو +970...)
  bool get _phoneOk => _phone.text.replaceAll(RegExp(r'\D'), '').length >= 9;

  Future<void> _submit() async {
    if (!_phoneOk) {
      setState(() => _error = 'اكتبي رقم جوال صحيح عشان المؤسسة تتواصل معك.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await context.read<MyApplicationsCubit>().apply(
          opportunityId: widget.opportunity.id,
          bio: _bio.text,
          availableDays: ApplyScreen.days.where(_days.contains).toList(),
          skills: _skills.toList(),
          phone: _phone.text,
        );
    if (!mounted) return;
    if (error == null) context.read<OpportunitiesCubit>().refresh();
    setState(() {
      _sending = false;
      _error = error;
      _done = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _Success(widget.opportunity);
    final o = widget.opportunity;
    return Scaffold(
      appBar: AppBar(title: const Text('طلب تطوع')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        children: [
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              OrgName(o.organizationName, verified: o.organizationVerified),
              const SizedBox(height: 8),
              InfoBit(o.isRemote ? Icons.wifi : Icons.location_on_outlined, o.placeLabel),
            ]),
          ),
          const SizedBox(height: 18),
          const Text('ليش حابة تتطوعي بهاي الفرصة؟', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _bio,
            maxLines: 4,
            maxLength: 300,
            decoration: const InputDecoration(hintText: 'جملتين بيكفوا...'),
          ),
          const Text('اختياري · بيساعد المؤسسة تتعرف عليكِ', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 18),
          const Text('رقم جوالك', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(hintText: '059xxxxxxx'),
          ),
          const Text('بيبيّن للمؤسسة بس إذا قبلت طلبك', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 18),
          const Text('الأيام المتاحة إلك', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _Chips(
            options: ApplyScreen.days,
            selected: _days,
            onToggle: (d) => setState(() => _days.contains(d) ? _days.remove(d) : _days.add(d)),
          ),
          if (o.skills.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('المهارات اللي عندك منهم', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _Chips(
              options: o.skills,
              selected: _skills,
              onToggle: (s) => setState(() => _skills.contains(s) ? _skills.remove(s) : _skills.add(s)),
            ),
          ],
          const SizedBox(height: 18),
          CheckboxListTile(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'بوافق على مشاركة اسمي ومهاراتي ورقمي مع «${o.organizationName}» بس.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: const TextStyle(color: AppColors.red)),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: FilledButton.icon(
            onPressed: _consent && !_sending ? _submit : null,
            icon: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_outlined),
            label: Text(_consent ? 'إرسال الطلب' : 'وافقي على المشاركة أول'),
          ),
        ),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const _Chips({required this.options, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in options)
            FilterChip(
              label: Text(o),
              selected: selected.contains(o),
              onSelected: (_) => onToggle(o),
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.card,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected.contains(o) ? Colors.white : AppColors.ink,
              ),
              side: BorderSide(color: selected.contains(o) ? AppColors.primary : const Color(0xFFDAD5C8)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
        ],
      );
}

/// بعد ما ينبعت الطلب.
class _Success extends StatelessWidget {
  final Opportunity opportunity;
  const _Success(this.opportunity);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text('انبعت طلبك 🎉', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  '«${opportunity.organizationName}» رح تراجع طلبك، وبتوصلك حالته بشاشة طلباتي.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.6),
                ),
                const SizedBox(height: 28),
                FilledButton(onPressed: () => context.go(Routes.myRequests), child: const Text('شوفي طلباتي')),
                const SizedBox(height: 8),
                TextButton(onPressed: () => context.go(Routes.opportunities), child: const Text('رجوع للفرص')),
              ],
            ),
          ),
        ),
      );
}
