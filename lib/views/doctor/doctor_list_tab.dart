import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/user_model.dart';
import '../widgets/sereni_widgets.dart';
import '../widgets/user_avatar.dart';

/// Home tab: greeting, search, and the "Top Doctors" list.
class DoctorListTab extends StatefulWidget {
  final ValueChanged<UserModel> onDoctorTap;
  const DoctorListTab({super.key, required this.onDoctorTap});

  @override
  State<DoctorListTab> createState() => _DoctorListTabState();
}

class _DoctorListTabState extends State<DoctorListTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showSortSheet(UserController users) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sort doctors by', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            for (final option in DoctorSort.values)
              ListTile(
                title: Text(option.label, style: GoogleFonts.poppins(fontSize: 14)),
                trailing: users.sort == option ? const Icon(Icons.check, color: SereniColors.brand) : null,
                onTap: () {
                  users.setSort(option);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final users = context.watch<UserController>();
    final me = auth.currentUserProfile;
    if (me == null) return const SizedBox.shrink();
    final doctors = users.visibleDoctors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      children: [
        // ---- Greeting row ----
        Row(
          children: [
            UserAvatar(user: me, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hi, WelcomeBack', style: GoogleFonts.poppins(fontSize: 10.5, color: SereniColors.brand)),
                  Text(me.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: SereniColors.ink)),
                ],
              ),
            ),
            _RoundIconButton(
              icon: Icons.notifications_none,
              label: 'Notifications',
              onTap: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('No new notifications'))),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ---- Search + sort ----
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: TextField(
                  controller: _search,
                  onChanged: context.read<UserController>().setQuery,
                  textInputAction: TextInputAction.search,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.black38),
                    prefixIcon: const Icon(Icons.search, color: SereniColors.ink),
                    suffixIcon: users.hasQuery
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _search.clear();
                              context.read<UserController>().setQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _RoundIconButton(icon: Icons.tune, label: 'Sort doctors', size: 46, onTap: () => _showSortSheet(users)),
          ],
        ),
        const SizedBox(height: 22),

        // ---- Section title ----
        Row(
          children: [
            Expanded(
              child: Text(users.hasQuery ? 'Results' : 'Top Doctors',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: SereniColors.ink)),
            ),
            if (users.canToggleAll)
              GestureDetector(
                onTap: users.toggleShowAll,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
                  decoration: BoxDecoration(color: SereniColors.brand, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(users.showAll ? 'show less' : 'see all',
                          style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white)),
                      const Icon(Icons.chevron_right, size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // ---- Doctor cards ----
        if (users.isLoading)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else if (users.errorMessage != null)
          Text(users.errorMessage!, style: GoogleFonts.poppins(fontSize: 13, color: SereniColors.error))
        else if (doctors.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              users.hasQuery ? 'No doctors match "${users.query}".' : 'No doctors are available yet. Check back soon.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: SereniColors.muted),
            ),
          )
        else
          for (final d in doctors)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DoctorCard(doctor: d, onTap: () => widget.onDoctorTap(d)),
            ),
      ],
    );
  }
}

class DoctorCard extends StatelessWidget {
  final UserModel doctor;
  final VoidCallback onTap;
  const DoctorCard({super.key, required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'View ${doctor.displayName}, ${doctor.specialty ?? 'doctor'}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 3,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 78,
              child: Row(
                children: [
                  UserAvatar(user: doctor, size: 66, height: 78, radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: SereniColors.ink)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 12, color: SereniColors.muted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                (doctor.availabilityHours?.trim().isNotEmpty ?? false) ? doctor.availabilityHours! : 'Hours not set',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 11, color: SereniColors.muted),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(doctor.feeLabel, style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFB300)),
                          const SizedBox(width: 2),
                          Text(doctor.ratingLabel, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Container(
                        width: 34,
                        height: 30,
                        decoration: BoxDecoration(color: SereniColors.brand, borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  const _RoundIconButton({required this.icon, required this.label, required this.onTap, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: Color(0xFFD9DFFF), shape: BoxShape.circle),
          child: Icon(icon, size: size * 0.5, color: SereniColors.brand),
        ),
      ),
    );
  }
}
