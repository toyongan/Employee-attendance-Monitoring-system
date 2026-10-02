import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/employee_repository.dart';

class HrEmployeesViewModel extends ChangeNotifier {
  HrEmployeesViewModel(this._repo) {
    _sub = _repo.watchAllEmployees().listen(
      (list) {
        employees = list;
        loaded = true;
        loadError = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('watchAllEmployees failed: $e');
        loadError = 'Could not load the roster: $e';
        loaded = true;
        notifyListeners();
      },
    );
  }

  final EmployeeRepository _repo;
  StreamSubscription<List<AppUser>>? _sub;

  bool loaded = false;
  String? loadError;
  List<AppUser> employees = [];

  /// uid of the employee currently being removed (shows a spinner).
  String? busyUid;

  /// Returns null on success, or a message to show HR on failure.
  Future<String?> deleteEmployee(AppUser e) async {
    busyUid = e.uid;
    notifyListeners();
    try {
      await _repo.deleteEmployee(e.uid);
      return null;
    } catch (err) {
      debugPrint('deleteEmployee failed: $err');
      return 'Could not remove ${e.fullName}: $err';
    } finally {
      busyUid = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
