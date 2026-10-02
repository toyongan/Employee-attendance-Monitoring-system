import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/attendance_rules.dart';
import '../models/app_user.dart';
import '../models/attendance_record.dart';
import '../repositories/attendance_repository.dart';

/// Drives the employee's "today" card.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._repo, this.user) {
    _sub = _repo.watchToday(user.uid).listen((r) {
      _record = r;
      _loaded = true;
      notifyListeners();
    });
    // Re-evaluate every 30s so status flips to Absent once work hours end.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _now = DateTime.now();
      notifyListeners();
    });
  }

  final AttendanceRepository _repo;
  final AppUser user;

  StreamSubscription<AttendanceRecord?>? _sub;
  Timer? _timer;
  AttendanceRecord? _record;
  bool _loaded = false;
  DateTime _now = DateTime.now();

  bool get loaded => _loaded;
  DateTime get now => _now;
  DateTime? get scannedAt => _record?.scannedAt;

  AttendanceStatus get status =>
      AttendanceRules.statusFor(day: _now, record: _record, now: _now);

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
