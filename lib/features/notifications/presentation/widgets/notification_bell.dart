import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/features/notifications/presentation/cubit/notifications_cubit.dart';

/// زر الجرس، وعليه رقم الإشعارات اللي ما انقرت.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<NotificationsCubit>();
    final unread = context.read<NotificationsCubit>().unreadCount;
    return IconButton.outlined(
      tooltip: unread > 0 ? 'الإشعارات، $unread جديدة' : 'الإشعارات',
      style: IconButton.styleFrom(
        backgroundColor: AppColors.card,
        side: const BorderSide(color: Color(0xFFDAD5C8)),
      ),
      onPressed: () => context.push(Routes.notifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        backgroundColor: AppColors.orange,
        child: const Icon(Icons.notifications_none),
      ),
    );
  }
}
