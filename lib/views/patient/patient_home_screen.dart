import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/appointment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/user_model.dart';
import '../widgets/sereni_nav_bar.dart';
import '../widgets/sereni_widgets.dart';
import '../doctor/doctor_info_screen.dart';
import '../doctor/doctor_list_tab.dart';
import 'community_tab.dart';
import 'patient_appointments_tab.dart';
import 'patient_profile_tab.dart';

/// The patient's app: four tabs behind the blue navigation pill.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _index = 0;
  late final AppointmentController _appointments;
  late final CommunityController _community;

  @override
  void initState() {
    super.initState();
    _appointments = context.read<AppointmentController>();
    _community = context.read<CommunityController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserController>().loadDoctors();
      // Start watching the patient's bookings as soon as they're signed in,
      // so the Appointments tab is already up to date.
      final me = context.read<AuthController>().currentUserProfile;
      if (me != null) {
        _appointments.loadMyAppointments(me.userId);
        _community.load(me.userId);
      }
    });
  }

  @override
  void dispose() {
    // This screen only goes away on logout: clear the bookings so the next
    // account never sees them. Deferred so listeners aren't notified mid-teardown.
    Future.microtask(_appointments.reset);
    Future.microtask(_community.reset);
    super.dispose();
  }

  void _selectTab(int i) {
    if (mounted) setState(() => _index = i);
  }

  void _openDoctor(UserModel doctor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorInfoScreen(
          doctor: doctor,
          // The info page shows the same nav bar; tapping it returns here on that tab.
          onNavSelected: _selectTab,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SereniColors.page,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            DoctorListTab(onDoctorTap: _openDoctor),
            const CommunityTab(),
            const PatientProfileTab(),
            PatientAppointmentsTab(onNavSelected: _selectTab),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SereniNavBar(currentIndex: _index, onTap: _selectTab),
      ),
    );
  }
}
