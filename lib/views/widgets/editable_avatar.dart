import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_controller.dart';
import '../../models/user_model.dart';
import 'sereni_widgets.dart';
import 'user_avatar.dart';

/// Tap to pick a photo (camera or gallery). The image is uploaded to
/// Cloudinary and its link is saved on the user's profile automatically.
class EditableAvatar extends StatefulWidget {
  final UserModel user;
  final double size;
  const EditableAvatar({super.key, required this.user, this.size = 96});

  @override
  State<EditableAvatar> createState() => _EditableAvatarState();
}

class _EditableAvatarState extends State<EditableAvatar> {
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: SereniColors.brand,
              ),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: SereniColors.brand,
              ),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final users = context.read<UserController>();

    try {
      // Shrinking on the phone first keeps uploads fast and cheap.
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;

      setState(() => _uploading = true);
      final error = await users.updateProfilePhoto(
        widget.user.userId,
        picked.path,
      );
      messenger.showSnackBar(SnackBar(content: Text(error ?? 'Photo updated')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the camera or your photos. Check the app permissions.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Semantics(
      button: true,
      label: 'Change profile photo',
      child: GestureDetector(
        onTap: _uploading ? null : _choosePhoto,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(user: widget.user, size: size),
              if (_uploading)
                Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: size * 0.32,
                  height: size * 0.32,
                  decoration: BoxDecoration(
                    color: SereniColors.brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: size * 0.16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
