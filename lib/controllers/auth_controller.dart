import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUserProfile;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<dynamic>? _authSubscription;
  StreamSubscription<UserModel?>? _profileSubscription;

  UserModel? get currentUserProfile => _currentUserProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _authService.currentUser != null;
  bool get isDoctor => _currentUserProfile?.isDoctor ?? false;
  bool get isPatient => _currentUserProfile?.isPatient ?? false;

  AuthController() {
    _authSubscription = _authService.authStateChanges.listen((
      firebaseUser,
    ) async {
      await _profileSubscription?.cancel();
      if (firebaseUser == null) {
        _currentUserProfile = null;
      } else {
        _profileSubscription = _authService
            .getUserData(firebaseUser.uid)
            .listen(
              (profile) async {
                if (profile != null && !profile.isActive) {
                  _errorMessage =
                      'This account has been deactivated. Contact support.';
                  await _authService.signOut();
                  return;
                }
                _currentUserProfile = profile;
                notifyListeners();
              },
              onError: (Object error) {
                _errorMessage =
                    'Failed to load your profile. Please try again.';
                notifyListeners();
              },
            );
      }
      notifyListeners();
    });
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final error = await _authService.signIn(email: email, password: password);

    if (error != null) {
      _errorMessage = error;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      final profile = await _authService.getUserData(uid).first;

      if (profile == null || !profile.isActive) {
        await _authService.signOut();
        _currentUserProfile = null;
        _errorMessage = profile == null
            ? 'We could not find your profile. Contact support.'
            : 'This account has been deactivated. Contact support.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _currentUserProfile = profile;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Patients and doctors sign themselves up. On success the user is already
  /// signed in, and AuthGate sends them to the right home screen.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String contactNumber,
    required String role, // 'doctor' or 'patient'
    String? specialty,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final error = await _authService.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      contactNumber: contactNumber,
      role: role,
      specialty: specialty,
    );

    _isLoading = false;
    _errorMessage = error;
    notifyListeners();
    return error == null;
  }

  /// Returns null on success, or an error message.
  Future<String?> sendPasswordReset(String email) =>
      _authService.sendPasswordReset(email);

  Future<void> logout() async {
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      try {} catch (e) {
        // Offline or token clear failed — don't block logout because of it.
      }
    }
    await _authService.signOut();
    _currentUserProfile = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
