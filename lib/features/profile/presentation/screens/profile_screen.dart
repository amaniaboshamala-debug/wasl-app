import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/applications/presentation/cubit/my_applications_cubit.dart';
import 'package:wasl/features/auth/domain/entities/app_user.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_state.dart';
import 'package:wasl/features/organization/presentation/cubit/my_org_cubit.dart';
import 'package:wasl/features/profile/presentation/cubit/profile_cubit.dart';

/// حسابي: الاسم والدور، ملخص سريع، وروابط (تعديل الملف · المفضلة · الإشعارات · الخروج).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().load();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('أكيد بدك تطلعي من حسابك؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            // الأزرار بالثيم عرضها كامل، وجوا الـ Dialog لازم يكون إلها عرض محدد
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) await context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final user = auth is Authenticated ? auth.user : null;
    final profile = context.watch<ProfileCubit>().state.profile;
    final isOrg = user?.isOrganization ?? false;
    final isVolunteer = user?.role == UserRole.volunteer;

    final name = (profile?.name.isNotEmpty ?? false) ? profile!.name : (user?.name ?? '');
    final initial = name.trim().isEmpty ? '؟' : String.fromCharCode(name.trim().runes.first);

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: RefreshIndicator(
        onRefresh: context.read<ProfileCubit>().load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primarySoft,
                child: Text(initial,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 12),
            Text(name.isEmpty ? 'بدون اسم' : name,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(user?.email ?? '',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Center(
              child: Wrap(spacing: 8, children: [
                StatusChip(user?.roleLabel ?? '', color: AppColors.primaryDark, background: AppColors.primarySoft),
                if (profile?.region.isNotEmpty ?? false)
                  StatusChip(profile!.region, color: AppColors.blue, background: AppColors.blueSoft),
              ]),
            ),
            if (!isOrg && profile != null && profile.completeness < 5) ...[
              const SizedBox(height: 16),
              _CompleteCard(done: profile.completeness),
            ],
            if (isVolunteer) ...[
              const SizedBox(height: 16),
              const _VolunteerStats(),
            ],
            if (profile?.skills.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              const Text('مهاراتي', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in profile!.skills) StatusChip(s, color: AppColors.blue, background: AppColors.blueSoft),
              ]),
            ],
            const SizedBox(height: 20),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                _Link(Icons.edit_outlined, 'تعديل ملفي الشخصي', () => context.push(Routes.editProfile)),
                if (isOrg)
                  _Link(Icons.apartment_outlined, 'معلومات المؤسسة', () => context.push(Routes.orgEdit),
                      enabled: context.watch<MyOrgCubit>().org != null),
                if (!isOrg) _Link(Icons.workspace_premium_outlined, 'سجلّي التطوعي وشهاداتي', () => context.push(Routes.myRecord)),
                if (!isOrg) _Link(Icons.bookmark_border, 'المفضلة', () => context.push(Routes.favorites)),
                _Link(Icons.shield_outlined, 'ركن التوعية', () => context.push(Routes.awareness)),
                _Link(Icons.notifications_none, 'الإشعارات', () => context.push(Routes.notifications)),
              ]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
              ),
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  const _Link(this.icon, this.label, this.onTap, {this.enabled = true});

  @override
  Widget build(BuildContext context) => ListTile(
        enabled: enabled,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

class _CompleteCard extends StatelessWidget {
  final int done;
  const _CompleteCard({required this.done});

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => context.push(Routes.editProfile),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('كمّلي ملفك الشخصي', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('المؤسسات بتختار أسرع لما تعرف مهاراتك ومنطقتك.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 10),
          ProgressLine(value: done / 5, label: '$done من 5'),
        ]),
      );
}

class _VolunteerStats extends StatefulWidget {
  const _VolunteerStats();

  @override
  State<_VolunteerStats> createState() => _VolunteerStatsState();
}

class _VolunteerStatsState extends State<_VolunteerStats> {
  @override
  void initState() {
    super.initState();
    context.read<MyApplicationsCubit>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<MyApplicationsCubit>();
    final apps = context.read<MyApplicationsCubit>().items;
    final accepted = apps.where((a) => a.status == ApplicationStatus.accepted).length;
    final pending = apps.where((a) => a.status == ApplicationStatus.pending).length;
    Widget stat(String v, String l) => Expanded(
          child: Column(children: [
            Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(l, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        );
    return AppCard(
      child: Row(children: [
        stat('${apps.length}', 'طلبات'),
        stat('$pending', 'قيد المراجعة'),
        stat('$accepted', 'مقبولة'),
      ]),
    );
  }
}
