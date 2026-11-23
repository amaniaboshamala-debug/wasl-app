import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:wasl/features/favorites/presentation/cubit/favorites_cubit.dart';

/// زر الحفظ بالمفضلة (🔖) لأي مبادرة أو خدمة أو فرصة.
class FavoriteButton extends StatefulWidget {
  final FavoriteType type;
  final String id;
  const FavoriteButton({super.key, required this.type, required this.id});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  @override
  void initState() {
    super.initState();
    context.read<FavoritesCubit>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FavoritesCubit>();
    final cubit = context.read<FavoritesCubit>();
    final saved = cubit.isFavorite(widget.type, widget.id);
    return IconButton(
      tooltip: saved ? 'شيليها من المفضلة' : 'احفظيها بالمفضلة',
      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: saved ? AppColors.primary : null),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final ok = await cubit.toggle(widget.type, widget.id);
        messenger.showSnackBar(SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(!ok ? 'ما قدرنا نحفظ، تأكدي من النت' : (saved ? 'انشالت من المفضلة' : 'انحفظت بالمفضلة 🔖')),
        ));
      },
    );
  }
}
