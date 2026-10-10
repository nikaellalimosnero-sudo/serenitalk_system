import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/doctor_controller.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_edit_profile_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  static const _bg = Color(0xFFE3ECF7);
  static const _panel = Color(0xFFBCD4EE);
  static const _accent = Color(0xFF1F5FA8);

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  late final DoctorController _doctorController;

  @override
  void initState() {
    super.initState();
    _doctorController = context.read<DoctorController>();
    final doctorId = context.read<AuthController>().currentUserProfile?.userId;
    if (doctorId != null) _doctorController.load(doctorId);
  }

  @override
  void dispose() {
    _doctorController.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final doctor = auth.currentUserProfile;
    final appointments = context.watch<DoctorController>();
    if (doctor == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: DoctorHomeScreen._bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                SvgPicture.asset('assets/images/logo.svg', width: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Doctor',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: DoctorHomeScreen._accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: auth.logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DoctorHomeScreen._accent,
                    side: const BorderSide(
                      color: DoctorHomeScreen._accent,
                      width: 2,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Log out'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: DoctorHomeScreen._panel,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${doctor.firstName}',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialty ?? '',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DoctorEditProfileScreen(),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: DoctorHomeScreen._accent,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(
                'Edit profile (what patients see)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: '${appointments.pendingRequests.length}',
                    label: 'Pending requests',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    value: '${appointments.todaysSessionsCount}',
                    label: "Today's sessions",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Appointment requests',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DoctorAppointmentsScreen(),
                    ),
                  ),
                  child: const Text('See all'),
                ),
              ],
            ),
            if (appointments.appointmentsError != null)
              _MessageCard(
                message: appointments.appointmentsError!,
                icon: Icons.error_outline,
              )
            else if (appointments.isLoading)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (appointments.pendingPreview.isEmpty)
              const _MessageCard(
                message: 'New appointment requests will appear here.',
                icon: Icons.event_available_outlined,
              )
            else
              ...appointments.pendingPreview.map(
                (appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DoctorAppointmentCard(
                    appointment: appointment,
                    showActions: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: DoctorHomeScreen._accent,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const _MessageCard({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: DoctorHomeScreen._accent),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
