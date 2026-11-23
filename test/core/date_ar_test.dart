import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/utils/date_ar.dart';

void main() {
  group('DateAr.range', () {
    test('بدون تاريخ', () {
      expect(DateAr.range(null, null), 'الموعد بيتحدد قريباً');
    });

    test('يوم واحد', () {
      expect(DateAr.range(DateTime(2026, 11, 24), null), '24 نوفمبر');
      expect(DateAr.range(DateTime(2026, 11, 24), DateTime(2026, 11, 24)), '24 نوفمبر');
    });

    test('نفس الشهر', () {
      expect(DateAr.range(DateTime(2026, 11, 24), DateTime(2026, 11, 26)), '24 – 26 نوفمبر');
    });

    test('شهرين مختلفين', () {
      expect(DateAr.range(DateTime(2026, 11, 28), DateTime(2026, 12, 3)), '28 نوفمبر – 3 ديسمبر');
    });
  });

  group('DateAr.ago', () {
    DateTime before(Duration d) => DateTime.now().subtract(d);

    test('دقايق وساعات', () {
      expect(DateAr.ago(before(const Duration(seconds: 10))), 'هلأ');
      expect(DateAr.ago(before(const Duration(minutes: 5))), 'قبل 5 دقائق');
      expect(DateAr.ago(before(const Duration(hours: 1))), 'قبل ساعة');
      expect(DateAr.ago(before(const Duration(hours: 2))), 'قبل ساعتين');
    });

    test('أيام', () {
      expect(DateAr.ago(before(const Duration(days: 1, hours: 1))), 'أمس');
      expect(DateAr.ago(before(const Duration(days: 3, hours: 1))), 'قبل 3 أيام');
    });
  });
}
