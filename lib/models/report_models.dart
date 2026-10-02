/// Shared small data types used by the HR "Today" and "Reports" screens.

enum ReportPeriod { daily, weekly, monthly }

/// One employee scanned on a given day (used by the "Scanned today" list).
class ScannedEntry {
  final String employeeName;
  final String department;
  final String position;
  final DateTime scannedAt;

  const ScannedEntry({
    required this.employeeName,
    required this.department,
    required this.position,
    required this.scannedAt,
  });
}

/// One row of the present/absent summary report.
class ReportRow {
  final String employeeName;
  final String department;
  final int presentDays;
  final int absentDays;

  const ReportRow({
    required this.employeeName,
    required this.department,
    required this.presentDays,
    required this.absentDays,
  });

  int get totalDays => presentDays + absentDays;

  /// null when there is nothing to measure yet (e.g. brand-new employee).
  double? get rate => totalDays == 0 ? null : presentDays / totalDays;
}
