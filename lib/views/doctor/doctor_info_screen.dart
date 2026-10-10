import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_model.dart';
import '../widgets/sereni_nav_bar.dart';
import '../widgets/sereni_widgets.dart';
import '../widgets/user_avatar.dart';
import '../patient/book_appointment_screen.dart';

/// A doctor's profile: photo, specialty, rating, availability and background.
class DoctorInfoScreen extends StatefulWidget {
  final UserModel doctor;

  /// Called when the patient taps the nav bar on this page (after this page closes).
  final ValueChanged<int> onNavSelected;

  const DoctorInfoScreen({
    super.key,
    required this.doctor,
    required this.onNavSelected,
  });

  @override
  State<DoctorInfoScreen> createState() => _DoctorInfoScreenState();
}

class _DoctorInfoScreenState extends State<DoctorInfoScreen> {
  bool _favorite = false; // local only for now

  void _soon(String what) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$what is coming soon.')));

  @override
  Widget build(BuildContext context) {
    final d = widget.doctor;

    return Scaffold(
      backgroundColor: SereniColors.page,
      body: SafeArea(
        bottom: false,
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
                      'Doctor Info',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: SereniColors.brand,
                      ),
                    ),
                  ),
                  // Mirrors the back button's width so the title stays centred;
                  // search returns to the list where the search bar is.
                  IconButton(
                    tooltip: 'Search doctors',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.search,
                      size: 22,
                      color: SereniColors.brand,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                children: [
                  // ---- Profile card ----
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                    decoration: BoxDecoration(
                      color: SereniColors.panel,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: UserAvatar(user: d, size: 118),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          padding: const EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                d.displayName,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: SereniColors.ink,
                                ),
                              ),
                              Text(
                                d.specialty ?? 'Mental health professional',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: SereniColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFFFFB300),
                              text: d.ratingLabel,
                            ),
                            _InfoChip(
                              icon: Icons.chat_bubble_outline,
                              text: '${d.reviewCount}',
                            ),
                            _InfoChip(
                              icon: Icons.schedule,
                              text: d.availabilityLabel,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BookAppointmentScreen(
                                    doctor: d,
                                    onNavSelected: widget.onNavSelected,
                                  ),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: SereniColors.brand,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Schedule',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            _CircleIcon(
                              icon: Icons.info_outline,
                              label: 'Fee',
                              onTap: () => _soon('Fee details'),
                            ),
                            const SizedBox(width: 6),
                            _CircleIcon(
                              icon: Icons.help_outline,
                              label: 'Help',
                              onTap: () => _soon('Help'),
                            ),
                            const SizedBox(width: 6),
                            _CircleIcon(
                              icon: Icons.star_border,
                              label: 'Rate',
                              onTap: () => _soon('Rating'),
                            ),
                            const SizedBox(width: 6),
                            _CircleIcon(
                              icon: _favorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              label: _favorite
                                  ? 'Remove from favorites'
                                  : 'Add to favorites',
                              color: _favorite
                                  ? Colors.red
                                  : SereniColors.brand,
                              onTap: () =>
                                  setState(() => _favorite = !_favorite),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4, top: 6),
                      child: Text(
                        d.feeLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: SereniColors.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ---- Text sections ----
                  _Section(title: 'Profile', body: d.bio),
                  _Section(title: 'Career Path', body: d.careerPath),
                  _Section(title: 'Highlights', body: d.highlights),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SereniNavBar(
          currentIndex: 0,
          onTap: (i) {
            Navigator.of(context).pop();
            widget.onNavSelected(i);
          },
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  const _InfoChip({
    required this.icon,
    required this.text,
    this.iconColor = SereniColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: SereniColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _CircleIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = SereniColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final text = (body?.trim().isNotEmpty ?? false)
        ? body!.trim()
        : 'This doctor has not added this yet.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SereniColors.brand,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              height: 1.5,
              color: SereniColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
