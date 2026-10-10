import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/community_controller.dart';
import '../../models/post_model.dart';
import '../widgets/community_widgets.dart';
import '../widgets/sereni_widgets.dart';

/// Write a new community post. It is published under the user's anonymous
/// alias - never their real name.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _category;
  bool _categoryMissing = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    setState(() => _categoryMissing = _category == null);
    if (!formOk || _category == null) return;
    FocusScope.of(context).unfocus();

    final community = context.read<CommunityController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await community.createPost(
      category: _category!,
      title: _title.text,
      body: _body.text,
    );

    if (!mounted) return;
    if (error == null) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Post published')));
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final alias = context.read<CommunityController>().myAlias ?? 'anonymous';

    return Scaffold(
      backgroundColor: SereniColors.page,
      body: SafeArea(
        child: Column(
          children: [
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
                      'New post',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: SereniColors.brand,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  SereniPanel(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null) SereniAlert(_error!),
                          Padding(
                            padding: const EdgeInsets.only(left: 2, bottom: 8),
                            child: Text(
                              'Topic',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: SereniColors.ink,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final cat in PostCategory.all)
                                TopicChip(
                                  label: cat,
                                  selected: _category == cat,
                                  onTap: () => setState(() {
                                    _category = cat;
                                    _categoryMissing = false;
                                  }),
                                ),
                            ],
                          ),
                          if (_categoryMissing)
                            Padding(
                              padding: const EdgeInsets.only(left: 2, top: 6),
                              child: Text(
                                'Choose a topic',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: SereniColors.error,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          SereniTextField(
                            label: 'Title',
                            controller: _title,
                            hint: "What's on your mind?",
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 3,
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.length < PostLimits.titleMin) {
                                return 'Give your post a title';
                              }
                              if (s.length > PostLimits.titleMax) {
                                return 'Keep it under ${PostLimits.titleMax} characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          SereniTextField(
                            label: 'Details (optional)',
                            controller: _body,
                            hint: 'Share more if you want to...',
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 5,
                            maxLines: 10,
                            validator: (v) =>
                                (v?.trim().length ?? 0) > PostLimits.bodyMax
                                ? 'Keep it under ${PostLimits.bodyMax} characters'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 15,
                                color: SereniColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'You will post as $alias. Your real name is never shown.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: SereniColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.favorite_border,
                                size: 15,
                                color: SereniColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'If you are in immediate danger or thinking about harming '
                                  'yourself, please contact your local emergency number or '
                                  'a crisis line right away. This community is peer support, '
                                  'not emergency help.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: SereniColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SereniButton(
                            label: 'Post',
                            loading: _saving,
                            onPressed: _submit,
                          ),
                        ],
                      ),
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
