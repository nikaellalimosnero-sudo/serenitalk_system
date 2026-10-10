import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment_model.dart';
import '../models/user_model.dart';
import 'availability_parser.dart';

class _SlotTakenException implements Exception {}

class _RequestUnavailableException implements Exception {
  final String message;
  _RequestUnavailableException(this.message);
}

class AppointmentBookingResult {
  final AppointmentModel? appointment;
  final String? error;

  const AppointmentBookingResult._({this.appointment, this.error});

  const AppointmentBookingResult.success(AppointmentModel appointment)
    : this._(appointment: appointment);
  const AppointmentBookingResult.failure(String error) : this._(error: error);
}

class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _slots =>
      _db.collection('booked_slots');

  static String slotId(String doctorId, DateTime start) =>
      '${doctorId}_${start.toUtc().millisecondsSinceEpoch}';

  /// Start times (as epoch millis) already taken for [doctorId] on [day].
  /// Live, so a slot grabbed by someone else disappears from the picker.
  Stream<Set<int>> watchBookedSlots(String doctorId, DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);
    return _slots
        .where('doctor_id', isEqualTo: doctorId)
        .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('start_time', isLessThan: Timestamp.fromDate(to))
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => (d.data()['start_time'] as Timestamp)
                    .toDate()
                    .millisecondsSinceEpoch,
              )
              .toSet(),
        );
  }

  Future<AppointmentBookingResult> bookAppointment({
    required UserModel patient,
    required UserModel doctor,
    required DateTime startTime,
    required bool bookedForSelf,
    required String patientFullName,
    required int patientAge,
    required String patientGender,
    required String concern,
  }) async {
    if (!doctor.isDoctor) {
      return const AppointmentBookingResult.failure(
        'You can only book an appointment with a doctor.',
      );
    }
    if (patientFullName.trim().length < 2) {
      return const AppointmentBookingResult.failure(
        "Enter the patient's full name.",
      );
    }
    if (patientAge < 0 || patientAge > 120) {
      return const AppointmentBookingResult.failure('Enter a valid age.');
    }
    if (!PatientGender.all.contains(patientGender)) {
      return const AppointmentBookingResult.failure('Choose a gender.');
    }
    if (concern.trim().length < 5) {
      return const AppointmentBookingResult.failure(
        'Briefly describe the problem.',
      );
    }

    final now = DateTime.now();
    if (!startTime.isAfter(now)) {
      return const AppointmentBookingResult.failure(
        'That time has already passed. Pick another slot.',
      );
    }

    // The slot must really be one of the doctor's published slots.
    final validSlots = AvailabilityParser.slotsForDay(doctor, startTime);
    final isValid = validSlots.any(
      (s) => s.millisecondsSinceEpoch == startTime.millisecondsSinceEpoch,
    );
    if (!isValid) {
      return const AppointmentBookingResult.failure(
        "That time is not in this doctor's schedule.",
      );
    }

    final endTime = startTime.add(
      const Duration(minutes: AvailabilityParser.slotMinutes),
    );
    final apptRef = _appointments.doc();
    final slotRef = _slots.doc(slotId(doctor.userId, startTime));

    try {
      await _db.runTransaction((tx) async {
        final existing = await tx.get(slotRef);
        if (existing.exists) throw _SlotTakenException();

        tx.set(apptRef, {
          'doctor_id': doctor.userId,
          'doctor_name': doctor.displayName,
          'doctor_photo_url': doctor.photoUrl,
          'doctor_specialty': doctor.specialty,
          'patient_user_id': patient.userId,
          'start_time': Timestamp.fromDate(startTime),
          'end_time': Timestamp.fromDate(endTime),
          'booked_for_self': bookedForSelf,
          'patient_full_name': patientFullName.trim(),
          'patient_age': patientAge,
          'patient_gender': patientGender,
          'concern': concern.trim(),
          'status': AppointmentStatus.pending,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        tx.set(slotRef, {
          'doctor_id': doctor.userId,
          'start_time': Timestamp.fromDate(startTime),
          'end_time': Timestamp.fromDate(endTime),
          'appointment_id': apptRef.id,
        });
      });
      return AppointmentBookingResult.success(
        AppointmentModel(
          id: apptRef.id,
          doctorId: doctor.userId,
          doctorName: doctor.displayName,
          doctorPhotoUrl: doctor.photoUrl,
          doctorSpecialty: doctor.specialty,
          patientUserId: patient.userId,
          startTime: startTime,
          endTime: endTime,
          bookedForSelf: bookedForSelf,
          patientFullName: patientFullName.trim(),
          patientAge: patientAge,
          patientGender: patientGender,
          concern: concern.trim(),
          status: AppointmentStatus.pending,
        ),
      );
    } on _SlotTakenException {
      return const AppointmentBookingResult.failure(
        'Sorry, that time was just booked. Please pick another slot.',
      );
    } on FirebaseException catch (e) {
      // A security-rules rejection on the slot also means someone beat us to it.
      if (e.code == 'permission-denied') {
        return const AppointmentBookingResult.failure(
          'That time is no longer available. Please pick another slot.',
        );
      }
      return const AppointmentBookingResult.failure(
        'Could not book your appointment. Check your connection and try again.',
      );
    }
  }

  /// The signed-in patient's own appointments, soonest first.
  Stream<List<AppointmentModel>> watchPatientAppointments(String patientId) =>
      _watch(_appointments.where('patient_user_id', isEqualTo: patientId));

  /// A doctor's appointments, soonest first (for the doctor side later).
  Stream<List<AppointmentModel>> watchDoctorAppointments(String doctorId) =>
      _watch(_appointments.where('doctor_id', isEqualTo: doctorId));

  // Sorted here instead of with orderBy so no composite index is needed.
  Stream<List<AppointmentModel>> _watch(Query<Map<String, dynamic>> query) {
    return query.snapshots().map((snap) {
      final list = snap.docs.map(AppointmentModel.fromFirestore).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    });
  }

  /// Cancels an appointment (patient or doctor) and frees the time slot.
  Future<String?> cancelAppointment(AppointmentModel appointment) async {
    if (!appointment.canCancel) {
      return 'This appointment can no longer be cancelled.';
    }
    try {
      final batch = _db.batch();
      batch.update(_appointments.doc(appointment.id), {
        'status': AppointmentStatus.cancelled,
        'updated_at': FieldValue.serverTimestamp(),
      });
      batch.delete(
        _slots.doc(slotId(appointment.doctorId, appointment.startTime)),
      );
      await batch.commit();
      return null;
    } on FirebaseException {
      return 'Could not cancel the appointment. Check your connection and try again.';
    }
  }

  /// Doctor accepts a pending appointment. Returns null on success.
  Future<String?> confirmAppointment(AppointmentModel appointment) =>
      _respondToRequest(appointment, AppointmentStatus.confirmed);

  /// Doctor declines a pending appointment and the time slot is released
  /// so another patient can book it. Returns null on success.
  Future<String?> declineAppointment(AppointmentModel appointment) =>
      _respondToRequest(appointment, AppointmentStatus.declined);

  Future<String?> _respondToRequest(
    AppointmentModel appointment,
    String newStatus,
  ) async {
    final apptRef = _appointments.doc(appointment.id);
    final slotRef = _slots.doc(
      slotId(appointment.doctorId, appointment.startTime),
    );
    final accepting = newStatus == AppointmentStatus.confirmed;

    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(apptRef);
        final data = snap.data();
        if (data == null) {
          throw _RequestUnavailableException('This request no longer exists.');
        }

        final status = data['status'] as String?;
        if (status == AppointmentStatus.cancelled) {
          throw _RequestUnavailableException(
            'The patient cancelled this appointment.',
          );
        }
        if (status != AppointmentStatus.pending) {
          throw _RequestUnavailableException(
            'This request was already answered.',
          );
        }
        final end = (data['end_time'] as Timestamp).toDate();
        if (!end.isAfter(DateTime.now())) {
          throw _RequestUnavailableException('This request has expired.');
        }

        tx.update(apptRef, {
          'status': newStatus,
          'updated_at': FieldValue.serverTimestamp(),
        });
        // Declining gives the time back; accepting keeps the slot locked.
        if (!accepting) tx.delete(slotRef);
      });
      return null;
    } on _RequestUnavailableException catch (e) {
      return e.message;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'You do not have permission to update this appointment. '
            'Check the Firestore rules for doctor appointment updates.';
      }
      return accepting
          ? 'Could not accept the appointment. Check your connection and try again.'
          : 'Could not decline the appointment. Check your connection and try again.';
    }
  }
}
