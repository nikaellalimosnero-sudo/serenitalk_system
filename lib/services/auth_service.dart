import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  /// Returns null on success, or a user-friendly error message.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    }
  }

  /// Self-registration for patients AND doctors.
  /// firestore.rules guarantees a new account can only be 'patient' or 'doctor'.
  Future<String?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String contactNumber,
    required String role,
    String? specialty,
  }) async {
    if (role != UserRole.patient && role != UserRole.doctor) {
      return 'Choose whether you are a patient or a doctor.';
    }

    UserCredential? cred;
    try {
      cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;
      final isDoctor = role == UserRole.doctor;

      await _db.collection('users').doc(uid).set({
        'first_name': firstName,
        'middle_name': null,
        'last_name': lastName,
        'role': role,
        'email': email,
        'contact_number': contactNumber,
        'status': 'Active',
        'specialty': isDoctor ? specialty : null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    } on FirebaseException {
      // Login was created but the profile wasn't saved – remove the login so
      // the email isn't left stuck without a profile.
      await cred?.user?.delete();
      return 'We could not save your profile. Please try again.';
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      // Don't reveal whether an account exists for this email.
      if (e.code == 'user-not-found') return null;
      return _friendlyError(e);
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Stream<UserModel?> getUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.id, doc.data()!);
    });
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in.';
      case 'weak-password':
        return 'Choose a stronger password (8+ characters, letters and numbers).';
      default:
        debugPrint('Auth error: ${e.code} - ${e.message}');
        return 'Something went wrong (${e.code}). Please try again.';
    }
  }
}
