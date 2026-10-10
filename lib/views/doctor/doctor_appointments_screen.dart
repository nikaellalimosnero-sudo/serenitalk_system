import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/doctor_controller.dart';
import '../../models/appointment_model.dart';
import '../widgets/appointment_widgets.dart';

const _doctorAccent = Color(0xFF1F5FA8);

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctor = context.watch<DoctorController>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFE3ECF7),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE3ECF7),
          title: Text(
            'Appointments',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: doctor.appointmentsError != null
            ? _EmptyState(
                message: doctor.appointmentsError!,
                icon: Icons.error_outline,
              )
            : doctor.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _AppointmentList(
                    appointments: doctor.pendingRequests,
                    emptyMessage: 'There are no pending requests.',
                    showActions: true,
                  ),
                  _AppointmentList(
                    appointments: doctor.upcoming,
                    emptyMessage:
                        'You have no confirmed upcoming appointments.',
                  ),
                  _AppointmentList(
                    appointments: doctor.past,
                    emptyMessage: 'Your past appointments will appear here.',
                  ),
                ],
              ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final String emptyMessage;
  final bool showActions;

  const _AppointmentList({
    required this.appointments,
    required this.emptyMessage,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return _EmptyState(
        message: emptyMessage,
        icon: Icons.event_available_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => DoctorAppointmentCard(
        appointment: appointments[index],
        showActions: showActions,
      ),
    );
  }
}

class DoctorAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool showActions;

  const DoctorAppointmentCard({
    super.key,
    required this.appointment,
    this.showActions = false,
  });

  Future<void> _respond(BuildContext context, {required bool accept}) async {
    final controller = context.read<DoctorController>();
    final messenger = ScaffoldMessenger.of(context);

    if (!accept) {
      final shouldDecline = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Decline this appointment?'),
          content: const Text(
            "This will update the patient's appointment status and release the time slot.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep request'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Decline'),
            ),
          ],
        ),
      );
      if (!context.mounted || shouldDecline != true) return;
    }

    final error = accept
        ? await controller.acceptAppointment(appointment)
        : await controller.declineAppointment(appointment);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (accept
                  ? 'Appointment accepted.'
                  : 'Appointment declined. The slot is available again.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DoctorController>();
    final busy = controller.isBusy(appointment.id);
    final canRespond =
        showActions &&
        appointment.status == AppointmentStatus.pending &&
        appointment.endTime.isAfter(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  appointment.patientFullName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusChip(appointment.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${appointment.bookedForSelf ? 'Self' : 'Booked for another person'}'
            ' · ${appointment.patientAge} · ${appointment.patientGender}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: _doctorAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${Fmt.fullDate(appointment.startTime)} · ${Fmt.time(appointment.startTime)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _doctorAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Concern',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 3),
          Text(appointment.concern, style: GoogleFonts.poppins(fontSize: 13)),
          if (appointment.status == AppointmentStatus.pending &&
              !appointment.endTime.isAfter(DateTime.now())) ...[
            const SizedBox(height: 8),
            Text(
              'This request has expired.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (canRespond) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => _respond(context, accept: false),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: busy
                        ? null
                        : () => _respond(context, accept: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _doctorAccent,
                    ),
                    child: busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: _doctorAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
