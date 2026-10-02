import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { employee, hr }

class AppUser {
  final String uid;
  final String email;
  final UserRole role;
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime birthdate;
  final String gender;
  final String phone;
  final String address;
  final String department;
  final String position;

  /// Small (compressed) profile photo, stored as Base64 so no separate
  /// Firebase Storage bucket is needed. Null/empty until one is added.
  final String? photoBase64;

  /// Random secret that is encoded in this employee's QR code.
  final String qrToken;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.birthdate,
    required this.gender,
    required this.phone,
    required this.address,
    required this.department,
    required this.position,
    this.photoBase64,
    required this.qrToken,
    required this.createdAt,
  });

  String get fullName {
    final mid = (middleName == null || middleName!.trim().isEmpty)
        ? ''
        : ' ${middleName!.trim()}';
    return '$firstName$mid $lastName';
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return ('$f$l').toUpperCase();
  }

  bool get hasPhoto => photoBase64 != null && photoBase64!.isNotEmpty;

  bool get isHr => role == UserRole.hr;

  Map<String, dynamic> toMap() => {
        'email': email,
        'role': role.name,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'birthdate': Timestamp.fromDate(birthdate),
        'gender': gender,
        'phone': phone,
        'address': address,
        'department': department,
        'position': position,
        'photoBase64': photoBase64,
        'qrToken': qrToken,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AppUser(
      uid: doc.id,
      email: d['email'] ?? '',
      role: d['role'] == 'hr' ? UserRole.hr : UserRole.employee,
      firstName: d['firstName'] ?? '',
      middleName: d['middleName'],
      lastName: d['lastName'] ?? '',
      birthdate: (d['birthdate'] as Timestamp?)?.toDate() ?? DateTime(2000),
      gender: d['gender'] ?? '',
      phone: d['phone'] ?? '',
      address: d['address'] ?? '',
      department: d['department'] ?? '',
      position: d['position'] ?? '',
      photoBase64: d['photoBase64'],
      qrToken: d['qrToken'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
