import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_model.dart';
import 'sereni_widgets.dart';

/// Profile photo, or the person's initials when there is no photo (or it fails to load).
class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double size;
  final double? height; // defaults to size (square / circle)
  final double? radius; // null = fully round

  const UserAvatar({super.key, required this.user, this.size = 44, this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    final h = height ?? size;
    final url = user.photoUrl;

    Widget initials() => Container(
          color: SereniColors.panel,
          alignment: Alignment.center,
          child: Text(
            user.initials,
            style: GoogleFonts.poppins(
              fontSize: (size < h ? size : h) * 0.36,
              fontWeight: FontWeight.w700,
              color: SereniColors.brand,
            ),
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size / 2),
      child: SizedBox(
        width: size,
        height: h,
        child: (url != null && url.trim().isNotEmpty)
            ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => initials())
            : initials(),
      ),
    );
  }
}
