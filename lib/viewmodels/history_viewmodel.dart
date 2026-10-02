import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/attendance_rules.dart';
import '../models/app_user.dart';
import '../models/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class DayEntry {
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? scannedAt;
  const DayEntry(this.date, this.status, this.scannedAt);
}

/// Employee's attendance module: last 30 days + summary counts.
class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel(this._repo, this.user) {
    _sub = _repo.watchHistory(user.uid).listen((records) {
      _records = {for (final r in records) r.dateKey: r};
      _loaded = true;
      notifyListeners();
    });
  }

  static const int windowDays = 30;

  final AttendanceRepository _repo;
  final AppUser user;
  StreamSubscription<List<AttendanceRecord>>? _sub;
  Map<String, AttendanceRecord> _records = {};
  bool _loaded = false;

  bool get loaded => _loaded;

  List<DayEntry> get entries {
    final now = DateTime.now();
    final today = AttendanceRules.dateOnly(now);
    final accountStart = AttendanceRules.dateOnly(user.createdAt);
    final windowStart = today.subtract(const Duration(days: windowDays - 1));
    final start = accountStart.isAfter(windowStart)
        ? accountStart
        : windowStart;

    final list = <DayEntry>[];
    for (
      var d = today;
      !d.isBefore(start);
      d = DateTime(d.year, d.month, d.day - 1)
    ) {
      final rec = _records[AttendanceRepository.dateKey(d)];
      final status = AttendanceRules.statusFor(day: d, record: rec, now: now);
      // Hide weekends/holidays unless the employee was actually scanned.
      if (status == AttendanceStatus.dayOff) continue;
      list.add(DayEntry(d, status, rec?.scannedAt));
    }
    return list;
  }

  int _count(AttendanceStatus s) => entries.where((e) => e.status == s).length;
  int get presentCount => _count(AttendanceStatus.present);
  int get absentCount => _count(AttendanceStatus.absent);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
