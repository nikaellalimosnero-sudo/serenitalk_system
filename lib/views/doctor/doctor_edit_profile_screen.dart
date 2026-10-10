import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../widgets/editable_avatar.dart';
import '../widgets/sereni_widgets.dart';

/// Doctors fill in what patients see on the Doctor Info page.
class DoctorEditProfileScreen extends StatefulWidget {
  const DoctorEditProfileScreen({super.key});

  @override
  State<DoctorEditProfileScreen> createState() =>
      _DoctorEditProfileScreenState();
}

class _DoctorEditProfileScreenState extends State<DoctorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _specialty;
  late final TextEditingController _fee;
  late final TextEditingController _days;
  late final TextEditingController _hours;
  late final TextEditingController _bio;
  late final TextEditingController _career;
  late final TextEditingController _highlights;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthController>().currentUserProfile!;
    _specialty = TextEditingController(text: me.specialty ?? '');
    _fee = TextEditingController(
      text: me.fee == null
          ? ''
          : (me.fee! % 1 == 0 ? '${me.fee!.toInt()}' : '${me.fee}'),
    );
    _days = TextEditingController(text: me.availabilityDays ?? '');
    _hours = TextEditingController(text: me.availabilityHours ?? '');
    _bio = TextEditingController(text: me.bio ?? '');
    _career = TextEditingController(text: me.careerPath ?? '');
    _highlights = TextEditingController(text: me.highlights ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _specialty,
      _fee,
      _days,
      _hours,
      _bio,
      _career,
      _highlights,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _nullIfEmpty(TextEditingController c) {
    final s = c.text.trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final uid = context.read<AuthController>().currentUserProfile!.userId;
    final users = context.read<UserController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await users.saveDoctorProfile(uid, {
      'specialty': _specialty.text.trim(),
      'fee': double.tryParse(_fee.text.trim()),
      'availability_days': _nullIfEmpty(_days),
      'availability_hours': _nullIfEmpty(_hours),
      'bio': _nullIfEmpty(_bio),
      'career_path': _nullIfEmpty(_career),
      'highlights': _nullIfEmpty(_highlights),
    });

    if (!mounted) return;
    if (error == null) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().currentUserProfile;
    if (me == null) return const SizedBox.shrink();

    return SereniShell(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: SereniColors.brand,
                ),
              ),
              Expanded(
                child: Text(
                  'Edit profile',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: SereniColors.brand,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 10),
          EditableAvatar(user: me, size: 104),
          const SizedBox(height: 6),
          Text(
            'Tap to change your photo (saves right away)',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: SereniColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          SereniPanel(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) SereniAlert(_error!),
                  SereniTextField(
                    label: 'Specialty',
                    controller: _specialty,
                    hint: 'e.g. Psychiatrist',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        Validators.required(v, 'Enter your specialty'),
                  ),
                  const SizedBox(height: 14),
                  SereniTextField(
                    label: 'Fee (Php)',
                    controller: _fee,
                    hint: '500',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return null;
                      final n = double.tryParse(s);
                      return (n == null || n < 0)
                          ? 'Enter a valid amount'
                          : null;
                    },
                  ),
                  const SizedBox(height: 14),
                  SereniTextField(
                    label: 'Available days',
                    controller: _days,
                    hint: 'e.g. Mon-Sat',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  SereniTextField(
                    label: 'Available hours',
                    controller: _hours,
                    hint: 'e.g. 10:30 AM - 3:30 PM',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  SereniTextField(
                    label: 'Profile',
                    controller: _bio,
                    hint: 'Tell patients about yourself',
                    keyboardType: TextInputType.multiline,
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 14),
                  SereniTextField(
                    label: 'Career path',
                    controller: _career,
                    hint: 'Education and experience',
                    keyboardType: TextInputType.multiline,
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 14),
                  SereniTextField(
                    label: 'Highlights',
                    controller: _highlights,
                    hint: 'Awards, focus areas, achievements',
                    keyboardType: TextInputType.multiline,
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 22),
                  SereniButton(
                    label: 'Save',
                    loading: _saving,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
