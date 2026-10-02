import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../repositories/attendance_repository.dart';
import '../../viewmodels/hr_scan_viewmodel.dart';

/// The "Scan" tab body. HrShell provides the Scaffold, AppBar and the
/// HrScanViewModel above this widget.
class HrScanBody extends StatefulWidget {
  const HrScanBody({super.key});

  @override
  State<HrScanBody> createState() => _HrScanBodyState();
}

class _HrScanBodyState extends State<HrScanBody> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HrScanViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      if (capture.barcodes.isEmpty) return;
                      vm.onQrDetected(capture.barcodes.first.rawValue);
                    },
                    errorBuilder: (context, error, child) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Camera unavailable. Allow camera access in '
                          'your phone settings.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ResultPanel(vm: vm),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.vm});
  final HrScanViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (!vm.busy) {
      return const SizedBox(
        height: 96,
        child: Center(
          child: Text("Point the camera at an employee's QR code."),
        ),
      );
    }

    // Processing
    if (vm.result == null && vm.errorMessage == null) {
      return const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    late Color color;
    late IconData icon;
    late String title;
    String? detail;

    if (vm.errorMessage != null) {
      color = AppColors.absent;
      icon = Icons.error_rounded;
      title = 'Not saved';
      detail = vm.errorMessage;
    } else {
      final r = vm.result!;
      final time = r.time == null ? '' : DateFormat.jm().format(r.time!);
      switch (r.outcome) {
        case ScanOutcome.marked:
          color = AppColors.present;
          icon = Icons.check_circle_rounded;
          title = '${r.employee!.fullName} is present';
          detail = '${r.employee!.position}, ${r.employee!.department}'
              '  •  $time';
        case ScanOutcome.alreadyMarked:
          color = AppColors.pending;
          icon = Icons.info_rounded;
          title = '${r.employee!.fullName} is already marked';
          detail = 'Checked in earlier today at $time.';
        case ScanOutcome.invalidQr:
          color = AppColors.absent;
          icon = Icons.qr_code_scanner_rounded;
          title = 'Not an employee QR code';
          detail = 'Ask the employee to open My QR in the app.';
        case ScanOutcome.unknownEmployee:
          color = AppColors.absent;
          icon = Icons.person_off_rounded;
          title = 'No employee found';
          detail = 'This QR code is not linked to an account.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(detail, style: const TextStyle(color: Colors.white)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: vm.reset,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: color,
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Scan next'),
          ),
        ],
      ),
    );
  }
}
