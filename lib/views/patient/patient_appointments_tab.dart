import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/appointment_controller.dart';
import '../../models/appointment_model.dart';
import '../widgets/appointment_widgets.dart';
import '../widgets/sereni_widgets.dart';
import 'appointment_details_screen.dart';

/// The patient's "Appointments" tab: every booking with its live status,
/// split into Upcoming and History. Tap one to open its details.
class PatientAppointmentsTab extends StatefulWidget {
  /// Passed on to the details screen so its nav bar can switch tabs.
  final ValueChanged<int> onNavSelected;
  const PatientAppointmentsTab({super.key, required this.onNavSelected});

  @override
  State<PatientAppointmentsTab> createState() => _PatientAppointmentsTabState();
}

class _PatientAppointmentsTabState extends State<PatientAppointmentsTab> {
  bool _showHistory = false;

  void _open(AppointmentModel a) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailsScreen(
          appointment: a,
          onNavSelected: widget.onNavSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppointmentController>();
    final upcoming = c.upcoming;
    final history = c.history;
    final list = _showHistory ? history : upcoming;

    Widget body;
    if (c.isLoadingMine) {
      body = const Center(child: CircularProgressIndicator());
    } else if (c.mineError != null) {
      body = _Message(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        text: c.mineError!,
      );
    } else if (list.isEmpty) {
      body = _Message(
        icon: Icons.calendar_today_outlined,
        title: _showHistory ? 'No past appointments' : 'No upcoming sessions',
        text: _showHistory
            ? 'Finished, cancelled and declined appointments will show up here.'
            : 'Book a doctor from the Home tab and your appointment will appear here.',
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) =>
            _AppointmentCard(appointment: list[i], onTap: () => _open(list[i])),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Text(
            'Appointments',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: SereniColors.brand,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Row(
            children: [
              _TabPill(
                label: 'Upcoming (${upcoming.length})',
                selected: !_showHistory,
                onTap: () => setState(() => _showHistory = false),
              ),
              const SizedBox(width: 8),
              _TabPill(
                label: 'History',
                selected: _showHistory,
                onTap: () => setState(() => _showHistory = true),
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;
  const _AppointmentCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Semantics(
      button: true,
      label:
          'Appointment with ${a.doctorName}, ${Fmt.fullDate(a.startTime)}, '
          '${Fmt.time(a.startTime)}, ${Fmt.statusLabel(a.displayStatus)}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 3,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _Thumb(name: a.doctorName, url: a.doctorPhotoUrl, size: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: SereniColors.ink,
                        ),
                      ),
                      Text(
                        a.doctorSpecialty ?? 'Mental health professional',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: SereniColors.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: SereniColors.brand,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${Fmt.fullDate(a.startTime)} · ${Fmt.time(a.startTime)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SereniColors.brand,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _StatusBadge(a.displayStatus),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: SereniColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Status pill tinted with its own colour (works on the white card).
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = Fmt.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Fmt.statusIcon(status), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            Fmt.statusLabel(status),
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? SereniColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SereniColors.brand, width: 1.2),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : SereniColors.brand,
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _Message({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: SereniColors.brand),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: SereniColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: SereniColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Doctor photo from the booking snapshot, or their initials.
class _Thumb extends StatelessWidget {
  final String name;
  final String? url;
  final double size;
  const _Thumb({required this.name, required this.url, required this.size});

  String get _initials {
    final parts = name
        .replaceFirst(RegExp(r'^dr\.?\s+', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final last = parts.length > 1 ? parts.last[0] : '';
    return '${parts.first[0]}$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget initials() => Container(
      color: SereniColors.panel,
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
