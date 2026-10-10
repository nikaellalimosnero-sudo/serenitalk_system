import 'package:cloud_firestore/cloud_firestore.dart';

/// Keep this list in sync with firestore.rules.
class PostCategory {
  static const anxiety = 'Anxiety';
  static const stress = 'Stress';
  static const depression = 'Depression';
  static const sleep = 'Sleep';
  static const relationships = 'Relationships';
  static const grief = 'Grief';
  static const other = 'Other';
  static const all = [
    anxiety,
    stress,
    depression,
    sleep,
    relationships,
    grief,
    other,
  ];
}

class PostLimits {
  static const titleMin = 3;
  static const titleMax = 120;
  static const bodyMax = 2000;
  static const commentMax = 1000;
}

class PostModel {
  final String id;
  final String authorId;
  final String authorAlias; // e.g. "quiet_river42" - never the real name
  final String category;
  final String title;
  final String body; // optional, may be empty
  final int upvoteCount;
  final int commentCount;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorAlias,
    required this.category,
    required this.title,
    required this.body,
    required this.upvoteCount,
    required this.commentCount,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: d['author_id'] ?? '',
      authorAlias: d['author_alias'] ?? 'anonymous',
      category: d['category'] ?? PostCategory.other,
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      upvoteCount: (d['upvote_count'] as num?)?.toInt() ?? 0,
      commentCount: (d['comment_count'] as num?)?.toInt() ?? 0,
      // null while the server timestamp of a fresh write is still pending
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class CommentModel {
  final String id;
  final String authorId;
  final String authorAlias;
  final String body;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.authorId,
    required this.authorAlias,
    required this.body,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      authorId: d['author_id'] ?? '',
      authorAlias: d['author_alias'] ?? 'anonymous',
      body: d['body'] ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
