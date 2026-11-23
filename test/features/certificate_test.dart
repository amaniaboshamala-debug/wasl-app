import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/features/initiatives/data/models/initiative_model.dart';
import 'package:wasl/features/opportunities/data/models/opportunity_model.dart';

import '../helpers/fixtures.dart';

void main() {
  test('الفرصة بدون شهادة بشكل افتراضي', () {
    expect(OpportunityModel.fromJson(opportunityJson).offersCertificate, isFalse);
  });

  test('الفرصة مع شهادة، ومين بيصدّقها', () {
    final o = OpportunityModel.fromJson({...opportunityJson, 'offers_certificate': true});
    expect(o.offersCertificate, isTrue);
    expect(o.certificateLabel, 'شهادة تطوع مصدّقة');
    final withIssuer = OpportunityModel.fromJson(
        {...opportunityJson, 'offers_certificate': true, 'certificate_issuer': 'وزارة التنمية'});
    expect(withIssuer.certificateLabel, 'شهادة مصدّقة من وزارة التنمية');
  });

  test('المبادرة مع شهادة', () {
    final i = InitiativeModel.fromJson({...initiativeJson, 'offers_certificate': true});
    expect(i.offersCertificate, isTrue);
    expect(i.certificateLabel, 'شهادة تطوع مصدّقة');
  });
}
