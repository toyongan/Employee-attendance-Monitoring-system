import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../viewmodels/history_viewmodel.dart';
import '../widgets/status_style.dart';

/// The employee's attendance-monitoring module.
class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    final text = Theme.of(context).textTheme;

    if (!vm.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final entries = vm.entries;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'My attendance',
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Last ${HistoryViewModel.windowDays} days',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Present',
                value: vm.presentCount,
                color: AppColors.present,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                label: 'Absent',
                value: vm.absentCount,
                color: AppColors.absent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (entries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No attendance to show yet.'),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _DayTile(entry: entries[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.entry});
  final DayEntry entry;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(entry.status);
    return ListTile(
      leading: Icon(style.icon, color: style.color),
      title: Text(DateFormat('EEE, MMM d').format(entry.date)),
      subtitle: entry.scannedAt != null
          ? Text('Checked in ${DateFormat.jm().format(entry.scannedAt!)}')
          : null,
      trailing: Text(
        style.label,
        style: TextStyle(color: style.color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
