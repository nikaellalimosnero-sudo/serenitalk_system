import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );

  /// What a patient sees: the list of doctors.
  Stream<List<UserModel>> getDoctors() {
    return _users
        .where('role', isEqualTo: UserRole.doctor)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList(),
        );
  }

  /// A doctor saving their own public profile. Rating / review count are
  Future<String?> updateDoctorProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _users.doc(uid).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException {
      return 'Could not save your profile. Check your connection and try again.';
    }
  }

  Future<String?> updatePhotoUrl(String uid, String url) =>
      updateDoctorProfile(uid, {'photo_url': url});

  Stream<UserModel?> getUserById(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }
}
