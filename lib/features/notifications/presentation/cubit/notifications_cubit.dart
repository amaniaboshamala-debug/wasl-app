import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/features/notifications/domain/entities/app_notification.dart';
import 'package:wasl/features/notifications/domain/repositories/notifications_repository.dart';

/// إشعاراتي + عدد غير المقروء (للنقطة على الجرس).
class NotificationsCubit extends ListCubit<AppNotification> {
  final NotificationsRepository _repo;
  NotificationsCubit(this._repo) : super(_repo.getMine);

  int get unreadCount => items.where((n) => !n.isRead).length;

  /// بنعلّمه مقروء عالشاشة فوراً، وبعدين على السيرفر.
  Future<void> markRead(String id) async {
    final s = state;
    if (s is! ListLoaded<AppNotification>) return;
    emit(ListLoaded([for (final n in s.items) n.id == id ? n.copyWith(isRead: true) : n],
        fromCache: s.fromCache, savedAt: s.savedAt));
    await _repo.markRead(id);
  }

  Future<void> markAllRead() async {
    final s = state;
    if (s is! ListLoaded<AppNotification>) return;
    emit(ListLoaded([for (final n in s.items) n.copyWith(isRead: true)], fromCache: s.fromCache, savedAt: s.savedAt));
    await _repo.markAllRead();
  }
}
