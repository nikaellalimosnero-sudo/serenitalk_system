import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inquiry_model.dart';
import '../models/user_model.dart';

class InquiryService {
  final CollectionReference<Map<String, dynamic>> _inquiries = FirebaseFirestore
      .instance
      .collection('inquiries');

  /// Sorted here instead of with orderBy so no composite index is needed.
  Stream<List<InquiryModel>> watchDoctorInquiries(String doctorId) {
    return _inquiries.where('doctor_id', isEqualTo: doctorId).snapshots().map((
      snap,
    ) {
      final list = snap.docs.map(InquiryModel.fromFirestore).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Doctor opened an inquiry. Returns null on success, or an error message.
  Future<String?> markRead(String inquiryId) async {
    try {
      await _inquiries.doc(inquiryId).update({'status': InquiryStatus.read});
      return null;
    } on FirebaseException {
      return 'Could not update the inquiry. Please try again.';
    }
  }

  /// For the patient side later (the Chat / "Ask a question" feature).
  /// Returns null on success, or an error message.
  Future<String?> sendInquiry({
    required UserModel patient,
    required UserModel doctor,
    required String message,
  }) async {
    if (!doctor.isDoctor) return 'You can only send questions to a doctor.';
    if (message.trim().length < 3) return 'Write your question first.';
    try {
      await _inquiries.add({
        'doctor_id': doctor.userId,
        'patient_user_id': patient.userId,
        'patient_name': patient.fullName,
        'patient_photo_url': patient.photoUrl,
        'message': message.trim(),
        'status': InquiryStatus.unread,
        'created_at': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException {
      return 'Could not send your question. Check your connection and try again.';
    }
  }
}
