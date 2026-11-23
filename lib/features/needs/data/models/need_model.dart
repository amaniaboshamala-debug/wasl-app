import 'package:wasl/features/needs/domain/entities/need.dart';

/// تحويل سطر من جدول needs (مع المبادرة والمؤسسة) لـ Need.
class NeedModel {
  static const _status = {
    'open': NeedStatus.open,
    'partially_covered': NeedStatus.partiallyCovered,
    'fully_covered': NeedStatus.fullyCovered,
    'closed': NeedStatus.closed,
  };

  static Need fromJson(Map<String, dynamic> j) {
    final initiative = (j['initiatives'] as Map?) ?? const {};
    final org = (initiative['organizations'] as Map?) ?? const {};
    return Need(
      id: j['id'] as String,
      initiativeId: (j['initiative_id'] as String?) ?? '',
      initiativeTitle: (initiative['title'] as String?) ?? '',
      type: (j['type'] as String?) ?? 'احتياج',
      description: (j['description'] as String?) ?? '',
      quantityNeeded: (j['quantity_needed'] as num?)?.toInt() ?? 0,
      quantityProvided: (j['quantity_provided'] as num?)?.toInt() ?? 0,
      region: (initiative['region'] as String?) ?? '',
      organizationName: (org['name'] as String?) ?? '',
      status: _status[j['status']] ?? NeedStatus.open,
    );
  }
}
