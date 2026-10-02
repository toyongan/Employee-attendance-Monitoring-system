import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/attendance_record.dart';
import '../models/report_models.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/employee_repository.dart';

/// Drives HR's "Scanned today" tab: everyone marked present so far today,
/// newest first.
class HrTodayViewModel extends ChangeNotifier {
  HrTodayViewModel(this._attendanceRepo, this._employeeRepo) {
    _load();
  }

  final AttendanceRepository _attendanceRepo;
  final EmployeeRepository _employeeRepo;

  StreamSubscription<List<AttendanceRecord>>? _sub;
  Map<String, AppUser> _employeesById = {};

  bool loaded = false;
  List<ScannedEntry> entries = [];

  Future<void> _load() async {
    final employees = await _employeeRepo.fetchAllEmployees();
    _employeesById = {for (final e in employees) e.uid: e};

    final today = AttendanceRepository.dateKey(DateTime.now());
    _sub = _attendanceRepo.watchByDate(today).listen((records) {
      entries = records.map((r) {
        final emp = _employeesById[r.employeeId];
        return ScannedEntry(
          employeeName: r.employeeName,
          department: emp?.department ?? '—',
          position: emp?.position ?? '—',
          scannedAt: r.scannedAt,
        );
      }).toList();
      loaded = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
