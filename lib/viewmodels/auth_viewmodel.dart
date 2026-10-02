import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repo) {
    _sub = _repo.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _repo;
  StreamSubscription<User?>? _sub;
  StreamSubscription<AppUser?>? _profileSub;

  bool initializing = true;
  bool loading = false;
  String? error;
  AppUser? user;

  Future<void> _onAuthChanged(User? fbUser) async {
    await _profileSub?.cancel();
    _profileSub = null;

    if (fbUser == null) {
      user = null;
    } else {
      try {
        user = await _repo.fetchProfile(fbUser.uid);
        if (user == null) {
          error = 'No profile found for this account. Contact HR.';
          await _repo.signOut();
        } else {
          // Keep `user` current so an HR-approved profile change (or a
          // photo update) shows up immediately, without needing to sign
          // back in.
          _profileSub = _repo.watchProfile(fbUser.uid).listen((updated) {
            if (updated != null) {
              user = updated;
              notifyListeners();
            }
          });
        }
      } catch (e) {
        debugPrint('Loading profile failed: $e');
        error = 'Could not load your profile. Check your connection.';
        await _repo.signOut();
      }
    }
    initializing = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      await _repo.signIn(email, password);
    } on FirebaseAuthException catch (e) {
      error = _friendly(e);
    } catch (e) {
      debugPrint('signIn failed: $e');
      error = 'Something went wrong. Please try again.';
    }
    loading = false;
    notifyListeners();
  }

  /// HR creating an employee's account. This never touches `user` or
  /// `initializing` — HR's own session is untouched because the account is
  /// created on a separate Firebase app instance (see
  /// AuthRepository.createEmployeeAsAdmin).
  Future<bool> addEmployeeAsAdmin({
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
    error = null;
    loading = true;
    notifyListeners();
    try {
      await _repo.createEmployeeAsAdmin(
        email: email,
        password: password,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        birthdate: birthdate,
        gender: gender,
        phone: phone,
        address: address,
        department: department,
        position: position,
        photoBase64: photoBase64,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('addEmployeeAsAdmin auth error: ${e.code} ${e.message}');
      error = _friendly(e);
      return false;
    } on FirebaseException catch (e) {
      // Firestore errors (e.g. permission-denied) land here.
      debugPrint(
          'addEmployeeAsAdmin firebase error: ${e.plugin}/${e.code} ${e.message}');
      error = e.code == 'permission-denied'
          ? 'Permission denied by Firestore rules. HR must be allowed to '
              'create user profiles.'
          : 'Could not create the employee account (${e.code}).';
      return false;
    } catch (e) {
      debugPrint('addEmployeeAsAdmin failed: $e');
      error = 'Could not create the employee account: $e';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => _repo.signOut();

  void clearError() {
    error = null;
    notifyListeners();
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Use a password with at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase Authentication.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
