import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/utils/result.dart';

import '../helpers/fixtures.dart';

void main() {
  setUp(setUpHive);
  tearDown(tearDownHive);

  String title(Map<String, dynamic> j) => j['title'] as String;

  test('لما في نت: بيرجّع البيانات وبيحفظ نسخة', () async {
    final result = await fetchWithCache(
      cacheKey: 'k',
      remote: () async => [initiativeJson],
      parse: title,
    );
    final data = (result as Ok<CachedList<String>>).data;
    expect(data.items, ['أيام صحية للأطفال']);
    expect(data.fromCache, isFalse);
  });

  test('لما ما في نت: بيرجّع آخر نسخة محفوظة', () async {
    await fetchWithCache(cacheKey: 'k', remote: () async => [initiativeJson], parse: title);
    final result = await fetchWithCache<String>(
      cacheKey: 'k',
      remote: () async => throw Exception('no internet'),
      parse: title,
    );
    final data = (result as Ok<CachedList<String>>).data;
    expect(data.items, ['أيام صحية للأطفال']);
    expect(data.fromCache, isTrue);
    expect(data.savedAt, isNotNull);
  });

  test('لما ما في نت ولا نسخة محفوظة: رسالة "لا يوجد اتصال"', () async {
    final result = await fetchWithCache<String>(
      cacheKey: 'empty',
      remote: () async => throw Exception('no internet'),
      parse: title,
    );
    expect((result as Err).failure.message, Failure.network.message);
  });
}
