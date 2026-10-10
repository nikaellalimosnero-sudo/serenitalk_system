import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/sereni_widgets.dart';

class ComingSoonTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const ComingSoonTab({super.key, required this.icon, required this.title, required this.message});

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
            Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: SereniColors.ink)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: SereniColors.muted)),
          ],
        ),
      ),
    );
  }
}
