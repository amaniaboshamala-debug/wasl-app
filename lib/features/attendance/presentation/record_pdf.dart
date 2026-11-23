import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:wasl/core/utils/date_ar.dart';
import 'package:wasl/features/attendance/domain/volunteer_record.dart';
import 'package:wasl/features/profile/domain/entities/user_profile.dart';

/// ملفات PDF: الشهادة والسيرة التطوعية (بالعربي ومن اليمين لليسار).
class RecordPdf {
  static const _green = PdfColor.fromInt(0xFF1F6F5C);
  static const _soft = PdfColor.fromInt(0xFFE3F0EA);
  static const _muted = PdfColor.fromInt(0xFF6B7570);

  static Future<pw.ThemeData> _theme() async => pw.ThemeData.withFont(
        base: await PdfGoogleFonts.cairoRegular(),
        bold: await PdfGoogleFonts.cairoBold(),
      );

  /// بيفتح نافذة المشاركة/التنزيل
  static Future<void> share(Uint8List bytes, String filename) => Printing.sharePdf(bytes: bytes, filename: filename);

  static String _date(DateTime d) => '${d.day} ${DateAr.month(d)} ${d.year}';

  static Future<Uint8List> certificate(VolunteerCertificate c) async {
    final doc = pw.Document(theme: await _theme(), title: 'شهادة تطوع - ${c.title}');
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Container(
          padding: const pw.EdgeInsets.all(36),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _green, width: 3),
            borderRadius: pw.BorderRadius.circular(16),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(children: [
                pw.Text('وَصْل', style: const pw.TextStyle(fontSize: 18, color: _green, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('شهادة تطوع', style: const pw.TextStyle(fontSize: 34, fontWeight: pw.FontWeight.bold)),
              ]),
              pw.Column(children: [
                pw.Text('تشهد ${c.issuedBy} بأنّ', style: const pw.TextStyle(fontSize: 16, color: _muted)),
                pw.SizedBox(height: 8),
                pw.Text(c.volunteerName.isEmpty ? '—' : c.volunteerName,
                    style: const pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: _green)),
                pw.SizedBox(height: 10),
                pw.Text(
                  'شارك/ت متطوعاً/ة في «${c.title}» مع ${c.orgName}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.circular(20)),
                  child: pw.Text('بمجموع ${VolunteerRecord.formatHours(c.hours)} ساعة تطوعية',
                      style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _green)),
                ),
              ]),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('تاريخ الإصدار: ${_date(c.issuedAt)}', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('رمز التحقق: ${c.code}', style: const pw.TextStyle(fontSize: 11, color: _muted)),
                    pw.Text('صادرة عبر منصة وَصْل', style: const pw.TextStyle(fontSize: 9, color: _muted)),
                  ]),
                  pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: c.code, width: 64, height: 64, color: _green),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
    return doc.save();
  }

  static Future<Uint8List> cv({
    required String name,
    required String email,
    UserProfile? profile,
    required VolunteerRecord record,
  }) async {
    final doc = pw.Document(theme: await _theme(), title: 'السيرة التطوعية - $name');
    pw.Widget heading(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
          child: pw.Text(t, style: const pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _green)),
        );
    final earned = record.badges.where((b) => b.earned).map((b) => b.title).toList();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      textDirection: pw.TextDirection.rtl,
      build: (_) => [
        pw.Text(name, style: const pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
        pw.Text(
          [if ((profile?.region ?? '').isNotEmpty) profile!.region, if ((profile?.phone ?? '').isNotEmpty) profile!.phone, email]
              .join('  ·  '),
          style: const pw.TextStyle(fontSize: 11, color: _muted),
        ),
        if ((profile?.bio ?? '').isNotEmpty) ...[pw.SizedBox(height: 8), pw.Text(profile!.bio)],
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.circular(10)),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
            _stat(VolunteerRecord.formatHours(record.totalHours), 'ساعة تطوع'),
            _stat('${record.done.length}', 'فرصة'),
            _stat('${record.certificates.length}', 'شهادة'),
            _stat('${record.orgCount}', 'مؤسسة'),
          ]),
        ),
        if ((profile?.skills ?? const []).isNotEmpty) ...[
          heading('المهارات'),
          pw.Text(profile!.skills.join('  ·  ')),
        ],
        heading('الخبرات التطوعية'),
        if (record.done.isEmpty) pw.Text('لسا ما في ساعات مسجّلة.', style: const pw.TextStyle(color: _muted)),
        for (final e in record.done)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(e.title, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text([e.orgName, if (e.date != null) _date(e.date!)].where((s) => s.isNotEmpty).join(' · '),
                      style: const pw.TextStyle(fontSize: 10, color: _muted)),
                ]),
              ),
              pw.Text('${VolunteerRecord.formatHours(e.hours)} ساعة'),
            ]),
          ),
        if (record.certificates.isNotEmpty) ...[
          heading('الشهادات'),
          for (final c in record.certificates)
            pw.Bullet(
              text: '${c.title} — ${c.issuedBy} (${VolunteerRecord.formatHours(c.hours)} ساعة) · ${c.code}',
            ),
        ],
        if (earned.isNotEmpty) ...[heading('الإنجازات'), pw.Text(earned.join('  ·  '))],
        pw.SizedBox(height: 20),
        pw.Text('الساعات والشهادات مسجّلة ومصدّقة عبر منصة وَصْل.',
            style: const pw.TextStyle(fontSize: 9, color: _muted)),
      ],
    ));
    return doc.save();
  }

  static pw.Widget _stat(String value, String label) => pw.Column(children: [
        pw.Text(value, style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _green)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _muted)),
      ]);
}
