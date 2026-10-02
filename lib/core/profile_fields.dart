import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Human-readable labels and value formatting for the editable AppUser
/// fields, shared between the employee's edit form and HR's request review.
class ProfileFields {
  ProfileFields._();

  static const List<String> editableKeys = [
    'firstName',
    'middleName',
    'lastName',
    'birthdate',
    'gender',
    'phone',
    'address',
    'department',
    'position',
    'photoBase64',
  ];

  static String label(String key) {
    switch (key) {
      case 'firstName':
        return 'First name';
      case 'middleName':
        return 'Middle name';
      case 'lastName':
        return 'Last name';
      case 'birthdate':
        return 'Birthdate';
      case 'gender':
        return 'Gender';
      case 'phone':
        return 'Phone';
      case 'address':
        return 'Address';
      case 'department':
        return 'Department';
      case 'position':
        return 'Position';
      case 'photoBase64':
        return 'Profile photo';
      default:
        return key;
    }
  }

  /// Formats a raw field value for display. Returns null for the photo
  /// field — callers should render that one as an image, not text.
  static String? displayValue(String key, dynamic value) {
    if (key == 'photoBase64') return null;
    if (value == null) return '—';
    if (value is Timestamp) {
      return DateFormat('MMMM d, y').format(value.toDate());
    }
    if (value is DateTime) {
      return DateFormat('MMMM d, y').format(value);
    }
    final s = value.toString().trim();
    return s.isEmpty ? '—' : s;
  }
}
