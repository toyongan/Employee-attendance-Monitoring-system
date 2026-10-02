import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/profile_update_request.dart';
import '../repositories/profile_request_repository.dart';

/// Drives the employee's "Edit profile" screen: submitting a change
/// request, watching its status, and surfacing resolved-but-unseen ones as
/// notifications.
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._repo, this.user) {
    _sub = _repo.watchMyRequests(user.uid).listen((list) {
      requests = list;
      final pendingOnes =
          list.where((r) => r.status == RequestStatus.pending).toList();
      pending = pendingOnes.isEmpty ? null : pendingOnes.first;
      unseenResolved = list
          .where((r) => r.status != RequestStatus.pending && !r.seenByEmployee)
          .toList();
      loaded = true;
      notifyListeners();
    });
  }

  final ProfileRequestRepository _repo;
  final AppUser user;
  StreamSubscription<List<ProfileUpdateRequest>>? _sub;

  bool loaded = false;
  List<ProfileUpdateRequest> requests = [];
  ProfileUpdateRequest? pending;
  List<ProfileUpdateRequest> unseenResolved = [];

  bool submitting = false;
  String? error;

  /// Total badge count shown on the employee's tab: a pending request
  /// counts as "1 to keep an eye on", plus any resolved-but-undismissed
  /// ones.
  int get notificationCount =>
      unseenResolved.length + (pending != null ? 1 : 0);

  Future<bool> submit(Map<String, dynamic> changes) async {
    if (changes.isEmpty) {
      error = 'Change at least one field before submitting.';
      notifyListeners();
      return false;
    }
    submitting = true;
    error = null;
    notifyListeners();
    try {
      await _repo.submitRequest(
        employeeId: user.uid,
        employeeName: user.fullName,
        changes: changes,
      );
      return true;
    } catch (_) {
      error = 'Could not submit your request. Check your connection.';
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<void> cancelPending() async {
    final p = pending;
    if (p != null) await _repo.cancel(p.id);
  }

  Future<void> dismiss(String requestId) => _repo.markSeen(requestId);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
