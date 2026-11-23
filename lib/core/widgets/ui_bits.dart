import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/presentation/region_cubit.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/theme/app_theme.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/core/utils/regions.dart';

/// قطع صغيرة مشتركة بين الشاشات (من نظام التصميم).

/// شارة صغيرة ملوّنة: "متاحة"، "التسجيل مفتوح"...
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  const StatusChip(this.label, {super.key, required this.color, required this.background});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      );
}

/// أيقونة صغيرة + نص رمادي: 📍 خانيونس
class InfoBit extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoBit(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.muted), overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}

/// اسم المؤسسة مع علامة التوثيق إذا موثّقة.
class OrgName extends StatelessWidget {
  final String name;
  final bool verified;
  final double fontSize;
  const OrgName(this.name, {super.key, this.verified = false, this.fontSize = 12});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(name,
                style: TextStyle(fontSize: fontSize, color: AppColors.muted), overflow: TextOverflow.ellipsis),
          ),
          if (verified) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: 'مؤسسة موثّقة',
              child: Icon(Icons.verified_outlined, size: fontSize + 4, color: AppColors.primary),
            ),
          ],
        ],
      );
}

/// كرت أبيض بزوايا دائرية، وبينضغط.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      );
}

/// شريط التقدّم: 8 من 12
class ProgressLine extends StatelessWidget {
  final double value;
  final String label;
  const ProgressLine({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1).toDouble(),
                minHeight: 6,
                backgroundColor: const Color(0xFFE8E4DA),
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      );
}

/// عنوان قسم مع "عرض الكل".
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionHeader(this.title, {super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: AppTheme.heading(size: 17))),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('عرض الكل', style: TextStyle(fontSize: 13))),
        ],
      );
}

/// حالة "ما في نتائج" أو "صار خطأ"، مع زر اختياري.
class MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const MessageView({super.key, required this.icon, required this.title, this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(22)),
                child: Icon(icon, size: 34, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
}

/// شريط صغير: "بدون نت · آخر تحديث قبل ساعتين"
class CacheNotice extends StatelessWidget {
  final DateTime? savedAt;
  const CacheNotice({super.key, this.savedAt});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.orangeSoft, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 16, color: AppColors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                savedAt == null ? 'بتشوفي آخر نسخة محفوظة' : 'بتشوفي آخر نسخة محفوظة · ${DateAr.ago(savedAt!)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A3E00)),
              ),
            ),
          ],
        ),
      );
}

/// هيكل رمادي مكان الكروت وقت التحميل.
class SkeletonList extends StatelessWidget {
  final int count;
  final double height;
  const SkeletonList({super.key, this.count = 3, this.height = 120});

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
          count,
          (_) => Container(
            height: height,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: const Color(0xFFECE8DF), borderRadius: BorderRadius.circular(18)),
          ),
        ),
      );
}

/// زر المنطقة: 📍 مدينة غزة ⌄ — بيفتح قائمة المناطق.
class RegionButton extends StatelessWidget {
  final bool compact;
  const RegionButton({super.key, this.compact = false});

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<RegionCubit>();
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('اختاري منطقتك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final r in ['__all__', ...Regions.all])
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(
                  (r == '__all__' ? cubit.state == null : cubit.state == r)
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.primary,
                ),
                title: Text(r == '__all__' ? 'كل المناطق' : r),
                onTap: () => Navigator.pop(ctx, r),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await cubit.select(picked == '__all__' ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionCubit>().state;
    return OutlinedButton.icon(
      onPressed: () => _pick(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.card,
        side: const BorderSide(color: AppColors.line),
        minimumSize: Size(0, compact ? 36 : 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compact ? 10 : 22)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      icon: const Icon(Icons.location_on_outlined, size: 16),
      label: Text(region ?? 'كل المناطق'),
    );
  }
}

/// أزرار تصفية أفقية: الكل · الصحة · التعليم...
class FilterChips extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;
  const FilterChips({super.key, required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final o in [null, ...options])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(o ?? 'الكل'),
                selected: selected == o,
                onSelected: (_) => onChanged(o),
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.card,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected == o ? Colors.white : AppColors.ink,
                ),
                side: BorderSide(color: selected == o ? AppColors.primary : AppColors.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
        ],
      ),
    );
  }
}

/// سطر بشاشة التفاصيل: أيقونة · العنوان · القيمة
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const DetailRow(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      );
}

/// شارة "📜 شهادة تطوع مصدّقة" على الكروت.
class CertificateChip extends StatelessWidget {
  const CertificateChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.goldSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gold),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.workspace_premium_outlined, size: 14, color: AppColors.goldDark),
          SizedBox(width: 4),
          Text('شهادة تطوع مصدّقة',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldDark)),
        ]),
      );
}
