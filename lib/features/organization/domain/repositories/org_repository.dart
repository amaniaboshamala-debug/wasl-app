import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/organization/domain/entities/org_initiative.dart';
import 'package:wasl/features/organization/domain/entities/org_opportunity.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';
import 'package:wasl/features/organization/domain/entities/org_request.dart';
import 'package:wasl/features/organization/domain/entities/organization.dart';

/// بيانات الفرصة الجديدة اللي المؤسسة بتنشرها.
class NewOpportunityInput {
  final String title;
  final String tasks;
  final String type; // volunteer · paid · volunteer_allowance
  final String? compensation;
  final bool isRemote;
  final String? region;
  final String location;
  final DateTime? date;
  final String duration;
  final DateTime? applyDeadline;
  final int volunteersNeeded;
  final List<String> skills;
  final bool offersCertificate;
  final String? certificateIssuer;

  const NewOpportunityInput({
    required this.title,
    required this.tasks,
    this.type = 'volunteer',
    this.compensation,
    this.isRemote = false,
    this.region,
    this.location = '',
    this.date,
    this.duration = '',
    this.applyDeadline,
    this.volunteersNeeded = 1,
    this.skills = const [],
    this.offersCertificate = false,
    this.certificateIssuer,
  });
}

/// بيانات المبادرة الجديدة.
class NewInitiativeInput {
  final String title;
  final String description;
  final String category;
  final String region;
  final DateTime? startDate;
  final DateTime? endDate;
  final int volunteersNeeded;
  final List<String> skills;
  final bool offersCertificate;
  final String? certificateIssuer;
  const NewInitiativeInput({
    required this.title,
    required this.description,
    required this.category,
    required this.region,
    this.startDate,
    this.endDate,
    this.volunteersNeeded = 0,
    this.skills = const [],
    this.offersCertificate = false,
    this.certificateIssuer,
  });
}

/// بيانات الخدمة الجديدة.
class NewServiceInput {
  final String name;
  final String category;
  final String description;
  final String beneficiaries;
  final String region;
  final String schedule;
  final String howToBenefit;
  const NewServiceInput({
    required this.name,
    required this.category,
    this.description = '',
    this.beneficiaries = '',
    required this.region,
    this.schedule = '',
    this.howToBenefit = '',
  });
}

abstract class OrgRepository {
  /// مؤسستي: Ok(null) يعني لسا ما انعملت.
  Future<Result<Organization?>> getMyOrg();
  Future<Result<Organization>> createOrg({required String name, String bio, String region, String contact});
  Future<Result<Organization>> updateOrg({required String name, String bio, String region, String contact});

  Future<Result<CachedList<OrgOpportunity>>> getOpportunities();
  Future<Failure?> createOpportunity(NewOpportunityInput input);
  Future<Failure?> setOpportunityOpen(String id, bool open);

  Future<Result<CachedList<OrgInitiative>>> getInitiatives();
  Future<Failure?> createInitiative(NewInitiativeInput input);
  Future<Failure?> setInitiativeStatus(String id, String status);
  Future<Failure?> addNeed({required String initiativeId, required String type, String description, required int quantity});
  Future<Failure?> closeNeed(String needId);
  Future<Failure?> decideOffer(String offerId, {required bool received});

  Future<Result<CachedList<CommunityService>>> getServices();
  Future<Failure?> createService(NewServiceInput input);
  Future<Failure?> confirmService(String id);
  Future<Failure?> setServiceStatus(String id, ServiceStatus status);

  Future<Result<CachedList<OrgRequest>>> getRequests();
  Future<Failure?> decide(String applicationId, {required bool accept});
}
