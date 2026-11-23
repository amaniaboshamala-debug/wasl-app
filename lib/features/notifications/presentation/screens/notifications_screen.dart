import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/notifications/domain/entities/app_notification.dart';
import 'package:wasl/features/notifications/presentation/cubit/notifications_cubit.dart';

/// الإشعارات: الجديد مميّز بلون، ولما ينضغط بيفتح الشاشة المناسبة.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().refresh();
  }

  static (IconData, Color, Color) _style(String type) => switch (type) {
        'accepted' => (Icons.check_circle_outline, AppColors.primary, AppColors.primarySoft),
        'rejected' => (Icons.info_outline, AppColors.muted, const Color(0xFFEEECE6)),
        'new_application' => (Icons.inbox_outlined, AppColors.orange, AppColors.orangeSoft),
        'withdrawn' => (Icons.logout, AppColors.red, AppColors.redSoft),
        'certificate' => (Icons.workspace_premium_outlined, const Color(0xFF5B3A8C), const Color(0xFFEFE8F7)),
        'reminder' || 'log_hours' => (Icons.alarm, AppColors.orange, AppColors.orangeSoft),
        'match' => (Icons.auto_awesome_outlined, AppColors.primary, AppColors.primarySoft),
        'need' || 'need_offer' => (Icons.volunteer_activism_outlined, AppColors.orange, AppColors.orangeSoft),
        _ => (Icons.notifications_none, AppColors.blue, AppColors.blueSoft),
      };

  void _open(AppNotification n) {
    final cubit = context.read<NotificationsCubit>();
    if (!n.isRead) cubit.markRead(n.id);
    final link = n.link;
    if (link == null || link.isEmpty) return;
    // صفحات التفاصيل بتنفتح فوق (وفيها زر رجوع)، والتبويبات بننتقل لها
    final isDetails = Routes.isDetails(link) || link == Routes.myRecord;
    if (isDetails) {
      context.push(link);
    } else {
      context.go(link);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();
    final state = context.watch<NotificationsCubit>().state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (cubit.unreadCount > 0)
            TextButton(onPressed: cubit.markAllRead, child: const Text('قرأتها كلها')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: cubit.refresh,
        child: switch (state) {
          ListLoading<AppNotification>() =>
            ListView(padding: const EdgeInsets.all(18), children: const [SkeletonList(count: 4, height: 80)]),
          ListError<AppNotification>(:final message) => ListView(children: [
              const SizedBox(height: 40),
              MessageView(
                icon: Icons.wifi_off_outlined,
                title: 'ما قدرنا نحمّل الإشعارات',
                subtitle: message,
                actionLabel: 'حاولي مرة تانية',
                onAction: cubit.refresh,
              ),
            ]),
          ListLoaded<AppNotification>(:final items) when items.isEmpty => ListView(children: const [
              SizedBox(height: 60),
              MessageView(
                icon: Icons.notifications_none,
                title: 'ما في إشعارات لسا',
                subtitle: 'لما يصير شي على طلباتك أو فرصك، بيوصلك هون.',
              ),
            ]),
          ListLoaded<AppNotification>(:final items, :final fromCache, :final savedAt) => ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                if (fromCache) CacheNotice(savedAt: savedAt),
                for (final n in items) ...[
                  _Tile(n, style: _style(n.type), onTap: () => _open(n)),
                  const SizedBox(height: 10),
                ],
              ],
            ),
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final AppNotification n;
  final (IconData, Color, Color) style;
  final VoidCallback onTap;
  const _Tile(this.n, {required this.style, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, fg, bg) = style;
    return Material(
      color: n.isRead ? AppColors.card : const Color(0xFFF1F7F4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: fg, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(n.title,
                        style: TextStyle(fontSize: 14, fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w700)),
                  ),
                  if (!n.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                    ),
                ]),
                if (n.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(n.body, style: const TextStyle(fontSize: 13, color: Color(0xFF3B4A44), height: 1.5)),
                ],
                const SizedBox(height: 4),
                Text(DateAr.ago(n.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
