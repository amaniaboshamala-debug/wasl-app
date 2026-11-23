import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/applications/presentation/cubit/my_applications_cubit.dart';
import 'package:wasl/features/opportunities/presentation/cubit/opportunities_cubit.dart';

/// بنسأل قبل الانسحاب، وبعدين بنسحب وبنعرض النتيجة.
Future<void> confirmWithdraw(BuildContext context, VolunteerApplication app) async {
  final cubit = context.read<MyApplicationsCubit>();
  final opportunities = context.read<OpportunitiesCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('انسحاب من الفرصة'),
      content: Text(
        app.status == ApplicationStatus.accepted
            ? 'طلبك على «${app.opportunityTitle}» مقبول. أكيد بدك تنسحبي؟ المؤسسة رح تعرف إنك انسحبتِ.'
            : 'أكيد بدك تسحبي طلبك على «${app.opportunityTitle}»؟',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.red, minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('انسحاب'),
        ),
      ],
    ),
  );
  if (yes != true) return;
  final error = await cubit.withdraw(app.id);
  if (error == null) opportunities.refresh(); // عدد المقاعد بيتغيّر
  messenger.showSnackBar(SnackBar(content: Text(error ?? 'انسحبتِ من الفرصة')));
}
