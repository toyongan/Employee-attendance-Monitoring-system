import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/profile_update_request.dart';
import '../repositories/profile_request_repository.dart';

/// Drives HR's "Requests" queue: every profile change awaiting a decision.
class HrRequestsViewModel extends ChangeNotifier {
  HrRequestsViewModel(this._repo) {
    _sub = _repo.watchPending().listen(
      (list) {
        pending = list;
        loaded = true;
        loadError = null;
        notifyListeners();
      },
      onError: (Object e) {
        // Without this, a Firestore error (e.g. permission-denied) is
        // swallowed and the tab just sits on a spinner or looks empty.
        debugPrint('watchPending failed: $e');
        loadError = 'Could not load requests: $e';
        loaded = true;
        notifyListeners();
      },
    );
  }

  final ProfileRequestRepository _repo;
  StreamSubscription<List<ProfileUpdateRequest>>? _sub;

  bool loaded = false;
  String? loadError;
  List<ProfileUpdateRequest> pending = [];
  String? busyRequestId;

  /// Each returns null on success, or a message to show HR on failure.
  Future<String?> approve(ProfileUpdateRequest r) =>
      _run(r, () => _repo.approve(r));

  Future<String?> reject(ProfileUpdateRequest r) =>
      _run(r, () => _repo.reject(r));

  Future<String?> _run(
      ProfileUpdateRequest r, Future<void> Function() action) async {
    busyRequestId = r.id;
    notifyListeners();
    try {
      await action();
      return null;
    } catch (e) {
      debugPrint('Request action failed: $e');
      return 'Could not update the request: $e';
    } finally {
      busyRequestId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
