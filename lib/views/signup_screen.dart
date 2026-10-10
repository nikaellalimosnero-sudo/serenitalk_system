import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import 'widgets/sereni_widgets.dart';

/// Patients and doctors create their own account here.
/// Doctors are also asked for their specialty.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _specialty = TextEditingController();
  String _role = UserRole.patient;

  bool get _isDoctor => _role == UserRole.doctor;

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _contact,
      _email,
      _password,
      _specialty,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);

    final ok = await auth.register(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      contactNumber: _contact.text.trim(),
      role: _role,
      specialty: _isDoctor ? _specialty.text.trim() : null,
    );

    // Registered users are already signed in – close this screen and let
    // AuthGate show the doctor or patient home.
    if (ok) navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return SereniShell(
      child: Column(
        children: [
          const SereniBrand(compact: true),
          const SizedBox(height: 16),
          SereniPanel(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create account',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: SereniColors.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (auth.errorMessage != null)
                    SereniAlert(auth.errorMessage!),
                  _RoleSwitch(
                    value: _role,
                    onChanged: (r) => setState(() => _role = r),
                  ),
                  const SizedBox(height: 14),
                  SereniTextField(
                    label: 'First name',
                    controller: _firstName,
                    hint: 'Your first name',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.givenName],
                    validator: (v) =>
                        Validators.required(v, 'Enter your first name'),
                  ),
                  const SizedBox(height: 14),
                  SereniTextField(
                    label: 'Last name',
                    controller: _lastName,
                    hint: 'Your last name',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.familyName],
                    validator: (v) =>
                        Validators.required(v, 'Enter your last name'),
                  ),
                  const SizedBox(height: 14),
                  SereniTextField(
                    label: 'Contact number',
                    controller: _contact,
                    hint: '09XX XXX XXXX',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: (v) => Validators.required(
                      v,
                      'Enter your contact number',
                      min: 7,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SereniTextField(
                    label: 'Email',
                    controller: _email,
                    hint: 'example@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  if (_isDoctor) ...[
                    const SizedBox(height: 14),
                    SereniTextField(
                      label: 'Specialty',
                      controller: _specialty,
                      hint: 'e.g. Psychiatry',
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          Validators.required(v, 'Enter your specialty'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SereniTextField(
                    label: 'Password',
                    controller: _password,
                    hint: 'At least 8 characters',
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => _submit(),
                    validator: Validators.newPassword,
                  ),
                  const SizedBox(height: 22),
                  SereniButton(
                    label: 'Sign Up',
                    loading: auth.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: SereniColors.ink,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Log In',
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

class _RoleSwitch extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RoleSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget option(String role, String label) {
      final selected = value == role;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: 'I am a $label',
          child: GestureDetector(
            onTap: () => onChanged(role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: selected ? SereniColors.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : SereniColors.muted,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'I am a',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: SereniColors.ink,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: SereniColors.field,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              option(UserRole.patient, 'Patient'),
              option(UserRole.doctor, 'Doctor'),
            ],
          ),
        ),
      ],
    );
  }
}
