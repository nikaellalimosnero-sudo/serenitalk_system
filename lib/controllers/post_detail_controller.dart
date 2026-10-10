import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/community_model.dart';
import '../models/post_model.dart';
import '../services/community_service.dart';

/// Comments for ONE post. Created when the post screen opens and disposed
/// when it closes, so the live comment stream never outlives the screen.
class PostDetailController extends ChangeNotifier {
  final String postId;
  final CommunityService _service = CommunityService();

  List<CommentModel> _comments = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<CommentModel>>? _sub;

  PostDetailController(this.postId) {
    _sub = _service
        .watchComments(postId)
        .listen(
          (list) {
            _comments = list;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object _) {
            _isLoading = false;
            _errorMessage = 'Could not load the comments.';
            notifyListeners();
          },
        );
  }

  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns null on success, or an error message.
  Future<String?> addComment({required String uid, required String body}) =>
      _service.addComment(
        postId: postId,
        authorId: uid,
        authorAlias: CommunityAlias.forUid(uid),
        body: body,
      );

  Future<String?> editComment(CommentModel comment, String body) =>
      _service.editComment(
        postId: postId,
        commentId: comment.id,
        body: body,
      );

  Future<String?> deleteComment(CommentModel comment) =>
      _service.deleteComment(postId: postId, commentId: comment.id);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
