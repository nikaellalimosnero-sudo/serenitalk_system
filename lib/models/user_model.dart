import 'package:cloud_firestore/cloud_firestore.dart';

/// The only two roles in SereniTalk. Keep these strings in sync with firestore.rules.
class UserRole {
  static const doctor = 'doctor';
  static const patient = 'patient';
}

class UserModel {
  final String userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String role; // 'doctor' or 'patient'
  final String email;
  final String contactNumber;
  final String status; // 'Active' or 'Inactive'

  // Doctor-only profile (doctors edit these themselves)
  final String? specialty;
  final String? photoUrl;
  final double? fee; // consultation fee in PHP
  final String? availabilityDays; // e.g. "Mon-Sat"
  final String? availabilityHours; // e.g. "10:30 AM - 3:30 PM"
  final String? bio; // "Profile" section
  final String? careerPath;
  final String? highlights;

  // Doctor-only, read-only from the app (set by the system / console).
  final double? rating; // null until the doctor has been rated
  final int reviewCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // For Push Notifications
  final String? fcmToken;

  UserModel({
    required this.userId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.role,
    required this.email,
    required this.contactNumber,
    required this.status,
    this.specialty,
    this.photoUrl,
    this.fee,
    this.availabilityDays,
    this.availabilityHours,
    this.bio,
    this.careerPath,
    this.highlights,
    this.rating,
    this.reviewCount = 0,
    this.createdAt,
    this.updatedAt,
    this.fcmToken,
  });

  String get fullName => [
    firstName,
    middleName,
    lastName,
  ].where((n) => n != null && n.isNotEmpty).join(' ');

  /// "Dr. Maria Reyes" - adds the title for doctors if it isn't already there.
  String get displayName {
    if (isDoctor &&
        !RegExp(r'^dr\.?\s', caseSensitive: false).hasMatch(fullName)) {
      return 'Dr. $fullName';
    }
    return fullName;
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    final s = '$f$l'.toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  String get feeLabel {
    final f = fee;
    if (f == null) return 'Fee not set';
    return 'Fee: ${f % 1 == 0 ? f.toInt() : f}Php';
  }

  String get ratingLabel => rating == null ? 'New' : rating!.toStringAsFixed(1);

  /// "Mon-Sat / 10:30 AM - 3:30 PM" (whatever the doctor filled in)
  String get availabilityLabel {
    final parts = [
      availabilityDays,
      availabilityHours,
    ].where((p) => p != null && p.trim().isNotEmpty).cast<String>();
    return parts.isEmpty ? 'Not set' : parts.join(' / ');
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      userId: id,
      firstName: data['first_name'] ?? '',
      middleName: data['middle_name'],
      lastName: data['last_name'] ?? '',
      role: data['role'] ?? UserRole.patient,
      email: data['email'] ?? '',
      contactNumber: data['contact_number'] ?? '',
      status: data['status'] ?? 'Active',
      specialty: data['specialty'],
      photoUrl: data['photo_url'],
      fee: (data['fee'] as num?)?.toDouble(),
      availabilityDays: data['availability_days'],
      availabilityHours: data['availability_hours'],
      bio: data['bio'],
      careerPath: data['career_path'],
      highlights: data['highlights'],
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: (data['review_count'] as num?)?.toInt() ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      fcmToken: data['fcm_token'],
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'role': role,
      'email': email,
      'contact_number': contactNumber,
      'status': status,
      'specialty': specialty,
      'photo_url': photoUrl,
      'fee': fee,
      'availability_days': availabilityDays,
      'availability_hours': availabilityHours,
      'bio': bio,
      'career_path': careerPath,
      'highlights': highlights,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'fcm_token': fcmToken,
    };
  }

  bool get isDoctor => role == UserRole.doctor;
  bool get isPatient => role == UserRole.patient;
  bool get isActive => status == 'Active';
}
