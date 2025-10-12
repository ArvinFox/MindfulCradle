import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/constants/colors.dart';
import '/providers/language_provider.dart';

class PWS18HintOverlay extends StatelessWidget {
  final bool visible;
  final VoidCallback onClose;
  final bool isMobile;
  final Duration duration;
  final Curve curve;

  const PWS18HintOverlay({
    super.key,
    required this.visible,
    required this.onClose,
    required this.isMobile,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  String _getHintText(String lang) {
    if (lang == 'si') {
      return "මෙම පරීක්ෂණය සඳහා පිළිතුරු 1 - 7 සංඛ්‍යාවන් භාවිතා වේ.\n\n"
          "1 = දැඩි ලෙස එකඟ\n2 = ටිකක් එකඟ\n3 = සාමාන්‍යයෙන් එකඟ\n"
          "4 = එකඟ නැත/නැත\n5 = සාමාන්‍යයෙන් අසම්මත\n6 = ටිකක් අසම්මත\n7 = දැඩි ලෙස අසම්මත";
    }
    return "For this questionnaire, please answer using numbers 1 - 7.\n\n"
        "1 = Strongly Agree\n2 = Somewhat Agree\n3 = A Little Agree\n"
        "4 = Neither Agree nor Disagree\n5 = A Little Disagree\n6 = Somewhat Disagree\n7 = Strongly Disagree";
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLang;
    final isSinhala = lang == 'si';
    final hintText = _getHintText(lang);
    final noteText = isSinhala
        ? "උදවු නැවත බැලීමට පහළ වම් කොනේ ඇති ? ලකුණ ක්ලික් කරන්න"
        : "To see the hints again click on the ? on the bottom left corner";

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: duration,
        curve: curve,
        child: DefaultTextStyle(
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.text,
            decoration: TextDecoration.none,
            height: 1.5,
          ),
          child: Stack(
            children: [
              // Blurred dimmed background
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: visible ? 6.0 : 0.0,
                  sigmaY: visible ? 6.0 : 0.0,
                ),
                child: Container(
                  color: Colors.black.withOpacity(visible ? 0.25 : 0.0),
                ),
              ),

              // Centered card
              Center(
                child: AnimatedScale(
                  scale: visible ? 1.0 : 0.95,
                  duration: duration,
                  curve: curve,
                  child: Container(
                    width: isMobile ? 340 : 480,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.help_outline,
                                color: Colors.orangeAccent,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isSinhala ? "උදවු" : "Hint",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          hintText,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          noteText,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.text.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: onClose,
                            child: Text(
                              isSinhala ? "හරි" : "OK",
                              style: GoogleFonts.poppins(
                                color: AppColors.buttonText,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
