import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';
import 'package:wasl/features/initiatives/presentation/cubit/initiatives_cubit.dart';
import 'package:wasl/features/needs/domain/entities/need.dart';
import 'package:wasl/features/needs/presentation/cubit/needs_cubit.dart';
import 'package:wasl/features/organization/domain/entities/org_initiative.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';
import 'package:wasl/features/organization/presentation/screens/org_initiatives_screen.dart';

/// صفحة المبادرة عند المؤسسة: حالتها، احتياجاتها، وعروض المساعدة على كل احتياج.
class OrgInitiativeScreen extends StatefulWidget {
  final String id;
  const OrgInitiativeScreen({super.key, required this.id});

  @override
  State<OrgInitiativeScreen> createState() => _OrgInitiativeScreenState();
}

class _OrgInitiativeScreenState extends State<OrgInitiativeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrgInitiativesCubit>().ensureLoaded();
  }

  OrgInitiative? _find(ListState<OrgInitiative> s) {
    if (s is! ListLoaded<OrgInitiative>) return null;
    for (final i in s.items) {
      if (i.initiative.id == widget.id) return i;
    }
    return null;
  }

  Future<void> _run(Future<String?> Function() call, String ok) async {
    final messenger = ScaffoldMessenger.of(context);
    final publicInitiatives = context.read<InitiativesCubit>();
    final publicNeeds = context.read<NeedsCubit>();
    final error = await call();
    if (error == null) {
      publicInitiatives.refresh();
      publicNeeds.refresh();
    }
    messenger.showSnackBar(SnackBar(content: Text(error ?? ok)));
  }

  Future<void> _addNeed(OrgInitiative item) async {
    final type = TextEditingController();
    final desc = TextEditingController();
    var qty = 10;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('احتياج جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: type,
              decoration: const InputDecoration(labelText: 'شو المحتاج؟', hintText: 'مثلاً: قرطاسية، أدوات تنظيف، مكان'),
            ),
            const SizedBox(height: 10),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'تفاصيل (اختياري)')),
            const SizedBox(height: 12),
            Row(children: [
              const Text('الكمية', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton.outlined(
                tooltip: 'أقل',
                onPressed: qty > 1 ? () => setSheet(() => qty--) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(width: 56, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))),
              IconButton.outlined(
                tooltip: 'أكتر',
                onPressed: () => setSheet(() => qty++),
                icon: const Icon(Icons.add),
              ),
            ]),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (type.text.trim().length >= 2) Navigator.pop(ctx, true);
              },
              child: const Text('إضافة'),
            ),
          ]),
        ),
      ),
    );
    if (ok == true && mounted) {
      await _run(
        () => context.read<OrgInitiativesCubit>().addNeed(
              initiativeId: item.initiative.id,
              type: type.text,
              description: desc.text,
              quantity: qty,
            ),
        'انضاف الاحتياج ✓',
      );
    }
    // بنستنى الـ sheet يخلّص حركة السكّير قبل ما نمسح الخانات
    Future.delayed(const Duration(milliseconds: 500), () {
      type.dispose();
      desc.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrgInitiativesCubit>().state;
    final item = _find(state);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: state is ListLoading<OrgInitiative>
            ? const Center(child: CircularProgressIndicator())
            : const MessageView(icon: Icons.search_off, title: 'ما لقينا هاي المبادرة'),
      );
    }
    final i = item.initiative;
    final cubit = context.read<OrgInitiativesCubit>();
    final (label, fg, bg) = initiativeStatusStyle(i.status);
    final canFinish = i.status == InitiativeStatus.published || i.status == InitiativeStatus.active;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المبادرة'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'خيارات',
            onSelected: (v) => _run(() => cubit.setStatus(i.id, v), v == 'completed' ? 'المبادرة خلصت ✓' : 'انلغت المبادرة'),
            itemBuilder: (_) => [
              if (canFinish) const PopupMenuItem(value: 'completed', child: Text('خلصت المبادرة')),
              if (i.status != InitiativeStatus.cancelled && i.status != InitiativeStatus.completed)
                const PopupMenuItem(value: 'cancelled', child: Text('إلغاء المبادرة')),
            ],
          ),
        ],
      ),
      floatingActionButton: i.status == InitiativeStatus.cancelled || i.status == InitiativeStatus.completed
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addNeed(item),
              icon: const Icon(Icons.add),
              label: const Text('احتياج جديد'),
            ),
      body: RefreshIndicator(
        onRefresh: cubit.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
          children: [
            Row(children: [
              Expanded(child: Text(i.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
              StatusChip(label, color: fg, background: bg),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 14, runSpacing: 6, children: [
              if (i.region.isNotEmpty) InfoBit(Icons.location_on_outlined, i.region),
              InfoBit(Icons.calendar_today_outlined, DateAr.range(i.startDate, i.endDate)),
              if (i.offersCertificate) const CertificateChip(),
            ]),
            if (i.status == InitiativeStatus.pending) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  'المبادرة عند فريق وَصْل للمراجعة، وبتطلع للناس بعد الموافقة. بتقدري تضيفي احتياجاتها من هلأ.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7A3E00)),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text('الاحتياجات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (item.needs.isEmpty)
              const Text('لسا ما في احتياجات. اضغطي "احتياج جديد" تحت.', style: TextStyle(color: AppColors.muted))
            else
              for (final n in item.needs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NeedBlock(
                    n,
                    onDecide: (offer, received) => _run(
                      () => cubit.decideOffer(offer.id, received: received),
                      received ? 'سجّلنا الاستلام ✓ والمتوفّر زاد' : 'تمام',
                    ),
                    onClose: () => _run(() => cubit.closeNeed(n.need.id), 'سكّرتِ الاحتياج'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _NeedBlock extends StatelessWidget {
  final OrgNeed item;
  final void Function(NeedOffer offer, bool received) onDecide;
  final VoidCallback onClose;
  const _NeedBlock(this.item, {required this.onDecide, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final n = item.need;
    final open = n.status == NeedStatus.open || n.status == NeedStatus.partiallyCovered;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(n.type, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
          StatusChip(n.statusLabel, color: AppColors.primaryDark, background: AppColors.primarySoft),
          if (open)
            IconButton(tooltip: 'سكّري الاحتياج', onPressed: onClose, icon: const Icon(Icons.close, size: 20)),
        ]),
        if (n.description.isNotEmpty)
          Text(n.description, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 8),
        ProgressLine(value: n.progress, label: '${n.quantityProvided} من ${n.quantityNeeded}'),
        if (item.offers.isNotEmpty) ...[
          const Divider(height: 24),
          const Text('عروض المساعدة', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final o in item.offers) _OfferRow(o, onDecide: onDecide),
        ],
      ]),
    );
  }
}

class _OfferRow extends StatelessWidget {
  final NeedOffer offer;
  final void Function(NeedOffer offer, bool received) onDecide;
  const _OfferRow(this.offer, {required this.onDecide});

  @override
  Widget build(BuildContext context) {
    final pending = offer.status == NeedOfferStatus.pending;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              '${offer.userName.isEmpty ? 'حدا' : offer.userName} · ${offer.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(DateAr.ago(offer.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
        if (offer.note.isNotEmpty) Text('"${offer.note}"', style: const TextStyle(fontSize: 13, color: Color(0xFF3B4A44))),
        if (offer.phone.isNotEmpty)
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: offer.phone)),
            icon: const Icon(Icons.call_outlined, size: 16),
            label: Text(offer.phone, textDirection: TextDirection.ltr),
          ),
        if (pending)
          Row(children: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
              onPressed: () => onDecide(offer, true),
              child: const Text('استلمنا ✓'),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: () => onDecide(offer, false), child: const Text('ما بنحتاجها')),
          ])
        else
          Text(
            offer.status == NeedOfferStatus.received ? '✓ استلمتوها' : 'ما احتجتوها',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
      ]),
    );
  }
}
