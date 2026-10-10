import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import 'login_screen.dart';
import 'doctor/doctor_home_screen.dart';
import 'patient/patient_home_screen.dart';

/// Decides what the user sees. Nothing navigates manually after login – this
/// widget rebuilds whenever AuthController changes.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        // Keep showing the login screen (with its button spinner) while a login
        // is still being checked, so a deactivated account never flashes a home screen.
        if (!auth.isLoggedIn || auth.isLoading) return const LoginScreen();

        if (auth.currentUserProfile == null) {
          if (auth.errorMessage != null) {
            return _ProfileError(
              message: auth.errorMessage!,
              onLogout: auth.logout,
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.isDoctor) return const DoctorHomeScreen();
        if (auth.isPatient) return const PatientHomeScreen();

        return _ProfileError(
          message: 'Your account has no valid role. Contact support.',
          onLogout: auth.logout,
        );
      },
    );
  }
}

class _ProfileError extends StatelessWidget {
  final String message;
  final Future<void> Function() onLogout;
  const _ProfileError({required this.message, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onLogout, child: const Text('Log out')),
            ],
          ),
        ),
      ),
    );
  }
}
