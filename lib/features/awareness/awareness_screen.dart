import 'package:flutter/material.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/core/theme/app_theme.dart';
import 'package:wasl/core/widgets/illustrations.dart';
import 'package:wasl/core/widgets/ui_bits.dart';

/// نصيحة توعوية: رسمة + عنوان + نص قصير + تفاصيل.
class AwarenessTip {
  final String category;
  final String title;
  final String summary;
  final List<String> points;
  final String illustration;
  const AwarenessTip(this.category, this.title, this.summary, this.points, this.illustration);
}

/// ركن التوعية: نصايح قصيرة بتحمي الناس.
class AwarenessScreen extends StatefulWidget {
  const AwarenessScreen({super.key});

  static const tips = [
    AwarenessTip('الأمان', 'احمي حالك من الاحتيال', 'وَصْل ما بيستقبل ولا بيحوّل فلوس. أي طلب تحويل بلّغي عنه.', [
      'وَصْل ما بيطلب منك فلوس أبداً، ولا أي مؤسسة عليه مسموحلها تطلب.',
      'ما تعطي حدا رقم بطاقتك أو كود بيوصلك برسالة.',
      'إذا حدا طلب تحويل باسم مبادرة، اضغطي ⋮ ثم "إبلاغ".',
    ], Illustration.shield),
    AwarenessTip('الأمان', 'تأكّدي من المؤسسة', 'العلامة ✓ جنب اسم المؤسسة يعني فريق وَصْل تأكد منها.', [
      'المؤسسات الموثّقة إلها علامة ✓ جنب اسمها.',
      'مبادرات المؤسسات الجديدة بتنراجع قبل ما تنتشر.',
      'إذا شكّيتي بإشي، بلّغي وإحنا بنراجع.',
    ], Illustration.shieldSage),
    AwarenessTip('التطوع', 'تطوّعي بأمان', 'روحي مع حدا، وخلّي أهلك يعرفوا وين، وما تشاركي معلومات خاصة.', [
      'خبّري حدا من أهلك وين رايحة ومع مين.',
      'تواصلي مع المؤسسة من خلال الرقم اللي بالتطبيق.',
      'التزمي بتعليمات السلامة بمكان النشاط.',
    ], Illustration.seedling),
    AwarenessTip('التطوع', 'خلّي ساعاتك تنحسب', 'ورجي كود الحضور أول ما توصلي وقبل ما تروّحي.', [
      'كود الحضور موجود بـ "طلباتي" تحت الطلب المقبول.',
      'الساعات بتنحسب لحالها وبتطلع بسجلّك التطوعي.',
      'الفرص اللي فيها شهادة، بتوصلك الشهادة PDF.',
    ], Illustration.seedlingPeach),
    AwarenessTip('الصحة النفسية', 'الحكي بيريّح', 'إذا حاسة بضغط، في خدمات دعم نفسي مجانية قريبة منك.', [
      'دوّري بالخدمات على "دعم نفسي" بمنطقتك.',
      'الحكي مع حدا بتثقي فيه خطوة قوية، مش ضعف.',
      'إذا حدا قريب منك تعبان، اسمعيه وشجّعيه يطلب مساعدة.',
    ], Illustration.talk),
  ];

  @override
  State<AwarenessScreen> createState() => _AwarenessScreenState();
}

class _AwarenessScreenState extends State<AwarenessScreen> {
  String? _category;

  void _open(AwarenessTip t) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Illustration(t.illustration, label: t.title, width: 120, height: 120)),
              const SizedBox(height: 12),
              Text(t.title, textAlign: TextAlign.center, style: AppTheme.heading(size: 20, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              for (final p in t.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p, style: const TextStyle(fontSize: 15, height: 1.7))),
                  ]),
                ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final categories = AwarenessScreen.tips.map((t) => t.category).toSet().toList();
    final shown = AwarenessScreen.tips.where((t) => _category == null || t.category == _category).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('ركن التوعية')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: 190,
              child: Stack(fit: StackFit.expand, children: [
                const Illustration(Illustration.community, label: 'ناس مجتمعين حوالين بيت', fit: BoxFit.cover),
                PositionedDirectional(
                  start: 14,
                  end: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(18)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('مجتمعنا أقوى لما نعرف', style: AppTheme.heading(size: 16, weight: FontWeight.w700)),
                      const Text('نصايح قصيرة بتحميكِ وبتحمي غيرك', style: TextStyle(fontSize: 13, color: Color(0xFF4E5A55))),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          FilterChips(options: categories, selected: _category, onChanged: (c) => setState(() => _category = c)),
          const SizedBox(height: 12),
          for (final t in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => _open(t),
                child: Row(children: [
                  Illustration(t.illustration, label: t.title, width: 76, height: 76),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.category,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _categoryColor(t.category))),
                      const SizedBox(height: 2),
                      Text(t.title, style: AppTheme.heading(size: 15)),
                      const SizedBox(height: 2),
                      Text(t.summary, style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.muted)),
                    ]),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  static Color _categoryColor(String c) => switch (c) {
        'الأمان' => AppColors.orange,
        'الصحة النفسية' => const Color(0xFF8A4A6B),
        _ => AppColors.primary,
      };
}
