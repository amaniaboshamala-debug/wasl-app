import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/features/auth/domain/entities/app_user.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_state.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    final loading = context.watch<AuthCubit>().state is AuthLoading;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مين أنت؟'),
        actions: [
          TextButton(onPressed: loading ? null : cubit.logout, child: const Text('خروج')),
        ],
      ),
      body: AbsorbPointer(
        absorbing: loading, // ما ينضغط مرتين وهو بيحفظ
        child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'اختاري كيف بدك تستخدمي وَصْل:',
            style: TextStyle(color: AppColors.muted, fontSize: 15),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            icon: Icons.person_outline,
            title: 'مستخدم',
            subtitle: 'بدي أتصفح المبادرات والخدمات',
            onTap: () => cubit.chooseRole(UserRole.user),
          ),
          _RoleCard(
            icon: Icons.volunteer_activism_outlined,
            title: 'متطوع',
            subtitle: 'بدي أشارك بالمبادرات وأوثّق ساعاتي',
            onTap: () => cubit.chooseRole(UserRole.volunteer),
          ),
          _RoleCard(
            icon: Icons.apartment_outlined,
            title: 'مؤسسة أو فريق',
            subtitle: 'بدي أنشر مبادرات وخدمات واحتياجات',
            onTap: () => cubit.chooseRole(UserRole.organization),
          ),
          if (loading) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        ],
      ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: AppColors.primary, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
