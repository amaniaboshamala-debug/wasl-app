import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/features/reports/data/reports_repository.dart';

/// زر ⋮ فيه "إبلاغ"، بيفتح قائمة الأسباب.
class ReportButton extends StatelessWidget {
  final String itemType; // initiative · service · opportunity · need
  final String itemId;
  const ReportButton({super.key, required this.itemType, required this.itemId});

  Future<void> _report(BuildContext context) async {
    final repo = context.read<ReportsRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          const Text('ليش بدك تبلّغي؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('البلاغ بيوصل لفريق وَصْل بس، والمنشور ما بيعرف مين بلّغ.'),
          const SizedBox(height: 8),
          for (final r in ReportsRepository.reasons)
            ListTile(title: Text(r), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.pop(ctx, r)),
        ]),
      ),
    );
    if (reason == null) return;
    final error = await repo.report(itemType: itemType, itemId: itemId, reason: reason);
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'وصل بلاغك، شكراً إلك 🤍')));
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: 'خيارات',
        onSelected: (_) => _report(context),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_outlined), SizedBox(width: 8), Text('إبلاغ')])),
        ],
      );
}
