import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/appointment_controller.dart';
import '../../models/appointment_model.dart';
import '../widgets/appointment_widgets.dart';
import '../widgets/sereni_nav_bar.dart';
import '../widgets/sereni_widgets.dart';

/// "Your Appointment": schedule, patient information and the problem described.
/// Shown right after booking and when a patient opens one from the Appointments tab.
class AppointmentDetailsScreen extends StatefulWidget {
  /// Starting data. The screen then follows the live copy so status changes
  /// (doctor confirms, cancellation) show up without reopening.
  final AppointmentModel appointment;
  final ValueChanged<int> onNavSelected;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointment,
    required this.onNavSelected,
  });

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  bool _cancelling = false;

  String _statusMessage(String status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return 'Your doctor confirmed this appointment.';
      case AppointmentStatus.cancelled:
        return 'This appointment was cancelled.';
      case AppointmentStatus.completed:
        return 'This appointment is completed.';
      case AppointmentStatus.declined:
        return 'Your doctor could not take this appointment. Try another time.';
      case AppointmentStatus.expired:
        return 'This request was never answered and its time has passed.';
      default:
        return 'Waiting for your doctor to confirm this appointment.';
    }
  }

  Future<void> _cancel(AppointmentModel a) async {
    final controller = context.read<AppointmentController>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel appointment?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Your ${Fmt.weekdayTime(a.startTime)} time slot will be released.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SereniColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    final error = await controller.cancelAppointment(a);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Appointment cancelled')),
    );
    if (mounted) setState(() => _cancelling = false);
  }

  @override
  Widget build(BuildContext context) {
    final a =
        context.watch<AppointmentController>().appointmentById(
          widget.appointment.id,
        ) ??
        widget.appointment;
    final confirmedLike =
        a.status == AppointmentStatus.confirmed ||
        a.status == AppointmentStatus.completed;

    return Scaffold(
      backgroundColor: SereniColors.page,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---- Top bar ----
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
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
                      'Your Appointment',
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
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  // ---- Doctor card ----
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SereniColors.panel,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        _DoctorPhoto(
                          name: a.doctorName,
                          url: a.doctorPhotoUrl,
                          size: 66,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      a.doctorName,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: SereniColors.ink,
                                      ),
                                    ),
                                    Text(
                                      a.doctorSpecialty ??
                                          'Mental health professional',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        color: SereniColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              StatusChip(a.displayStatus),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const AppointmentDivider(),
                  const SizedBox(height: 14),

                  // ---- Schedule + actions ----
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: SereniColors.brand,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                Fmt.fullDate(a.startTime),
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                Fmt.weekdayTime(a.startTime),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: SereniColors.brand,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _CircleAction(
                        icon: Icons.check,
                        label: 'Appointment status',
                        filled: confirmedLike,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_statusMessage(a.displayStatus)),
                          ),
                        ),
                      ),
                      if (a.canCancel) ...[
                        const SizedBox(width: 8),
                        _CircleAction(
                          icon: Icons.close,
                          label: 'Cancel appointment',
                          filled: true,
                          loading: _cancelling,
                          onTap: _cancelling ? null : () => _cancel(a),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  const AppointmentDivider(),
                  const SizedBox(height: 16),

                  // ---- Patient information ----
                  _InfoRow(
                    'Booking For',
                    a.bookedForSelf ? 'Yourself' : 'Another Person',
                  ),
                  _InfoRow('Full Name', a.patientFullName),
                  _InfoRow('Age', '${a.patientAge}'),
                  _InfoRow('Gender', a.patientGender),
                  const SizedBox(height: 12),
                  const AppointmentDivider(),
                  const SizedBox(height: 16),

                  // ---- Problem ----
                  Text(
                    'Problem',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: SereniColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.concern,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.55,
                      color: SereniColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SereniNavBar(
          currentIndex: 3,
          onTap: (i) {
            Navigator.of(context).popUntil((r) => r.isFirst);
            widget.onNavSelected(i);
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: SereniColors.muted),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SereniColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final bool loading;
  final VoidCallback? onTap;
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: filled ? SereniColors.brand : SereniColors.panel,
            shape: BoxShape.circle,
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  icon,
                  size: 18,
                  color: filled ? Colors.white : SereniColors.brand,
                ),
        ),
      ),
    );
  }
}

/// The doctor's photo from the booking snapshot, or their initials.
class _DoctorPhoto extends StatelessWidget {
  final String name;
  final String? url;
  final double size;
  const _DoctorPhoto({
    required this.name,
    required this.url,
    required this.size,
  });

  String get _initials {
    final parts = name
        .replaceFirst(RegExp(r'^dr\.?\s+', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget initials() => Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.poppins(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: SereniColors.brand,
        ),
      ),
    );

    final hasUrl = url != null && url!.trim().isNotEmpty;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasUrl
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initials(),
              )
            : initials(),
      ),
    );
  }
}
