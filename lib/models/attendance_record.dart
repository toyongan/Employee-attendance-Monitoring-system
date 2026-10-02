import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, notMarked, dayOff }

class AttendanceRecord {
  final String id; // "<employeeUid>_<yyyy-MM-dd>"
  final String employeeId;
  final String employeeName;
  final String dateKey;
  final DateTime scannedAt;
  final String scannedBy;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.dateKey,
    required this.scannedAt,
    required this.scannedBy,
  });

  factory AttendanceRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AttendanceRecord(
      id: doc.id,
      employeeId: d['employeeId'] ?? '',
      employeeName: d['employeeName'] ?? '',
      dateKey: d['dateKey'] ?? '',
      // serverTimestamp is null on the local device until the write is confirmed.
      scannedAt: (d['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scannedBy: d['scannedBy'] ?? '',
    );
  }
}
