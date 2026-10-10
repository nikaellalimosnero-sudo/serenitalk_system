import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/appointment_model.dart';
import '../models/inquiry_model.dart';
import '../services/appointment_service.dart';
import '../services/inquiry_service.dart';

/// Everything the doctor's Home screen and "Appointment requests" screen need.
/// Both screens read from this one controller,
class DoctorController extends ChangeNotifier {
  static const previewCount = 3;

  final AppointmentService _appointmentService = AppointmentService();
  final InquiryService _inquiryService = InquiryService();

  List<AppointmentModel> _appointments = []; // soonest first
  List<InquiryModel> _inquiries = []; // newest first
  bool _isLoading = false;
  String? _errorMessage;
  String? _appointmentsError;
  final Set<String> _busyIds = {}; // appointments being accepted / declined
  StreamSubscription<List<AppointmentModel>>? _appointmentsSub;
  StreamSubscription<List<InquiryModel>>? _inquiriesSub;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get appointmentsError => _appointmentsError;

  /// True while this appointment is being accepted/declined (disable its buttons).
  bool isBusy(String appointmentId) => _busyIds.contains(appointmentId);

  /// Waiting for the doctor's answer and not yet over.
  List<AppointmentModel> get pendingRequests {
    final now = DateTime.now();
    return _appointments
        .where(
          (a) =>
              a.status == AppointmentStatus.pending && a.endTime.isAfter(now),
        )
        .toList();
  }

  /// Accepted and still ahead.
  List<AppointmentModel> get upcoming {
    final now = DateTime.now();
    return _appointments
        .where(
          (a) =>
              a.status == AppointmentStatus.confirmed && a.endTime.isAfter(now),
        )
        .toList();
  }

  /// Everything else: finished, cancelled, declined, or never answered in time.
  /// Most recent first.
  List<AppointmentModel> get past {
    final now = DateTime.now();
    return _appointments
        .where((a) {
          final isPending = a.status == AppointmentStatus.pending;
          final isConfirmed = a.status == AppointmentStatus.confirmed;
          final stillAhead = a.endTime.isAfter(now);
          return !((isPending || isConfirmed) && stillAhead);
        })
        .toList()
        .reversed
        .toList();
  }

  // Home screen numbers

  /// "Today's sessions": accepted (or already completed) appointments today.
  int get todaysSessionsCount {
    final now = DateTime.now();
    return _appointments
        .where(
          (a) =>
              (a.status == AppointmentStatus.confirmed ||
                  a.status == AppointmentStatus.completed) &&
              a.startTime.year == now.year &&
              a.startTime.month == now.month &&
              a.startTime.day == now.day,
        )
        .length;
  }

  /// "New inquiries": inquiries the doctor hasn't opened yet.
  int get newInquiriesCount => _inquiries.where((i) => i.isNew).length;

  /// First few pending requests for the Home preview.
  List<AppointmentModel> get pendingPreview =>
      pendingRequests.take(previewCount).toList();

  /// Latest inquiries for the Home preview.
  List<InquiryModel> get recentInquiries =>
      _inquiries.take(previewCount).toList();

  /// "New patient" badge: true if this patient has no accepted or completed
  /// appointment with the doctor yet.
  bool isNewPatient(AppointmentModel a) => !_appointments.any(
    (o) =>
        o.id != a.id &&
        o.patientUserId == a.patientUserId &&
        (o.status == AppointmentStatus.confirmed ||
            o.status == AppointmentStatus.completed),
  );

  // Loading

  // Call once when the doctor's home screen opens.
  void load(String doctorId) {
    _appointmentsSub?.cancel();
    _inquiriesSub?.cancel();
    _isLoading = true;
    _errorMessage = null;
    _appointmentsError = null;
    _appointments = [];
    _inquiries = [];
    _busyIds.clear();
    notifyListeners();

    _appointmentsSub = _appointmentService
        .watchDoctorAppointments(doctorId)
        .listen(
          (list) {
            _appointments = list;
            _isLoading = false;
            _appointmentsError = null;
            notifyListeners();
          },
          onError: (Object _) {
            _isLoading = false;
            _appointmentsError =
                'Could not load appointments. Check that Firestore rules allow '
                'doctors to read appointments assigned to their user ID.';
            notifyListeners();
          },
        );

    _inquiriesSub = _inquiryService
        .watchDoctorInquiries(doctorId)
        .listen(
          (list) {
            _inquiries = list;
            notifyListeners();
          },
          onError: (Object _) {
            _errorMessage = 'Failed to load your inquiries.';
            notifyListeners();
          },
        );
  }

  // Actions

  /// Returns null on success, or an error message to show in a SnackBar.
  /// The lists update by themselves through the live stream.
  Future<String?> acceptAppointment(AppointmentModel appointment) =>
      _respond(appointment, _appointmentService.confirmAppointment);

  /// Declines the request and frees the time slot for other patients.
  /// Returns null on success, or an error message.
  Future<String?> declineAppointment(AppointmentModel appointment) =>
      _respond(appointment, _appointmentService.declineAppointment);

  Future<String?> _respond(
    AppointmentModel appointment,
    Future<String?> Function(AppointmentModel) action,
  ) async {
    if (_busyIds.contains(appointment.id)) return null; // ignore double taps
    _busyIds.add(appointment.id);
    notifyListeners();

    final error = await action(appointment);

    _busyIds.remove(appointment.id);
    notifyListeners();
    return error;
  }

  /// Returns null on success, or an error message.
  Future<String?> markInquiryRead(String inquiryId) =>
      _inquiryService.markRead(inquiryId);

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Call on logout so the next account doesn't see stale data.
  void reset() {
    _appointmentsSub?.cancel();
    _inquiriesSub?.cancel();
    _appointmentsSub = null;
    _inquiriesSub = null;
    _appointments = [];
    _inquiries = [];
    _busyIds.clear();
    _isLoading = false;
    _errorMessage = null;
    _appointmentsError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _appointmentsSub?.cancel();
    _inquiriesSub?.cancel();
    super.dispose();
  }
}
