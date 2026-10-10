import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/cloudinary_service.dart';
import '../services/user_service.dart';

enum DoctorSort {
  rating('Top rated'),
  fee('Lowest fee'),
  name('Name (A-Z)');

  const DoctorSort(this.label);
  final String label;
}

class UserController extends ChangeNotifier {
  static const _topCount = 4; // "Top Doctors" shows this many until "see all"

  final UserService _userService = UserService();
  final CloudinaryService _cloudinary = CloudinaryService();

  List<UserModel> _doctors = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _query = '';
  DoctorSort _sort = DoctorSort.rating;
  bool _showAll = false;
  StreamSubscription<List<UserModel>>? _doctorsSubscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DoctorSort get sort => _sort;
  bool get showAll => _showAll;
  bool get hasQuery => _query.trim().isNotEmpty;
  String get query => _query.trim();

  /// Only worth showing the "see all" button when there is something to expand.
  bool get canToggleAll => !hasQuery && _doctors.length > _topCount;

  List<UserModel> get visibleDoctors {
    final q = _query.trim().toLowerCase();
    var list = _doctors.where((d) {
      if (q.isEmpty) return true;
      return d.displayName.toLowerCase().contains(q) ||
          (d.specialty ?? '').toLowerCase().contains(q);
    }).toList()..sort(_compare);
    if (q.isEmpty && !_showAll && list.length > _topCount) {
      list = list.sublist(0, _topCount);
    }
    return list;
  }

  int _compare(UserModel a, UserModel b) {
    switch (_sort) {
      case DoctorSort.rating:
        final r = (b.rating ?? 0).compareTo(a.rating ?? 0);
        return r != 0
            ? r
            : a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      case DoctorSort.fee:
        final fa = a.fee ?? double.infinity; // doctors without a fee go last
        final fb = b.fee ?? double.infinity;
        return fa.compareTo(fb);
      case DoctorSort.name:
        return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    }
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setSort(DoctorSort value) {
    _sort = value;
    notifyListeners();
  }

  void toggleShowAll() {
    _showAll = !_showAll;
    notifyListeners();
  }

  Future<void> loadDoctors() async {
    await _doctorsSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _doctorsSubscription = _userService.getDoctors().listen(
      (doctors) {
        _doctors = doctors;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = 'Failed to load doctors. Please try again.';
        notifyListeners();
      },
    );
  }

  /// Doctor saves their own public profile. Returns null on success.
  Future<String?> saveDoctorProfile(String uid, Map<String, dynamic> data) =>
      _userService.updateDoctorProfile(uid, data);

  /// Uploads a picked photo to Cloudinary, then saves its URL on the user's
  /// profile (works for both doctors and patients). Returns null on success.
  Future<String?> updateProfilePhoto(String uid, String filePath) async {
    try {
      final url = await _cloudinary.uploadImage(filePath);
      return await _userService.updatePhotoUrl(uid, url);
    } on CloudinaryException catch (e) {
      return e.message;
    }
  }

  @override
  void dispose() {
    _doctorsSubscription?.cancel();
    super.dispose();
  }
}
