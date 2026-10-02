import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../widgets/status_style.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.user, required this.onShowQr});

  final AppUser user;
  final VoidCallback onShowQr;

  String _subtitle(DashboardViewModel vm) {
    final endLabel = DateFormat.jm().format(
      DateTime(2000, 1, 1, AppConstants.workEndHour),
    );
    switch (vm.status) {
      case AttendanceStatus.present:
        final t = vm.scannedAt;
        return t == null
            ? 'HR has marked you present.'
            : 'HR checked you in at ${DateFormat.jm().format(t)}.';
      case AttendanceStatus.absent:
        return 'No scan was recorded before work ended at $endLabel.';
      case AttendanceStatus.notMarked:
        return 'Show your QR code to HR to be marked present.';
      case AttendanceStatus.dayOff:
        return 'No work is scheduled today.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final text = Theme.of(context).textTheme;
    final style = StatusStyle.of(vm.status);

    final startLabel = DateFormat.jm().format(
      DateTime(2000, 1, 1, AppConstants.workStartHour),
    );
    final endLabel = DateFormat.jm().format(
      DateTime(2000, 1, 1, AppConstants.workEndHour),
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Hello, ${user.firstName}',
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(DateFormat('EEEE, MMMM d').format(vm.now), style: text.bodyMedium),
        const SizedBox(height: 20),
        if (!vm.loaded)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: style.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(style.icon, size: 44, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  style.label,
                  style: text.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitle(vm),
                  style: text.bodyLarge?.copyWith(color: Colors.white),
                ),
                if (vm.status == AttendanceStatus.notMarked) ...[
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    onPressed: onShowQr,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: style.color,
                    ),
                    child: const Text('Show my QR code'),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Work hours'),
            subtitle: Text('$startLabel to $endLabel, Monday to Friday'),
          ),
        ),
      ],
    );
  }
}
