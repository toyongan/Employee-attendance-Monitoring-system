import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../models/app_user.dart';
import '../models/attendance_record.dart';

enum ScanOutcome { marked, alreadyMarked, invalidQr, unknownEmployee }

class ScanResult {
  final ScanOutcome outcome;
  final AppUser? employee;
  final DateTime? time;
  const ScanResult(this.outcome, {this.employee, this.time});
}

class AttendanceRepository {
  AttendanceRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static String dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  CollectionReference<Map<String, dynamic>> get _attendance =>
      _db.collection(AppConstants.attendanceCollection);

  /// Live record for today (null = not scanned yet).
  Stream<AttendanceRecord?> watchToday(String uid) {
    final id = '${uid}_${dateKey(DateTime.now())}';
    return _attendance
        .doc(id)
        .snapshots()
        .map((snap) => snap.exists ? AttendanceRecord.fromDoc(snap) : null);
  }

  /// All of one employee's records (sorted client-side, so no index needed).
  /// All of one employee's records (sorted client-side, so no index needed).
  Stream<List<AttendanceRecord>> watchHistory(String uid) {
    return _attendance.where('employeeId', isEqualTo: uid).snapshots().map(
          (snap) => snap.docs.map(AttendanceRecord.fromDoc).toList(),
        );
  }

  /// Everyone marked present on one calendar day (HR "scanned today" list).
  Stream<List<AttendanceRecord>> watchByDate(String dateKey) {
    return _attendance.where('dateKey', isEqualTo: dateKey).snapshots().map(
      (snap) {
        final list = snap.docs.map(AttendanceRecord.fromDoc).toList();
        list.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
        return list;
      },
    );
  }

  /// All records between two dateKeys, inclusive (used to build reports).
  /// A single-field range query, so it needs no composite index.
  Future<List<AttendanceRecord>> fetchRange(
    String startKey,
    String endKey,
  ) async {
    final snap = await _attendance
        .where('dateKey', isGreaterThanOrEqualTo: startKey)
        .where('dateKey', isLessThanOrEqualTo: endKey)
        .get();
    return snap.docs.map(AttendanceRecord.fromDoc).toList();
  }

  /// HR scans an employee QR -> marks that employee present for today.
  Future<ScanResult> markPresentFromQr(String? raw, AppUser hr) async {
    if (raw == null || !raw.startsWith(AppConstants.qrPrefix)) {
      return const ScanResult(ScanOutcome.invalidQr);
    }
    final token = raw.substring(AppConstants.qrPrefix.length);
    if (token.length < 16) return const ScanResult(ScanOutcome.invalidQr);

    final match = await _db
        .collection(AppConstants.usersCollection)
        .where('qrToken', isEqualTo: token)
        .limit(1)
        .get();
    if (match.docs.isEmpty) {
      return const ScanResult(ScanOutcome.unknownEmployee);
    }

    final employee = AppUser.fromDoc(match.docs.first);
    if (employee.isHr) return const ScanResult(ScanOutcome.invalidQr);

    final now = DateTime.now();
    final key = dateKey(now);
    final ref = _attendance.doc('${employee.uid}_$key');

    return _db.runTransaction<ScanResult>((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) {
        final rec = AttendanceRecord.fromDoc(existing);
        return ScanResult(
          ScanOutcome.alreadyMarked,
          employee: employee,
          time: rec.scannedAt,
        );
      }
      tx.set(ref, {
        'employeeId': employee.uid,
        'employeeName': employee.fullName,
        'dateKey': key,
        'scannedAt': FieldValue.serverTimestamp(),
        'scannedBy': hr.uid,
      });
      return ScanResult(ScanOutcome.marked, employee: employee, time: now);
    });
  }
}
