import 'package:flutter/foundation.dart';

import '../core/attendance_rules.dart';
import '../models/attendance_record.dart';
import '../models/report_models.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/employee_repository.dart';

/// Drives HR's "Reports" tab: pick daily / weekly / monthly, then build a
/// present/absent summary per employee for that range.
class ReportViewModel extends ChangeNotifier {
  ReportViewModel(this._attendanceRepo, this._employeeRepo);

  final AttendanceRepository _attendanceRepo;
  final EmployeeRepository _employeeRepo;

  ReportPeriod period = ReportPeriod.daily;
  DateTime anchor = DateTime.now();
  DateTime rangeStart = DateTime.now();
  DateTime rangeEnd = DateTime.now();

  bool loading = false;
  String? error;
  List<ReportRow> rows = [];

  void setPeriod(ReportPeriod p) {
    period = p;
    notifyListeners();
  }

  void setAnchor(DateTime d) {
    anchor = d;
    notifyListeners();
  }

  (DateTime, DateTime) _computeRange() {
    final d = AttendanceRules.dateOnly(anchor);
    switch (period) {
      case ReportPeriod.daily:
        return (d, d);
      case ReportPeriod.weekly:
        final start = d.subtract(Duration(days: d.weekday - DateTime.monday));
        final end = start.add(const Duration(days: 6));
        return (start, end);
      case ReportPeriod.monthly:
        final start = DateTime(d.year, d.month, 1);
        final end = DateTime(d.year, d.month + 1, 0);
        return (start, end);
    }
  }

  Future<void> generate() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final (start, end) = _computeRange();
      rangeStart = start;
      rangeEnd = end;

      final employees = await _employeeRepo.fetchAllEmployees();
      final records = await _attendanceRepo.fetchRange(
        AttendanceRepository.dateKey(start),
        AttendanceRepository.dateKey(end),
      );
      final byKey = {
        for (final r in records) '${r.employeeId}_${r.dateKey}': r,
      };

      final now = DateTime.now();
      final today = AttendanceRules.dateOnly(now);
      final result = <ReportRow>[];

      for (final emp in employees) {
        var present = 0;
        var absent = 0;
        for (var d = start;
            !d.isAfter(end);
            d = d.add(const Duration(days: 1))) {
          if (d.isAfter(today)) continue; // future day: nothing to count yet
          final rec = byKey['${emp.uid}_${AttendanceRepository.dateKey(d)}'];
          final status =
              AttendanceRules.statusFor(day: d, record: rec, now: now);
          if (status == AttendanceStatus.present) present++;
          if (status == AttendanceStatus.absent) absent++;
        }
        result.add(ReportRow(
          employeeName: emp.fullName,
          department: emp.department,
          presentDays: present,
          absentDays: absent,
        ));
      }
      rows = result;
    } catch (_) {
      error = 'Could not load the report. Check your connection.';
    }

    loading = false;
    notifyListeners();
  }
}
