import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/app_user.dart';

/// Lookups over the employee roster, plus HR's "remove employee" action.
class EmployeeRepository {
  EmployeeRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<List<AppUser>> fetchAllEmployees() async {
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'employee')
        .get();
    final list = snap.docs.map(AppUser.fromDoc).toList();
    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    return list;
  }

  /// Live roster for HR's "Employees" tab, so a newly-added employee shows
  /// up immediately without a manual refresh.
  Stream<List<AppUser>> watchAllEmployees() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'employee')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AppUser.fromDoc).toList();
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
      return list;
    });
  }

  /// Removes an employee's Firestore data: their attendance records, their
  /// profile-change requests, and finally the profile itself.
  ///
  /// This does NOT delete the Firebase Authentication login — a client app
  /// can't delete another user's Auth account. Delete that in the Firebase
  /// console (Authentication → Users), otherwise the email stays taken.
  ///
  /// The profile is deleted last, so if anything fails part-way the employee
  /// still shows in the roster and HR can simply retry.
  Future<void> deleteEmployee(String uid) async {
    final attendance = await _db
        .collection(AppConstants.attendanceCollection)
        .where('employeeId', isEqualTo: uid)
        .get();
    final requests = await _db
        .collection('profileUpdateRequests')
        .where('employeeId', isEqualTo: uid)
        .get();

    final refs = [
      ...attendance.docs.map((d) => d.reference),
      ...requests.docs.map((d) => d.reference),
    ];

    // A batch holds at most 500 writes, so delete in chunks.
    for (var i = 0; i < refs.length; i += 400) {
      final batch = _db.batch();
      for (final ref in refs.skip(i).take(400)) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    await _db.collection(AppConstants.usersCollection).doc(uid).delete();
  }
}
