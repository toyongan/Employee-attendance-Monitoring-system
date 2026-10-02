/// Central place for work-schedule rules and Firestore names.
class AppConstants {
  // ---- Work schedule (edit to match your company) ----
  static const int workStartHour = 8; // 8:00 AM
  static const int workEndHour = 17; // 5:00 PM (after this, unscanned = Absent)
  static const List<int> workDays = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];

  // ---- Firestore ----
  static const String usersCollection = 'users';
  static const String attendanceCollection = 'attendance';

  // ---- QR ----
  /// Prefix so the scanner can reject random QR codes.
  static const String qrPrefix = 'ATTQR:';
}
