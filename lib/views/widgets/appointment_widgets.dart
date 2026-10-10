import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/appointment_model.dart';
import 'sereni_widgets.dart';

class Fmt {
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  static String month(DateTime d) => _months[d.month - 1];
  static String monthShort(DateTime d) =>
      _months[d.month - 1].substring(0, 3).toUpperCase();
  static String weekday(DateTime d) => _weekdays[d.weekday - 1];
  static String monthYear(DateTime d) => '${month(d)} ${d.year}';
  static String fullDate(DateTime d) => '${month(d)} ${d.day}, ${d.year}';

  /// 10:00 AM, 1:30 PM
  static String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  /// WED, 10:00 AM
  static String weekdayTime(DateTime d) => '${weekday(d)}, ${time(d)}';

  static String statusLabel(String status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.declined:
        return 'Declined';
      case AppointmentStatus.expired:
        return 'Expired';
      default:
        return 'Pending';
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return const Color(0xFF1B8A4B);
      case AppointmentStatus.cancelled:
        return SereniColors.error;
      case AppointmentStatus.completed:
        return SereniColors.brand;
      case AppointmentStatus.declined:
        return SereniColors.error;
      case AppointmentStatus.expired:
        return SereniColors.muted;
      default:
        return const Color(0xFFB26A00);
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.declined:
        return Icons.block;
      case AppointmentStatus.expired:
        return Icons.event_busy_outlined;
      default:
        return Icons.hourglass_bottom;
    }
  }
}

/// White pill showing an appointment's status.
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = Fmt.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
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

/// The thin blue separator line used in the appointment designs.
class AppointmentDivider extends StatelessWidget {
  const AppointmentDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1.2, color: SereniColors.brand.withValues(alpha: 0.7));
}
