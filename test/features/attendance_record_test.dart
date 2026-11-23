import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/features/attendance/domain/volunteer_record.dart';
import 'package:wasl/features/organization/data/models/org_models.dart';

import '../helpers/fixtures.dart';

Map<String, dynamic> _app(String id, String title, String org, List<Map<String, dynamic>> attendance, {String? date}) => {
      'id': id,
      'opportunity_id': 'op-$id',
      'opportunities': {'title': title, 'type': 'volunteer', 'date': date, 'organizations': {'name': org}},
      'attendance': attendance,
    };

void main() {
  group('كود الحضور', () {
    const id = '3f2a8c4e-1b2d-4e5f-8a9b-0c1d2e3f4a5b';
    test('بيرمّز وبيفك صح', () {
      expect(AttendanceQr.decode(AttendanceQr.encode(id)), id);
    });
    test('بيرفض أي كود تاني', () {
      expect(AttendanceQr.decode('https://example.com'), isNull);
      expect(AttendanceQr.decode('wasl-att:123'), isNull);
      expect(AttendanceQr.decode(null), isNull);
    });
  });

  group('سجل التطوع', () {
    final record = VolunteerRecord.fromRows(
      [
        _app('a1', 'دروس تقوية', 'جمعية نور', [
          {'hours': 3, 'approved': true},
          {'hours': 2.5, 'approved': true},
          {'hours': 0, 'approved': false}, // جلسة مفتوحة ما بتنحسب
        ], date: '2026-11-10T08:00:00Z'),
        _app('a2', 'توزيع طرود', 'مؤسسة شفاء', [
          {'hours': 6, 'approved': true},
        ], date: '2026-11-15T08:00:00Z'),
        _app('a3', 'فرصة لسا ما بلّشت', 'جمعية نور', []),
      ],
      [
        {
          'code': 'WSL-AB12-CD34',
          'title': 'دروس تقوية',
          'org_name': 'جمعية نور',
          'issuer': '',
          'volunteer_name': 'سارة',
          'hours': 5.5,
          'issued_at': '2026-11-20T10:00:00Z',
        },
      ],
    );

    test('بيجمع الساعات المعتمدة بس', () {
      expect(record.totalHours, 11.5);
      expect(record.entries.firstWhere((e) => e.applicationId == 'a1').hours, 5.5);
      expect(record.done, hasLength(2));
      expect(record.orgCount, 2);
    });

    test('الأحدث أول', () {
      expect(record.entries.first.title, 'توزيع طرود');
    });

    test('الشهادة والجهة المصدّقة', () {
      final c = record.certificates.single;
      expect(c.code, 'WSL-AB12-CD34');
      expect(c.issuedBy, 'جمعية نور'); // ما في جهة تانية، فالمؤسسة نفسها
    });

    test('الشارات', () {
      final earned = record.badges.where((b) => b.earned).map((b) => b.title).toList();
      expect(earned, containsAll(['أول خطوة', '10 ساعات', 'موثّقة']));
      expect(earned, isNot(contains('50 ساعة')));
      final fifty = record.badges.firstWhere((b) => b.title == '50 ساعة');
      expect(fifty.progress, closeTo(11.5 / 50, 0.001));
    });

    test('شكل الساعات', () {
      expect(VolunteerRecord.formatHours(3), '3');
      expect(VolunteerRecord.formatHours(2.5), '2.5');
    });

    test('سجل فاضي', () {
      final empty = VolunteerRecord.fromRows(const [], const []);
      expect(empty.totalHours, 0);
      expect(empty.earnedCount, 0);
    });
  });

  test('طلب المؤسسة بيقرأ الساعات والشهادة', () {
    final r = OrgModels.request({
      ...orgRequestJson,
      'status': 'accepted',
      'opportunities': {'title': 'دروس', 'organization_id': 'o1', 'offers_certificate': true},
      'attendance': [
        {'hours': 2, 'approved': true, 'check_in_at': '2026-11-20T08:00:00Z', 'check_out_at': '2026-11-20T10:00:00Z'},
        {'hours': 0, 'approved': false, 'check_in_at': '2026-11-21T08:00:00Z', 'check_out_at': null},
      ],
      'certificates': [
        {'code': 'WSL-1111-2222'},
      ],
    });
    expect(r.hours, 2);
    expect(r.checkedIn, isTrue);
    expect(r.offersCertificate, isTrue);
    expect(r.certificateCode, 'WSL-1111-2222');

    final plain = OrgModels.request(orgRequestJson);
    expect(plain.hours, 0);
    expect(plain.checkedIn, isFalse);
    expect(plain.certificateCode, isNull);
  });
}
