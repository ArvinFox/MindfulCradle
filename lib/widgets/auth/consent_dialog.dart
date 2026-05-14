import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../screens/profile/privacy_policy_screen.dart';
import '../../utils/translate.dart';
import '../gradient_button.dart';

/// GDPR / Privacy Policy Consent Dialog shown during new-user sign-up.
class ConsentDialog extends StatefulWidget {
  final String langCode;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ConsentDialog({
    super.key,
    required this.langCode,
    required this.onAccept,
    required this.onDecline,
  });

  /// Show the consent dialog and return [true] if the user accepted.
  static Future<bool?> show(BuildContext context, String langCode) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConsentDialog(
        langCode: langCode,
        onAccept: () => Navigator.of(context).pop(true),
        onDecline: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  State<ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<ConsentDialog> {
  bool _isChecked = false;

  void _openPolicy(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final t = Translate.withLang(widget.langCode);
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;

    final title = t.auth('consentDialogTitle');
    final acceptText = t.auth('consentAgreeButton');
    final declineText = t.auth('consentDeclineButton');
    final checkboxText = t.auth('consentCheckboxText');
    final viewPolicyText = t.auth('consentReadPolicy');

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width < 720 ? width - 24 : 640,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 16 : 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.heroGradientStart,
                      AppColors.heroGradientMid,
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ──────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(compact ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Intro blurb
                      Text(
                        t.auth('consentDialogSubtitle'),
                        style: GoogleFonts.roboto(
                          fontSize: compact ? 13 : 14,
                          height: 1.55,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Data points
                      _ConsentPoint(
                        icon: Icons.folder_open_rounded,
                        compact: compact,
                        title: t.auth('consentPoint1Title'),
                        body: t.auth('consentPoint1Body'),
                      ),
                      _ConsentPoint(
                        icon: Icons.psychology_rounded,
                        compact: compact,
                        title: t.auth('consentPoint2Title'),
                        body: t.auth('consentPoint2Body'),
                      ),
                      _ConsentPoint(
                        icon: Icons.lock_rounded,
                        compact: compact,
                        title: t.auth('consentPoint3Title'),
                        body: t.auth('consentPoint3Body'),
                      ),
                      _ConsentPoint(
                        icon: Icons.verified_user_rounded,
                        compact: compact,
                        title: t.auth('consentPoint4Title'),
                        body: t.auth('consentPoint4Body'),
                      ),

                      const SizedBox(height: 4),

                      // View full policy link
                      GestureDetector(
                        onTap: () => _openPolicy(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            viewPolicyText,
                            style: GoogleFonts.poppins(
                              fontSize: compact ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Agreement checkbox
                      CheckboxListTile(
                        value: _isChecked,
                        onChanged: (value) {
                          setState(() => _isChecked = value ?? false);
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                        title: Text(
                          checkboxText,
                          style: GoogleFonts.poppins(
                            fontSize: compact ? 12 : 13,
                            height: 1.45,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Buttons ──────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 20,
                  0,
                  compact ? 16 : 20,
                  compact ? 16 : 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onDecline();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.35),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(
                          declineText,
                          style: GoogleFonts.poppins(
                            fontSize: compact ? 13 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GradientButton(
                        onPressed: _isChecked
                            ? () {
                                HapticFeedback.mediumImpact();
                                widget.onAccept();
                              }
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        borderRadius: BorderRadius.circular(12),
                        child: Text(
                          acceptText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: compact ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widget ─────────────────────────────────────────────────────────────

class _ConsentPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool compact;

  const _ConsentPoint({
    required this.icon,
    required this.title,
    required this.body,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.roboto(
                    fontSize: compact ? 12 : 13,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
