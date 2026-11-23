import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasl/core/router/routes.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/widgets/ui_bits.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_state.dart';
import 'package:wasl/features/needs/domain/entities/need.dart';
import 'package:wasl/features/needs/presentation/widgets/offer_need_sheet.dart';

/// كرت الاحتياج: النوع والوصف والمبادرة، وشريط قديش اتوفّر منه.
/// لما ينضغط بيفتح المبادرة تبعته.
class NeedCard extends StatelessWidget {
  final Need item;
  const NeedCard(this.item, {super.key});

  /// الزر للناس والمتطوعين، مش للمؤسسات والإدارة، وبس لما الاحتياج لسا مفتوح.
  bool _canOffer(BuildContext context) {
    if (item.status != NeedStatus.open && item.status != NeedStatus.partiallyCovered) return false;
    final auth = context.read<AuthCubit?>()?.state;
    if (auth is! Authenticated) return false;
    return !auth.user.isOrganization && !auth.user.isAdmin;
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (item.status) {
      NeedStatus.open => (AppColors.red, AppColors.redSoft),
      NeedStatus.partiallyCovered => (const Color(0xFF7A3E00), AppColors.orangeSoft),
      _ => (AppColors.primaryDark, AppColors.primarySoft),
    };
    return AppCard(
      onTap: item.initiativeId.isEmpty ? null : () => context.push(Routes.initiativeDetails(item.initiativeId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.type, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
              const SizedBox(width: 8),
              StatusChip(item.statusLabel, color: fg, background: bg),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.description, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              if (item.initiativeTitle.isNotEmpty) InfoBit(Icons.flag_outlined, item.initiativeTitle),
              if (item.region.isNotEmpty) InfoBit(Icons.location_on_outlined, item.region),
            ],
          ),
          if (item.quantityNeeded > 0) ...[
            const SizedBox(height: 10),
            ProgressLine(value: item.progress, label: '${item.quantityProvided} من ${item.quantityNeeded}'),
          ],
          if (_canOffer(context))
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => showOfferNeedSheet(context, item),
                icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
                label: const Text('بقدر أوفّر هاد'),
              ),
            ),
        ],
      ),
    );
  }
}
