import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../widgets/sereni_widgets.dart';
import '../widgets/editable_avatar.dart';

class PatientProfileTab extends StatelessWidget {
  const PatientProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final me = auth.currentUserProfile;
    if (me == null) return const SizedBox.shrink();

    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SereniColors.brand),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13))),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Center(child: EditableAvatar(user: me, size: 96)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            me.fullName,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Center(
          child: Text(
            'Patient',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SereniColors.brand,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              row(Icons.email_outlined, me.email),
              row(Icons.phone_outlined, me.contactNumber),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SereniButton(label: 'Log out', onPressed: auth.logout),
      ],
    );
  }
}
