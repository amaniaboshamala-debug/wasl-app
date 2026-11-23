import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/features/auth/data/models/app_user_model.dart';
import 'package:wasl/features/auth/domain/entities/app_user.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';
import 'package:wasl/features/organization/data/models/org_models.dart';
import 'package:wasl/features/organization/domain/entities/org_initiative.dart';

import '../helpers/fixtures.dart';

void main() {
  group('مبادرة المؤسسة مع احتياجاتها وعروض المساعدة', () {
    final row = <String, dynamic>{
      ...initiativeJson,
      'status': 'pending',
      'needs': [
        {
          'id': 'n1',
          'initiative_id': 'i1',
          'type': 'قرطاسية',
          'description': 'دفاتر',
          'quantity_needed': 100,
          'quantity_provided': 40,
          'status': 'partially_covered',
          'need_offers': [
            {
              'id': 'o1',
              'quantity': 20,
              'note': 'دفاتر جديدة',
              'phone': '0591111111',
              'status': 'pending',
              'created_at': '2026-11-21T10:00:00Z',
              'profiles': {'full_name': 'سارة', 'region': 'مدينة غزة'},
            },
            {
              'id': 'o2',
              'quantity': 10,
              'status': 'received',
              'created_at': '2026-11-20T10:00:00Z',
              'profiles': {'full_name': 'محمد'},
            },
          ],
        },
      ],
    };

    test('بيقرأ المبادرة والاحتياج والعروض', () {
      final i = OrgModels.initiative(row);
      expect(i.initiative.title, 'أيام صحية للأطفال');
      expect(i.initiative.status, InitiativeStatus.pending);
      expect(i.needs, hasLength(1));
      final need = i.needs.first;
      expect(need.need.type, 'قرطاسية');
      expect(need.need.initiativeTitle, 'أيام صحية للأطفال'); // من المبادرة نفسها
      expect(need.offers, hasLength(2));
      expect(need.offers.first.id, 'o1'); // الأحدث أول
      expect(need.offers.first.userName, 'سارة');
      expect(need.offers.first.status, NeedOfferStatus.pending);
      expect(need.pendingOffers, 1);
      expect(i.pendingOffers, 1);
    });

    test('مبادرة بدون احتياجات', () {
      final i = OrgModels.initiative({...initiativeJson});
      expect(i.needs, isEmpty);
      expect(i.pendingOffers, 0);
    });
  });

  test('حساب الإدارة بيتقرأ صح', () {
    final u = AppUserModel.fromProfile({'id': 'a1', 'full_name': 'أماني', 'role': 'admin'}, 'a@b.c');
    expect(u.role, UserRole.admin);
    expect(u.isAdmin, isTrue);
    expect(u.roleLabel, 'إدارة وَصْل');
  });
}
