import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/report_models.dart';
import '../../services/pdf_service.dart';
import '../../viewmodels/report_viewmodel.dart';

/// HR's "Reports" tab: filter present/absent counts by day, week, or month,
/// then export the table as a PDF.
class HrReportView extends StatefulWidget {
  const HrReportView({super.key});

  @override
  State<HrReportView> createState() => _HrReportViewState();
}

class _HrReportViewState extends State<HrReportView> {
  @override
  void initState() {
    super.initState();
    // Generate the first report right after this tab is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReportViewModel>().generate();
    });
  }

  Future<void> _pickDate(ReportViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.anchor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      vm.setAnchor(picked);
      await vm.generate();
    }
  }

  String _rangeLabel(ReportViewModel vm) {
    final f = DateFormat('MMM d, y');
    if (vm.period == ReportPeriod.daily) return f.format(vm.rangeStart);
    return '${f.format(vm.rangeStart)} \u2013 ${f.format(vm.rangeEnd)}';
  }

  String _periodLabel(ReportPeriod p) {
    switch (p) {
      case ReportPeriod.daily:
        return 'Daily';
      case ReportPeriod.weekly:
        return 'Weekly';
      case ReportPeriod.monthly:
        return 'Monthly';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Attendance reports',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Filter by day, week, or month, then export.',
            style: text.bodyMedium),
        const SizedBox(height: 16),
        SegmentedButton<ReportPeriod>(
          segments: const [
            ButtonSegment(value: ReportPeriod.daily, label: Text('Daily')),
            ButtonSegment(value: ReportPeriod.weekly, label: Text('Weekly')),
            ButtonSegment(value: ReportPeriod.monthly, label: Text('Monthly')),
          ],
          selected: {vm.period},
          onSelectionChanged: (s) {
            vm.setPeriod(s.first);
            vm.generate();
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _pickDate(vm),
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(vm.loading ? 'Loading…' : _rangeLabel(vm)),
        ),
        const SizedBox(height: 20),
        if (vm.error != null)
          Text(vm.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (vm.loading)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${vm.rows.length} employees', style: text.bodyMedium),
              FilledButton.icon(
                onPressed: vm.rows.isEmpty
                    ? null
                    : () async {
                        final bytes = await PdfService.buildAttendanceReport(
                          rows: vm.rows,
                          periodLabel: _periodLabel(vm.period),
                          rangeLabel: _rangeLabel(vm),
                        );
                        await Printing.sharePdf(
                            bytes: bytes, filename: 'attendance_report.pdf');
                      },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Export PDF'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (vm.rows.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No employees to report on yet.'),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < vm.rows.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _RowTile(row: vm.rows[i]),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row});
  final ReportRow row;

  @override
  Widget build(BuildContext context) {
    final rateText = row.rate == null ? '—' : '${(row.rate! * 100).round()}%';
    return ListTile(
      title: Text(row.employeeName),
      subtitle: Text(row.department),
      trailing: Text('${row.presentDays}P / ${row.absentDays}A  •  $rateText'),
    );
  }
}
