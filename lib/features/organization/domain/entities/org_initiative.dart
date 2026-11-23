import 'package:equatable/equatable.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';
import 'package:wasl/features/needs/domain/entities/need.dart';

enum NeedOfferStatus { pending, received, declined }

/// عرض من حدا إنه بيوفّر جزء من احتياج.
class NeedOffer extends Equatable {
  final String id;
  final String userName;
  final String userRegion;
  final int quantity;
  final String note;
  final String phone;
  final NeedOfferStatus status;
  final DateTime createdAt;

  const NeedOffer({
    required this.id,
    this.userName = '',
    this.userRegion = '',
    required this.quantity,
    this.note = '',
    this.phone = '',
    this.status = NeedOfferStatus.pending,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, status];
}

/// احتياج من احتياجات المبادرة، مع العروض اللي وصلت عليه.
class OrgNeed extends Equatable {
  final Need need;
  final List<NeedOffer> offers;
  const OrgNeed(this.need, {this.offers = const []});

  int get pendingOffers => offers.where((o) => o.status == NeedOfferStatus.pending).length;

  @override
  List<Object?> get props => [need, offers];
}

/// مبادرة من مبادرات المؤسسة، مع احتياجاتها.
class OrgInitiative extends Equatable {
  final Initiative initiative;
  final List<OrgNeed> needs;
  const OrgInitiative(this.initiative, {this.needs = const []});

  int get pendingOffers => needs.fold(0, (sum, n) => sum + n.pendingOffers);

  @override
  List<Object?> get props => [initiative, needs];
}
