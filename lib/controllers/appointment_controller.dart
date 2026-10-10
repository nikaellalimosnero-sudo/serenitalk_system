import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/appointment_model.dart';
import '../models/user_model.dart';
import '../services/appointment_service.dart';
import '../services/availability_parser.dart';

/// One time button in the "Available Time" grid.
class SlotOption {
  final DateTime time;
  final bool isBooked;
  final bool isPast;
  const SlotOption(this.time, {required this.isBooked, required this.isPast});

  bool get isAvailable => !isBooked && !isPast;
}

class AppointmentController extends ChangeNotifier {
  final AppointmentService _service = AppointmentService();

  //Booking flow state
  UserModel? _doctor;
  List<DateTime> _dates = [];
  DateTime? _selectedDate;
  DateTime? _selectedSlot;
  Set<int> _booked = {};
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  StreamSubscription<Set<int>>? _slotsSub;

  //"My appointments" state
  List<AppointmentModel> _mine = [];
  bool _isLoadingMine = false;
  String? _mineError;
  String? _mineFor; // patient id the subscription below belongs to
  StreamSubscription<List<AppointmentModel>>? _mineSub;

  UserModel? get doctor => _doctor;
  List<DateTime> get dates => _dates;
  DateTime? get selectedDate => _selectedDate;
  DateTime? get selectedSlot => _selectedSlot;
  bool get isLoadingSlots => _isLoadingSlots;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasAvailability => _dates.isNotEmpty;
  bool get isLoadingMine => _isLoadingMine;
  String? get mineError => _mineError;
  bool get canSubmit =>
      _doctor != null && _selectedSlot != null && !_isSubmitting;

  /// Slots for the selected date, each marked available / booked / past.
  List<SlotOption> get slots {
    final d = _doctor, day = _selectedDate;
    if (d == null || day == null) return const [];
    final now = DateTime.now();
    return AvailabilityParser.slotsForDay(d, day)
        .map(
          (t) => SlotOption(
            t,
            isBooked: _booked.contains(t.millisecondsSinceEpoch),
            isPast: !t.isAfter(now),
          ),
        )
        .toList();
  }

  List<AppointmentModel> get upcoming =>
      _mine.where((a) => a.isUpcoming).toList();
  List<AppointmentModel> get history =>
      _mine.where((a) => !a.isUpcoming).toList().reversed.toList();

  // Booking flow
  // Call when the patient taps "Schedule" on a doctor's info page.
  void startBooking(UserModel doctor) {
    _slotsSub?.cancel();
    _doctor = doctor;
    _dates = AvailabilityParser.bookableDates(doctor);
    _selectedDate = null;
    _selectedSlot = null;
    _booked = {};
    _errorMessage = null;
    _isSubmitting = false;
    if (_dates.isEmpty) {
      notifyListeners();
    } else {
      selectDate(_dates.first);
    }
  }

  void selectDate(DateTime date) {
    final d = _doctor;
    if (d == null) return;
    _slotsSub?.cancel();
    _selectedDate = date;
    _selectedSlot = null;
    _booked = {};
    _errorMessage = null;
    _isLoadingSlots = true;
    notifyListeners();

    _slotsSub = _service
        .watchBookedSlots(d.userId, date)
        .listen(
          (booked) {
            _booked = booked;
            _isLoadingSlots = false;
            // Someone else grabbed the slot this patient had selected.
            final chosen = _selectedSlot;
            if (chosen != null &&
                booked.contains(chosen.millisecondsSinceEpoch)) {
              _selectedSlot = null;
              _errorMessage =
                  'That time was just booked. Please pick another slot.';
            }
            notifyListeners();
          },
          onError: (Object _) {
            _isLoadingSlots = false;
            _errorMessage = 'Could not load available times. Please try again.';
            notifyListeners();
          },
        );
  }

  void selectSlot(DateTime time) {
    final option = slots.where(
      (s) => s.time.millisecondsSinceEpoch == time.millisecondsSinceEpoch,
    );
    if (option.isEmpty || !option.first.isAvailable) return;
    _selectedSlot = time;
    _errorMessage = null;
    notifyListeners();
  }

  /// Returns true when the appointment was booked.
  Future<AppointmentModel?> bookAppointment({
    required UserModel patient,
    required bool bookedForSelf,
    required String patientFullName,
    required int patientAge,
    required String patientGender,
    required String concern,
  }) async {
    final d = _doctor, slot = _selectedSlot;
    if (d == null || slot == null) {
      _errorMessage = 'Pick a date and time first.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.bookAppointment(
      patient: patient,
      doctor: d,
      startTime: slot,
      bookedForSelf: bookedForSelf,
      patientFullName: patientFullName,
      patientAge: patientAge,
      patientGender: patientGender,
      concern: concern,
    );

    _isSubmitting = false;
    _errorMessage = result.error;
    final appointment = result.appointment;
    if (appointment != null) {
      _mine = [..._mine, appointment]
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      _selectedSlot = null;
    }
    notifyListeners();
    return appointment;
  }

  //Call when the booking screen closes.
  void endBooking() {
    _slotsSub?.cancel();
    _slotsSub = null;
    _doctor = null;
    _dates = [];
    _selectedDate = null;
    _selectedSlot = null;
    _booked = {};
    _errorMessage = null;
    _isSubmitting = false;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void loadMyAppointments(String patientId) {
    if (_mineFor == patientId && _mineSub != null) return;
    _mineSub?.cancel();
    _mineFor = patientId;
    _isLoadingMine = true;
    _mineError = null;
    notifyListeners();

    _mineSub = _service
        .watchPatientAppointments(patientId)
        .listen(
          (list) {
            _mine = list;
            _isLoadingMine = false;
            _mineError = null;
            notifyListeners();
          },
          onError: (Object _) {
            _isLoadingMine = false;
            _mineError = 'Failed to load your appointments.';
            notifyListeners();
          },
        );
  }

  /// Returns null on success, or an error message.
  Future<String?> cancelAppointment(AppointmentModel appointment) =>
      _service.cancelAppointment(appointment);

  /// Call on logout so the next account doesn't see stale data.
  void reset() {
    _mineSub?.cancel();
    _mineSub = null;
    _mineFor = null;
    _mine = [];
    _isLoadingMine = false;
    _mineError = null;
    endBooking();
  }

  @override
  void dispose() {
    _slotsSub?.cancel();
    _mineSub?.cancel();
    super.dispose();
  }

  AppointmentModel? appointmentById(String id) {
    for (final appointment in _mine) {
      if (appointment.id == id) {
        return appointment;
      }
    }
    return null;
  }
}
