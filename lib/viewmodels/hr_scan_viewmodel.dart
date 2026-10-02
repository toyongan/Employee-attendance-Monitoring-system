import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/attendance_repository.dart';

class HrScanViewModel extends ChangeNotifier {
  HrScanViewModel(this._repo, this.hr);

  final AttendanceRepository _repo;
  final AppUser hr;

  bool busy = false; // true while processing OR while a result is on screen
  ScanResult? result;
  String? errorMessage;

  Future<void> onQrDetected(String? raw) async {
    if (busy) return;
    busy = true;
    result = null;
    errorMessage = null;
    notifyListeners();
    try {
      result = await _repo.markPresentFromQr(raw, hr);
    } catch (_) {
      errorMessage = 'Could not save attendance. Check your connection.';
    }
    notifyListeners();
  }

  /// Dismiss the result and allow the next scan.
  void reset() {
    busy = false;
    result = null;
    errorMessage = null;
    notifyListeners();
  }
}
