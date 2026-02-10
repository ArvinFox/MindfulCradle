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

    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.6,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
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
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Decline button
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onDecline();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            declineText,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Accept button
        ElevatedButton(
          onPressed: _isChecked
              ? () {
                  HapticFeedback.mediumImpact();
                  widget.onAccept();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.buttonText,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            acceptText,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
