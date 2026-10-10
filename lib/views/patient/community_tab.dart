import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/community_controller.dart';
import '../../models/post_model.dart';
import '../widgets/community_widgets.dart';
import '../widgets/sereni_widgets.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

/// "Peer Community": browse posts by topic, upvote, and open a post to read
/// and write comments. The Chat tab of the patient app.
class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  final _search = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    final c = context.read<CommunityController>();
    setState(() => _searching = !_searching);
    if (!_searching) {
      _search.clear();
      c.setQuery('');
    }
  }

  void _showSortSheet(CommunityController c) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sort posts by',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            for (final option in PostSort.values)
              ListTile(
                title: Text(
                  option.label,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                trailing: c.sort == option
                    ? const Icon(Icons.check, color: SereniColors.brand)
                    : null,
                onTap: () {
                  c.setSort(option);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _upvote(CommunityController c, PostModel post) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await c.toggleUpvote(post);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _openPost(PostModel post) =>
      Navigator.of(context).push(PostDetailScreen.route(post));

  void _newPost() =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CreatePostScreen()));

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CommunityController>();
    final posts = c.visiblePosts;

    Widget body;
    if (c.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (c.errorMessage != null) {
      body = _Message(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        text: c.errorMessage!,
        onRetry: c.retry,
      );
    } else if (posts.isEmpty) {
      body = _Message(
        icon: Icons.forum_outlined,
        title: c.hasFilters ? 'No matching posts' : 'No posts yet',
        text: c.hasFilters
            ? 'Try another topic or search.'
            : 'Be the first to share something with the community.',
      );
    } else {
      body = ListView.separated(
        // Extra bottom space so the "new post" button never hides a card.
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 90),
        itemCount: posts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final post = posts[i];
          return PostCard(
            post: post,
            upvoted: c.hasUpvoted(post.id),
            onTap: () => _openPost(post),
            onUpvote: () => _upvote(c, post),
          );
        },
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            // ---- Header ----
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Peer Community',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: SereniColors.brand,
                      ),
                    ),
                  ),
                  _RoundIcon(
                    icon: _searching ? Icons.close : Icons.search,
                    label: _searching ? 'Close search' : 'Search posts',
                    onTap: _toggleSearch,
                  ),
                  const SizedBox(width: 8),
                  _RoundIcon(
                    icon: Icons.tune,
                    label: 'Sort posts',
                    onTap: () => _showSortSheet(c),
                  ),
                ],
              ),
            ),

            // ---- Search field ----
            if (_searching)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _search,
                    autofocus: true,
                    onChanged: c.setQuery,
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search posts',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black38,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: SereniColors.ink,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

            // ---- Topic chips ----
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  Center(
                    child: Text(
                      'Topic',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: SereniColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TopicChip(
                    label: 'All',
                    selected: c.category == null,
                    onTap: () => c.setCategory(null),
                  ),
                  for (final cat in PostCategory.all) ...[
                    const SizedBox(width: 8),
                    TopicChip(
                      label: cat,
                      selected: c.category == cat,
                      onTap: () => c.setCategory(cat),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(child: body),
          ],
        ),

        // ---- New post button ----
        Positioned(
          right: 18,
          bottom: 16,
          child: Semantics(
            button: true,
            label: 'Write a new post',
            child: Material(
              color: SereniColors.brand,
              elevation: 4,
              shadowColor: SereniColors.brand.withValues(alpha: 0.4),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: _newPost,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'New post',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RoundIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFD9DFFF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: SereniColors.brand),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback? onRetry;
  const _Message({
    required this.icon,
    required this.title,
    required this.text,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: SereniColors.brand),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: SereniColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: SereniColors.muted,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
