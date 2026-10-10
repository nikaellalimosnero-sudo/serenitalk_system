import 'package:cloud_firestore/cloud_firestore.dart';

/// Keep these strings in sync with firestore.rules.
class AppointmentStatus {
  static const pending = 'pending'; // booked by patient, waiting for doctor
  static const confirmed = 'confirmed';
  static const cancelled = 'cancelled';
  static const completed = 'completed';
  static const declined = 'declined'; // doctor said no; the slot is released

  static const expired = 'expired';
}

class PatientGender {
  static const male = 'Male';
  static const female = 'Female';
  static const other = 'Other';
  static const all = [male, female, other];
}

class AppointmentModel {
  final String id;
  final String doctorId;
  final String
  doctorName; // copied at booking time so lists need no extra reads
  final String? doctorPhotoUrl;
  final String? doctorSpecialty;
  final String patientUserId; // the account that made the booking
  final DateTime startTime;
  final DateTime endTime;

  // "Patient Details" section of the booking form
  final bool bookedForSelf; // "Yourself" vs "Another Person"
  final String patientFullName;
  final int patientAge;
  final String patientGender;
  final String concern; // "Describe your problem"

  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    this.doctorPhotoUrl,
    this.doctorSpecialty,
    required this.patientUserId,
    required this.startTime,
    required this.endTime,
    required this.bookedForSelf,
    required this.patientFullName,
    required this.patientAge,
    required this.patientGender,
    required this.concern,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;

  bool get isUpcoming => isActive && endTime.isAfter(DateTime.now());

  bool get canCancel => isUpcoming;

  /// A pending request whose time has passed without the doctor answering.
  bool get isExpired =>
      status == AppointmentStatus.pending && !endTime.isAfter(DateTime.now());

  /// What the patient should see: the stored status, except stale pending
  /// requests read as "Expired" instead of "Pending" forever.
  String get displayStatus => isExpired ? AppointmentStatus.expired : status;

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      doctorId: d['doctor_id'] ?? '',
      doctorName: d['doctor_name'] ?? '',
      doctorPhotoUrl: d['doctor_photo_url'],
      doctorSpecialty: d['doctor_specialty'],
      patientUserId: d['patient_user_id'] ?? '',
      startTime: (d['start_time'] as Timestamp).toDate(),
      endTime: (d['end_time'] as Timestamp).toDate(),
      bookedForSelf: d['booked_for_self'] ?? true,
      patientFullName: d['patient_full_name'] ?? '',
      patientAge: (d['patient_age'] as num?)?.toInt() ?? 0,
      patientGender: d['patient_gender'] ?? PatientGender.other,
      concern: d['concern'] ?? '',
      status: d['status'] ?? AppointmentStatus.pending,
      createdAt: (d['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (d['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
