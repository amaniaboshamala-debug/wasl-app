import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wasl/core/theme/app_colors.dart';
import 'package:wasl/features/attendance/data/attendance_repository.dart';
import 'package:wasl/features/attendance/domain/volunteer_record.dart';
import 'package:wasl/features/organization/presentation/cubit/org_lists_cubits.dart';

/// المؤسسة بتمسح كود الحضور: أول مسحة دخول، التانية خروج.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _busy = false;
  String? _lastId;
  DateTime _lastAt = DateTime(2000);
  ({bool ok, String title, String subtitle})? _result;
  Timer? _hide;
  bool _changed = false;

  late final OrgRequestsCubit _requests;

  @override
  void initState() {
    super.initState();
    _requests = context.read<OrgRequestsCubit>(); // عشان نحدّث الطلبات لما نطلع
  }

  @override
  void dispose() {
    _hide?.cancel();
    _controller.dispose();
    if (_changed) _requests.refresh(); // الساعات تغيّرت
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    final id = AttendanceQr.decode(raw);
    if (id == null) {
      if (raw != null) _show(false, 'هاد مش كود حضور من وَصْل', 'خلّي المتطوع يفتح "طلباتي" ← كود الحضور');
      return;
    }
    // نفس الكود خلال 5 ثواني = نفس المسحة
    if (id == _lastId && DateTime.now().difference(_lastAt) < const Duration(seconds: 5)) return;
    _lastId = id;
    _lastAt = DateTime.now();
    setState(() => _busy = true);
    try {
      final r = await context.read<AttendanceRepository>().scan(id);
      _changed = true;
      _show(
        true,
        r.checkedIn ? 'أهلاً ${r.name} 👋 سجّل دخول' : 'يعطيك العافية ${r.name} ✓',
        r.checkedIn ? r.opportunity : '${r.opportunity} · ${VolunteerRecord.formatHours(r.hours)} ساعة',
      );
    } on AttendanceException catch (e) {
      _show(false, 'ما زبط', e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(bool ok, String title, String subtitle) {
    if (!mounted) return;
    _hide?.cancel();
    setState(() => _result = (ok: ok, title: title, subtitle: subtitle));
    _hide = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _result = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('مسح الحضور'),
        actions: [
          IconButton(
            tooltip: 'الضو',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'قلب الكاميرا',
            icon: const Icon(Icons.cameraswitch_outlined),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: r == null
              ? Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(14)),
                  child: Text(
                    _busy ? 'لحظة…' : 'وجّهي الكاميرا على كود الحضور تبع المتطوع',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: r.ok ? AppColors.primarySoft : AppColors.redSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Icon(r.ok ? Icons.check_circle : Icons.error_outline,
                        color: r.ok ? AppColors.primaryDark : AppColors.red, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(r.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(r.subtitle, style: const TextStyle(fontSize: 13)),
                      ]),
                    ),
                  ]),
                ),
        ),
      ]),
    );
  }
}
