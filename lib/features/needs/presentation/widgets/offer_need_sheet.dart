import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/features/needs/data/repositories/need_offers_repository.dart';
import 'package:wasl/features/needs/domain/entities/need.dart';
import 'package:wasl/features/profile/presentation/cubit/profile_cubit.dart';

/// بيفتح نافذة "بقدر أوفّر هاد" تحت الشاشة.
Future<void> showOfferNeedSheet(BuildContext context, Need need) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OfferNeedSheet(need),
    );

class _OfferNeedSheet extends StatefulWidget {
  final Need need;
  const _OfferNeedSheet(this.need);

  @override
  State<_OfferNeedSheet> createState() => _OfferNeedSheetState();
}

class _OfferNeedSheetState extends State<_OfferNeedSheet> {
  final _note = TextEditingController();
  final _phone = TextEditingController();
  late int _qty;
  bool _sending = false;
  String? _error;

  int get _remaining => (widget.need.quantityNeeded - widget.need.quantityProvided).clamp(1, 100000);

  @override
  void initState() {
    super.initState();
    _qty = _remaining < 5 ? _remaining : 5;
    _phone.text = context.read<ProfileCubit?>()?.profile?.phone ?? '';
  }

  @override
  void dispose() {
    _note.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 9) {
      setState(() => _error = 'اكتبي رقم جوال عشان المؤسسة تتواصل معك للاستلام.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await context.read<NeedOffersRepository>().offer(
          needId: widget.need.id,
          quantity: _qty,
          note: _note.text,
          phone: _phone.text,
        );
    if (!mounted) return;
    if (error == null) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('وصل عرضك للمؤسسة، ورح يتواصلوا معك 🤝')));
    } else {
      setState(() {
        _sending = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.need;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('🤝 بقدر أوفّر: ${n.type}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        if (n.initiativeTitle.isNotEmpty)
          Text('لمبادرة «${n.initiativeTitle}»', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 4),
        Text('باقي ${n.quantityNeeded - n.quantityProvided} من ${n.quantityNeeded}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 14),
        Row(children: [
          const Text('قديش بتقدري توفّري؟', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton.outlined(
            tooltip: 'أقل',
            onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(width: 48, child: Text('$_qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))),
          IconButton.outlined(
            tooltip: 'أكتر',
            onPressed: _qty < _remaining ? () => setState(() => _qty++) : null,
            icon: const Icon(Icons.add),
          ),
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)', hintText: 'مثلاً: دفاتر جديدة، بقدر أوصلهم'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(labelText: 'رقم جوالك', hintText: '059xxxxxxx'),
        ),
        const SizedBox(height: 8),
        const Text(
          'مساعدات عينية بس. وَصْل ما بيستقبل ولا بيحوّل فلوس، والمؤسسة بتتواصل معك للاستلام.',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.red)),
        ],
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('ابعتي العرض'),
        ),
      ]),
    );
  }
}
