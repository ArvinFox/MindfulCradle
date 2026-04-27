import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

/// GDPR Consent Dialog
/// Displays data collection information and requires user consent
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

  /// Show the consent dialog
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

  @override
  Widget build(BuildContext context) {
    final isSinhala = widget.langCode == 'si';
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;

    final title = isSinhala ? 'දත්ත හා පෞද්ගලිකත්වය' : 'Data & Privacy';
    final content = isSinhala
        ? 'Mindful Cradle ඔබගේ අත්දැකීම පුද්ගලීකරණය කිරීමට සහ සේවා වැඩිදියුණු කිරීමට දත්ත එකතු කරයි.\n\nඑකතු කරන දත්ත:\n• සෞඛ්‍ය ලකුණු (DASS-21, MAAS, PWS-18)\n• ගර්භණී සතිය සහ මූලික පැතිකඩ\n• යෙදුම භාවිතා සංඛ්‍යාලේඛන'
        : 'Mindful Cradle collects data to personalize your experience and improve our services.\n\nData we collect:\n• Health scores (DASS-21, MAAS, PWS-18)\n• Pregnancy week and basic profile\n• App usage statistics';

    final acceptText = isSinhala
        ? 'අනුමත කර ඉදිරියට යන්න'
        : 'Accept & Continue';
    final declineText = isSinhala ? 'අවලංගු කරන්න' : 'Cancel';
    final checkboxText = isSinhala
        ? 'මම භාවිත නියම හා පෞද්ගලිකත්ව ප්‍රතිපත්තියට එකඟ වෙමි'
        : 'I agree to the Terms & Conditions and Privacy Policy';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width < 720 ? width - 24 : 640,
          maxHeight: MediaQuery.of(context).size.height * 0.84,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content,
                          style: GoogleFonts.poppins(
                            fontSize: compact ? 13 : 14,
                            height: 1.55,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 14),
                        CheckboxListTile(
                          value: _isChecked,
                          onChanged: (value) {
                            setState(() => _isChecked = value ?? false);
                          },
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            checkboxText,
                            style: GoogleFonts.poppins(
                              fontSize: compact ? 12 : 13,
                              height: 1.4,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                      child: ElevatedButton(
                        onPressed: _isChecked
                            ? () {
                                HapticFeedback.mediumImpact();
                                widget.onAccept();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.buttonText,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          acceptText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: compact ? 13 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
