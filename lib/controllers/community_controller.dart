import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/community_model.dart';
import '../models/post_model.dart';
import '../services/community_service.dart';

enum PostSort {
  newest('Newest'),
  top('Most upvoted'),
  discussed('Most discussed');

  const PostSort(this.label);
  final String label;
}

/// The community feed: posts, which ones I upvoted, plus the topic filter,
/// search text and sort order the Community tab shows.
class CommunityController extends ChangeNotifier {
  final CommunityService _service = CommunityService();

  List<PostModel> _posts = [];
  Set<String> _myUpvotes = {};
  String? _uid;
  String? _category; // null = "All"
  String _query = '';
  PostSort _sort = PostSort.newest;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<PostModel>>? _postsSub;
  StreamSubscription<Set<String>>? _votesSub;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get category => _category;
  PostSort get sort => _sort;
  String get query => _query.trim();
  bool get hasFilters => _category != null || query.isNotEmpty;

  /// The signed-in user's anonymous name, e.g. "quiet_river42".
  String? get myAlias => _uid == null ? null : CommunityAlias.forUid(_uid!);

  bool hasUpvoted(String postId) => _myUpvotes.contains(postId);

  PostModel? postById(String id) {
    for (final p in _posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// What the feed shows: filtered by topic and search, then sorted.
  List<PostModel> get visiblePosts {
    final q = _query.trim().toLowerCase();
    final list = _posts.where((p) {
      if (_category != null && p.category != _category) return false;
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.body.toLowerCase().contains(q);
    }).toList()..sort(_compare);
    return list;
  }

  int _compare(PostModel a, PostModel b) {
    int newest() => b.createdAt.compareTo(a.createdAt);
    switch (_sort) {
      case PostSort.newest:
        return newest();
      case PostSort.top:
        final r = b.upvoteCount.compareTo(a.upvoteCount);
        return r != 0 ? r : newest();
      case PostSort.discussed:
        final r = b.commentCount.compareTo(a.commentCount);
        return r != 0 ? r : newest();
    }
  }

  void setCategory(String? value) {
    _category = value;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setSort(PostSort value) {
    _sort = value;
    notifyListeners();
  }

  /// Safe to call more than once: does nothing if already watching this user.
  void load(String uid) {
    if (_uid == uid && _postsSub != null) return;
    _postsSub?.cancel();
    _votesSub?.cancel();
    _uid = uid;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _postsSub = _service.watchPosts().listen(
      (posts) {
        _posts = posts;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = error is FirebaseException &&
                error.code == 'permission-denied'
            ? 'Firestore rules blocked access to community posts. Allow signed-in '
                  'patients to read posts.'
            : 'Failed to load the community. Please try again.';
        debugPrint('Community feed failed: $error');
        notifyListeners();
      },
    );

    _votesSub = _service
        .watchMyUpvotes(uid)
        .listen(
          (ids) {
            _myUpvotes = ids;
            notifyListeners();
          },
          onError: (Object _) {
            // Not fatal: the feed still works, upvotes just aren't highlighted.
          },
        );
  }

  /// Restarts the feed streams after a load error.
  void retry() {
    final uid = _uid;
    if (uid == null) return;
    _postsSub?.cancel();
    _votesSub?.cancel();
    _postsSub = null;
    _votesSub = null;
    load(uid);
  }

  /// Upvote or remove the upvote. Returns null on success, or an error message.
  /// The feed updates itself instantly from the local Firestore cache.
  Future<String?> toggleUpvote(PostModel post) {
    final uid = _uid;
    if (uid == null) return Future.value('Please log in again.');
    return _service.setUpvote(
      postId: post.id,
      uid: uid,
      upvote: !hasUpvoted(post.id),
    );
  }

  /// Returns null on success, or an error message.
  Future<String?> createPost({
    required String category,
    required String title,
    required String body,
  }) {
    final uid = _uid;
    if (uid == null) return Future.value('Please log in again.');
    return _service.createPost(
      authorId: uid,
      authorAlias: CommunityAlias.forUid(uid),
      category: category,
      title: title,
      body: body,
    );
  }

  Future<String?> deletePost(String postId) => _service.deletePost(postId);

  /// Call on logout so the next account doesn't see stale data.
  void reset() {
    _postsSub?.cancel();
    _votesSub?.cancel();
    _postsSub = null;
    _votesSub = null;
    _uid = null;
    _posts = [];
    _myUpvotes = {};
    _category = null;
    _query = '';
    _sort = PostSort.newest;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _postsSub?.cancel();
    _votesSub?.cancel();
    super.dispose();
  }
}
