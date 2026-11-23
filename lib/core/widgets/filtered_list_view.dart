import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/core/presentation/region_cubit.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/utils/regions.dart';
import 'package:wasl/core/widgets/ui_bits.dart';

/// قائمة عامة لتبويبات استكشف: بتعرض التحميل والخطأ والكاش،
/// وبتصفّي حسب المنطقة والبحث والتصنيف. كل تبويب بيعطيها شو يعرض بس.
class FilteredListView<T, C extends ListCubit<T>> extends StatefulWidget {
  final String query;
  final String Function(T) region;
  final String Function(T) searchText;
  final String? Function(T)? category;
  final bool Function(T)? where; // تصفية إضافية (مثلاً: بأجر بس)
  final bool filterByRegion;
  final Widget Function(T) itemBuilder;
  final String countLabel; // "خدمة"، "مبادرة"...
  final IconData emptyIcon;
  final String emptyTitle;

  const FilteredListView({
    super.key,
    required this.query,
    required this.region,
    required this.searchText,
    this.category,
    this.where,
    this.filterByRegion = true,
    required this.itemBuilder,
    required this.countLabel,
    required this.emptyIcon,
    required this.emptyTitle,
  });

  @override
  State<FilteredListView<T, C>> createState() => _FilteredListViewState<T, C>();
}

class _FilteredListViewState<T, C extends ListCubit<T>> extends State<FilteredListView<T, C>>
    with AutomaticKeepAliveClientMixin {
  String? _category;

  @override
  bool get wantKeepAlive => true; // ما يرجع يحمّل كل ما نتنقل بين التبويبات

  @override
  void initState() {
    super.initState();
    context.read<C>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cubit = context.read<C>();
    final region = context.watch<RegionCubit>().state;
    final state = context.watch<C>().state;

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: switch (state) {
        ListLoading<T>() => ListView(padding: const EdgeInsets.all(18), children: const [SkeletonList(count: 4)]),
        ListError<T>(:final message) => ListView(children: [
            const SizedBox(height: 40),
            MessageView(
              icon: Icons.wifi_off_outlined,
              title: 'ما قدرنا نحمّل البيانات',
              subtitle: message,
              actionLabel: 'حاولي مرة تانية',
              onAction: cubit.refresh,
            ),
          ]),
        ListLoaded<T>(:final items, :final fromCache, :final savedAt) =>
          _buildList(items, fromCache, savedAt, region),
      },
    );
  }

  Widget _buildList(List<T> all, bool fromCache, DateTime? savedAt, String? region) {
    final q = widget.query.trim();
    final inRegion = all
        .where((e) => widget.where?.call(e) ?? true)
        .where((e) => !widget.filterByRegion || Regions.matches(widget.region(e), region))
        .toList();
    final categories = widget.category == null
        ? const <String>[]
        : {for (final e in inRegion) widget.category!(e)}.whereType<String>().where((c) => c.isNotEmpty).toList();
    // إذا التصنيف المختار مش موجود بهاي المنطقة، بنرجع لـ "الكل"
    final cat = categories.contains(_category) ? _category : null;
    final shown = inRegion.where((e) {
      if (cat != null && widget.category?.call(e) != cat) return false;
      if (q.isNotEmpty && !widget.searchText(e).contains(q)) return false;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        if (fromCache) CacheNotice(savedAt: savedAt),
        Row(
          children: [
            const RegionButton(compact: true),
            const Spacer(),
            Text('${shown.length} ${widget.countLabel}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 10),
          FilterChips(
            options: categories,
            selected: cat,
            onChanged: (c) => setState(() => _category = c),
          ),
        ],
        const SizedBox(height: 12),
        if (shown.isEmpty)
          MessageView(
            icon: widget.emptyIcon,
            title: widget.emptyTitle,
            subtitle: region != null ? 'جربي تختاري "كل المناطق" أو تغيّري البحث.' : 'جربي تغيّري البحث أو التصنيف.',
          )
        else
          for (final e in shown) Padding(padding: const EdgeInsets.only(bottom: 12), child: widget.itemBuilder(e)),
      ],
    );
  }
}
