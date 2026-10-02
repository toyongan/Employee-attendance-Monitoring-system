import '../models/attendance_record.dart';
import 'constants.dart';

/// Pure functions that decide an employee's status for a given day.
class AttendanceRules {
  static bool isWorkday(DateTime d) =>
      AppConstants.workDays.contains(d.weekday);

  static DateTime workEndOf(DateTime d) =>
      DateTime(d.year, d.month, d.day, AppConstants.workEndHour);

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// [record] is the attendance doc for [day] (null if HR never scanned).
  static AttendanceStatus statusFor({
    required DateTime day,
    required AttendanceRecord? record,
    required DateTime now,
  }) {
    if (record != null) return AttendanceStatus.present;
    if (!isWorkday(day)) return AttendanceStatus.dayOff;

    final d = dateOnly(day);
    final today = dateOnly(now);
    if (d.isBefore(today)) return AttendanceStatus.absent;
    if (d.isAfter(today)) return AttendanceStatus.notMarked;
    // today
    return now.isAfter(workEndOf(day))
        ? AttendanceStatus.absent
        : AttendanceStatus.notMarked;
  }
}
