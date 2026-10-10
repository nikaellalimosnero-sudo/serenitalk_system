import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../controllers/post_detail_controller.dart';
import '../../models/post_model.dart';
import '../widgets/community_widgets.dart';
import '../widgets/sereni_widgets.dart';

/// One post with its comments and a box to write a new comment.
/// Open it with `Navigator.push(PostDetailScreen.route(post))`.
class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  /// Wraps the screen with its own comments controller.
  static Route<void> route(PostModel post) => MaterialPageRoute(
    builder: (_) => ChangeNotifierProvider(
      create: (_) => PostDetailController(post.id),
      child: PostDetailScreen(post: post),
    ),
  );

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _upvote(PostModel post) async {
    final error = await context.read<CommunityController>().toggleUpvote(post);
    if (error != null && mounted) _toast(error);
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty || _sending) return;
    final me = context.read<AuthController>().currentUserProfile;
    if (me == null) return;
    final detail = context.read<PostDetailController>();
    FocusScope.of(context).unfocus();

    setState(() => _sending = true);
    final error = await detail.addComment(uid: me.userId, body: text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      _comment.clear();
    } else {
      _toast(error);
    }
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SereniColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true && mounted;
  }

  Future<void> _deletePost(PostModel post) async {
    if (!await _confirm(
      'Delete post?',
      'This removes your post and its comments from the community.',
      'Delete',
    )) {
      return;
    }
    if (!mounted) return;
    final community = context.read<CommunityController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final error = await community.deletePost(post.id);
    if (error == null) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Post deleted')));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _deleteComment(CommentModel comment) async {
    if (!await _confirm(
      'Delete comment?',
      'This cannot be undone.',
      'Delete',
    )) {
      return;
    }
    if (!mounted) return;
    final detail = context.read<PostDetailController>();
    final error = await detail.deleteComment(comment);
    if (error != null && mounted) _toast(error);
  }

  Future<void> _editComment(CommentModel comment) async {
    final body = await showDialog<String>(
      context: context,
      builder: (_) => _EditCommentDialog(initialBody: comment.body),
    );
    if (body == null || !mounted) return;
    final error = await context.read<PostDetailController>().editComment(
      comment,
      body,
    );
    if (error != null && mounted) _toast(error);
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityController>();
    final detail = context.watch<PostDetailController>();
    final myId = context.watch<AuthController>().currentUserProfile?.userId;
    final post = community.postById(widget.post.id) ?? widget.post;
    final isMine = myId != null && myId == post.authorId;
    final comments = detail.comments;

    return Scaffold(
      backgroundColor: SereniColors.page,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Top bar ----
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: SereniColors.brand,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Post',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: SereniColors.brand,
                      ),
                    ),
                  ),
                  isMine
                      ? IconButton(
                          tooltip: 'Delete post',
                          onPressed: () => _deletePost(post),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 22,
                            color: SereniColors.error,
                          ),
                        )
                      : const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                children: [
                  // ---- The post ----
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    decoration: BoxDecoration(
                      color: SereniColors.panel,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CategoryPill(post.category),
                        const SizedBox(height: 10),
                        Text(
                          post.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                            color: SereniColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Posted by ${post.authorAlias}${isMine ? ' (you)' : ''}'
                          ' · ${timeAgo(post.createdAt)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: SereniColors.muted,
                          ),
                        ),
                        if (post.body.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            post.body.trim(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              height: 1.55,
                              color: SereniColors.ink,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            UpvoteButton(
                              count: post.upvoteCount,
                              upvoted: community.hasUpvoted(post.id),
                              onTap: () => _upvote(post),
                            ),
                            CommentCount(post.commentCount),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ---- Comments ----
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'Comments (${post.commentCount})',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SereniColors.brand,
                      ),
                    ),
                  ),
                  if (detail.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (detail.errorMessage != null)
                    Text(
                      detail.errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: SereniColors.error,
                      ),
                    )
                  else if (comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'No comments yet. Be the first to offer some support.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: SereniColors.muted,
                        ),
                      ),
                    )
                  else
                    for (final c in comments)
                      _CommentTile(
                        comment: c,
                        isPostAuthor: c.authorId == post.authorId,
                        isMine: c.authorId == myId,
                        onEdit: () => _editComment(c),
                        onDelete: () => _deleteComment(c),
                      ),
                ],
              ),
            ),

            // ---- Write a comment ----
            Container(
              padding: const EdgeInsets.fromLTRB(18, 8, 12, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8)],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: SereniColors.field,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _comment,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            PostLimits.commentMax,
                          ),
                        ],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: SereniColors.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write a supportive comment...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: SereniColors.placeholder,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Send comment',
                          onPressed: _send,
                          icon: const Icon(
                            Icons.send_rounded,
                            color: SereniColors.brand,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCommentDialog extends StatefulWidget {
  final String initialBody;

  const _EditCommentDialog({required this.initialBody});

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late final TextEditingController _editor;

  @override
  void initState() {
    super.initState();
    _editor = TextEditingController(text: widget.initialBody);
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Edit comment',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: TextField(
        controller: _editor,
        autofocus: true,
        minLines: 2,
        maxLines: 5,
        maxLength: PostLimits.commentMax,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Write a supportive comment...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _editor.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool isPostAuthor;
  final bool isMine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CommentTile({
    required this.comment,
    required this.isPostAuthor,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _tag(String text) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: SereniColors.panel,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: SereniColors.brand,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  comment.authorAlias,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SereniColors.ink,
                  ),
                ),
              ),
              if (isPostAuthor) _tag('Author'),
              if (isMine) _tag('You'),
              const SizedBox(width: 8),
              Text(
                timeAgo(comment.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: SereniColors.muted,
                ),
              ),
              const Spacer(),
              if (isMine) ...[
                IconButton(
                  tooltip: 'Edit comment',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: SereniColors.muted,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete comment',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: SereniColors.muted,
                  ),
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              comment.body,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                height: 1.5,
                color: SereniColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
