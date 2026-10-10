import '../models/user_model.dart';

/// Doctors type their availability as free text ("Mon-Sat", "10:30 AM - 3:30 PM").
/// This turns that text into real dates and time slots a patient can book.
class AvailabilityParser {
  static const slotMinutes = 30;
  static const bookingWindowDays = 365;

  static const _dayIndex = {
    'mon': DateTime.monday,
    'tue': DateTime.tuesday,
    'wed': DateTime.wednesday,
    'thu': DateTime.thursday,
    'fri': DateTime.friday,
    'sat': DateTime.saturday,
    'sun': DateTime.sunday,
  };

  /// "Mon-Sat", "Mon, Wed, Fri", "Mon-Fri & Sun", "Daily" -> {1..7}. Null if unreadable.
  static Set<int>? parseDays(String? raw) {
    final text = (raw ?? '').trim().toLowerCase();
    if (text.isEmpty) return null;
    if (text.contains('daily') || text.contains('every day')) {
      return {1, 2, 3, 4, 5, 6, 7};
    }

    final result = <int>{};
    for (final token in text.split(RegExp(r'[,&/]|\band\b'))) {
      final t = token.trim();
      if (t.isEmpty) continue;
      final parts = t.split(RegExp(r'\s*(?:-|–|—|\bto\b)\s*'));
      final first = _dayOf(parts.first);
      if (first == null) return null;
      if (parts.length == 1) {
        result.add(first);
        continue;
      }
      final last = _dayOf(parts.last);
      if (last == null) return null;
      // Walk forward so ranges like "Fri-Mon" wrap around the week.
      var d = first;
      result.add(d);
      while (d != last) {
        d = d % 7 + 1;
        result.add(d);
      }
    }
    return result.isEmpty ? null : result;
  }

  static int? _dayOf(String s) {
    final t = s.trim();
    return t.length < 3 ? null : _dayIndex[t.substring(0, 3)];
  }

  /// "10:30 AM - 3:30 PM" -> (start: 630, end: 930) in minutes after midnight.
  static ({int start, int end})? parseHours(String? raw) {
    final m = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*([ap])\.?m\.?\s*(?:-|–|—|\bto\b)\s*(\d{1,2})(?::(\d{2}))?\s*([ap])\.?m\.?',
      caseSensitive: false,
    ).firstMatch(raw ?? '');
    if (m == null) return null;

    int toMinutes(String h, String? min, String ap) {
      final hour = int.parse(h);
      if (hour < 1 || hour > 12) return -1;
      return (hour % 12 + (ap.toLowerCase() == 'p' ? 12 : 0)) * 60 +
          (int.tryParse(min ?? '0') ?? 0);
    }

    final start = toMinutes(m.group(1)!, m.group(2), m.group(3)!);
    final end = toMinutes(m.group(4)!, m.group(5), m.group(6)!);
    if (start < 0 || end < 0 || end <= start) return null;
    return (start: start, end: end);
  }

  /// Every slot start time for [doctor] on the calendar day of [day].
  static List<DateTime> slotsForDay(UserModel doctor, DateTime day) {
    final days = parseDays(doctor.availabilityDays);
    final hours = parseHours(doctor.availabilityHours);
    if (days == null || hours == null || !days.contains(day.weekday)) {
      return const [];
    }
    final slots = <DateTime>[];
    for (var m = hours.start; m + slotMinutes <= hours.end; m += slotMinutes) {
      slots.add(DateTime(day.year, day.month, day.day, m ~/ 60, m % 60));
    }
    return slots;
  }

  /// The next [bookingWindowDays] days on which the doctor still has a future slot.
  static List<DateTime> bookableDates(UserModel doctor) {
    final now = DateTime.now();
    final dates = <DateTime>[];
    for (var i = 0; i < bookingWindowDays; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      if (slotsForDay(doctor, day).any((s) => s.isAfter(now))) dates.add(day);
    }
    return dates;
  }
}
