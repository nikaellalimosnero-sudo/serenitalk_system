import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/post_model.dart';

class CommunityService {
  /// Newest posts loaded into the feed (pagination can come later).
  static const feedLimit = 100;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');
  CollectionReference<Map<String, dynamic>> _upvotes(String uid) =>
      _db.collection('users').doc(uid).collection('upvotes');
  CollectionReference<Map<String, dynamic>> _comments(String postId) =>
      _posts.doc(postId).collection('comments');

  // Feed

  /// Latest posts, newest first. Category / search / sort happen in the
  /// controller so no composite index is needed.
  Stream<List<PostModel>> watchPosts() {
    return _posts
        .orderBy('created_at', descending: true)
        .limit(feedLimit)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());
  }

  /// Ids of the posts [uid] has upvoted.
  Stream<Set<String>> watchMyUpvotes(String uid) {
    return _upvotes(uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  // Posts

  /// Returns null on success, or an error message.
  Future<String?> createPost({
    required String authorId,
    required String authorAlias,
    required String category,
    required String title,
    required String body,
  }) async {
    final t = title.trim();
    final b = body.trim();
    if (!PostCategory.all.contains(category)) return 'Choose a topic.';
    if (t.length < PostLimits.titleMin) return 'Give your post a title.';
    if (t.length > PostLimits.titleMax) {
      return 'Keep the title under ${PostLimits.titleMax} characters.';
    }
    if (b.length > PostLimits.bodyMax) {
      return 'Keep the details under ${PostLimits.bodyMax} characters.';
    }

    try {
      await _posts.add({
        'author_id': authorId,
        'author_alias': authorAlias,
        'category': category,
        'title': t,
        'body': b,
        'upvote_count': 0,
        'comment_count': 0,
        'created_at': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException catch (e) {
      debugPrint('Community post publish failed (${e.code}): ${e.message}');
      if (e.code == 'permission-denied') {
        return 'Firestore rules blocked publishing. Allow signed-in patients '
            'to create community posts.';
      }
      if (e.code == 'unavailable') {
        return 'Could not reach the community. Check your connection and try again.';
      }
      return 'Could not publish your post. Check your connection and try again.';
    }
  }

  /// Author deletes their own post. (Its comments become unreachable.)
  Future<String?> deletePost(String postId) async {
    try {
      await _posts.doc(postId).delete();
      return null;
    } on FirebaseException {
      return 'Could not delete the post. Please try again.';
    }
  }

  /// Adds or removes [uid]'s upvote. The marker and the counter change in one
  /// batch, which is also what the security rules require.
  Future<String?> setUpvote({
    required String postId,
    required String uid,
    required bool upvote,
  }) async {
    try {
      final batch = _db.batch();
      final voteRef = _upvotes(uid).doc(postId);
      if (upvote) {
        batch.set(voteRef, {'created_at': FieldValue.serverTimestamp()});
      } else {
        batch.delete(voteRef);
      }
      batch.update(_posts.doc(postId), {
        'upvote_count': FieldValue.increment(upvote ? 1 : -1),
      });
      await batch.commit();
      return null;
    } on FirebaseException {
      return 'Could not save your upvote. Please try again.';
    }
  }

  // Comments

  /// Oldest first, like a conversation.
  Stream<List<CommentModel>> watchComments(String postId) {
    return _comments(postId)
        .orderBy('created_at')
        .snapshots()
        .map((snap) => snap.docs.map(CommentModel.fromFirestore).toList());
  }

  /// Returns null on success, or an error message.
  Future<String?> addComment({
    required String postId,
    required String authorId,
    required String authorAlias,
    required String body,
  }) async {
    final text = body.trim();
    if (text.isEmpty) return 'Write something first.';
    if (text.length > PostLimits.commentMax) {
      return 'Keep comments under ${PostLimits.commentMax} characters.';
    }

    try {
      final batch = _db.batch();
      batch.set(_comments(postId).doc(), {
        'author_id': authorId,
        'author_alias': authorAlias,
        'body': text,
        'created_at': FieldValue.serverTimestamp(),
      });
      batch.update(_posts.doc(postId), {
        'comment_count': FieldValue.increment(1),
      });
      await batch.commit();
      return null;
    } on FirebaseException {
      return 'Could not post your comment. Check your connection and try again.';
    }
  }

  /// Updates the body of an existing comment without changing its timestamp
  /// or the post's comment count.
  Future<String?> editComment({
    required String postId,
    required String commentId,
    required String body,
  }) async {
    final text = body.trim();
    if (text.isEmpty) return 'Write something first.';
    if (text.length > PostLimits.commentMax) {
      return 'Keep comments under ${PostLimits.commentMax} characters.';
    }

    try {
      await _comments(postId).doc(commentId).update({'body': text});
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Firestore rules blocked editing. Allow comment authors to '
            'update their comment body.';
      }
      if (e.code == 'unavailable') {
        return 'Could not reach the community. Check your connection and try again.';
      }
      return 'Could not update the comment. Please try again.';
    }
  }

  /// Author deletes their own comment.
  Future<String?> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      final batch = _db.batch();
      batch.delete(_comments(postId).doc(commentId));
      batch.update(_posts.doc(postId), {
        'comment_count': FieldValue.increment(-1),
      });
      await batch.commit();
      return null;
    } on FirebaseException {
      return 'Could not delete the comment. Please try again.';
    }
  }
}
