import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/organization/data/models/org_models.dart';
import 'package:wasl/features/organization/data/repositories/org_repository_impl.dart';

import '../helpers/fixtures.dart';

void main() {
  group('OrgModels', () {
    test('المؤسسة وأول حرف من اسمها', () {
      final o = OrgModels.organization({'id': 'o1', 'name': 'جمعية نور', 'is_verified': false});
      expect(o.name, 'جمعية نور');
      expect(o.initial, 'ج');
      expect(o.isVerified, isFalse);
      expect(OrgModels.organization({'id': 'o2', 'name': ''}).initial, '؟');
    });

    test('فرصة المؤسسة بتعدّ الطلبات الجديدة بس', () {
      final o = OrgModels.opportunity({
        ...opportunityJson,
        'applications': [
          {'status': 'pending'},
          {'status': 'pending'},
          {'status': 'accepted'},
          {'status': 'withdrawn'},
        ],
      });
      expect(o.pendingCount, 2);
      expect(o.opportunity.title, 'مدخل بيانات لمسح تعليمي');
    });

    test('الطلب: الاسم والمنطقة، والمهارات من الملف إذا ما اختار بالتقديم', () {
      final r = OrgModels.request(orgRequestJson);
      expect(r.volunteerName, 'سارة محمد');
      expect(r.shortName, 'سارة م.');
      expect(r.volunteerRegion, 'مدينة غزة');
      expect(r.skills, ['تدريس', 'رسم']);
      expect(r.opportunityTitle, 'مساعدة في دروس تقوية');
      expect(r.status, ApplicationStatus.pending);
      expect(r.isPending, isTrue);
    });

    test('المهارات اللي اختارها بالتقديم أولى من الملف', () {
      final r = OrgModels.request({...orgRequestJson, 'skills': ['إكسل']});
      expect(r.skills, ['إكسل']);
    });

    test('الاسم الفاضي أو الكلمة الوحدة', () {
      expect(OrgModels.request({...orgRequestJson, 'profiles': {'full_name': ''}}).shortName, 'متطوع');
      expect(OrgModels.request({...orgRequestJson, 'profiles': {'full_name': 'سارة'}}).shortName, 'سارة');
    });
  });

  test('رسائل أخطاء المؤسسة بالعربي', () {
    expect(arabicOrgError('opportunity_full'), 'اكتمل عدد المتطوعين على هاي الفرصة.');
    expect(arabicOrgError('volunteer_withdrew'), 'المتطوع انسحب من هاد الطلب.');
    expect(arabicOrgError('new row violates row-level security policy'), 'ما عندك صلاحية تعملي هاد.');
    expect(arabicOrgError('شي تاني'), 'صار خطأ، حاولي مرة تانية.');
  });
}
