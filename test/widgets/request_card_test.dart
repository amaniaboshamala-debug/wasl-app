import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/features/organization/data/models/org_models.dart';
import 'package:wasl/features/organization/presentation/widgets/request_card.dart';

import '../helpers/fixtures.dart';

Widget wrap(Widget child) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('الطلب الجديد: فيه قبول ورفض، والرقم مخفي', (tester) async {
    await tester.pumpWidget(wrap(RequestCard(OrgModels.request(orgRequestJson))));
    expect(find.text('سارة محمد'), findsOneWidget);
    expect(find.text('على: مساعدة في دروس تقوية'), findsOneWidget);
    expect(find.text('قبول'), findsOneWidget);
    expect(find.text('رفض'), findsOneWidget);
    expect(find.text('0591234567'), findsNothing); // الرقم بيبين بعد القبول بس
  });

  testWidgets('الطلب المقبول: بيبيّن الرقم، وما في أزرار قبول ورفض', (tester) async {
    await tester.pumpWidget(wrap(RequestCard(OrgModels.request({...orgRequestJson, 'status': 'accepted'}))));
    expect(find.text('مقبول'), findsOneWidget);
    expect(find.text('0591234567'), findsOneWidget);
    expect(find.text('قبول'), findsNothing);
  });
}
