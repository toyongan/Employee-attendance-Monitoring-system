import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/constants.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> fetchProfile(String uid) async {
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  /// Live version of [fetchProfile], so an HR-approved change (or a new
  /// photo) reaches an already-signed-in employee without a re-login.
  Stream<AppUser?> watchProfile(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);
  }

  /// Creates the Firebase Auth account AND the employee profile with its
  /// unique, auto-generated QR token. New accounts are always employees;
  /// HR accounts are provisioned manually (see README).
  Future<AppUser> registerEmployee({
    required String email,
    required String password,
    required String firstName,
    String? middleName,
    required String lastName,
    required DateTime birthdate,
    required String gender,
    required String phone,
    required String address,
    required String department,
    required String position,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    final user = AppUser(
      uid: uid,
      email: email.trim(),
      role: UserRole.employee,
      firstName: firstName.trim(),
      middleName: (middleName == null || middleName.trim().isEmpty)
          ? null
          : middleName.trim(),
      lastName: lastName.trim(),
      birthdate: birthdate,
      gender: gender,
      phone: phone.trim(),
      address: address.trim(),
      department: department.trim(),
      position: position.trim(),
      qrToken: _generateToken(),
      createdAt: DateTime.now(),
    );

    try {
      await _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(user.toMap());
    } catch (e) {
      // Don't leave an auth account with no profile behind.
      await cred.user!.delete();
      rethrow;
    }
    return (await fetchProfile(uid))!;
  }

  /// HR creates an employee's account on their behalf. `createUserWith-
  /// EmailAndPassword` normally signs in as the new user immediately, which
  /// would kick HR out of their own session — so this runs on a second,
  /// temporary Firebase app instance instead. HR's own sign-in (on the
  /// default app/`_auth`) is never touched, and the profile document is
  /// still written through the normal, HR-authenticated Firestore client.
  Future<AppUser> createEmployeeAsAdmin({
    required String email,
    required String password,
    required String firstName,
    String? middleName,
    required String lastName,
    required DateTime birthdate,
    required String gender,
    required String phone,
    required String address,
    required String department,
    required String position,
    String? photoBase64,
  }) async {
    FirebaseApp secondaryApp;
    try {
      secondaryApp = Firebase.app('AddEmployee');
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: 'AddEmployee',
        options: Firebase.app().options,
      );
    }
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    final cred = await secondaryAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    final user = AppUser(
      uid: uid,
      email: email.trim(),
      role: UserRole.employee,
      firstName: firstName.trim(),
      middleName: (middleName == null || middleName.trim().isEmpty)
          ? null
          : middleName.trim(),
      lastName: lastName.trim(),
      birthdate: birthdate,
      gender: gender,
      phone: phone.trim(),
      address: address.trim(),
      department: department.trim(),
      position: position.trim(),
      photoBase64: photoBase64,
      qrToken: _generateToken(),
      createdAt: DateTime.now(),
    );

    try {
      // Written through the PRIMARY Firestore client — authenticated as
      // HR, which is what the security rules expect for an admin-created
      // profile.
      await _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(user.toMap());
    } catch (e) {
      // Don't leave an auth account with no profile behind.
      await cred.user!.delete();
      rethrow;
    } finally {
      // Drop the temporary session; HR's own sign-in is unaffected.
      await secondaryAuth.signOut();
    }

    return (await fetchProfile(uid))!;
  }

  /// 192 bits of randomness -> unguessable, unique per employee.
  String _generateToken() {
    final rnd = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    return List.generate(32, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
