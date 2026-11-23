import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/presentation/region_cubit.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/initiatives/data/models/initiative_model.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';
import 'package:wasl/features/initiatives/domain/repositories/initiatives_repository.dart';
import 'package:wasl/features/initiatives/presentation/cubit/initiatives_cubit.dart';
import 'package:wasl/features/initiatives/presentation/widgets/initiative_card.dart';
import 'package:wasl/features/initiatives/presentation/widgets/initiatives_view.dart';

import '../helpers/fixtures.dart';

/// Repository وهمي: بيرجّع اللي بدنا ياه بدل ما يحكي مع Supabase.
class FakeInitiativesRepository implements InitiativesRepository {
  Result<CachedList<Initiative>> result;
  FakeInitiativesRepository(this.result);
  @override
  Future<Result<CachedList<Initiative>>> getOpen() async => result;
}

final _two = [
  InitiativeModel.fromJson(initiativeJson), // صحية · خانيونس
  InitiativeModel.fromJson({
    ...initiativeJson,
    'id': 'i2',
    'title': 'تعلّم وارتقِ',
    'category': 'تعليمية',
    'region': 'مدينة غزة',
  }),
];

void main() {
  setUp(setUpHive);
  tearDown(tearDownHive);

  late RegionCubit region;

  Future<void> pumpView(WidgetTester tester, FakeInitiativesRepository repo, {String query = ''}) async {
    region = RegionCubit();
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider.value(value: region),
        BlocProvider(create: (_) => InitiativesCubit(repo)),
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: InitiativesView(query: query)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('بتعرض كل المبادرات وعددها', (tester) async {
    await pumpView(tester, FakeInitiativesRepository(Ok(CachedList(_two))));
    expect(find.byType(InitiativeCard), findsNWidgets(2));
    expect(find.text('2 مبادرة'), findsOneWidget);
  });

  testWidgets('البحث بيصفّي النتائج', (tester) async {
    await pumpView(tester, FakeInitiativesRepository(Ok(CachedList(_two))), query: 'تعلّم');
    expect(find.byType(InitiativeCard), findsOneWidget);
    expect(find.text('تعلّم وارتقِ'), findsOneWidget);
  });

  testWidgets('اختيار المنطقة بيصفّي النتائج', (tester) async {
    await pumpView(tester, FakeInitiativesRepository(Ok(CachedList(_two))));
    await tester.runAsync(() => region.select('خانيونس'));
    await tester.pumpAndSettle();
    expect(find.byType(InitiativeCard), findsOneWidget);
    expect(find.text('أيام صحية للأطفال'), findsOneWidget);
  });

  testWidgets('زر التصنيف بيصفّي النتائج', (tester) async {
    await pumpView(tester, FakeInitiativesRepository(Ok(CachedList(_two))));
    await tester.tap(find.widgetWithText(ChoiceChip, 'تعليمية'));
    await tester.pumpAndSettle();
    expect(find.byType(InitiativeCard), findsOneWidget);
    expect(find.text('تعلّم وارتقِ'), findsOneWidget);
  });

  testWidgets('لما ما في نتائج بتطلع رسالة', (tester) async {
    await pumpView(tester, FakeInitiativesRepository(Ok(CachedList(_two))), query: 'كلمة مش موجودة');
    expect(find.byType(InitiativeCard), findsNothing);
    expect(find.text('ما في مبادرات هون حالياً'), findsOneWidget);
  });

  testWidgets('بدون نت بيطلع شريط "آخر نسخة محفوظة"', (tester) async {
    await pumpView(tester, FakeInitiativesRepository(Ok(CachedList(_two, fromCache: true))));
    expect(find.textContaining('آخر نسخة محفوظة'), findsOneWidget);
  });

  testWidgets('لما يصير خطأ، بيطلع زر "حاولي مرة تانية" وبيشتغل', (tester) async {
    final repo = FakeInitiativesRepository(const Err(Failure('لا يوجد اتصال')));
    await pumpView(tester, repo);
    expect(find.text('ما قدرنا نحمّل البيانات'), findsOneWidget);

    repo.result = Ok(CachedList(_two));
    await tester.tap(find.text('حاولي مرة تانية'));
    await tester.pumpAndSettle();
    expect(find.byType(InitiativeCard), findsNWidgets(2));
  });
}
