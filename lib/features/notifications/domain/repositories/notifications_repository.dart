import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<Result<CachedList<AppNotification>>> getMine();
  Future<bool> markRead(String id);
  Future<bool> markAllRead();
}
