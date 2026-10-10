import 'package:cloud_firestore/cloud_firestore.dart';

class InquiryStatus {
  static const unread = 'new'; // patient sent it, doctor hasn't opened it
  static const read = 'read';
}

/// A short question a patient sends a doctor before (or instead of) booking,
/// e.g. "Asked about session rates".
class InquiryModel {
  final String id;
  final String doctorId;
  final String patientUserId;
  final String patientName; // copied at send time so lists need no extra reads
  final String? patientPhotoUrl;
  final String message;
  final String status;
  final DateTime createdAt;

  const InquiryModel({
    required this.id,
    required this.doctorId,
    required this.patientUserId,
    required this.patientName,
    this.patientPhotoUrl,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  bool get isNew => status == InquiryStatus.unread;

  factory InquiryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InquiryModel(
      id: doc.id,
      doctorId: d['doctor_id'] ?? '',
      patientUserId: d['patient_user_id'] ?? '',
      patientName: d['patient_name'] ?? '',
      patientPhotoUrl: d['patient_photo_url'],
      message: d['message'] ?? '',
      status: d['status'] ?? InquiryStatus.unread,
      // null while the server timestamp of a fresh write is still pending
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
