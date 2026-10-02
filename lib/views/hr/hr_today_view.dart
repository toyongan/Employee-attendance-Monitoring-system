import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/pdf_service.dart';
import '../../viewmodels/hr_today_viewmodel.dart';

/// HR's "Today" tab: everyone marked present so far today, with a PDF export.
class HrTodayView extends StatelessWidget {
  const HrTodayView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HrTodayViewModel>();
    final text = Theme.of(context).textTheme;

    if (!vm.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scanned today',
                      style: text.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: text.bodyMedium),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Export to PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: vm.entries.isEmpty
                  ? null
                  : () async {
                      final bytes = await PdfService.buildScannedTodayReport(
                          vm.entries, DateTime.now());
                      await Printing.sharePdf(
                          bytes: bytes, filename: 'scanned_today.pdf');
                    },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.groups, color: AppColors.present),
                const SizedBox(width: 12),
                Text(
                  '${vm.entries.length} employees marked present',
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (vm.entries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No one has been scanned yet today.'),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < vm.entries.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(vm.entries[i].employeeName),
                    subtitle: Text(
                        '${vm.entries[i].position}, ${vm.entries[i].department}'),
                    trailing:
                        Text(DateFormat.jm().format(vm.entries[i].scannedAt)),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
