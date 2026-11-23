import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:wasl/features/notifications/domain/entities/app_notification.dart';
import 'package:wasl/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remote;
  NotificationsRepositoryImpl(this._remote);

  @override
  Future<Result<CachedList<AppNotification>>> getMine() => fetchWithCache(
        cacheKey: 'notifications_${_remote.currentUserId ?? 'guest'}',
        remote: _remote.fetchMine,
        parse: AppNotification.fromJson,
      );

  @override
  Future<bool> markRead(String id) => _ok(() => _remote.markRead(id));

  @override
  Future<bool> markAllRead() => _ok(_remote.markAllRead);

  Future<bool> _ok(Future<void> Function() call) async {
    try {
      await call();
      return true;
    } catch (_) {
      return false;
    }
  }
}
