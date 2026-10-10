import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/post_model.dart';
import 'sereni_widgets.dart';

/// "just now", "5m ago", "2h ago", "3d ago", "2w ago".
String timeAgo(DateTime time) {
  final d = DateTime.now().difference(time);
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${(d.inDays / 7).floor()}w ago';
}

/// The small blue topic label on top of every post ("Anxiety").
class CategoryPill extends StatelessWidget {
  final String label;
  const CategoryPill(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: SereniColors.brand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Selectable topic chip (feed filter and new-post topic picker).
class TopicChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const TopicChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? SereniColors.brand : SereniColors.field,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : SereniColors.brand,
            ),
          ),
        ),
      ),
    );
  }
}

/// Up-arrow + count. Highlighted when the signed-in user has upvoted.
class UpvoteButton extends StatelessWidget {
  final int count;
  final bool upvoted;
  final VoidCallback onTap;
  const UpvoteButton({
    super.key,
    required this.count,
    required this.upvoted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: upvoted,
      label: upvoted
          ? 'Remove upvote, $count upvotes'
          : 'Upvote, $count upvotes',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: upvoted ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: upvoted ? SereniColors.brand : SereniColors.ink,
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: upvoted ? FontWeight.w700 : FontWeight.w500,
                  color: upvoted ? SereniColors.brand : SereniColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Speech-bubble + comment count.
class CommentCount extends StatelessWidget {
  final int count;
  const CommentCount(this.count, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 15,
            color: SereniColors.ink,
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: GoogleFonts.poppins(fontSize: 12, color: SereniColors.ink),
          ),
        ],
      ),
    );
  }
}

/// One post in the feed.
class PostCard extends StatelessWidget {
  final PostModel post;
  final bool upvoted;
  final VoidCallback onTap;
  final VoidCallback onUpvote;
  const PostCard({
    super.key,
    required this.post,
    required this.upvoted,
    required this.onTap,
    required this.onUpvote,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${post.category} post: ${post.title}. ${post.upvoteCount} upvotes, '
          '${post.commentCount} comments.',
      child: Material(
        color: SereniColors.panel,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryPill(post.category),
                const SizedBox(height: 8),
                Text(
                  post.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: SereniColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Posted by ${post.authorAlias} · ${timeAgo(post.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: SereniColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    UpvoteButton(
                      count: post.upvoteCount,
                      upvoted: upvoted,
                      onTap: onUpvote,
                    ),
                    CommentCount(post.commentCount),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
