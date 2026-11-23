import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/features/initiatives/data/models/initiative_model.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';
import 'package:wasl/features/needs/data/models/need_model.dart';
import 'package:wasl/features/needs/domain/entities/need.dart';
import 'package:wasl/features/services/data/models/community_service_model.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';

import '../helpers/fixtures.dart';

/// الكاش (Hive) بيرجّع الـ Maps الداخلية بنوع `Map<dynamic, dynamic>`،
/// فبنجرب التحويل بالشكلين: من Supabase ومن الكاش.
Map<String, dynamic> asFromCache(Map<String, dynamic> j) =>
    j.map((k, v) => MapEntry(k, v is Map ? Map<dynamic, dynamic>.from(v) : v));

void main() {
  group('InitiativeModel', () {
    for (final source in ['Supabase', 'الكاش']) {
      test('بيقرأ المبادرة صح من $source', () {
        final json = source == 'Supabase' ? initiativeJson : asFromCache(initiativeJson);
        final i = InitiativeModel.fromJson(json);
        expect(i.title, 'أيام صحية للأطفال');
        expect(i.organizationName, 'مؤسسة شفاء');
        expect(i.organizationVerified, isTrue);
        expect(i.startDate, DateTime(2026, 11, 24));
        expect(i.volunteersNeeded, 12);
        expect(i.skills, ['إسعاف أولي', 'تنظيم فعاليات']);
        expect(i.status, InitiativeStatus.published);
      });
    }

    test('ما بيوقع إذا في خانات فاضية', () {
      final i = InitiativeModel.fromJson({'id': 'x', 'status': 'شي غريب'});
      expect(i.title, '');
      expect(i.startDate, isNull);
      expect(i.skills, isEmpty);
      expect(i.status, InitiativeStatus.published);
    });
  });

  group('CommunityServiceModel', () {
    test('بيقرأ الخدمة صح', () {
      final s = CommunityServiceModel.fromJson(asFromCache(serviceJson));
      expect(s.name, 'عيادة أطفال مجانية');
      expect(s.provider, 'مؤسسة شفاء');
      expect(s.status, ServiceStatus.limited);
      expect(s.statusLabel, 'محدودة');
      expect(s.needsConfirmation, isFalse);
    });

    test('الخدمة اللي ما تأكدت من أسبوع بتحتاج تأكيد', () {
      final old = {...serviceJson, 'last_confirmed_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String()};
      expect(CommunityServiceModel.fromJson(old).needsConfirmation, isTrue);
    });
  });

  group('NeedModel', () {
    test('بيقرأ الاحتياج مع المبادرة والمنطقة والمؤسسة', () {
      final n = NeedModel.fromJson(needJson);
      expect(n.type, 'قرطاسية');
      expect(n.initiativeTitle, 'تعلّم وارتقِ');
      expect(n.region, 'مدينة غزة');
      expect(n.organizationName, 'جمعية نور');
      expect(n.status, NeedStatus.partiallyCovered);
      expect(n.progress, closeTo(0.6, 0.001));
      expect(n.isUrgent, isFalse); // 60% متوفّر
    });

    test('الاحتياج المفتوح عاجل، والمكتمل لأ', () {
      expect(NeedModel.fromJson({...needJson, 'status': 'open'}).isUrgent, isTrue);
      expect(NeedModel.fromJson({...needJson, 'status': 'fully_covered'}).isUrgent, isFalse);
    });

    test('ما بيقسم على صفر', () {
      expect(NeedModel.fromJson({...needJson, 'quantity_needed': 0}).progress, 0);
    });
  });
}
