import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/admin/data/admin_repository.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/initiatives/data/models/initiative_model.dart';

/// لوحة الإدارة (لحساب admin بس): مؤسسات · مبادرات للمراجعة · بلاغات.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('إدارة وَصْل'),
            actions: [
              IconButton(
                tooltip: 'تسجيل الخروج',
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<AuthCubit>().logout(),
              ),
            ],
            bottom: const TabBar(tabs: [Tab(text: 'المؤسسات'), Tab(text: 'المبادرات'), Tab(text: 'البلاغات')]),
          ),
          body: const TabBarView(children: [_OrgsTab(), _InitiativesTab(), _ReportsTab()]),
        ),
      );
}

/// قائمة عامة بتحمّل وبتتحدّث بالسحب.
class _Loader<T> extends StatefulWidget {
  final Future<List<T>> Function(AdminRepository repo) load;
  final Widget Function(BuildContext context, T item, Future<void> Function() reload) itemBuilder;
  final String empty;
  const _Loader({required this.load, required this.itemBuilder, required this.empty});

  @override
  State<_Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<_Loader<T>> {
  late Future<List<T>> _future = widget.load(context.read<AdminRepository>());

  Future<void> _reload() async {
    final f = widget.load(context.read<AdminRepository>());
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<T>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                MessageView(
                  icon: Icons.error_outline,
                  title: 'ما قدرنا نحمّل',
                  subtitle: 'تأكدي إنه حسابك admin، وإنك شغّلتي ملف 009.',
                  actionLabel: 'حاولي مرة تانية',
                  onAction: _reload,
                ),
              ]);
            }
            final items = snap.data ?? <T>[];
            if (items.isEmpty) {
              return ListView(children: [MessageView(icon: Icons.check_circle_outline, title: widget.empty)]);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final i in items)
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: widget.itemBuilder(context, i, _reload)),
              ],
            );
          },
        ),
      );
}

Future<void> _act(BuildContext context, Future<void> Function() call, String ok, Future<void> Function() reload) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await call();
    messenger.showSnackBar(SnackBar(content: Text(ok)));
    await reload();
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('ما زبطت، حاولي مرة تانية.')));
  }
}

class _OrgsTab extends StatelessWidget {
  const _OrgsTab();

  @override
  Widget build(BuildContext context) => _Loader<Map<String, dynamic>>(
        load: (r) => r.organizations(),
        empty: 'ما في مؤسسات لسا',
        itemBuilder: (context, o, reload) {
          final verified = (o['is_verified'] as bool?) ?? false;
          final repo = context.read<AdminRepository>();
          return AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: OrgName((o['name'] as String?) ?? '', verified: verified, fontSize: 15)),
                StatusChip(
                  verified ? 'موثّقة' : 'بانتظار التوثيق',
                  color: verified ? AppColors.primaryDark : const Color(0xFF7A3E00),
                  background: verified ? AppColors.primarySoft : AppColors.orangeSoft,
                ),
              ]),
              if ((o['bio'] as String?)?.isNotEmpty ?? false)
                Padding(padding: const EdgeInsets.only(top: 6), child: Text(o['bio'] as String)),
              const SizedBox(height: 6),
              Wrap(spacing: 14, children: [
                if ((o['region'] as String?)?.isNotEmpty ?? false) InfoBit(Icons.location_on_outlined, o['region'] as String),
                if ((o['contact'] as String?)?.isNotEmpty ?? false) InfoBit(Icons.call_outlined, o['contact'] as String),
              ]),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: verified
                    ? TextButton(
                        style: TextButton.styleFrom(foregroundColor: AppColors.red),
                        onPressed: () => _act(context, () => repo.verifyOrg(o['id'] as String, false), 'انشال التوثيق', reload),
                        child: const Text('شيلي التوثيق'),
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                        onPressed: () => _act(context, () => repo.verifyOrg(o['id'] as String, true), 'توثّقت المؤسسة ✓', reload),
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('وثّقي المؤسسة'),
                      ),
              ),
            ]),
          );
        },
      );
}

class _InitiativesTab extends StatelessWidget {
  const _InitiativesTab();

  @override
  Widget build(BuildContext context) => _Loader<Map<String, dynamic>>(
        load: (r) => r.pendingInitiatives(),
        empty: 'ما في مبادرات بتستنى مراجعة ✓',
        itemBuilder: (context, row, reload) {
          final i = InitiativeModel.fromJson(row);
          final repo = context.read<AdminRepository>();
          return AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(i.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              OrgName(i.organizationName, verified: i.organizationVerified),
              const SizedBox(height: 6),
              Text(i.description, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 6),
              Wrap(spacing: 14, children: [
                InfoBit(Icons.category_outlined, i.category),
                if (i.region.isNotEmpty) InfoBit(Icons.location_on_outlined, i.region),
                InfoBit(Icons.calendar_today_outlined, DateAr.range(i.startDate, i.endDate)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                    onPressed: () => _act(context, () => repo.setInitiativeStatus(i.id, 'published'), 'انتشرت المبادرة ✓', reload),
                    child: const Text('انشري'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42), foregroundColor: AppColors.red),
                    onPressed: () => _act(context, () => repo.setInitiativeStatus(i.id, 'cancelled'), 'انرفضت المبادرة', reload),
                    child: const Text('ارفضي'),
                  ),
                ),
              ]),
            ]),
          );
        },
      );
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) => _Loader<AdminReport>(
        load: (r) => r.openReports(),
        empty: 'ما في بلاغات مفتوحة ✓',
        itemBuilder: (context, r, reload) {
          final repo = context.read<AdminRepository>();
          final route = switch (r.itemType) {
            'initiative' => Routes.initiativeDetails(r.itemId),
            'service' => Routes.serviceDetails(r.itemId),
            'opportunity' => Routes.opportunityDetails(r.itemId),
            _ => null,
          };
          return AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                StatusChip(r.itemTypeLabel, color: AppColors.blue, background: AppColors.blueSoft),
                const Spacer(),
                Text(DateAr.ago(r.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
              const SizedBox(height: 8),
              Text(r.reason, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (r.reporterName.isNotEmpty)
                Text('من: ${r.reporterName}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 8),
              Row(children: [
                if (route != null) TextButton(onPressed: () => context.push(route), child: const Text('شوفي المنشور')),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () => _act(context, () => repo.resolveReport(r.id), 'تمام، انحلّ البلاغ', reload),
                  child: const Text('انحلّ'),
                ),
              ]),
            ]),
          );
        },
      );
}
