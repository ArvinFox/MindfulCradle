import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/constants/colors.dart';
import '/providers/language_provider.dart';

class DASS21HintOverlay extends StatefulWidget {
  final bool visible;
  final VoidCallback onClose;
  final bool isMobile;
  final Duration duration;
  final Curve curve;

  const DASS21HintOverlay({
    super.key,
    required this.visible,
    required this.onClose,
    required this.isMobile,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<DASS21HintOverlay> createState() => _DASS21HintOverlayState();
}

class _DASS21HintOverlayState extends State<DASS21HintOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getHintText(String lang) {
    if (lang == 'si') {
      return "මෙම පරීක්ෂණය සඳහා පිළිතුරු 1 - 4 සංඛ්‍යාවන් භාවිතා වේ.\n\n"
          "1 = මට කිසිසේත් අදාළ නැත.\n2 = මට තරමක් දුරට හෝ සමහර වෙලාවට අදාළයි\n3 = මට සැලකිය යුතු ප්‍රමාණයකට හෝ සැලකිය යුතු කාලයකට අදාළයි\n4 =මට බොහෝ දුරට හෝ බොහෝ වෙලාවට අදාළයි.";
    }
    return "For this questionnaire, please answer using numbers 1 - 4.\n\n"
        "1 = Did not apply to me at all\n2 = Applied to me to some degree, or some of the time\n3 = Applied to me to a considerable degree, or a good part of time\n4 = Applied to me very much, or most of the time";
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLang;
    final isSinhala = lang == 'si';
    final hintText = _getHintText(lang);
    final noteText = isSinhala
        ? "උදවු නැවත බැලීමට ප්‍රශ්න පිටුවේ පහළ වම් කොනේ ඇති ? ලකුණ ක්ලික් කරන්න"
        : "To see the hints again click on the ? on the bottom left corner on the questionnaire page";

    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1.0 : 0.0,
        duration: widget.duration,
        curve: widget.curve,
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
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.visible ? 6.0 : 0.0,
                  sigmaY: widget.visible ? 6.0 : 0.0,
                ),
                child: Container(
                  color: Colors.black.withOpacity(widget.visible ? 0.25 : 0.0),
                ),
              ),

              // Pulsing question mark
              Positioned(
                bottom: 40,
                left: 40,
                child: AnimatedOpacity(
                  opacity: widget.visible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 50,),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.help_outline,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Centered hint card
              Center(
                child: AnimatedScale(
                  scale: widget.visible ? 1.0 : 0.95,
                  duration: widget.duration,
                  curve: widget.curve,
                  child: Container(
                    width: widget.isMobile ? 340 : 480,
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: widget.onClose,
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
