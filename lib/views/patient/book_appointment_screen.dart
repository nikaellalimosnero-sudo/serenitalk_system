import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controllers/appointment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../widgets/appointment_widgets.dart';
import '../widgets/sereni_nav_bar.dart';
import '../widgets/sereni_widgets.dart';
import 'appointment_details_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final UserModel doctor;

  /// Called after the patient taps the nav bar (once this page has closed).
  final ValueChanged<int> onNavSelected;

  const BookAppointmentScreen({
    super.key,
    required this.doctor,
    required this.onNavSelected,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _concern = TextEditingController();
  late final AppointmentController _appointments;

  bool _forSelf = true;
  String? _gender;
  bool _genderMissing = false;

  @override
  void initState() {
    super.initState();
    _appointments = context.read<AppointmentController>();
    final patient = context.read<AuthController>().currentUserProfile;
    _name.text = patient?.fullName ?? '';
    if (patient != null) _appointments.loadMyAppointments(patient.userId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _appointments.startBooking(widget.doctor);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _concern.dispose();
    // Not during the unmount itself, so listeners aren't notified mid-teardown.
    Future.microtask(_appointments.endBooking);
    super.dispose();
  }

  void _setForSelf(bool value) {
    if (_forSelf == value) return;
    setState(() {
      _forSelf = value;
      _name.text = value
          ? (context.read<AuthController>().currentUserProfile?.fullName ?? '')
          : '';
    });
  }

  Future<void> _chooseMonth(List<DateTime> dates) async {
    final months = <DateTime>[];
    for (final date in dates) {
      final month = DateTime(date.year, date.month);
      if (!months.any(
        (existing) =>
            existing.year == month.year && existing.month == month.month,
      )) {
        months.add(month);
      }
    }

    final selectedMonth = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthPicker(
        months: months,
        selectedDate: _appointments.selectedDate,
      ),
    );
    if (!mounted || selectedMonth == null) return;

    final firstAvailableDate = dates.firstWhere(
      (date) =>
          date.year == selectedMonth.year && date.month == selectedMonth.month,
    );
    _appointments.selectDate(firstAvailableDate);
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    setState(() => _genderMissing = _gender == null);
    if (!formOk || _gender == null) return;

    if (_appointments.selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a date and a time first.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    final me = context.read<AuthController>().currentUserProfile!;
    final navigator = Navigator.of(context);

    final appointment = await _appointments.bookAppointment(
      patient: me,
      bookedForSelf: _forSelf,
      patientFullName: _name.text,
      patientAge: int.parse(_age.text.trim()),
      patientGender: _gender!,
      concern: _concern.text,
    );
    if (!mounted || appointment == null) return;

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailsScreen(
          appointment: appointment,
          onNavSelected: widget.onNavSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppointmentController>();
    final d = widget.doctor;
    final selectedDate = c.selectedDate;
    final selectedSlot = c.selectedSlot;
    final displayedMonth =
        selectedDate ?? (c.dates.isEmpty ? null : c.dates.first);
    final displayedDates = displayedMonth == null
        ? <DateTime>[]
        : c.dates
              .where(
                (date) =>
                    date.year == displayedMonth.year &&
                    date.month == displayedMonth.month,
              )
              .toList();

    return Scaffold(
      backgroundColor: SereniColors.page,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---- Top bar: back + doctor name pill ----
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
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: SereniColors.brand,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          d.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: c.doctor == null
                  ? const Center(child: CircularProgressIndicator())
                  : !c.hasAvailability
                  ? _NoTimes(doctor: d)
                  : ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      children: [
                        // ---- Date strip ----
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                          decoration: BoxDecoration(
                            color: SereniColors.panel,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _chooseMonth(c.dates),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      Fmt.monthYear(
                                        displayedMonth ?? DateTime.now(),
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: SereniColors.brand,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 18,
                                      color: SereniColors.brand,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 66,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: displayedDates.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, i) {
                                    final date = displayedDates[i];
                                    return _DateChip(
                                      date: date,
                                      selected:
                                          selectedDate != null &&
                                          date.year == selectedDate.year &&
                                          date.month == selectedDate.month &&
                                          date.day == selectedDate.day,
                                      onTap: () => c.selectDate(date),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ---- Available time ----
                        const _SectionLabel('Available Time'),
                        const SizedBox(height: 10),
                        if (c.isLoadingSlots)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final s in c.slots)
                                _TimeChip(
                                  option: s,
                                  selected:
                                      selectedSlot != null &&
                                      selectedSlot.millisecondsSinceEpoch ==
                                          s.time.millisecondsSinceEpoch,
                                  onTap: () => c.selectSlot(s.time),
                                ),
                            ],
                          ),
                        const SizedBox(height: 18),
                        const AppointmentDivider(),
                        const SizedBox(height: 16),

                        // ---- Patient details + problem ----
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionLabel('Patient Details'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _ChoicePill(
                                    label: 'Yourself',
                                    selected: _forSelf,
                                    onTap: () => _setForSelf(true),
                                  ),
                                  const SizedBox(width: 8),
                                  _ChoicePill(
                                    label: 'Another Person',
                                    selected: !_forSelf,
                                    onTap: () => _setForSelf(false),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SereniTextField(
                                label: 'Full Name',
                                controller: _name,
                                hint: 'Jane Doe',
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: (v) => Validators.required(
                                  v,
                                  'Enter the full name',
                                ),
                              ),
                              const SizedBox(height: 14),
                              SereniTextField(
                                label: 'Age',
                                controller: _age,
                                hint: '30',
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  final n = int.tryParse((v ?? '').trim());
                                  return (n == null || n < 0 || n > 120)
                                      ? 'Enter a valid age'
                                      : null;
                                },
                              ),
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 2,
                                  bottom: 6,
                                ),
                                child: Text(
                                  'Gender',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: SereniColors.ink,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  for (final g in PatientGender.all) ...[
                                    _ChoicePill(
                                      label: g,
                                      selected: _gender == g,
                                      onTap: () => setState(() {
                                        _gender = g;
                                        _genderMissing = false;
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                              if (_genderMissing)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 2,
                                    top: 6,
                                  ),
                                  child: Text(
                                    'Choose a gender',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: SereniColors.error,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              const AppointmentDivider(),
                              const SizedBox(height: 16),
                              SereniTextField(
                                label: 'Describe your problem',
                                controller: _concern,
                                hint: 'Enter your problem here...',
                                keyboardType: TextInputType.multiline,
                                minLines: 4,
                                maxLines: 8,
                                validator: (v) => Validators.required(
                                  v,
                                  'Briefly describe your problem',
                                  min: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ---- Summary + submit ----
                        if (selectedSlot != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '${Fmt.fullDate(selectedSlot)} · ${Fmt.weekdayTime(selectedSlot)}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: SereniColors.brand,
                              ),
                            ),
                          ),
                        if (c.errorMessage != null)
                          SereniAlert(c.errorMessage!),
                        SereniButton(
                          label: 'Book appointment',
                          loading: c.isSubmitting,
                          onPressed: _submit,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SereniNavBar(
          currentIndex: 3,
          onTap: (i) {
            Navigator.of(context).popUntil((r) => r.isFirst);
            widget.onNavSelected(i);
          },
        ),
      ),
    );
  }
}

class _NoTimes extends StatelessWidget {
  final UserModel doctor;
  const _NoTimes({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: SereniColors.brand,
            ),
            const SizedBox(height: 12),
            Text(
              'No open times',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: SereniColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${doctor.displayName} has no bookable times in the next year. Check back soon.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: SereniColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  final List<DateTime> months;
  final DateTime? selectedDate;

  const _MonthPicker({required this.months, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose a month'),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: ListView.builder(
          itemCount: months.length,
          itemBuilder: (context, index) {
            final month = months[index];
            final selected =
                month.year == selectedDate?.year &&
                month.month == selectedDate?.month;
            return ListTile(
              title: Text(Fmt.monthYear(month)),
              selected: selected,
              onTap: () => Navigator.of(context).pop(month),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: SereniColors.brand,
    ),
  );
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${Fmt.weekday(date)} ${Fmt.month(date)} ${date.day}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          decoration: BoxDecoration(
            color: selected ? SereniColors.brand : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : SereniColors.ink,
                ),
              ),
              Text(
                Fmt.weekday(date),
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : SereniColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final SlotOption option;
  final bool selected;
  final VoidCallback onTap;
  const _TimeChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = option.isAvailable;
    final Color bg = selected
        ? SereniColors.brand
        : available
        ? SereniColors.panel
        : SereniColors.field.withValues(alpha: 0.5);
    final Color fg = selected
        ? Colors.white
        : available
        ? SereniColors.ink
        : SereniColors.placeholder;

    return Semantics(
      button: true,
      enabled: available,
      selected: selected,
      label:
          '${Fmt.time(option.time)}${option.isBooked ? ', already booked' : ''}',
      child: GestureDetector(
        onTap: available ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            Fmt.time(option.time),
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
              decoration: option.isBooked ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoicePill({
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? SereniColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SereniColors.brand, width: 1.2),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : SereniColors.brand,
            ),
          ),
        ),
      ),
    );
  }
}
