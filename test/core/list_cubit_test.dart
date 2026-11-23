import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/utils/result.dart';

void main() {
  group('ListCubit', () {
    test('بيبلّش بالتحميل، وبعدين بيعرض القائمة', () async {
      final cubit = ListCubit<int>(() async => const Ok(CachedList([1, 2, 3])));
      expect(cubit.state, isA<ListLoading<int>>());
      await cubit.refresh();
      expect(cubit.state, const ListLoaded<int>([1, 2, 3]));
      expect(cubit.items, [1, 2, 3]);
    });

    test('بيعرض رسالة الخطأ لما يفشل', () async {
      final cubit = ListCubit<int>(() async => const Err(Failure('صار خطأ')));
      await cubit.refresh();
      expect(cubit.state, const ListError<int>('صار خطأ'));
      expect(cubit.items, isEmpty);
    });

    test('بيوصّل إنه البيانات من الكاش', () async {
      final at = DateTime(2026, 11, 20);
      final cubit = ListCubit<int>(() async => Ok(CachedList([1], fromCache: true, savedAt: at)));
      await cubit.refresh();
      final s = cubit.state as ListLoaded<int>;
      expect(s.fromCache, isTrue);
      expect(s.savedAt, at);
    });

    test('ensureLoaded بتحمّل مرة وحدة بس', () async {
      var calls = 0;
      final cubit = ListCubit<int>(() async {
        calls++;
        return const Ok(CachedList([1]));
      });
      await cubit.ensureLoaded();
      await cubit.ensureLoaded();
      expect(calls, 1);
      await cubit.refresh();
      expect(calls, 2);
    });

    test('التحديث ما بيمسح القائمة الموجودة وقت التحميل', () async {
      final states = <ListState<int>>[];
      final cubit = ListCubit<int>(() async => const Ok(CachedList([1])));
      await cubit.refresh();
      final sub = cubit.stream.listen(states.add);
      await cubit.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(states.whereType<ListLoading<int>>(), isEmpty);
      await sub.cancel();
    });

    test('reset بيفضّي القائمة، وensureLoaded بترجع تحمّل', () async {
      var calls = 0;
      final cubit = ListCubit<int>(() async {
        calls++;
        return const Ok(CachedList([1]));
      });
      await cubit.ensureLoaded();
      cubit.reset();
      expect(cubit.state, isA<ListLoading<int>>());
      await cubit.ensureLoaded();
      expect(calls, 2);
    });
  });
}
