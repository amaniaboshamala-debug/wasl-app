import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:wasl/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:wasl/features/notifications/domain/entities/app_notification.dart';
import 'package:wasl/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:wasl/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wasl/features/profile/domain/entities/user_profile.dart';

class FakeFavorites implements FavoritesRepository {
  bool online = true;
  final saved = <String>{};
  @override
  Future<Set<String>> getKeys() async => {...saved};
  @override
  Future<bool> add(FavoriteType type, String id) async {
    if (online) saved.add(favoriteKey(type, id));
    return online;
  }

  @override
  Future<bool> remove(FavoriteType type, String id) async {
    if (online) saved.remove(favoriteKey(type, id));
    return online;
  }
}

class FakeNotifications implements NotificationsRepository {
  final List<String> marked = [];
  bool allMarked = false;
  @override
  Future<Result<CachedList<AppNotification>>> getMine() async => Ok(CachedList([
        AppNotification(id: 'n1', title: 'انقبل طلبك', createdAt: DateTime(2026)),
        AppNotification(id: 'n2', title: 'طلب جديد', createdAt: DateTime(2026)),
        AppNotification(id: 'n3', title: 'قديم', isRead: true, createdAt: DateTime(2026)),
      ]));
  @override
  Future<bool> markRead(String id) async {
    marked.add(id);
    return true;
  }

  @override
  Future<bool> markAllRead() async => allMarked = true;
}

void main() {
  group('UserProfile', () {
    test('بيقرأ الملف وبيحسب قديش معبّى', () {
      final p = UserProfile.fromJson({
        'id': 'u1',
        'full_name': 'أماني',
        'region': 'مدينة غزة',
        'skills': ['تدريس'],
        'phone': null,
        'bio': null,
      });
      expect(p.name, 'أماني');
      expect(p.skills, ['تدريس']);
      expect(p.phone, '');
      expect(p.completeness, 3); // الاسم + المنطقة + المهارات
    });
  });

  group('الإشعارات', () {
    test('AppNotification.fromJson', () {
      final n = AppNotification.fromJson({
        'id': 'x',
        'title': 'طلب تطوع جديد',
        'body': 'سارة قدّمت',
        'type': 'new_application',
        'link': '/org/requests',
        'is_read': false,
        'created_at': '2026-11-21T10:00:00Z',
      });
      expect(n.type, 'new_application');
      expect(n.link, '/org/requests');
      expect(n.isRead, isFalse);
    });

    test('عدد غير المقروء، وتعليم واحد مقروء', () async {
      final repo = FakeNotifications();
      final cubit = NotificationsCubit(repo);
      await cubit.refresh();
      expect(cubit.unreadCount, 2);
      await cubit.markRead('n1');
      expect(cubit.unreadCount, 1);
      expect(repo.marked, ['n1']);
      expect((cubit.state as ListLoaded<AppNotification>).items.first.isRead, isTrue);
    });

    test('قرأتها كلها', () async {
      final repo = FakeNotifications();
      final cubit = NotificationsCubit(repo);
      await cubit.refresh();
      await cubit.markAllRead();
      expect(cubit.unreadCount, 0);
      expect(repo.allMarked, isTrue);
    });
  });

  group('المفضلة', () {
    test('حفظ وشيل', () async {
      final repo = FakeFavorites();
      final cubit = FavoritesCubit(repo);
      await cubit.ensureLoaded();
      expect(cubit.isFavorite(FavoriteType.opportunity, 'op1'), isFalse);

      expect(await cubit.toggle(FavoriteType.opportunity, 'op1'), isTrue);
      expect(cubit.isFavorite(FavoriteType.opportunity, 'op1'), isTrue);
      expect(cubit.idsOf(FavoriteType.opportunity), {'op1'});
      expect(cubit.idsOf(FavoriteType.service), isEmpty);
      expect(repo.saved, {'opportunity:op1'});

      await cubit.toggle(FavoriteType.opportunity, 'op1');
      expect(cubit.isFavorite(FavoriteType.opportunity, 'op1'), isFalse);
    });

    test('بدون نت: بيرجع زي ما كان', () async {
      final repo = FakeFavorites()..online = false;
      final cubit = FavoritesCubit(repo);
      expect(await cubit.toggle(FavoriteType.service, 's1'), isFalse);
      expect(cubit.isFavorite(FavoriteType.service, 's1'), isFalse);
    });
  });
}
