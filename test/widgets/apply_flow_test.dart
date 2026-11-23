import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/applications/data/models/application_model.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/applications/domain/repositories/applications_repository.dart';
import 'package:wasl/features/applications/presentation/cubit/my_applications_cubit.dart';
import 'package:wasl/features/opportunities/data/models/opportunity_model.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';
import 'package:wasl/features/opportunities/domain/repositories/opportunities_repository.dart';
import 'package:wasl/features/opportunities/presentation/cubit/opportunities_cubit.dart';
import 'package:wasl/features/opportunities/presentation/screens/apply_screen.dart';
import 'package:wasl/features/opportunities/presentation/widgets/opportunity_card.dart';

import '../helpers/fixtures.dart';

/// Repository وهمي للطلبات: بيحفظ اللي انبعت، وبيرجّع الخطأ اللي بدنا ياه.
class FakeApplicationsRepository implements ApplicationsRepository {
  final List<VolunteerApplication> mine = [];
  Failure? nextError;
  Map<String, Object?>? lastApply;

  @override
  Future<Result<CachedList<VolunteerApplication>>> getMine() async => Ok(CachedList([...mine]));

  @override
  Future<Failure?> apply({
    required String opportunityId,
    String? bio,
    List<String> availableDays = const [],
    List<String> skills = const [],
    String? phone,
  }) async {
    if (nextError != null) return nextError;
    lastApply = {'id': opportunityId, 'bio': bio, 'days': availableDays, 'skills': skills, 'phone': phone};
    mine.add(ApplicationModel.fromJson({...applicationJson, 'opportunity_id': opportunityId}));
    return null;
  }

  @override
  Future<Failure?> withdraw(String applicationId) async => null;
}

class FakeOpportunitiesRepository implements OpportunitiesRepository {
  @override
  Future<Result<CachedList<Opportunity>>> getVisible() async =>
      Ok(CachedList([OpportunityModel.fromJson(opportunityJson)]));
}

void main() {
  final opportunity = OpportunityModel.fromJson(opportunityJson);

  testWidgets('كرت الفرصة بيعرض النوع والمقاعد الباقية', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: OpportunityCard(opportunity)),
      ),
    ));
    expect(find.text('مدخل بيانات لمسح تعليمي'), findsOneWidget);
    expect(find.text('عمل بأجر · 50 ₪ يومياً'), findsOneWidget);
    expect(find.text('باقي 4 مقاعد'), findsOneWidget);
  });

  group('نموذج التقديم', () {
    late FakeApplicationsRepository repo;
    late MyApplicationsCubit apps;

    Future<void> pumpApply(WidgetTester tester) async {
      // شاشة طويلة عشان كل النموذج يبيّن بدون سكرول
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repo = FakeApplicationsRepository();
      apps = MyApplicationsCubit(repo);
      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider.value(value: apps),
          BlocProvider(create: (_) => OpportunitiesCubit(FakeOpportunitiesRepository())),
        ],
        child: MaterialApp(
          home: Directionality(textDirection: TextDirection.rtl, child: ApplyScreen(opportunity: opportunity)),
        ),
      ));
    }

    FilledButton sendButton(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton));

    testWidgets('زر الإرسال مقفول لحد ما توافقي على المشاركة', (tester) async {
      await pumpApply(tester);
      expect(find.text('وافقي على المشاركة أول'), findsOneWidget);
      expect(sendButton(tester).onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(find.text('إرسال الطلب'), findsOneWidget);
      expect(sendButton(tester).onPressed, isNotNull);
    });

    testWidgets('بيبعت الأيام والمهارات، وبيطلع "انبعت طلبك"', (tester) async {
      await pumpApply(tester);
      await tester.enterText(find.byType(TextField).at(0), 'بحب أساعد');
      await tester.enterText(find.byType(TextField).at(1), '0591234567');
      await tester.tap(find.text('الأحد'));
      await tester.tap(find.text('السبت'));
      await tester.tap(find.text('دقة')); // بنشيلها (المهارات كلها مختارة بالبداية)
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('إرسال الطلب'));
      await tester.pumpAndSettle();

      expect(repo.lastApply, {
        'id': 'op1',
        'bio': 'بحب أساعد',
        'days': ['السبت', 'الأحد'], // بترتيب أيام الأسبوع، مش بترتيب الضغط
        'skills': ['إكسل'],
        'phone': '0591234567',
      });
      expect(find.text('انبعت طلبك 🎉'), findsOneWidget);
      expect(apps.forOpportunity('op1'), isNotNull);
    });

    testWidgets('بدون رقم جوال صحيح ما بينبعت', (tester) async {
      await pumpApply(tester);
      await tester.enterText(find.byType(TextField).at(1), '059');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('إرسال الطلب'));
      await tester.pumpAndSettle();
      expect(find.textContaining('رقم جوال صحيح'), findsOneWidget);
      expect(repo.lastApply, isNull);
    });

    testWidgets('إذا رفض السيرفر، بتطلع الرسالة وبيضل بالنموذج', (tester) async {
      await pumpApply(tester);
      await tester.enterText(find.byType(TextField).at(1), '0591234567');
      repo.nextError = const Failure('الفرصة سكّرت أو اكتمل عددها.');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('إرسال الطلب'));
      await tester.pumpAndSettle();
      expect(find.text('الفرصة سكّرت أو اكتمل عددها.'), findsOneWidget);
      expect(find.text('انبعت طلبك 🎉'), findsNothing);
    });
  });
}
