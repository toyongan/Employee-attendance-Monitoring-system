import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, approved, rejected }

/// An employee's proposed changes to their own profile. Nothing on the
/// live `users/{uid}` document changes until HR approves this.
class ProfileUpdateRequest {
  final String id;
  final String employeeId;
  final String employeeName;

  /// Field name -> proposed new value (raw Firestore-friendly values:
  /// String, Timestamp for birthdate, or a Base64 String for a new photo).
  final Map<String, dynamic> changes;

  final RequestStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;

  /// False right after HR approves/rejects; the employee "reads" it by
  /// dismissing the notification, which flips this back to true.
  final bool seenByEmployee;

  const ProfileUpdateRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.changes,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    required this.seenByEmployee,
  });

  factory ProfileUpdateRequest.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return ProfileUpdateRequest(
      id: doc.id,
      employeeId: d['employeeId'] ?? '',
      employeeName: d['employeeName'] ?? '',
      changes: Map<String, dynamic>.from(d['changes'] ?? {}),
      status: _statusFrom(d['status']),
      requestedAt: (d['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (d['reviewedAt'] as Timestamp?)?.toDate(),
      seenByEmployee: d['seenByEmployee'] ?? true,
    );
  }

  static RequestStatus _statusFrom(String? s) {
    switch (s) {
      case 'approved':
        return RequestStatus.approved;
      case 'rejected':
        return RequestStatus.rejected;
      default:
        return RequestStatus.pending;
    }
  }
}
