import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors sampled from the SereniTalk login design.
class SereniColors {
  static const page = Color(0xFFE8EBFF);
  static const panel = Color(0xFFC5CCFF);
  static const field = Color(0xFFDADEFF);
  static const ink = Color(0xFF0E1330);
  static const muted = Color(0xFF4A5280);
  static const brand = Color(0xFF2F55E8);
  static const teal = Color(0xFF2B86B6);
  static const placeholder = Color(0xFF8792EC);
  static const error = Color(0xFFB3261E);
}

/// Page background + white rounded card, like the design. Scrolls when the
/// keyboard is open or on small phones.
class SereniShell extends StatelessWidget {
  final Widget child;
  const SereniShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SereniColors.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(14, 28, 14, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Heart logo + "Sereni / Talk" + "Mental Health Support".
class SereniBrand extends StatelessWidget {
  final bool compact;
  const SereniBrand({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/logo.svg',
          width: compact ? 64 : 100,
          semanticsLabel: 'SereniTalk logo',
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          compact ? 'SereniTalk' : 'Sereni\nTalk',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: compact ? 24 : 34,
            fontWeight: FontWeight.w300,
            height: 1.05,
            letterSpacing: 0.5,
            color: SereniColors.teal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mental Health Support',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: SereniColors.brand,
          ),
        ),
      ],
    );
  }
}

/// The lavender rounded panel that holds the form.
class SereniPanel extends StatelessWidget {
  final Widget child;
  const SereniPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: SereniColors.panel,
        borderRadius: BorderRadius.circular(30),
      ),
      child: child,
    );
  }
}

class SereniTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final void Function(String)? onSubmitted;
  final int maxLines;
  final int? minLines;

  const SereniTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.isPassword = false,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  State<SereniTextField> createState() => _SereniTextFieldState();
}

class _SereniTextFieldState extends State<SereniTextField> {
  bool _obscure = true;

  OutlineInputBorder _border([Color? color, double width = 2]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: color == null
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: SereniColors.ink,
            ),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          minLines: widget.isPassword ? 1 : widget.minLines,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          autocorrect: false,
          enableSuggestions: !widget.isPassword,
          style: GoogleFonts.poppins(fontSize: 15, color: SereniColors.ink),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 15,
              color: SereniColors.placeholder,
            ),
            filled: true,
            fillColor: SereniColors.field,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorStyle: GoogleFonts.poppins(fontSize: 11.5, color: SereniColors.error),
            border: _border(),
            enabledBorder: _border(),
            focusedBorder: _border(SereniColors.brand),
            errorBorder: _border(SereniColors.error, 1.5),
            focusedErrorBorder: _border(SereniColors.error),
            suffixIcon: widget.isPassword
                ? IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: SereniColors.ink,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Big pill button, as in the design.
class SereniButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;

  const SereniButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.color = SereniColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.72,
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: color.withValues(alpha: 0.7),
              disabledForegroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 4,
              shadowColor: color.withValues(alpha: 0.4),
            ),
            onPressed: loading ? null : onPressed,
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : Text(label, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class SereniAlert extends StatelessWidget {
  final String message;
  const SereniAlert(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SereniColors.error, width: 1.5),
        ),
        child: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500, color: SereniColors.error),
        ),
      ),
    );
  }
}

/// Shared validators so login and sign-up behave the same.
class Validators {
  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter your email';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s)) return 'Enter a valid email address';
    return null;
  }

  static String? newPassword(String? v) {
    final s = v ?? '';
    if (s.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
      return 'Include at least one letter and one number';
    }
    return null;
  }

  static String? required(String? v, String message, {int min = 2}) =>
      (v == null || v.trim().length < min) ? message : null;
}
