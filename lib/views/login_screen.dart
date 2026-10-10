import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import 'signup_screen.dart';
import 'widgets/sereni_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authController = context.read<AuthController>();

    final success = await authController.login(
      email: _emailController.text.trim(),
      password: _passwordController.text, // never trim passwords
    );

    if (success) {
      final uid = authController.currentUserProfile?.userId;
      // No manual navigation – AuthGate reacts to the auth state automatically.
    }
    // On failure the message shows inside the panel (auth.errorMessage).
  }

  Future<void> _openSignUp() async {
    final auth = context.read<AuthController>();
    auth.clearError();
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
    auth.clearError();
  }

  Future<void> _forgotPassword() async {
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    final email = await showDialog<String>(
      context: context,
      builder: (_) =>
          _ForgotPasswordDialog(initialEmail: _emailController.text.trim()),
    );
    if (email == null) return;

    final error = await auth.sendPasswordReset(email);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ??
              'If an account exists for $email, a reset link is on its way.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return SereniShell(
      child: Column(
        children: [
          const SereniBrand(),
          const SizedBox(height: 20),
          SereniPanel(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log In',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: SereniColors.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (auth.errorMessage != null)
                    SereniAlert(auth.errorMessage!),
                  SereniTextField(
                    label: 'Email',
                    controller: _emailController,
                    hint: 'example@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 14),
                  SereniTextField(
                    label: 'Password',
                    controller: _passwordController,
                    hint: '••••••••••••',
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _handleLogin(),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your password' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: SereniColors.ink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        minimumSize: const Size(48, 36),
                      ),
                      child: Text(
                        'Forget Password',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SereniButton(
                    label: 'Log In',
                    loading: auth.isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: SereniColors.ink,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openSignUp,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: SereniColors.brand,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns its own controller so it is disposed safely with the dialog.
class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Reset password',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your email and we'll send you a link to set a new password.",
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 14),
            SereniTextField(
              label: 'Email',
              controller: _email,
              hint: 'example@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate())
              Navigator.pop(context, _email.text.trim());
          },
          child: const Text('Send link'),
        ),
      ],
    );
  }
}
