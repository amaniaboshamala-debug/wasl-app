import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/features/applications/data/models/application_model.dart';
import 'package:wasl/features/applications/data/repositories/applications_repository_impl.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/opportunities/data/models/opportunity_model.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';

import '../helpers/fixtures.dart';

void main() {
  group('OpportunityModel', () {
    test('بيقرأ الفرصة صح', () {
      final o = OpportunityModel.fromJson(opportunityJson);
      expect(o.title, 'مدخل بيانات لمسح تعليمي');
      expect(o.organizationName, 'جمعية نور');
      expect(o.type, OpportunityType.paid);
      expect(o.isPaid, isTrue);
      expect(o.typeLabel, 'عمل بأجر · 50 ₪ يومياً');
      expect(o.seatsLeft, 4);
      expect(o.seatsLabel, 'باقي 4 مقاعد');
      expect(o.isOpen, isTrue);
      expect(o.placeLabel, 'مدينة غزة');
      expect(o.skills, ['إكسل', 'دقة']);
    });

    test('الفرصة عن بُعد', () {
      final o = OpportunityModel.fromJson({...opportunityJson, 'is_remote': true, 'region': null});
      expect(o.placeLabel, 'عن بُعد');
    });

    test('أنواع الفرص', () {
      expect(OpportunityModel.fromJson({...opportunityJson, 'type': 'volunteer'}).typeLabel, 'تطوع بدون مقابل');
      expect(
        OpportunityModel.fromJson({...opportunityJson, 'type': 'volunteer_allowance', 'compensation': 'بدل مواصلات'})
            .typeLabel,
        'تطوع + بدل مواصلات',
      );
    });

    test('عدد المقاعد الباقية بالعربي', () {
      Opportunity withAccepted(int n) => OpportunityModel.fromJson({...opportunityJson, 'accepted_count': n});
      expect(withAccepted(5).seatsLabel, 'باقي مقعد واحد');
      expect(withAccepted(4).seatsLabel, 'باقي مقعدان');
      expect(withAccepted(6).seatsLabel, 'اكتمل العدد');
      expect(withAccepted(6).isOpen, isFalse);
      expect(withAccepted(9).seatsLeft, 0); // ما بينزل تحت الصفر
    });

    test('الفرصة المكتملة أو المنتهية مش مفتوحة', () {
      expect(OpportunityModel.fromJson({...opportunityJson, 'status': 'full'}).isOpen, isFalse);
      final expired = OpportunityModel.fromJson({...opportunityJson, 'status': 'expired'});
      expect(expired.isOpen, isFalse);
      expect(expired.seatsLabel, 'انتهى التقديم');
    });
  });

  group('ApplicationModel', () {
    test('بيقرأ الطلب مع الفرصة والمؤسسة', () {
      final a = ApplicationModel.fromJson(applicationJson);
      expect(a.opportunityTitle, 'مدخل بيانات لمسح تعليمي');
      expect(a.organizationName, 'جمعية نور');
      expect(a.place, 'مدينة غزة');
      expect(a.availableDays, ['السبت', 'الأحد']);
      expect(a.status, ApplicationStatus.pending);
      expect(a.statusLabel, 'قيد المراجعة');
      expect(a.canWithdraw, isTrue);
    });

    test('بس الطلب قيد المراجعة أو المقبول بينسحب', () {
      ApplicationStatus s(String v) => ApplicationModel.fromJson({...applicationJson, 'status': v}).status;
      VolunteerApplication app(String v) => ApplicationModel.fromJson({...applicationJson, 'status': v});
      expect(s('accepted'), ApplicationStatus.accepted);
      expect(app('accepted').canWithdraw, isTrue);
      expect(app('rejected').canWithdraw, isFalse);
      expect(app('withdrawn').canWithdraw, isFalse);
      expect(app('withdrawn').statusLabel, 'انسحبتِ');
    });
  });

  group('رسائل أخطاء التقديم', () {
    test('بتترجم أخطاء السيرفر للعربي', () {
      expect(arabicApplicationError('only_volunteers'), 'التقديم على الفرص للمتطوعين بس.');
      expect(arabicApplicationError('ERROR: opportunity_closed'), 'الفرصة سكّرت أو اكتمل عددها.');
      expect(arabicApplicationError('already_applied'), 'قدّمتِ على هاي الفرصة قبل.');
      expect(arabicApplicationError('شي غريب'), 'صار خطأ، حاولي مرة تانية.');
    });
  });
}
