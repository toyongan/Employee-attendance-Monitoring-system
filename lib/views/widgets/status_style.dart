import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/attendance_record.dart';

class StatusStyle {
  final Color color;
  final IconData icon;
  final String label;
  const StatusStyle(this.color, this.icon, this.label);

  static StatusStyle of(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:
        return const StatusStyle(
          AppColors.present,
          Icons.check_circle_rounded,
          'Present',
        );
      case AttendanceStatus.absent:
        return const StatusStyle(
          AppColors.absent,
          Icons.cancel_rounded,
          'Absent',
        );
      case AttendanceStatus.notMarked:
        return const StatusStyle(
          AppColors.pending,
          Icons.schedule_rounded,
          'Not marked',
        );
      case AttendanceStatus.dayOff:
        return const StatusStyle(
          AppColors.dayOff,
          Icons.weekend_rounded,
          'Day off',
        );
    }
  }
}
