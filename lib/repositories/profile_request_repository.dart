import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/profile_update_request.dart';

/// All Firestore access for the employee-edits-require-HR-approval flow.
class ProfileRequestRepository {
  ProfileRequestRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('profileUpdateRequests');

  /// Employee submits proposed changes. Nothing on their profile changes
  /// until HR approves it.
  Future<void> submitRequest({
    required String employeeId,
    required String employeeName,
    required Map<String, dynamic> changes,
  }) async {
    await _col.add({
      'employeeId': employeeId,
      'employeeName': employeeName,
      'changes': changes,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'seenByEmployee': true,
    });
  }

  /// One employee's own requests (pending + resolved), newest first.
  Stream<List<ProfileUpdateRequest>> watchMyRequests(String employeeId) {
    return _col.where('employeeId', isEqualTo: employeeId).snapshots().map(
      (snap) {
        final list = snap.docs.map(ProfileUpdateRequest.fromDoc).toList();
        list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
        return list;
      },
    );
  }

  /// HR's review queue: every request still awaiting a decision.
  Stream<List<ProfileUpdateRequest>> watchPending() {
    return _col.where('status', isEqualTo: 'pending').snapshots().map(
      (snap) {
        final list = snap.docs.map(ProfileUpdateRequest.fromDoc).toList();
        list.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
        return list;
      },
    );
  }

  /// Applies the requested changes to the employee's profile and marks the
  /// request approved, in one atomic write.
  Future<void> approve(ProfileUpdateRequest request) async {
    final batch = _db.batch();
    final userRef =
        _db.collection(AppConstants.usersCollection).doc(request.employeeId);
    batch.update(userRef, request.changes);
    batch.update(_col.doc(request.id), {
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'seenByEmployee': false,
    });
    await batch.commit();
  }

  Future<void> reject(ProfileUpdateRequest request) async {
    await _col.doc(request.id).update({
      'status': 'rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
      'seenByEmployee': false,
    });
  }

  /// Employee dismisses a resolved request's notification.
  Future<void> markSeen(String requestId) async {
    await _col.doc(requestId).update({'seenByEmployee': true});
  }

  /// Employee withdraws their own request while it's still pending.
  Future<void> cancel(String requestId) async {
    await _col.doc(requestId).delete();
  }
}
