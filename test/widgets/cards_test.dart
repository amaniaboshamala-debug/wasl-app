import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/features/initiatives/data/models/initiative_model.dart';
import 'package:wasl/features/initiatives/presentation/widgets/initiative_card.dart';
import 'package:wasl/features/needs/data/models/need_model.dart';
import 'package:wasl/features/needs/presentation/widgets/need_card.dart';
import 'package:wasl/features/services/data/models/community_service_model.dart';
import 'package:wasl/features/services/presentation/widgets/service_card.dart';

import '../helpers/fixtures.dart';

/// بنعرض الويدجت لحاله بشاشة عربية (RTL)، بدون Supabase ولا خطوط من النت.
Widget wrap(Widget child) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
      ),
    );

void main() {
  testWidgets('كرت المبادرة بيعرض العنوان والمؤسسة والمكان والموعد', (tester) async {
    await tester.pumpWidget(wrap(InitiativeCard(InitiativeModel.fromJson(initiativeJson))));
    expect(find.text('أيام صحية للأطفال'), findsOneWidget);
    expect(find.text('مؤسسة شفاء'), findsOneWidget);
    expect(find.byIcon(Icons.verified_outlined), findsOneWidget); // موثّقة
    expect(find.text('خانيونس'), findsOneWidget);
    expect(find.text('24 – 26 نوفمبر'), findsOneWidget);
    expect(find.text('التسجيل مفتوح'), findsOneWidget);
    expect(find.text('بحاجة 12 متطوع'), findsOneWidget);
  });

  testWidgets('كرت الخدمة بيعرض الحالة وآخر تأكيد', (tester) async {
    await tester.pumpWidget(wrap(ServiceCard(CommunityServiceModel.fromJson(serviceJson))));
    expect(find.text('عيادة أطفال مجانية'), findsOneWidget);
    expect(find.text('محدودة'), findsOneWidget);
    expect(find.text('آخر تأكيد قبل ساعتين'), findsOneWidget);
    expect(find.byIcon(Icons.verified_outlined), findsNothing); // مش موثّقة
  });

  testWidgets('الخدمة القديمة بيطلع عليها "بحاجة تأكيد"', (tester) async {
    final old = {...serviceJson, 'last_confirmed_at': DateTime.now().subtract(const Duration(days: 9)).toIso8601String()};
    await tester.pumpWidget(wrap(ServiceCard(CommunityServiceModel.fromJson(old))));
    expect(find.textContaining('بحاجة تأكيد'), findsOneWidget);
  });

  testWidgets('كرت الاحتياج بيعرض قديش اتوفّر', (tester) async {
    await tester.pumpWidget(wrap(NeedCard(NeedModel.fromJson(needJson))));
    expect(find.text('قرطاسية'), findsOneWidget);
    expect(find.text('متوفّر جزئياً'), findsOneWidget);
    expect(find.text('60 من 100'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
