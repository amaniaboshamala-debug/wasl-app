import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:wasl/core/storage/local_cache.dart';

/// بيانات تجريبية بنفس شكل اللي بيرجّعه Supabase.
final initiativeJson = <String, dynamic>{
  'id': 'i1',
  'organization_id': 'o1',
  'title': 'أيام صحية للأطفال',
  'description': 'فحوصات مجانية للأطفال',
  'category': 'صحية',
  'region': 'خانيونس',
  'start_date': '2026-11-24',
  'end_date': '2026-11-26',
  'volunteers_needed': 12,
  'skills': ['إسعاف أولي', 'تنظيم فعاليات'],
  'image_url': null,
  'status': 'published',
  'organizations': {'name': 'مؤسسة شفاء', 'is_verified': true},
};

final serviceJson = <String, dynamic>{
  'id': 's1',
  'organization_id': 'o1',
  'name': 'عيادة أطفال مجانية',
  'description': 'كشف طبي',
  'beneficiaries': 'الأطفال',
  'region': 'دير البلح',
  'schedule': 'السبت – الخميس',
  'how_to_benefit': 'احضري مع الهوية',
  'status': 'limited',
  'category': 'صحة',
  'last_confirmed_at': DateTime.now().subtract(const Duration(hours: 2)).toUtc().toIso8601String(),
  'organizations': {'name': 'مؤسسة شفاء', 'is_verified': false},
};

final needJson = <String, dynamic>{
  'id': 'n1',
  'initiative_id': 'i1',
  'type': 'قرطاسية',
  'description': 'دفاتر وأقلام',
  'quantity_needed': 100,
  'quantity_provided': 60,
  'status': 'partially_covered',
  'initiatives': {
    'id': 'i1',
    'title': 'تعلّم وارتقِ',
    'region': 'مدينة غزة',
    'organizations': {'name': 'جمعية نور'},
  },
};

/// Hive بمجلد مؤقت، عشان الكاش والمنطقة يشتغلوا بالتست بدون جوال.
Future<void> setUpHive() async {
  final dir = await Directory.systemTemp.createTemp('wasl_test_');
  Hive.init(dir.path);
  await LocalCache.init();
}

Future<void> tearDownHive() async {
  await Hive.deleteFromDisk();
}

final opportunityJson = <String, dynamic>{
  'id': 'op1',
  'organization_id': 'o1',
  'initiative_id': 'i1',
  'title': 'مدخل بيانات لمسح تعليمي',
  'tasks': 'إدخال نتائج الاستبيان',
  'location': 'مقر الجمعية',
  'region': 'مدينة غزة',
  'date': '2026-11-25T08:00:00Z',
  'duration': '10 أيام',
  'apply_deadline': '2026-11-24',
  'volunteers_needed': 6,
  'accepted_count': 2,
  'skills': ['إكسل', 'دقة'],
  'type': 'paid',
  'compensation': '50 ₪ يومياً',
  'is_remote': false,
  'status': 'open',
  'organizations': {'name': 'جمعية نور', 'is_verified': true},
};

final applicationJson = <String, dynamic>{
  'id': 'a1',
  'opportunity_id': 'op1',
  'volunteer_id': 'u1',
  'bio': 'بحب أساعد',
  'available_days': ['السبت', 'الأحد'],
  'skills': ['إكسل'],
  'status': 'pending',
  'created_at': '2026-11-20T10:00:00Z',
  'opportunities': {
    'title': 'مدخل بيانات لمسح تعليمي',
    'location': 'مقر الجمعية',
    'region': 'مدينة غزة',
    'is_remote': false,
    'date': '2026-11-25T08:00:00Z',
    'organizations': {'name': 'جمعية نور'},
  },
};

final orgRequestJson = <String, dynamic>{
  'id': 'r1',
  'opportunity_id': 'op1',
  'volunteer_id': 'u1',
  'bio': 'بحب الأطفال',
  'available_days': ['السبت'],
  'skills': <String>[],
  'phone': '0591234567',
  'status': 'pending',
  'created_at': '2026-11-21T10:00:00Z',
  'profiles': {'full_name': 'سارة محمد', 'region': 'مدينة غزة', 'skills': ['تدريس', 'رسم']},
  'opportunities': {'title': 'مساعدة في دروس تقوية', 'organization_id': 'o1'},
};
